//
//  StoreKitManager.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 2/20/24.
//

import Foundation
import StoreKit

//alias
//The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
// the renewal states of auto-renewable subscriptions.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

//MARK: Step 1 - Create the class, implement the protocols
class StoreKitManager: ObservableObject {
    
    static let shared: StoreKitManager = StoreKitManager()
    
    private var subscriptions: [Product] = []
    private var purchasedSubscriptions: [Product] = []
    
    private var subscriptionGroupStatus: RenewalState?
    
    private let productIDs = ["com.BrettB.Home_Bake_Shop_Assistant_Annual_Subscription"]
    var updateListenerTask : Task<Void, Error>? = nil
    
    init() {
        
        //Start a transaction listener as close to app launch as possible so you don't miss a transaction
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
            updateListenerTask?.cancel()
        }
    
    //called inside the init()
    func requestProducts() async {
        do {
            // request from the app store using the product ids (hardcoded)
            subscriptions = try await Product.products(for: productIDs)
            print(subscriptions)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }
    
    //called inside the init()
    func listenForTransactions() -> Task<Void, Error> {
            return Task.detached {
                //Iterate through any transactions that don't come from a direct call to `purchase()`.
                for await result in Transaction.updates {
                    do {
                        let transaction = try self.checkVerified(result)
                        // deliver products to the user
                        await self.updateCustomerProductStatus()
                        
                        await transaction.finish()
                    } catch {
                        print("transaction failed verification")
                    }
                }
            }
        }
    
    // purchase the product
       func purchase(_ product: Product) async throws -> Transaction? {
           let result = try await product.purchase()
           
           switch result {
           case .success(let verification):
               //Check whether the transaction is verified. If it isn't,
               //this function rethrows the verification error.
               let transaction = try checkVerified(verification)
               
               //The transaction is verified. Deliver content to the user.
               await updateCustomerProductStatus()
               
               //Always finish a transaction.
               await transaction.finish()

               return transaction
           case .userCancelled, .pending:
               return nil
           default:
               return nil
           }
       }
    
    //Called inside the purchase function, to verify a transaction
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    //Called inside the purchase function, updates: purchasedSubscriptions: [Product] = [] with the newly purchased subscription
    func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                    case .autoRenewable:
                        if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                            purchasedSubscriptions.append(subscription)
                        }
                    default:
                        break
                }
                //Always finish a transaction.
                await transaction.finish()
            } catch {
                print("failed updating products")
            }
        }
    }
    
    func getSubscriptionStatus(product: Product) async {
            guard let subscription = product.subscription else {
                // Not a subscription
                return
            }
            do {
                let statuses = try await subscription.status

                for status in statuses {
                    let info = try checkVerified(status.renewalInfo)
                    switch status.state {
                    case .subscribed:
                        if info.willAutoRenew {
                            debugPrint("getSubscriptionStatus user subscription is active.")
                            return
                        } else {
                            debugPrint("getSubscriptionStatus user subscription is expiring.")
                            return
                        }
                    case .inBillingRetryPeriod:
                        debugPrint("getSubscriptionStatus user subscription is in billing retry period.")
                        return
                    case .inGracePeriod:
                        debugPrint("getSubscriptionStatus user subscription is in grace period.")
                        return
                    case .expired:
                        debugPrint("getSubscriptionStatus user subscription is expired.")
                        return
                    case .revoked:
                        debugPrint("getSubscriptionStatus user subscription was revoked.")
                        return
                    default:
                        fatalError("getSubscriptionStatus WARNING STATE NOT CONSIDERED.")
                    }
                }
            } catch {
                // do nothing
            }
            return
        }
}

//Called inside the checkVerified function
public enum StoreError: Error {
    case failedVerification
}

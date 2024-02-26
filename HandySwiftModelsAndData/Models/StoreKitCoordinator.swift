//
//  StoreKitManager.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 2/20/24.
//

import Foundation
import StoreKit

//Step 3A:
typealias Transaction = StoreKit.Transaction
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

class StoreKitCoordinator: NSObject {
    
    //MARK: Step 1
    /* You need to establish a place where Xcode can reference the productIDs of your offered products. You can either: a) create a new plist where the Key is the name of the product and the Value is the productID or b) store your productIDs in an array like:
     private let productIDs = ["productID1", "productID2"] */
    
    //MARK: Step 2
    /* If you created a plist, consider creating an "Offering Configuration" file that gathers the Offering Plist and makes the identifiers available for consumption to the StoreKitCoordinator. You can get more details for this at:
     https://www.delasign.com/blog/xcode-storekit-coordinator/ */
    
    //MARK: Step 3
    /* Create additional Models & Utilities:
     3A: Create 3 typealiases
     3B: Create an enum for a Store Error (See bottom of code for 3B)
     3C: Create an enum for subscription levels. This step is only required if your App uses one or more Subscription Groups which have multiple levels of service.
     */
    
    //MARK: Step 4 - Create the Coordinator
    
    // MARK: 4A) Variables
    static let identifier: String = "[StoreKitCoordinator]"
    static let shared: StoreKitCoordinator = StoreKitCoordinator()
    
    // A configuration that holds the Ids and the functionality to access them. This is created in Step 2
    let configuration: OfferingConfiguration = OfferingConfiguration()
    // A transaction listener to listen to transactions on init and through out the apps use.
    private var updateListenerTask: Task<Void, Error>?

    // MARK: 4A) Offering Arrays
    // Arrays are initially empty and are filled in when we gather the products
    public var consumables: [Product] = []
    public var nonConsumables: [Product] = []
    public var subscriptions: [Product] = []
    public var nonRenewables: [Product] = []
    
    // Arrays that hold the purchases products
    public var purchasedConsumables: [Product] = []
    public var purchasedNonConsumables: [Product] = []
    public var purchasedSubscriptions: [Product] = []
    public var purchasedNonRenewables: [Product] = []
    
    // A variable to hold the Subscription Group Renewal State, if you have more than one subscription group, you will need more than one.
    public var subscriptionGroupStatus: RenewalState?

    // MARK: 4A) Lifecycle
    func initialize() {
        // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        updateListenerTask = listenForTransactions()

        Task { [weak self] in
            guard let self = self else { return }
            // During store initialization, request products from the App Store.
            await self.requestProducts()

            // Deliver products that the customer purchases.
            await self.updateCustomerProductStatus()
        }
    }

    deinit {
        // Deinitialize configuration
        updateListenerTask?.cancel()
    }

}

//MARK: 4B) Get

extension StoreKitCoordinator {

    func requestProducts() async {
        guard let offering = configuration.offering else {
            return
        }
        do {
            // Request products from the App Store using the identifiers that the Products.plist file defines.
            let storeProducts = try await Product.products(for: offering.values)

            var newConsumables: [Product] = []
            var newNonConsumables: [Product] = []
            var newSubscriptions: [Product] = []
            var newNonRenewables: [Product] = []

            // Filter the products into categories based on their type.
            for product in storeProducts {
                switch product.type {
                case .consumable:
                    newConsumables.append(product)
                case .nonConsumable:
                    newNonConsumables.append(product)
                case .autoRenewable:
                    newSubscriptions.append(product)
                case .nonRenewable:
                    newNonRenewables.append(product)
                default:
                    // Ignore this product.
                    debugPrint("unknown product : \(product).")
                }
            }

            // Sort each product category by price, lowest to highest, to update the store.
            consumables = sortByPrice(newConsumables)
            nonConsumables = sortByPrice(newNonConsumables)
            subscriptions = sortByPrice(newSubscriptions)
            nonRenewables = sortByPrice(newNonRenewables)

        } catch {
            debugPrint("Failed product request from the App Store server: \(error).")
        }
    }

    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }

    // Get a subscription's level of service using the product ID.
    func getSubscriptionTier(for productId: String) -> SubscriptionTier {
        switch productId {
        case configuration.getSampleAutoRenewableSubscriptionId():
            return .standard
        case configuration.getSampleTierTwoAutoRenewableSubscriptionId():
            return .premium
        default:
            return .none
        }
    }
}

//MARK: 4C) Listen

extension StoreKitCoordinator {
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // Deliver products to the user.
                    await self.updateCustomerProductStatus()
                    // Always finish a transaction - This removes transactions from the queue and it tells Apple that the customer has recieved their items or service.
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    debugPrint("Transaction verification failed.")
                }
            }
        }
    }
}

//MARK: 4D) Purchase

extension StoreKitCoordinator {
    func purchase(_ product: Product) async throws -> Transaction? {
        // Begin purchasing the `Product` the user selects.
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check whether the transaction is verified. If it isn't,
            // this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            // The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            // Always finish a transaction - This removes transactions from the queue and it tells Apple that the customer has recieved their items or service.
            await transaction.finish()
            return transaction
        case .pending:
            return nil
        case .userCancelled:
            return nil
        default:
            return nil
        }
    }
}

//MARK: 4E) Update

extension StoreKitCoordinator {
    func updateCustomerProductStatus() async {
        var purchasedNonConsumables: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var purchasedNonRenewableSubscriptions: [Product] = []

        // Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                // Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)

                // Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .nonConsumable:
                    if let nonConsumable = nonConsumables.first(where: { $0.id == transaction.productID }) {
                        purchasedNonConsumables.append(nonConsumable)
                    } else {
                        debugPrint("Non-Consumable Product Id not within the offering : \(transaction.productID).")
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }) {
                        // Non-renewing subscriptions have no inherent expiration date, so they're always
                        // contained in `Transaction.currentEntitlements` after the user purchases them.
                        // This app defines this non-renewing subscription's expiration date to be one year after purchase.
                        // If the current date is within one year of the `purchaseDate`, the user is still entitled to this
                        // product.
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                                   to: transaction.purchaseDate)!

                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                        } else {
                            debugPrint("Non-Renewing Subscription with Id  \(transaction.productID) expired.")
                        }
                    } else {
                        debugPrint("Non-Renewing Subscription Product Id not within the offering : \(transaction.productID).")
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    } else {
                        debugPrint("Auto-Renewable Subscripton Product Id not within the offering : \(transaction.productID).")
                    }
                default:
                    debugPrint("Hit default \(transaction.productID).")
                    break
                }
            } catch {
                debugPrint("failed to grant product access \(result.debugDescription).")
            }
        }
        debugPrint("Updating Purchased Arrays... \(DebuggingIdentifiers.actionOrEventInProgress)")

        // Update the store information with the purchased products.
        self.purchasedNonConsumables = purchasedNonConsumables
        self.purchasedNonRenewables = purchasedNonRenewableSubscriptions

        // Update the store information with auto-renewable subscription products.
        self.purchasedSubscriptions = purchasedSubscriptions

        // Check the `subscriptionGroupStatus` to learn the auto-renewable subscription state to determine whether the customer
        // is new (never subscribed), active, or inactive (expired subscription). This app has only one subscription
        // group, so products in the subscriptions array all belong to the same group. The statuses that
        // `product.subscription.status` returns apply to the entire subscription group.
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
        
        // Notify System
        NotificationCenter.default.post(name: SystemNotifications.onStoreKitUpdate, object: nil)
    }
}

//MARK: 4F) Verify

extension StoreKitCoordinator {
    func isPurchased(_ product: Product) async throws -> Bool {
        // Determine whether the user purchases a given product.
        switch product.type {
        case .nonRenewable:
            return purchasedNonRenewables.contains(product)
        case .nonConsumable:
            return purchasedNonConsumables.contains(product)
        case .autoRenewable:
            return purchasedSubscriptions.contains(product)
        case .consumable:
            // Consumables can be purchased more than once, so never show them as purchased.
            return false
        default:
            return false
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
}

//Step 3B
enum StoreError: Error {
    case failedVerification
}

//Step 3C
enum SubscriptionTier: Int, Comparable {
    case none = 0
    case standard = 1
    case premium = 2

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

//MARK: Step 5
/* Initialize the Coordinator
In the ViewController where purchases can be made, in viewDidLoad, call:
 StoreKitCoordinator.shared.initialize()
 */

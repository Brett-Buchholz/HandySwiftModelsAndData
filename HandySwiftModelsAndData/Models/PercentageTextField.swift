//
//  PercentageTextField.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 1/10/24.
//

import UIKit

class PercentageField: UITextField {
    
    public var value: Double {
         get {
             let max = String(string.numbers)
             let divider: Double = pow(Double(10), Double(2))
             return abs(Double(max.numbers.integer) / divider) / 100
         }
         set(newVal) {
             text = String(format: "%.2f", newVal * 100) + "%"
         }
     }
     
     override func awakeFromNib() {
         super.awakeFromNib()
         addTarget(self, action: #selector(editingChanged), for: .editingChanged)
         keyboardType = .numberPad
         text = "%"
         editingChanged()
     }
     
     convenience init() {
         self.init()
         addTarget(self, action: #selector(editingChanged), for: .editingChanged)
         keyboardType = .numberPad
         text = "%"
         editingChanged()
     }
     
     @objc func editingChanged() {
         if !string.contains("%") {
             text?.removeLast()
         }
         let max = String(string.numbers)
         let divider: Double = pow(Double(10), Double(2))
         text = String(format: "%.2f", abs(Double(max.numbers.integer) / divider)) + "%"
         self.value = abs(Double(max.numbers.integer) / divider) / 100
     }
 }

//Extension already exists in CurrencyTextField
// extension UITextField {
//     var string: String { return text ?? "" }
// }

 extension String {
     var numbers: String { return components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined() }
     var integer: Int { return Int(numbers) ?? 0 }
}

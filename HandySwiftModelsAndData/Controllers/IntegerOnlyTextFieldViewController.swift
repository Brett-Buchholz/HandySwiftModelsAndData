//
//  IntegerOnlyTextFieldViewController.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 1/20/24.
//

import UIKit

//Adopt the UITextFieldDelegate protocol
class IntegerOnlyTextFieldViewController: UIViewController, UITextFieldDelegate {
    
    //Create an IBOutlet for the text field
    @IBOutlet weak var myTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the text field as a delegate
        myTextField.delegate = self
    }
    
    //Add one of the following functions:
    
    //This func doesn't allow decimal points to be entered
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
    
    //This func allows a decimal and 2 decimal places
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (myTextField.text! as NSString).replacingCharacters(in: range, with: string)
        let decimalRegex = try! NSRegularExpression(pattern: "^\\d*\\.?\\d{0,2}$", options: [])
        let matches = decimalRegex.matches(in: newString, options: [], range: NSMakeRange(0, newString.count))
        if matches.count == 1
        {
            return true
        }
        return false
    }
}

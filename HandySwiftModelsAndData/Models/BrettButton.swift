//
//  BrettButton.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 1/10/24.
//

import Foundation
import UIKit

class BrettButton: UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var masksToBounds: Bool {
        set {
            layer.masksToBounds = newValue
        }
        get {
            return layer.masksToBounds
        }
    }
    
    
    //Add a button animation when clicked
    override open var isHighlighted: Bool {
     didSet {
         UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
             self.titleLabel!.alpha = self.isHighlighted ? 0.3 : 1
             self.transform = self.isHighlighted ? .init(scaleX: 0.98, y: 0.98) : .identity
         }, completion: nil)
     }
   }

}

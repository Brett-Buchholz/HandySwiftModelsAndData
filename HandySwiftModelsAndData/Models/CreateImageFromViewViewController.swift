//
//  CreateImageFromViewViewController.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 1/12/24.
//

import UIKit

class CreateImageFromViewViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let image = customView.asImage() //Call the function on an existing view
    }
    
}

extension UIView {

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

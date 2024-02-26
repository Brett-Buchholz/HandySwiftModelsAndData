//
//  PDFKitViewController.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 1/10/24.
//

import UIKit
import PDFKit //An internal Swift library so easily imported

class PDFKitViewController: UIViewController, PDFViewDelegate {
    
    let pdfView = PDFView()  //Step 1 - Create a View
    let pdfThumbnailView = PDFThumbnailView() //Option to creates a thumbnail view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(pdfView) //Step 2 - Add the view as a subview
        
        //Step 4 Create a PDF Document. There are several ways to initialize the document:
        
        //Step 4: Option 1 - Create a blank PDF
        let newDocument = PDFDocument()
        
        /*Step 4: Option 2 - Create a PDF from an existing PDF. Do this by creating a url object
         and then passing that object into the PDFDocument(url: ) initializer. Both the url object
         and the PDFDocument(url: ) initializer return optional values so they need to be unwrapped. */
        guard let url = Bundle.main.url(forResource: "pdfFileName", withExtension: "pdf") else {
            return
        }
        guard let unwrappedDocument = PDFDocument(url: url) else {
            return
        }
        
        //Step 5 - However you initialized the PDF, set the pdfView.document equal to the created PDF
        pdfView.document = unwrappedDocument
        pdfView.document = newDocument
        
        //Step 5b - pdfView has a number of styling methods available
        
        //Step 6 - Set self as delegate on pdfView. Be sure to implement the PDFViewDelegate protocol.
        pdfView.delegate = self
        
        //Step 7 - insert pages into the document
        let page = PDFPage(image: <#T##UIImage#>)! //Optional must be unwrapped
        newDocument.insert(page, at: 0) //Insert the page at the index
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pdfView.frame = view.bounds //Step 3 - Create the frame for the subview
    }
    
    
}



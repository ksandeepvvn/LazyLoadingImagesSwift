//
//  ImageViewController.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import Foundation
import UIKit
class ImageViewController: UIViewController {
    
    @IBOutlet weak var navigation: UINavigationBar!
    @IBOutlet weak var imageView: UIImageView!
    
    var modelController = PhotoModelController()
    var selectedIndex: Int!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let photoDetails = self.modelController.resultsList[selectedIndex]
        if let image = photoDetails.image {
            self.imageView.image = image
            self.addDeleteButton()
        } else {
            //fetch image
            if let thumbnailURL = photoDetails.thumbnailURL {
                self.modelController.fetchImage(fromUrl: thumbnailURL, completionHandler: { (image, error) in
                    photoDetails.image = image
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        self.addDeleteButton()
                    }
                })
            }
            
        }
    }
    
    //Delete Function
    
    func addDeleteButton(){
        let deleteButton =  UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(self.deletEntry))
        self.navigationItem.rightBarButtonItem = deleteButton
    }
    
    //Removing Object at Particular Index
    
    @objc func deletEntry()  {
        self.modelController.resultsList.remove(at: self.selectedIndex)
        self.navigationController?.popViewController(animated: false)
    }
}


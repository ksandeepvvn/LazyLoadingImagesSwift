//
//  PhotosModel.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import Foundation
import UIKit
public class PhotosModel {
    let id : String?
    let title : String?
    //let imageURL : String?
    let thumbnailURL : String?
    var image : UIImage? = nil
    var thumbnailImage : UIImage? = nil
    
    init(jsonDict : [String:Any]) {
        self.id = jsonDict["description"] as? String
        self.title = jsonDict["title"] as? String
        self.thumbnailURL = jsonDict["imageHref"] as? String
    }
}

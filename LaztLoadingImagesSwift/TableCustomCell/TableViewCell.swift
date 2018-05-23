//
//  TableViewCell.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import Foundation
import UIKit
class TableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    
    @IBOutlet weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

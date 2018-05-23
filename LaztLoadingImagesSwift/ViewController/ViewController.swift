//
//  ViewController.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var refreshControl: UIRefreshControl!
    var modelController = PhotoModelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Defining TableView Height
        
        self.tableView.estimatedRowHeight = 180
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        
        //Activity Indicator Initiating
        self.activityIndicator.startAnimating()
        self.activityIndicator.tintColor = UIColor.red
        
        //Initialising Refresh Controller
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull To Referesh")
        refreshControl.tintColor = UIColor.red
        refreshControl.addTarget(self, action: #selector(Refresh), for: .valueChanged)
        
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        self.modelController.fetchJson(completionHandler: { [weak self](error) in
            guard let strongSelf = self else {
                return }
            
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.hidesWhenStopped = true
            strongSelf.tableView.reloadData()
            
        })
    }
    
    
    //Pull To Refresh
    @objc func Refresh()
    {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchAndLoadImages() {
        if let indexPathsVisible = self.tableView.indexPathsForVisibleRows {
            for indexPath in indexPathsVisible{
                let photoInfo = self.modelController.resultsList[indexPath.row]
                if photoInfo.thumbnailImage == nil {
                    if let cell = self.tableView.cellForRow(at: indexPath) as? TableViewCell {
                        
                        if((photoInfo.thumbnailURL != nil))
                        {
                        if let thumbnailURL = photoInfo.thumbnailURL {
                            self.modelController.fetchImage(fromUrl: thumbnailURL, completionHandler: { (image, error) in
                                
                            //Loading Image Asynchronusly
                                
                                DispatchQueue.main.async {
                                if(image == nil )
                                {
                                    //loading Default Image
                                 cell.cellImage?.image = UIImage(named: "PlaceHolder")
                                    }
                                    else
                                    {
                                    cell.cellImage?.image = image
                                    }
                                }
                            })
                        }
                        }
                        else
                        {
                            cell.cellImage?.image = UIImage(named: "PlaceHolder")
                        }
                    }
                }
            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.modelController.resultsList.count
    }
    
    
    //Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tabelCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        let photoInfo = self.modelController.resultsList[indexPath.row]
        tabelCell.title.text = photoInfo.title ?? ""
        tabelCell.descriptionText.text = photoInfo.id ?? ""
        if let photoImage = photoInfo.image {
            tabelCell.cellImage?.image = photoImage
        } else {
            if !tableView.isDecelerating && !tableView.isDragging {
                //Fetch image
                if let thumbnailURL = photoInfo.thumbnailURL {
                    self.modelController.fetchImage(fromUrl: thumbnailURL, completionHandler: { (image, error) in
                        tabelCell.cellImage?.image = UIImage(named: "PlaceHolder")
                        tabelCell.cellImage.downloadImageFrom(link: thumbnailURL, contentMode: UIViewContentMode.scaleAspectFit)
                    })
                }
            }
        }
        refreshControl.endRefreshing()
        return tabelCell
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
                if !decelerate{
                    self.fetchAndLoadImages()
                }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.fetchAndLoadImages()
    }
}



extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let imageVC  = self.storyboard?.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController{
            imageVC.modelController = self.modelController
            imageVC.selectedIndex = indexPath.row
            self.navigationController?.pushViewController(imageVC, animated: true)
        }
    }
}

extension UIImageView {
    func downloadImageFrom(link:String, contentMode: UIViewContentMode) {
        URLSession.shared.dataTask( with: NSURL(string:link)! as URL, completionHandler: {
            (data, response, error) -> Void in
            DispatchQueue.main.async() {
                self.contentMode =  contentMode
                if let data = data { self.image = UIImage(data: data) }
            }
        }).resume()
    }
}





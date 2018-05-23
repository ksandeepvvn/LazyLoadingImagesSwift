//
//  PhotoModelController.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import Foundation
import UIKit

class PhotoModelController: NSObject {
    
    var resultsList = [PhotosModel]()
    
    func fetchImage(fromUrl: String, completionHandler:@escaping (UIImage?, NSError?) -> Void) {
        let fetchImageCompletionHandler = { [weak self] (serviceResponse: ServiceResponse) -> Void in
            guard self != nil  else { return }
            if let error = serviceResponse.responseError {
                
                completionHandler(nil, error as NSError?)
                
                Swift.print("Error while searching area = \(error.userInfo[NSLocalizedDescriptionKey] ?? "unknown")")
                
                return
            }
            if let image = serviceResponse.image {
                completionHandler(image, nil)
            } else {
                completionHandler(nil, nil)
            }
        }
        
        SessionManager.sharedInstance.sendServerRequest(method: .get,
                                                        baseURL: fromUrl,
                                                        endPoint: "",
                                                        completionHandler: fetchImageCompletionHandler)
    }
    
    func fetchJson(completionHandler:@escaping (NSError?) -> Void) {
        let requestURL: URL = URL.init(string:"https://dl.dropboxusercontent.com/s/2iodh4vg0eortkl/facts.json" )!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // make the request
        let task = session.dataTask(with: urlRequest as URLRequest, completionHandler: { (data, response, error) in
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
                do{
                    let tempStr:String = NSString(data: data!, encoding: 8)! as String
                    let newData = tempStr.data(using: .utf8)
                    if let jsonResult = try JSONSerialization.jsonObject(with: newData!, options: []) as? [String:AnyObject] {
                        for json in jsonResult{
                            if let infoList = json.value as?  NSArray {
                                print ("provider_name: \(infoList.count)")
                                for i in 0..<(infoList.count)
                                {
                                    let photosDict = PhotosModel(jsonDict: infoList[i] as! [String : Any])
                                    self.resultsList.append(photosDict)
                                }
                                
                                completionHandler(nil)
                            }
                            else
                            {
                                print(json.value)
                            }
                        }
                        
                    }
                    
                    
                }
                catch {
                    print("Error with Json: \(error)")
                }
            }
        })
        task.resume()
        // Call the completion handler
        
    }
}

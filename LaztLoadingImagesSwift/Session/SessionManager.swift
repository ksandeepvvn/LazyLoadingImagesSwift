//
//  SessionManager.swift
//  LaztLoadingImagesSwift
//
//  Created by click2clinic3 on 23/05/18.
//  Copyright © 2018 Sandeep. All rights reserved.
//

import Foundation
import UIKit

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    
    static let allValues = [options, get, post, put, delete]
}

public class SessionManager {
    public static let sharedInstance = SessionManager()
    
    var tasks: [String: URLSessionTask] = [:]
    
    public static let baseURL = "https://dl.dropboxusercontent.com/s/2iodh4vg0eortkl/facts.json"
    
    public static let sharedURLSessionConfiguration: URLSessionConfiguration = {
        
        let configuration = URLSessionConfiguration.ephemeral
        
        configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        configuration.httpShouldSetCookies = false
        
        let timeoutSec: TimeInterval = 180
        configuration.timeoutIntervalForRequest = timeoutSec
        configuration.timeoutIntervalForResource = timeoutSec
        
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        return configuration
    }()
    
    private init() {
    }
    
    // The url session
    lazy var session = {
        
        URLSession(configuration: SessionManager.sharedURLSessionConfiguration,
                   delegate: nil,
                   delegateQueue: OperationQueue.main)
    }()
    
    
    func createHttpRequest(method: HTTPMethod,
                           baseURL: String? = SessionManager.baseURL,
                           endPoint: String,
                           resource: String? = nil,
                           headers: [String: AnyObject]? = nil,
                           body: Data? = nil,
                           queryParameters: [String: AnyObject]? = nil) -> (URLRequest, URLSession) {
        
        var endPoint = endPoint
        
        if let resourceName = resource {
            
            endPoint += "/\(resourceName.replacingOccurrences(of: ";", with: "%3B"))"
        }
        
        // First prepare a query string for the end point
        if let queryParameters = queryParameters {
            
            var queryParams: [String] = []
            
            for (key, value) in queryParameters {
                queryParams.append("\(key)=\(value)")
            }
            
            if queryParams.count > 0 {
                
                let paramString: String = queryParams.joined(separator: "&")
                
                if paramString.count > 0 {
                    
                    endPoint += "?\(paramString)"
                }
            }
        }
        
        var request = NSMutableURLRequest()
        
        if let baseURL = baseURL, baseURL.isEmpty == false, let url =  URL(string: baseURL + endPoint) {
            
            request = NSMutableURLRequest(url: url)
            
            // Specify the HTTP Method, post, put or get
            request.httpMethod = method.rawValue
            
            if let httpAdditionalHeaders = SessionManager.sharedURLSessionConfiguration.httpAdditionalHeaders {
                
                // Add standard headers
                for (key, value) in httpAdditionalHeaders {
                    
                    request.setValue(String(describing: value), forHTTPHeaderField: String(describing: key))
                }
            }
            
            // Add headers if there are any
            if let headers = headers {
                
                for (key, value) in headers {
                    
                    request.setValue(String(describing: value), forHTTPHeaderField: key)
                }
            }
            
            // If there is a body then set it for the request
            if let body = body {
                
                request.httpBody = body
            }
            
            request.httpShouldHandleCookies = false
            
        } else {
            
            Swift.print("Base Point : \(baseURL ?? "")")
            Swift.print("End Point : \(endPoint)")
        }
        
        return (request as URLRequest, session)
    }
    
    @discardableResult
    public func sendServerRequest(method: HTTPMethod,
                                  baseURL: String? = SessionManager.baseURL,
                                  endPoint: String,
                                  resource : String? = nil,
                                  headers: [String: AnyObject]? = nil,
                                  body: Data? = nil,
                                  queryParameters: [String: AnyObject]? = nil,
                                  completionHandler:@escaping (ServiceResponse) -> Void) -> String {
        
        let taskIdentifier = UUID().uuidString
        let serviceResponse = ServiceResponse()
        
        //if let loggedInUserName = SessionManager.sharedInstance.session.username {
        
        var (request, session) = createHttpRequest(method: method,
                                                   baseURL: baseURL,
                                                   endPoint: endPoint,
                                                   resource : resource,
                                                   headers: headers,
                                                   body: body,
                                                   queryParameters: queryParameters)
        
        if request.url == nil {
            
            serviceResponse.responseError = createError(with: ["errorMessage": "Invalid Request...!"])
            
            completionHandler(serviceResponse)
            self.tasks.removeValue(forKey: taskIdentifier)
            return taskIdentifier
        }
        
        Swift.print("Request : \(request)")
        Swift.print("Request Headers : \(String(describing: request.allHTTPHeaderFields))")
        
        if let httpBody = request.httpBody {
            
            Swift.print("Request Body : \(NSString(data: httpBody, encoding: String.Encoding.utf8.rawValue)!)")
        }
        
        let task = session.dataTask(with: request) {[weak self] (data, response, error) -> Void in
            
            guard let mySelf = self else {
                
                completionHandler(serviceResponse)
                
                return
            }
            
            Swift.print("Response : \(String(describing: response as? HTTPURLResponse))")
            Swift.print("Response Headers : \(String(describing: (response as? HTTPURLResponse)?.allHeaderFields))")
            
            
            if let httpResponse = response as? HTTPURLResponse {
                
                serviceResponse.statusCode = NSNumber(value: httpResponse.statusCode)
            }
            
            if let data = data {
                if let responseDataInString = String(data: data, encoding: String.Encoding.utf8) {
                    Swift.print(responseDataInString)
                }
                
                do {
                    
                    serviceResponse.jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
                    
                } catch {
                    
                    serviceResponse.jsonObject = nil
                    
                    if let image = UIImage(data: data) {
                        serviceResponse.image = image
                    } else {
                        serviceResponse.responseError = mySelf.createError(with: ["errorMessage": "Unable to parse response data."])
                        
                        Swift.print("WebServiceInterface Failed to convert data to a valid JSON: \(error.localizedDescription)")
                    }
                }
            }
            
            if serviceResponse.statusCode?.intValue != 200 || error != nil {
                
                if let errorJson = serviceResponse.jsonObject as? [String : Any] {
                    
                    serviceResponse.responseError = mySelf.createError(with: errorJson)
                    
                } else if error != nil {
                    
                    serviceResponse.responseError = error as NSError?
                    
                } else if serviceResponse.responseError == nil {
                    
                    serviceResponse.responseError = mySelf.createError()
                }
            }
            
            mySelf.tasks.removeValue(forKey: taskIdentifier)
            // Call the completion handler
            completionHandler(serviceResponse)
        }
        self.tasks[taskIdentifier] = task
        task.resume()
        return taskIdentifier
    }
    
    private func createError(with infoDict: [String : Any]? = nil) -> NSError {
        
        var userInfo: [String : Any] = [:]
        
        let errorCode = infoDict?["errorCode"] as? NSInteger ?? -1
        
        let errorMessage = infoDict?["errorMessage"] as? String ?? ""
        
        if errorMessage.isEmpty == false {
            
            userInfo[NSLocalizedDescriptionKey] = errorMessage
            
        } else {
            
            userInfo[NSLocalizedDescriptionKey] = "We are experiencing technical difficulties."
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = "Please contact helpdesk, if this problem persists."
        }
        
        let bundle = Bundle.main
        
        let error = NSError(domain: bundle.bundleIdentifier!,
                            code: errorCode,
                            userInfo: userInfo)
        return error
    }
    
}
public class ServiceResponse: NSObject {
    
    public var statusCode: NSNumber?
    public var headers: NSDictionary?
    public var jsonObject: AnyObject?
    public var responseError: NSError?
    public var image: UIImage?
}


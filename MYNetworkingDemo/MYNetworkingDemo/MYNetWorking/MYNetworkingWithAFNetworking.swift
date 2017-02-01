//
//  MYNetworkingWithAFNetworking.swift
//  MYNetworkingDemo
//
//  Created by 朱益锋 on 2017/2/1.
//  Copyright © 2017年 朱益锋. All rights reserved.
//

import UIKit
import AFNetworking

class MYNetworkingWithAFNetworking {
    var manager: AFHTTPSessionManager!
    
    let kAcceptableContentTypes:Set<String> = ["application/json",
                                               "text/html",
                                               "text/plain",
                                               "text/javascript",
                                               "text/xml",
                                               "image/*"]
    
    var domain: String {
        return ""
    }
    
    var successErrorCode = 0
    
    var timeoutInterval: TimeInterval {
        get {
            return self.manager.requestSerializer.timeoutInterval
        }
        set {
            self.manager.requestSerializer.timeoutInterval = newValue
        }
    }
    
    var baseParameters: MYParameters {
        return ["appVersion": "1.0"]
    }
    
    var enableDebugLog: Bool = false
    
    init() {
        self.manager = AFHTTPSessionManager()
        self.timeoutInterval = 30
        self.manager.responseSerializer.acceptableContentTypes = kAcceptableContentTypes
        self.manager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue
    }
    
    /**Get*/
    func get(_ urlString: String, parameters: [String: String]? = nil, timeoutInterval:TimeInterval=30, completionHandler:@escaping ResponseObjectBlock) {
        self.my_print(item: "URL(GET): \(self.getURLStringWithParameters(self.domain + urlString, parameters: parameters))")
        self.timeoutInterval = timeoutInterval
        self.manager.get(self.domain + urlString, parameters: parameters, progress: nil, success: { (urlSessionDataTask, responseObject) in
            completionHandler(urlSessionDataTask, responseObject, nil)
        }) { (urlSessionDataTask, error) in
            if urlSessionDataTask != nil {
                completionHandler(urlSessionDataTask!, nil, error)
            }else {
                completionHandler(nil, nil, error as NSError?)
            }
        }
    }
    
    /**Post*/
    func post(_ urlString: String, parameters: [String: String]? = nil,timeoutInterval:TimeInterval=30, completionHandler:@escaping ResponseObjectBlock) {
        self.my_print(item: "URL(POST): \(self.getURLStringWithParameters(self.domain + urlString, parameters: parameters))")
        self.timeoutInterval = timeoutInterval
        self.manager.post(self.domain + urlString, parameters: parameters, progress: nil, success: { (urlSessionDataTask, responseObject) in
            completionHandler(urlSessionDataTask, responseObject , nil)
        }) { (urlSessionDataTask, error) in
            completionHandler(urlSessionDataTask, nil, error)
        }
    }
    
    /**Download*/
    func downloadWithUrl(_ urlString: String, timeoutInterval:TimeInterval=30, progressHandler:@escaping ((_ progress:Progress) -> Void), completionHandler:@escaping (_ response:URLResponse?, _ filePath:URL?, _ error:Error?) -> Void) {
        self.my_print(item: "URL(Download): \(self.getURLStringWithParameters(urlString, parameters: nil))")
        self.timeoutInterval = timeoutInterval
        if let url = URL(string: urlString) {
            let downloadRequest = URLRequest(url: url)
            let downloadTask = self.manager.downloadTask(with: downloadRequest, progress: { (progress) in
                progressHandler(progress)
            }, destination: { (temporaryURL, response) -> URL in
                let directoryURLs = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
                if !directoryURLs.isEmpty {
                    return directoryURLs[0].appendingPathComponent(response.suggestedFilename!)
                }
                return temporaryURL
            }, completionHandler: { (response, fileURL, error) in
                completionHandler(response, fileURL, error)
            })
            downloadTask.resume()
        }
    }
    
    func uploadWithFormData(_ urlString:String,parameters:[String:String]? = nil, name: String, datas: [Data], timeoutInterval:TimeInterval=30, progress: MYProgressHandler?,  completionHandler:@escaping ResponseObjectBlock){
        self.my_print(item: "URL(UploadWithFormData): \(self.getURLStringWithParameters(self.domain + urlString, parameters: parameters))")
        self.timeoutInterval = timeoutInterval
        self.manager.post(self.domain + urlString, parameters: parameters, constructingBodyWith: { (formData) in
            for item in datas {
                formData.appendPart(withFileData: item, name:"data", fileName: name, mimeType: "image/jpg")
            }
        }, progress: progress, success: { (urlSessionDataTask, responseObject) in
            completionHandler(urlSessionDataTask, responseObject, nil)
        }) { (urlSessionDataTask, error) in
            completionHandler(urlSessionDataTask, nil, error)
        }
    }
    
    // MARK: - URLWithParameters
    func getURLStringWithParameters(_ url: String, parameters: MYParameters?) -> String {
        if let parameters = parameters {
            var url = "\(url)?"
            var i = 0
            for (key, value) in parameters {
                if i == parameters.count-1 {
                    url = "\(url)\(key)=\(value)"
                }else {
                    url = "\(url)\(key)=\(value)&"
                }
                i += 1
            }
            return url
        }else {
            return url
        }
    }
    
    // MARK: - CustomErrorHandler
    func getTopDictionaryOrCallbackError(_ resultValue: Any?, failure: MYFailureHandler) -> MYDictionary? {
        if resultValue == nil {
            let error = NSError(domain: self.domain, code: -99003, userInfo: [NSLocalizedDescriptionKey:"数据为空"])
            failure(error)
            return nil
        }else {
            if let dictionary = resultValue as? MYDictionary {
                if let error = self.getCustomErrorWithDictionary(dictionary: dictionary) {
                    failure(error)
                    return nil
                }
                return dictionary
            }else {
                let error = NSError(domain: self.domain, code: -99001, userInfo: [NSLocalizedDescriptionKey: "数据非[String: Any]类型"])
                failure(error)
                return nil
            }
        }
    }
    
    func getCustomErrorWithDictionary(dictionary: MYDictionary) -> NSError? {
        
        var serversMessage = ""
        if let message = dictionary["message"] as? String {
            serversMessage = message
        }
        
        if let errorCode = dictionary["error"] as? Int {
            if errorCode != self.successErrorCode {
                let customError = NSError(domain: self.domain, code: errorCode, userInfo: [NSLocalizedDescriptionKey:  serversMessage])
                print("AppServers Error: \(serversMessage)" + "code: \(errorCode)")
                return customError
            }
        }
        return nil
    }
    
    // MARK: - Parsing
    func getDictionaryWithKey(_ key: String?, resultValue: Any?, failure: MYFailureHandler) -> MYDictionary? {
        if let _key = key {
            if let dictionary = self.getTopDictionaryOrCallbackError(resultValue, failure: failure) {
                if let value = dictionary[_key] as? MYDictionary {
                    return value
                }
            }
            return nil
        }else {
            return self.getTopDictionaryOrCallbackError(resultValue, failure: failure)
        }
        
    }
    
    
    func getArrayWithKey(_ key: String, resultValue: Any?, failure: MYFailureHandler) -> [Any]? {
        if let dictionary = self.getTopDictionaryOrCallbackError(resultValue, failure: failure) {
            if let value = dictionary[key] as? [Any] {
                return value
            }
        }
        return nil
    }
    
    func getValueWithKey(_ key: String, resultValue: Any?, failure: MYFailureHandler) -> Any? {
        if let dictionary = self.getTopDictionaryOrCallbackError(resultValue, failure: failure) {
            return dictionary[key] as Any
        }
        return nil
    }
    
    func getSwiftArray<T>(array: NSArray) -> [T] {
        return array as! [T]
    }
    
    func getUrlStringWithParameters(_ urlString:String,parameters:[String:String]?) -> String{
        if let _parameters = parameters {
            return "\(urlString)?\(AFQueryStringFromParameters(_parameters))"
        }else {
            return urlString
        }
    }
    
    func my_print(item: Any...) {
        if !self.enableDebugLog {
            return
        }
        print(item)
    }
}

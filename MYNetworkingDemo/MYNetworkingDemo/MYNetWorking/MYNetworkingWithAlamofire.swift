//
//  MYNetworkingWithAlamofire.swift
//  MYNetworkingDemo
//
//  Created by 朱益锋 on 2017/2/1.
//  Copyright © 2017年 朱益锋. All rights reserved.
//

import UIKit
import Alamofire

class MYNetworkingWithAlamofire {
    
    static let sharedInstance = MYNetworkingWithAlamofire()
    
    var manager: SessionManager?
    
    var downloadRequest: DownloadRequest?
    
    var domain: String {
        return ""
    }
    
    var successErrorCode = 0
    
    var timeoutInterval: TimeInterval {
        get {
            guard let manager = self.manager else {
                return 0.0
            }
            return manager.session.configuration.timeoutIntervalForRequest
        }
        set {
            self.manager?.session.invalidateAndCancel()
            self.manager = nil
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = newValue
            configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
            self.manager = SessionManager(configuration: configuration)
        }
    }
    
    var baseParameters: MYParameters {
        return ["appVersion": "1.0"]
    }
    
    var enableDebugLog: Bool = false
    
    init() {
        self.timeoutInterval = 30
    }
    
    //GET
    func get(_ url: String, parameters: MYParameters?, timeoutInterval:TimeInterval=30, success: @escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(GET): \(self.getURLStringWithParameters(url, parameters: parameters))")
        self.timeoutInterval = timeoutInterval
        self.manager?.request(url, method: HTTPMethod.get, parameters: parameters
            ).responseJSON { (response) in
                switch response.result.isSuccess {
                case true:
                    success(response.result.value)
                    print(response.result.value as Any)
                case false:
                    failure(response.result.error)
                }
        }
    }
    
    //Post
    func post(_ url: String, parameters: MYParameters?, timeoutInterval:TimeInterval=30, success:@escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(POST): \(self.getURLStringWithParameters(url, parameters: parameters))")
        self.timeoutInterval = timeoutInterval
        self.manager?.request(url, method: HTTPMethod.post, parameters: parameters).responseJSON { (response) in
            switch response.result.isSuccess {
            case true:
                success(response.result.value)
            case false:
                failure(response.result.error)
            }
        }
    }
    
    //Download
    func download(_ url: String, timeoutInterval:TimeInterval=30, downloadProgressHandler: ((_ progress: Progress) -> Void)?=nil,success:@escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(Download): \(self.getURLStringWithParameters(url, parameters: nil))")
        self.timeoutInterval = timeoutInterval
        self.downloadRequest = self.manager?.download(url, to: DownloadRequest.suggestedDownloadDestination(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)).downloadProgress(closure: { (progress) in
            downloadProgressHandler?(progress)
        }).response(completionHandler: { (response) in
            if response.error == nil {
                if let url = response.destinationURL {
                    success(url)
                }else if let url = response.temporaryURL {
                    success(url)
                }
            }else {
                failure(response.error)
            }
        })
    }
    
    //ResumingDownload
    func resumingDownload(timeoutInterval:TimeInterval=30, downloadProgressHandler: ((_ progress: Progress) -> Void)?=nil,success:@escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        //        guard let downloadRequest = self.downloadRequest else {
        //            return
        //        }
        //        guard let resumeData = downloadRequest.resumeData else {
        //            return
        //        }
        //        self.my_print(item: "URL(Download): \(self.getURLStringWithParameters(url, parameters: parameters))")
        //        self.timeoutInterval = timeoutInterval
        //        self.downloadRequest = self.manager?.download(resumingWith: resumeData, to: DownloadRequest.suggestedDownloadDestination(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)).downloadProgress(closure: { (progress) in
        //            downloadProgressHandler?(progress)
        //        }).response(completionHandler: { (response) in
        //            if response.error == nil {
        //                if let url = response.destinationURL {
        //                    success(url)
        //                }else if let url = response.temporaryURL {
        //                    success(url)
        //                }
        //            }else {
        //                failure(response.error!)
        //            }
        //        })
    }
    
    //StopDownload
    func stopDownload() {
        self.downloadRequest?.cancel()
    }
    
    //Upload
    func uploadWithData(data: Data, toURL url: String, progressHandler: MYProgressHandler?=nil, success: @escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(UploadWithData): \(self.getURLStringWithParameters(url, parameters: nil))")
        self.manager?.upload(data, to: url).uploadProgress(closure: { (progress) in
            progressHandler?(progress)
        }).response(completionHandler: { (response) in
            if response.error == nil {
                success(response.data)
            }else {
                failure(response.error)
            }
        })
    }
    
    func uploadWithFileURL(fileURL: URL, toURL url: String, progressHandler: MYProgressHandler?=nil, success: @escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(UploadWithFileURL): \(self.getURLStringWithParameters(url, parameters: ["FileURL": fileURL.absoluteString]))")
        self.manager?.upload(fileURL, to: url).uploadProgress(closure: { (progress) in
            progressHandler?(progress)
        }).response(completionHandler: { (response) in
            if response.error == nil {
                success(response.data)
            }else {
                failure(response.error)
            }
        })
    }
    
    func uploadWithStream(stream: InputStream, toURL url: String, progressHandler: MYProgressHandler?=nil, success: @escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(UploadWithstream): \(self.getURLStringWithParameters(url, parameters: nil))")
        self.manager?.upload(stream, to: url).uploadProgress(closure: { (progress) in
            progressHandler?(progress)
        }).response(completionHandler: { (response) in
            if response.error == nil {
                success(response.data)
            }else {
                failure(response.error)
            }
        })
    }
    
    func uploadWithFormData(toURL url: String, formDatas: [Formdata], name: String, success: @escaping MYSuccessHandler, failure: @escaping MYFailureHandler) {
        self.my_print(item: "URL(UploadWithFormData): \(self.getURLStringWithParameters(url, parameters: nil))")
        self.manager?.upload(multipartFormData: { (formData) in
            for item in formDatas {
                switch item.dataType {
                case .image_jpeg:
                    formData.append(item.data!, withName: item.name!, mimeType: item.mimeType!)
                default:
                    break
                }
            }
        }, to: url, encodingCompletion: { (result) in
            switch result {
            case .success(let request, _, _):
                request.responseJSON(completionHandler: { (response) in
                    switch response.result.isSuccess {
                    case true:
                        success(response.result.value)
                    case false:
                        failure(response.result.error)
                    }
                })
            case .failure(let error):
                failure(error)
            }
        })
    }
    
    //URL
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
        var url = "\(urlString)?"
        if let _parameters = parameters {
            for key in _parameters.keys {
                if let value = _parameters[key] {
                    if value.characters.count <= 300000 {
                        url = "\(url)\(key)=\(value)&"
                    }
                }
            }
        }
        let index =  url.characters.index(url.endIndex, offsetBy: -1)
        return url.substring(to: index)
    }
    
    func my_print(item: Any...) {
        if !self.enableDebugLog {
            return
        }
        print(item)
    }
}

enum FormDataType {
    case image_jpg
    case image_png
    case image_jpeg
    case audio_mpeg3
}

class Formdata: NSObject {
    
    var dataType: FormDataType = .image_jpeg
    
    var mimeType: String?
    
    var name: String?
    
    var data: Data?
}

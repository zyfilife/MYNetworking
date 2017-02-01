//
//  MYNetworkingConfig.swift
//  MYNetworkingDemo
//
//  Created by 朱益锋 on 2017/2/1.
//  Copyright © 2017年 朱益锋. All rights reserved.
//

import Foundation

typealias MYSuccessHandler = (_ reslut: Any?) -> Void
typealias MYFailureHandler = (_ error:Error?) -> Void
typealias MYProgressHandler = (_ progress: Progress) -> Void
typealias MYParameters = [String: String]
typealias MYDictionary = [String: Any?]

typealias ResponseObjectBlock = (_ dataTask: URLSessionDataTask?, _ responseObject: Any?, _ error: Error?) -> Void
typealias FaileBlock = (_ error:NSError?) -> Void

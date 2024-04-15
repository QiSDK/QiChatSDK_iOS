//
//  LineLib.swift
//  TeneasyChatSDK_iOS
//
//  Created by XiaoFu on 14/4/24.
//

import Foundation
import Alamofire


public protocol lineLibDelegate : AnyObject{
    func useTheLine(line: String)
    func lineError(error: String)
}

public struct LineLib{
    
   public init(_ urlStrings: [String], delegate: lineLibDelegate? = nil) {
       self.delegate = delegate
       self.urlStrings = urlStrings
    }
  
    private var delegate: lineLibDelegate?
    private var urlStrings: [String] = [""]
   public func getLine(){
         var foundLine = false
        for urlString in urlStrings {
            if (foundLine){
                break
            }
            
            AF.request(urlString){ $0.timeoutInterval = 1}.response { response in

                switch response.result {
                case let .success(value):
                    //let contents = String(data: value, encoding: .utf8)
                    
                    if let v = value, v.count > 1{
                        foundLine = true
                        //delegate?.useTheLine(line: response.request?.url?.baseURL?.absoluteString ?? "")
                        print(response.request?.url?.host ?? "")
                        delegate?.useTheLine(line: "csapi.xdev.stream")
                    }
                  
                    break
                case let .failure(error):
                    print(error)
                    
                }
            }
        }
    }
}

//
//  LineLib.swift
//  TeneasyChatSDK_iOS
//
//  Created by XiaoFu on 14/4/24.
//

import Foundation
import Alamofire


public protocol lineLibDelegate : AnyObject{
    //收到消息
    func useTheLine(line: Any)
    func lineError(error: String)
}

struct LineLib{
  
    var delegate: lineLibDelegate?
    func getLine(urlStrings: [String]){
         var foundLine = false
        for urlString in urlStrings {
            if (foundLine){
                break
            }
            
            AF.request(urlString).response { response in

                switch response.result {
                case let .success(value):
                    //let contents = String(data: value, encoding: .utf8)
                    
                    if let v = value, v.count > 5{
                        foundLine = true
                        delegate?.useTheLine(line: urlString)
                    }
                  
                    break
                case let .failure(error):
                    print(error)
                    
                }
            }
            
            if !foundLine{
                delegate?.lineError(error: "没有可用线路")
            }
        }
    }
}

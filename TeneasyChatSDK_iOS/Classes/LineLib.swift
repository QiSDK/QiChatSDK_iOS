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
        LineLib.usedLine = false
        LineLib.retryTimes = 0
    }
    
    private var delegate: lineLibDelegate?
    private var urlStrings = [String]()
    private static var usedLine = false
    private static var retryTimes = 0
    
    public func getLine(){
        var foundLine = false
        var triedTimes = 0
        for urlString in urlStrings {
            if (foundLine){
                break
            }
            
            AF.request(urlString){ $0.timeoutInterval = 2}.response { response in
                switch response.result {
                case let .success(value):
                    
                    var f = false
                    if value != nil{
                        //没有加密
                        //let contents = String(data: value!, encoding: .utf8)
                        
                        //有加密，需解密
                        let base64 = String(data: value!, encoding: .utf8)
                        let contents = base64ToString(base64String: base64!)
                        
                        if let base = contents, base.contains("VITE_API_BASE_URL"){
                            if let c = AppConfig.deserialize(from: contents) {
                                var lineStrs: [String] = []
                                for l in c.lines{
                                    if l.VITE_API_BASE_URL.contains("https"){
                                        lineStrs.append(l.VITE_API_BASE_URL + "/verify")
                                        foundLine = true
                                        f = true
                                    }
                                }
                                step2(lineStrs: lineStrs, index: triedTimes)

                                let config = response.request?.url?.host ?? ""
                                debugPrint("txt：\(config)")
                            }
                        }
                    }
                    if !f{
                        triedTimes += 1
                        if triedTimes == urlStrings.count{
                            failedAndRetry()
                        }
                    }
                    
                    break
                case let .failure(error):
                    print(error)
                    triedTimes += 1
                    if triedTimes == urlStrings.count{
                        failedAndRetry()
                    }
                }
            }
        }
    }
    
    private func step2(lineStrs: [String], index: Int){
        
        var foundLine = false
       var triedTimes = 0
       for urlString in lineStrs {
           
           if (foundLine){
               break
           }
           
           AF.request(urlString){ $0.timeoutInterval = 2}.response { response in

               switch response.result {
               case let .success(value):
                   if let v = value,  String(data: v, encoding: .utf8)!.contains("10010") {
                       foundLine = true
                       
                       let line = response.request?.url?.host ?? ""
                       if !LineLib.usedLine{
                           delegate?.useTheLine(line: line)
                           debugPrint("使用线路：\(line)")
                           LineLib.usedLine = true
                       }
                       //delegate?.useTheLine(line: "csapi.xdev.stream")
                   }else{
                       triedTimes += 1
                       if triedTimes == lineStrs.count && (index + 1) == urlStrings.count{
                           failedAndRetry()
                       }
                   }
                 
                   break
               case let .failure(error):
                   print(error)
                   triedTimes += 1
                   if triedTimes == lineStrs.count && (index + 1) == urlStrings.count{
                       failedAndRetry()
                   }
               }
           }
       }
    }
    
    private func failedAndRetry(){
        if LineLib.retryTimes < 3{
            LineLib.retryTimes += 1
            delegate?.lineError(error: "线路获取失败，重试\(LineLib.retryTimes)")
            getLine()
        }else{
            delegate?.lineError(error: "无可用线路")
        }
    }
}

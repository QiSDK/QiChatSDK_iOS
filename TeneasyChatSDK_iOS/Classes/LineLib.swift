//
//  LineLib.swift
//  TeneasyChatSDK_iOS
//
//  Created by XiaoFu on 14/4/24.
//

import Foundation
import Alamofire


public protocol lineLibDelegate : AnyObject{
    func useTheLine(line: Line)
    func lineError(error: Result)
}

public struct LineLib{
    
    public init(_ urlStrings: [String], delegate: lineLibDelegate? = nil) {
        self.delegate = delegate
        self.txtList = urlStrings
        LineLib.usedLine = false
        LineLib.retryTimes = 0
    }
    
    private var delegate: lineLibDelegate?
    private var txtList = [String]()
    private static var usedLine = false
    private static var retryTimes = 0
    
    public func getLine(){
        var foundLine = false
        var myIndex = 0
        for txtUrl in txtList {
            if (LineLib.usedLine){
                break
            }
            
            AF.request(txtUrl){ $0.timeoutInterval = 2}.response { response in
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
                                var lineStrs: [Line] = []
                                for l in c.lines{
                                    if l.VITE_API_BASE_URL.contains("https"){
                                        //lineStrs.append(l.VITE_API_BASE_URL )
                                        foundLine = true
                                        f = true
                                        lineStrs.append(l)
                                    }
                                }
                                step2(lines: lineStrs, index: myIndex)
                                let config = response.request?.url?.host ?? ""
                                debugPrint("txt：\(config)")
                            }
                        }
                    }
                    myIndex += 1
                    if !f{
                        if myIndex == txtList.count{
                            failedAndRetry()
                        }
                    }
                    break
                case let .failure(error):
                    print(error)
                    myIndex += 1
                    if myIndex == txtList.count{
                        failedAndRetry()
                    }
                }
            }
        }
    }
    
    private func step2(lines: [Line], index: Int){
        
        var foundLine = false
       var myStep2Index = 0
       for line in lines {
           
           if (foundLine){
               break
           }
           
           AF.request("\(line.VITE_API_BASE_URL)/verify"){ $0.timeoutInterval = 2}.response { response in

               switch response.result {
               case let .success(value):
                   if let v = value,  String(data: v, encoding: .utf8)!.contains("10010") {
                       foundLine = true
                       
                       //let line = response.request?.url?.host ?? ""
                       if !LineLib.usedLine{
                           LineLib.usedLine = true
                           delegate?.useTheLine(line: line)
                           //debugPrint("使用线路：\(line)")
                       }
                   }else{
                       myStep2Index += 1
                       if myStep2Index == lines.count && (index + 1) == txtList.count{
                           failedAndRetry()
                       }
                   }
                 
                   break
               case let .failure(error):
                   print(error)
                   myStep2Index += 1
                   if myStep2Index == lines.count && (index + 1) == txtList.count{
                       failedAndRetry()
                   }
               }
           }
       }
    }
    
    private func failedAndRetry(){
        if LineLib.usedLine{
            return
        }
        var result = Result()
        if LineLib.retryTimes < 3{
            LineLib.retryTimes += 1
            result.Code = 1009
            result.Message = "线路获取失败，重试\(LineLib.retryTimes)"
            delegate?.lineError(error: result)
            getLine()
        }else{
            result.Code = 1008
            result.Message = "无可用线路"
            delegate?.lineError(error: result)
        }
    }
}

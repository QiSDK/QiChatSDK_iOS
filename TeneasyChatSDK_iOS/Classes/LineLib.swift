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

private struct LineLib{
    
    public init(_ urlStrings: [String], delegate: lineLibDelegate? = nil, tenantId: Int) {
        self.delegate = delegate
        self.txtList = urlStrings
        LineLib.usedLine = false
        LineLib.retryTimes = 0
        self.tenantId = tenantId
        bodyStr = ["gnsId": "wcs", "tenantId": tenantId]
    }
    
    private var delegate: lineLibDelegate?
    private var txtList = [String]()
    private static var usedLine = false
    private static var retryTimes = 0
     var bodyStr: Parameters? = nil
    private var tenantId: Int? = 0
    public func getLine(){
        var myIndex = 0
        for txtUrl in txtList {
            if (LineLib.usedLine){
                break
            }
            
            let url = checkUrl(str: txtUrl)
            if url.isEmpty{
                continue
            }
            
            AF.request(url){ $0.timeoutInterval = 2}.response { response in
                switch response.result {
                case let .success(value):
                    
                    var f = false
                    if value != nil{
                        //没有加密
                        //let contents = String(data: value!, encoding: .utf8)
                        
                        //有加密，需解密
                        //let base64 = String(data: value!, encoding: .utf8)
                        if let base64 = String(data: value!, encoding: .utf8) {
                            if let contents = base64ToString(base64String: base64), contents.contains("VITE_API_BASE_URL") {
                                if let c = AppConfig.deserialize(from: contents) {
                                    var lineStrs: [Line] = []
                                    for l in c.lines{
                                        if l.VITE_API_BASE_URL.contains("https"){
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
           
           let url = checkUrl(str: "\(line.VITE_API_BASE_URL)/v1/api/verify")
           
           if url.isEmpty{
               continue
           }
           
           AF.request(url, method: .post, parameters: bodyStr,  encoding: JSONEncoding.default) { $0.timeoutInterval = 2 }.response { response in

               switch response.result {
               case let .success(value):
                   //let ddd = String(data: value!, encoding: .utf8)
                   if let v = value,  String(data: v, encoding: .utf8)!.contains("tenantId\":\(self.tenantId ?? 0)") {
                       foundLine = true
                       //let line = response.request?.url?.host ?? ""
                       if !LineLib.usedLine{
                           LineLib.usedLine = true
                           delegate?.useTheLine(line: line)
                           debugPrint("使用线路：\(line)")
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
    
    func checkUrl(str: String) -> String{
        let r = (1...100000).randomElement()
         var newStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
        newStr = "\(newStr)?\(r ?? 0)"
        
        
        if (!newStr.hasPrefix("http")){
            newStr = ""
        }
        return newStr
    }
}

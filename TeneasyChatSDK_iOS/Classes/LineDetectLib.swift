//
//  LineLib.swift
//  TeneasyChatSDK_iOS
//
//  Created by XiaoFu on 14/4/24.
//

import Foundation
import Alamofire


public protocol LineDetectDelegate : AnyObject{
    func useTheLine(line: String)
    func lineError(error: Result)
}

public struct LineDetectLib{
    
    public init(_ urlStrings: String, delegate: LineDetectDelegate? = nil, tenantId: Int) {
        self.delegate = delegate
        self.urlList = urlStrings.split(separator: ",").map { String($0) }
        LineDetectLib.usedLine = false
        LineDetectLib.retryTimes = 0
        self.tenantId = tenantId
        bodyStr = ["gnsId": "wcs", "tenantId": tenantId]
    }
    
    private var delegate: LineDetectDelegate?
    private var urlList = [String]()
    private static var usedLine = false
    private static var retryTimes = 0
    var bodyStr: Parameters? = nil
    private var tenantId: Int? = 0
 
    public func getLine(){
        
         var foundLine = false
       var myStep2Index = 0
       for txtUrl in urlList {
           if (LineDetectLib.usedLine){
               break
           }
           
           if (foundLine){
               break
           }
           
           let url = checkUrl(str: "\(txtUrl)/v1/api/verify")
           
           if url.isEmpty{
               continue
           }
           
           AF.request(url, method: .post, parameters: bodyStr,  encoding: JSONEncoding.default) { $0.timeoutInterval = 2 }.response { response in

               switch response.result {
               case let .success(value):
                   //let ddd = String(data: value!, encoding: .utf8)
                   if let v = value,  String(data: v, encoding: .utf8)!.contains("tenantId\":\(self.tenantId ?? 0)") {
                       foundLine = true
                       
                       if !LineDetectLib.usedLine{
                           LineDetectLib.usedLine = true
                           let line = response.request?.url?.host ?? ""
                           delegate?.useTheLine(line: line)
                           debugPrint("使用线路：\(line)")
                       }
                   }else{
                       myStep2Index += 1
                       if myStep2Index == urlList.count{
                           failedAndRetry()
                       }
                   }
                 
                   break
               case let .failure(error):
                   print(error)
                   myStep2Index += 1
                   if myStep2Index == urlList.count{
                       failedAndRetry()
                   }
               }
           }
       }
    }
    
    private func failedAndRetry(){
        if LineDetectLib.usedLine{
            return
        }
        var result = Result()
        if LineDetectLib.retryTimes < 3{
            LineDetectLib.retryTimes += 1
            result.Code = 1009
            result.Message = "线路获取失败，重试\(LineDetectLib.retryTimes)"
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

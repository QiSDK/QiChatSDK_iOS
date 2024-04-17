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
    }
    
    private var delegate: lineLibDelegate?
    private var urlStrings = [String]()
    private static var usedLine = false
    
    
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
                        let contents = String(data: value!, encoding: .utf8)
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
                            }
                        }
                    }
                    if !f{
                        triedTimes += 1
                        if triedTimes == urlStrings.count{
                            delegate?.lineError(error: "无可用线路")
                        }
                    }
                    
                    break
                case let .failure(error):
                    print(error)
                    triedTimes += 1
                    if triedTimes == urlStrings.count{
                        delegate?.lineError(error: "无可用线路")
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
                           print("使用线路：\(line)")
                           LineLib.usedLine = true
                       }
                       //delegate?.useTheLine(line: "csapi.xdev.stream")
                   }else{
                       triedTimes += 1
                       if triedTimes == lineStrs.count && index == urlStrings.count{
                           delegate?.lineError(error: "无可用线路")
                       }
                   }
                 
                   break
               case let .failure(error):
                   print(error)
                   triedTimes += 1
                   if triedTimes == lineStrs.count && index == urlStrings.count{
                       delegate?.lineError(error: "无可用线路")
                   }
               }
           }
       }
    }
}

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
    var stop = false
    
    func getLine(urlString: String){
        AF.request(urlString).response { response in
            if !stop {
                switch response.result {
                case let .success(value):
                    let contents = String(data: value!, encoding: .utf8)
                    
                    guard let contents = contents else { return }
                    
                    if !contents.contains("getJSONP._JSONP") {
                        return
                    }
                    ///截取两个字符之间的字符串
                    let startRang = contents.range(of: "(")!
                    let endRang = contents.range(of: ")")!
                    let configStr = String(contents[startRang.upperBound..<endRang.lowerBound])
                    //let configModel = JSONDeserializer<BWConfigModel>.deserializeFrom(json: configStr)
                    // let message = AESCrypt.decrypt(configModel?.config, password: IFinal.yxAesKey)
                    
                    /*
                     do {
                     data = try Data(contentsOf: file)
                     } catch {
                     fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
                     }
                     
                     do {
                     let decoder = JSONDecoder()
                     return try decoder.decode(T.self, from: data)
                     } catch {
                     fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
                     }
                     */
                    
                    
                    //self?.stop = true
                case let .failure(error):
                    print(error)
                
                }
            }
        }
    }
}

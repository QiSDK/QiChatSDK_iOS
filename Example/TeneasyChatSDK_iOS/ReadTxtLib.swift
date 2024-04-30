import Foundation
import TeneasyChatSDK_iOS
import Alamofire

// https://swiftpackageregistry.com/daltoniam/Starscream
// https://www.kodeco.com/861-websockets-on-ios-with-starscream
public protocol readTextDelegate : AnyObject{
    func receivedText(msg: String)
}

/*
 interface ReadTextDelegate {
     // 收到消息
     fun receivedMsg(msg: String)
 }
 */

/*
 extension teneasySDKDelegate {
     func receivedMsg2(msg: EasyMessage) {
         /* return a default value or just leave empty */
     }
 }*/

open class ReadTxtLib {
    
    public init(_ urlStrings: [String], delegate: readTextDelegate? = nil) {
        self.delegate = delegate
        self.txtList = urlStrings
      
    }
    
    private var delegate: readTextDelegate?
    private var txtList = [String]()
    private static var usedLine = false
    private static var retryTimes = 0
    private var tenantId: Int? = 0
    public func readText(){
        for txtUrl in txtList {
            
            let url = checkUrl(str: txtUrl)
            if url.isEmpty{
                continue
            }
            let r = (1...100000).randomElement()
            AF.request(url){ $0.timeoutInterval = 2}.response { response in
                switch response.result {
                case let .success(value):
                    
                 
                    if value != nil{
                        //没有加密
                        //let contents = String(data: value!, encoding: .utf8)
                        
                        //有加密，需解密
                        //let base64 = String(data: value!, encoding: .utf8)
                        if let base64 = String(data: value!, encoding: .utf8) {
                            if let contents = self.base64ToString(base64String: base64) {
                                self.delegate?.receivedText(msg: contents)
                            }
                        }
                    }
                    break
                case let .failure(error):
                    print(error)
                  
                }
            }
        }
    }
    
    func base64ToString(base64String: String) -> String? {
        if let data = Data(base64Encoded: base64String) {
            if let decodedString = String(data: data, encoding: .utf8) {
                return decodedString
            }
        }
        return nil
    }
    
    func checkUrl(str: String) -> String{
        let r = (1...100000).randomElement()
         var newStr = str.trimmingCharacters(in: .whitespacesAndNewlines)
        newStr = "\(newStr)?\(r ?? 0)"
        
        print(newStr)
        if (!newStr.hasPrefix("http")){
            newStr = ""
        }
    
        return newStr
    }

}


//
//  LineLib.swift
//  TeneasyChatSDK_iOS
//
//  Created by XiaoFu on 14/4/24.
//

import Foundation
import Alamofire

public protocol LineDetectDelegate: AnyObject {
    func useTheLine(line: String)
    func lineError(error: Result)
}

public struct LineDetectLib {
    // MARK: - 属性定义
    private let delegate: LineDetectDelegate?
    private let urlList: [String]
    private let tenantId: Int
    private let bodyStr: Parameters
    private static var usedLine = false
    private static var retryTimes = 0
    
    private let maxRetries = 3 // 最大重试次数
    private let timeout: TimeInterval = 60 // 请求超时时间
    
    // MARK: - 初始化方法
    public init(_ urlStrings: String, delegate: LineDetectDelegate? = nil, tenantId: Int) {
        self.delegate = delegate
        self.urlList = urlStrings.split(separator: ",").map(String.init)
        self.tenantId = tenantId
        self.bodyStr = ["gnsId": "wcs", "tenantId": tenantId]
        
        LineDetectLib.usedLine = false
        LineDetectLib.retryTimes = 0
    }
    
    // MARK: - 公开方法
    public func getLine() {
        guard !urlList.isEmpty else {
            notifyError(code: 1008, message: "无可用线路")
            return
        }
        
        verifyUrls()
    }
    
    // MARK: - 私有方法
    /// 验证所有可用的URL
    private func verifyUrls() {
        var foundLine = false
        var checkedCount = 0
        
        for txtUrl in urlList {
            guard !LineDetectLib.usedLine else { break }
            guard !foundLine else { break }
            
            let verifyUrl = makeVerifyUrl(from: txtUrl)
            guard !verifyUrl.isEmpty else {
                debugPrint("无效的地址：\(txtUrl)")
                checkedCount += 1
                continue
            }
            
            makeVerifyRequest(url: verifyUrl) { success in
                if success {
                    foundLine = true
                    if !LineDetectLib.usedLine {
                        LineDetectLib.usedLine = true
                        if let url = URL(string: txtUrl),
                           let host = url.host {
                            let port: Int
                            if let urlPort = url.port {
                                // 使用URL中指定的端口
                                port = urlPort
                            } else {
                                // 根据协议设置默认端口
                                port = url.scheme?.lowercased() == "https" ? 443 : 80
                            }
                            
                            // 如果是默认端口（80或443），则不显示端口号
                            let line = (port == 80 || port == 443) ? host : "\(host):\(port)"
                            delegate?.useTheLine(line: line)
                            debugPrint("使用线路：\(line)")
                        }
                    }
                }
                
                checkedCount += 1
                if checkedCount == urlList.count && !foundLine {
                    failedAndRetry()
                }
            }
        }
    }
    
    /// 构建验证URL
    /// - Parameter baseUrl: 基础URL
    /// - Returns: 完整的验证URL
    private func makeVerifyUrl(from baseUrl: String) -> String {
        let trimmedUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUrl.hasPrefix("http") else { return "" }
        
        let random = (1...100000).randomElement() ?? 0
        return "\(trimmedUrl)/v1/api/verify?\(random)"
    }
    
    /// 发送验证请求
    /// - Parameters:
    ///   - url: 请求URL
    ///   - completion: 完成回调，成功返回true，失败返回false
    private func makeVerifyRequest(url: String, completion: @escaping (Bool) -> Void) {
        let uuid = UUID().uuidString
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "x-trace-id": uuid
        ]
        
        AF.request(url,
                  method: .post,
                  parameters: bodyStr,
                  encoding: JSONEncoding.default,
                  headers: headers) { $0.timeoutInterval = timeout }
        .response { response in
            switch response.result {
            case .success(let value):
                if let data = value,
                   let responseStr = String(data: data, encoding: .utf8),
                   responseStr.contains("tenantId") {
                    completion(true)
                } else {
                    debugPrint("线路失败：\(url), 响应数据错误")
                    completion(false)
                }
            case .failure(let error):
                debugPrint("请求失败：\(error)")
                completion(false)
            }
        }
    }
    
    /// 处理失败重试逻辑
    private func failedAndRetry() {
        guard !LineDetectLib.usedLine else { return }
        
        if LineDetectLib.retryTimes < maxRetries {
            LineDetectLib.retryTimes += 1
            notifyError(code: 1009, message: "线路获取失败，重试\(LineDetectLib.retryTimes)")
            getLine()
        } else {
            notifyError(code: 1008, message: "无可用线路")
        }
    }
    
    /// 通知错误信息
    /// - Parameters:
    ///   - code: 错误码
    ///   - message: 错误信息
    private func notifyError(code: Int, message: String) {
        var result = Result()
        result.Code = code
        result.Message = message
        delegate?.lineError(error: result)
    }
}

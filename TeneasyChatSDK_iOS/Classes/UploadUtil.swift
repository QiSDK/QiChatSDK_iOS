//
 //  UploadUtil.swift
 //  Pods
 //
 //  Created by Xiao Fu on 2/12/24.
 //
 import Foundation
 import Alamofire
 import Network
 import PhotosUI
 import UIKit
 import HandyJSON

 /// 上传监听协议，定义上传成功、进度更新和失败的回调方法
 public protocol UploadListener {
    
     /// 上传成功回调
     /// - Parameters:
     ///   - paths: 上传后文件的URL信息
     ///   - filePath: 本地文件路径
     ///   - size: 文件大小
     func uploadSuccess(paths: Urls, filePath: String, size: Int)
     
     /// 上传进度更新回调
     /// - Parameter progress: 上传进度，0-100的整数百分比
     func updateProgress(progress: Int)
     
     /// 上传失败回调
     /// - Parameter msg: 失败信息描述
     func uploadFailed(msg: String)
 }
 
 /*
  支持的文件类型分类：
  ".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".jfif", ".heic": // 图片
  ".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm": // 视频
  ".docx", ".doc", ".pdf", ".xls", ".xlsx", ".csv": // 文件
  */
 
 /// 全局上传进度变量，表示当前上传的百分比
public var uploadProgress = 0;

public var imageTypes = ["jpg", "jpeg", "png", "webp", "gif", "bmp", "jfif", "heic"] // 图片
public var videoTypes = ["mp4", "avi", "mkv", "mov", "wmv", "flv", "webm"] // 视频
public var fileTypes = ["docx", "doc", "pdf", "xls", "xlsx", "csv"] // 文件
 
 /// 上传工具结构体，封装上传相关功能
public struct UploadUtil {
    public init(listener: UploadListener?, filePath: String, fileData: Data, xToken: String, baseUrl: String) {
        self.listener = listener
        self.filePath = filePath
        self.fileData = fileData
        self.xToken = xToken
        self.baseUrl = baseUrl
    }
     
     /// 上传监听器，接收上传状态回调
    var listener : UploadListener?
     /// 本地文件路径
     var filePath: String
     /// 文件数据
     var fileData: Data
     
     var xToken: String = ""
     var baseUrl: String = ""
     
    /// 上传文件方法，支持图片、视频和文件类型
   public func upload() {
        uploadProgress = 1
        // 获取文件扩展名，转为小写
        let ext = filePath.split(separator: ".").last?.lowercased() ?? "$"
        
        // 判断文件类型是否支持
        if !fileTypes.contains(ext) && !imageTypes.contains(ext) && !videoTypes.contains(ext){
            self.listener?.uploadFailed(msg: "不支持的文件格式")
            return
        }
       
       print("upload imgData: \(fileData.count)")
        let api_url = baseUrl + "/v1/assets/upload-v4"
        guard let url = URL(string: api_url) else {
            return
        }
        
        // 创建URL请求，设置超时时间和缓存策略
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0 * 1000)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("multipart/form-data", forHTTPHeaderField: "Accept")

        // 添加认证token
        urlRequest.addValue(xToken, forHTTPHeaderField: "X-Token")
        let parameterDict = NSMutableDictionary()
        parameterDict.setValue(4, forKey: "type")
 
        // 通知监听器上传进度
        listener?.updateProgress(progress: uploadProgress);
     
       AF.upload(multipartFormData: { multiPart in
           // 添加参数到multipart表单
           for (key, value) in parameterDict {
               if let temp = value as? String {
                   multiPart.append(temp.data(using: .utf8)!, withName: key as! String)
               }
               if let temp = value as? Int {
                   multiPart.append("\(temp)".data(using: .utf8)!, withName: key as! String)
               }
           }
           
        // 根据文件类型设置上传文件的mimeType和文件名
        if (fileTypes.contains(ext)){
            multiPart.append(fileData, withName: "myFile", fileName:  "\(Date().timeIntervalSince1970)file.\(ext)", mimeType: self.getMimeType(for: ext))
        }
        else if (videoTypes.contains(ext)) {
            multiPart.append(fileData, withName: "myFile", fileName:  "\(Date().timeIntervalSince1970)file.\(ext)", mimeType: "video/mp4")
        } else {
            multiPart.append(fileData, withName: "myFile", fileName: "\(Date().timeIntervalSince1970)file.png", mimeType: "image/png")
        }
    }, with: urlRequest)
        .uploadProgress(queue: .main, closure: { progress in
            // 这里可以处理上传进度回调（目前未实现）
        })
        .response(completionHandler: { data in
            // 处理上传响应结果
            switch data.result {
            case .success:
               if let resData = data.data {
                   guard let strData = String(data: resData, encoding: String.Encoding.utf8) else {   listener?.uploadFailed(msg: "上传失败，无法转换为UTF-8字符串"); return}
                   //print(strData)
                 
                    let dic = strData.convertToDictionary()
                   if dic == nil{
                       listener?.uploadFailed(msg: "上传失败：\(strData)");
                       return
                   }

                    if data.response?.statusCode == 200{
                        // 解析成功返回的文件路径
                        let myResult = BaseRequestResult<FilePath>.deserialize(from: dic)
                        
                        if let path = myResult?.data?.filepath{
                            let urls = Urls()
                            urls.uri = path
                            listener?.uploadSuccess(paths: urls, filePath: filePath, size: fileData.count)
                            return
                        }
          
                    }else if data.response?.statusCode == 202{
                        // 处理视频上传的分段进度
                        if uploadProgress < 70{
                            uploadProgress = 70
                        }else{
                            uploadProgress += 10
                        }
                        listener?.updateProgress(progress: uploadProgress)
                        let myResult = BaseRequestResult<String>.deserialize(from: dic)
                        if !(myResult?.data ?? "").isEmpty{
                            // 开始订阅视频上传的服务器推送事件
                           self.subscribeToSSE(uploadId: myResult?.data ?? "", isVideo: true)
                            return
                        }
                    }
                    listener?.uploadFailed(msg: "上传失败\(strData)");
                } else {
                    listener?.uploadFailed(msg: "上传失败");
                }
            case .failure(let error):
                listener?.uploadFailed(msg: "上传失败");
                print("上传失败：" + error.localizedDescription)
            }
        })
    }
 
    /// 订阅服务器发送事件（SSE）以获取视频上传进度
    /// - Parameters:
    ///   - uploadId: 上传任务ID
    ///   - isVideo: 是否为视频上传
    private func subscribeToSSE(uploadId: String, isVideo: Bool){
 
          let api_url = baseUrl + "/v1/assets/upload-v4?uploadId=" + uploadId
          debugPrint("SSE 视频 url \(api_url) ---#")
          guard let url = URL(string: api_url) else {
              listener?.uploadFailed(msg: "API URL无效")
              return
          }
          let uuid = UUID().uuidString
          // 创建请求，设置超时和缓存策略
          var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0 * 1000 * 10)
          urlRequest.httpMethod = "GET"
          urlRequest.addValue("text/event-stream", forHTTPHeaderField: "Accept")
          
          // 添加认证token和追踪ID
          urlRequest.addValue(xToken, forHTTPHeaderField: "X-Token")
          urlRequest.addValue(uuid, forHTTPHeaderField: "x-trace-id")
          
          AF.streamRequest(urlRequest)
          .uploadProgress(queue: .main, closure: { progress in
              // 当前上传进度
              print("Upload Progress: \(progress.fractionCompleted)")
          })
          .responseStream { stream in
              print(stream)
              switch stream.result {
                  
              case .success(let response):
                  // 解析服务器推送的事件数据
                  if let strData = String(data: response, encoding: .utf8) {
    #if DEBUG
                      print(strData)
    #endif
                      if (strData.contains("无效UploadID")){
                          listener?.uploadFailed(msg: "无效UploadID");
                          return
                      }
                      let lines = strData.components(separatedBy: "\n")
                      var event: String?
                      var data: String?
                      
                      for line in lines {
                          if line.starts(with: "event:") {
                              event = String(line.dropFirst("event: ".count))
                          } else if line.starts(with: "data:") {
                              data = String(line.dropFirst("data: ".count))
                              
                              guard let dic = data?.convertToDictionary(),
                                    let myResult = UploadPercent.deserialize(from: dic) else {
                                  listener?.uploadFailed(msg: "反序列化SSE数据失败")
                                  return
                              }
                              
                              if (myResult.percentage == 100) {
                                  if let urls = myResult.data {
                                      // 上传完成，更新进度并回调成功
                                     listener?.updateProgress(progress: 100);
                                     listener?.uploadSuccess(paths: urls,  filePath: filePath, size: fileData.count)
                                     return
                                  } else {
                                      listener?.uploadFailed(msg: "上传100%，但未返回路径");
                                  }
                              } else {
                                  // 上传中，更新进度
                                  if (myResult.percentage > uploadProgress){
                                      listener?.updateProgress(progress: myResult.percentage);
                                      print("UploadUtil 上传进度：\(myResult.percentage)")
                                  }
                              }
                          }
                      }
                      
                      if let event = event, let data = data {
                          debugPrint("Event: \(event), Data: \(data)")
                      }
                  } else {
                      print("视频上传失败：")
                      listener?.uploadFailed(msg: "视频上传失败！");
                  }
              case .failure(let error):
                  listener?.uploadFailed(msg: "视频上传失败！");
                  print("视频上传失败：" + error.localizedDescription)
              case .none:
                  print("none")
              }
          }
      }
    
    /// 根据文件扩展名获取对应的MIME类型
    /// - Parameter ext: 文件扩展名
    /// - Returns: MIME类型字符串
    private func getMimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf":
            return "application/pdf"
        case "doc", "docx":
            return "application/msword"
        case "xls", "xlsx", "csv":
            return "application/vnd.ms-excel"
        default:
            return "*/*"
        }
    }
 }
 
 /// String扩展，增加将JSON字符串转换为字典的方法
extension String {
    /// 将JSON格式的字符串转换为字典
    /// - Returns: 字典类型，如果转换失败返回nil
    func convertToDictionary() -> [String: Any]? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("JSON转换失败: \(error.localizedDescription)")
            return nil
        }
    }
}

public class FilePath: HandyJSON {
    public  var filepath: String?
    required public init() {}
}

public class UploadPercent : HandyJSON {
    public  var percentage: Int = 0
    //var path: String? = ""
    var data: Urls?
    required public init() {}
}

public class Urls: HandyJSON {
    public var uri: String? = ""
    public var hlsUri: String? = ""
    public var thumbnailUri = ""
    required public init() {}
}


public class BaseRequestResult<T>: HandyJSON {
    public var code: Int?
    public var msg: String?
    public var data: T?
    required public init() {}
}

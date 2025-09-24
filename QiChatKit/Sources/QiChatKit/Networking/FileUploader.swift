import Foundation
import Alamofire

public protocol FileUploadDelegate: AnyObject {
    func fileUploader(_ uploader: FileUploader, didUpdate progress: Int)
    func fileUploader(_ uploader: FileUploader, didCompleteWith result: UploadedResource, localFilePath: String, size: Int)
    func fileUploader(_ uploader: FileUploader, didFailWith message: String)
}

public struct UploadedResource: Decodable {
    public let uri: String?
    public let hlsUri: String?
    public let thumbnailUri: String?
}

private struct UploadResponse<T: Decodable>: Decodable {
    let code: Int?
    let msg: String?
    let data: T?
}

private struct UploadProgressPayload: Decodable {
    let percentage: Int
    let data: UploadedResource?
}

public final class FileUploader {
    public weak var delegate: FileUploadDelegate?

    private enum FileCategory {
        case image
        case video
        case document

        static func category(for ext: String) -> FileCategory? {
            let lower = ext.lowercased()
            if Self.imageExtensions.contains(lower) { return .image }
            if Self.videoExtensions.contains(lower) { return .video }
            if Self.documentExtensions.contains(lower) { return .document }
            return nil
        }

        static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif", "bmp", "jfif", "heic"]
        static let videoExtensions: Set<String> = ["mp4", "avi", "mkv", "mov", "wmv", "flv", "webm"]
        static let documentExtensions: Set<String> = ["docx", "doc", "pdf", "xls", "xlsx", "csv"]
    }

    private let baseURL: URL
    private let token: String
    private let session: Session
    private let queue = DispatchQueue(label: "com.qichatkit.uploader")

    private var progress: Int = 0

    public init(baseURL: URL, token: String, session: Session = .default, delegate: FileUploadDelegate? = nil) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        self.delegate = delegate
    }

    @discardableResult
    public func upload(data: Data, filePath: String) -> DataRequest? {
        let fileSize = data.count
        guard let ext = filePath.split(separator: ".").last.map(String.init) else {
            delegate?.fileUploader(self, didFailWith: "缺少文件扩展名")
            return nil
        }

        guard let category = FileCategory.category(for: ext) else {
            delegate?.fileUploader(self, didFailWith: "不支持的文件格式")
            return nil
        }

        let uploadURL = baseURL.appendingPathComponent("v1/assets/upload-v4")
        var request = URLRequest(url: uploadURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("multipart/form-data", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "X-Token")

        progress = 1
        dispatchToMain { [weak self] in
            guard let self else { return }
            self.delegate?.fileUploader(self, didUpdate: self.progress)
        }

        let parameters: [String: Any] = ["type": 4]

        let requestBuilder: (MultipartFormData) -> Void = { form in
            parameters.forEach { key, value in
                if let string = value as? String, let data = string.data(using: .utf8) {
                    form.append(data, withName: key)
                } else if let intValue = value as? Int, let data = "\(intValue)".data(using: .utf8) {
                    form.append(data, withName: key)
                }
            }

            let fileName: String
            let mimeType: String
            switch category {
            case .document:
                fileName = "\(Date().timeIntervalSince1970)file.\(ext)"
                mimeType = Self.mimeType(for: ext)
            case .video:
                fileName = "\(Date().timeIntervalSince1970)file.\(ext)"
                mimeType = "video/mp4"
            case .image:
                fileName = "\(Date().timeIntervalSince1970)file.\(ext)"
                mimeType = "image/\(ext == "jpg" ? "jpeg" : ext)"
            }

            form.append(data,
                        withName: "myFile",
                        fileName: fileName,
                        mimeType: mimeType)
        }

        let uploadRequest = session.upload(multipartFormData: requestBuilder, with: request)
        uploadRequest.uploadProgress(queue: queue) { [weak self] value in
            guard let self else { return }
            let percentage = Int(value.fractionCompleted * 100)
            self.progress = max(percentage, self.progress)
            self.dispatchToMain {
                self.delegate?.fileUploader(self,
                                             didUpdate: self.progress)
            }
        }

        uploadRequest.responseData(queue: queue) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case .success(let data):
                let statusCode = response.response?.statusCode ?? 0
                if statusCode == 200 {
                    self.handleSuccessResponse(data: data, localPath: filePath, size: fileSize)
                } else if statusCode == 202 {
                    self.handleAcceptedResponse(data: data, originalSize: fileSize, localPath: filePath)
                } else {
                    let message = String(data: data, encoding: .utf8) ?? "上传失败"
                    self.dispatchToMain {
                        self.delegate?.fileUploader(self, didFailWith: message)
                    }
                }
            case .failure(let error):
                self.dispatchToMain {
                    self.delegate?.fileUploader(self, didFailWith: error.localizedDescription)
                }
            }
        }

        return uploadRequest
    }

    private func handleSuccessResponse(data: Data, localPath: String, size: Int) {
        do {
            let response = try JSONDecoder().decode(UploadResponse<UploadedResource>.self, from: data)
            if let resource = response.data {
                dispatchToMain { [weak self] in
                    guard let self else { return }
                    self.delegate?.fileUploader(self,
                                                didUpdate: 100)
                    self.delegate?.fileUploader(self,
                                                didCompleteWith: resource,
                                                localFilePath: localPath,
                                                size: size)
                }
            } else {
                dispatchToMain { [weak self] in
                    guard let self else { return }
                    self.delegate?.fileUploader(self, didFailWith: response.msg ?? "上传失败")
                }
            }
        } catch {
            dispatchToMain { [weak self] in
                guard let self else { return }
                self.delegate?.fileUploader(self, didFailWith: "上传结果解析失败")
            }
        }
    }

    private func handleAcceptedResponse(data: Data, originalSize: Int, localPath: String) {
        do {
            let response = try JSONDecoder().decode(UploadResponse<String>.self, from: data)
            guard let uploadId = response.data, !uploadId.isEmpty else {
                dispatchToMain { [weak self] in
                    guard let self else { return }
                    self.delegate?.fileUploader(self, didFailWith: response.msg ?? "上传失败")
                }
                return
            }
            if progress < 70 {
                progress = 70
            } else {
                progress = min(progress + 10, 95)
            }
            dispatchToMain { [weak self] in
                guard let self else { return }
                self.delegate?.fileUploader(self, didUpdate: self.progress)
            }
            subscribeToSSE(uploadId: uploadId, localPath: localPath, originalSize: originalSize)
        } catch {
            dispatchToMain { [weak self] in
                guard let self else { return }
                self.delegate?.fileUploader(self, didFailWith: "上传响应解析失败")
            }
        }
    }

    private func subscribeToSSE(uploadId: String, localPath: String, originalSize: Int) {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/assets/upload-v4"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "uploadId", value: uploadId)]
        guard let url = components?.url else {
            dispatchToMain { [weak self] in
                guard let self else { return }
                self.delegate?.fileUploader(self, didFailWith: "SSE 地址无效")
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.timeoutInterval = 600
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "X-Token")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "x-trace-id")

        let stream = session.streamRequest(request)
        stream.responseStreamString(queue: queue, stream: { [weak self] stream in
            guard let self else { return }
            switch stream.event {
            case .stream(let string):
                self.handleSSEPayload(string, localPath: localPath, originalSize: originalSize)
            case .complete(let completion):
                if let error = completion.error {
                    self.dispatchToMain {
                        self.delegate?.fileUploader(self, didFailWith: error.localizedDescription)
                    }
                }
            }
        })
    }

    private func handleSSEPayload(_ string: String, localPath: String, originalSize: Int) {
        let lines = string.split(separator: "\n")
        var dataLine: String?
        for line in lines where line.starts(with: "data:") {
            dataLine = String(line.dropFirst("data:".count)).trimmingCharacters(in: .whitespaces)
        }

        guard let payloadString = dataLine, let payloadData = payloadString.data(using: .utf8) else {
            return
        }

        do {
            let progressPayload = try JSONDecoder().decode(UploadProgressPayload.self, from: payloadData)
            if progressPayload.percentage >= 100 {
                if let resource = progressPayload.data {
                    dispatchToMain { [weak self] in
                        guard let self else { return }
                        self.delegate?.fileUploader(self, didUpdate: 100)
                        self.delegate?.fileUploader(self,
                                                    didCompleteWith: resource,
                                                    localFilePath: localPath,
                                                    size: originalSize)
                    }
                } else {
                    dispatchToMain { [weak self] in
                        guard let self else { return }
                        self.delegate?.fileUploader(self, didFailWith: "上传100%，但未返回路径")
                    }
                }
            } else if progressPayload.percentage > progress {
                progress = progressPayload.percentage
                dispatchToMain { [weak self] in
                    guard let self else { return }
                    self.delegate?.fileUploader(self, didUpdate: self.progress)
                }
            }
        } catch {
            dispatchToMain { [weak self] in
                guard let self else { return }
                self.delegate?.fileUploader(self, didFailWith: "SSE 数据解析失败")
            }
        }
    }

    private func dispatchToMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf": return "application/pdf"
        case "doc", "docx": return "application/msword"
        case "xls", "xlsx", "csv": return "application/vnd.ms-excel"
        default: return "application/octet-stream"
        }
    }
}

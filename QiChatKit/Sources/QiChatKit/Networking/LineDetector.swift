import Foundation
import Alamofire

public protocol LineDetectorDelegate: AnyObject {
    func lineDetector(_ detector: LineDetector, didSelect line: String)
    func lineDetector(_ detector: LineDetector, didFailWith result: SDKResult)
}

public final class LineDetector {
    private struct RemoteConfig: Decodable {
        let lines: [Line]
    }

    public struct Line: Decodable {
        public let apiBaseURL: URL
        public let wssHost: String
        public let imageBaseURL: URL

        private enum CodingKeys: String, CodingKey {
            case apiBaseURL = "VITE_API_BASE_URL"
            case wssHost = "VITE_WSS_HOST"
            case imageBaseURL = "VITE_IMG_URL"
        }
    }

    private let urlStrings: [String]
    private weak var delegate: LineDetectorDelegate?
    private let tenantId: Int
    private let maxRetries: Int
    private var retryCount = 0
    private let requestTimeout: TimeInterval
    private var isResolved = false

    private var linesToVerify: [(origin: String, lines: [Line])] = []

    public init(urls: String,
                tenantId: Int,
                delegate: LineDetectorDelegate?,
                maxRetries: Int = 3,
                requestTimeout: TimeInterval = 2) {
        self.urlStrings = urls.split(separator: ",").map { String($0) }
        self.tenantId = tenantId
        self.delegate = delegate
        self.maxRetries = maxRetries
        self.requestTimeout = requestTimeout
    }

    public func start() {
        guard !urlStrings.isEmpty else {
            notifyFailure(code: 1008, message: "无可用线路")
            return
        }
        resolveLines()
    }

    private func resolveLines() {
        linesToVerify.removeAll()
        let group = DispatchGroup()

        for urlString in urlStrings {
            guard let requestURL = sanitize(urlString) else { continue }
            group.enter()
            fetchConfig(from: requestURL) { [weak self] result in
                defer { group.leave() }
                guard let self else { return }
                switch result {
                case .success(let lines):
                    if !lines.isEmpty {
                        self.linesToVerify.append((origin: urlString, lines: lines))
                    }
                case .failure:
                    break
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            guard !self.linesToVerify.isEmpty else {
                if self.shouldRetry() {
                    self.resolveLines()
                } else {
                    self.notifyFailure(code: 1008, message: "无可用线路")
                }
                return
            }
            self.verifyResolvedLines()
        }
    }

    private func verifyResolvedLines() {
        guard !isResolved else { return }
        let dispatchQueue = DispatchQueue(label: "com.qichatkit.line.verify", qos: .userInitiated)
        dispatchQueue.async { [weak self] in
            guard let self else { return }
            for pair in self.linesToVerify {
                for line in pair.lines {
                    if self.isResolved { return }
                    guard let verifyURL = self.verifyURL(for: line) else { continue }

                    let body: Parameters = [
                        "gnsId": "wcs",
                        "tenantId": self.tenantId
                    ]

                    let semaphore = DispatchSemaphore(value: 0)
                    AF.request(verifyURL,
                               method: .post,
                               parameters: body,
                               encoding: JSONEncoding.default,
                               requestModifier: { $0.timeoutInterval = self.requestTimeout })
                        .responseData { [weak self] response in
                            defer { semaphore.signal() }
                            guard let self else { return }
                            switch response.result {
                            case .success(let data):
                                if self.isValidResponse(data) {
                                    self.finishSuccessfully(with: line)
                                }
                            case .failure:
                                break
                            }
                        }
                    semaphore.wait()
                    if self.isResolved { return }
                }
            }

            if !self.isResolved {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if self.shouldRetry() {
                        self.notifyRetryAttempt(self.retryCount)
                        self.resolveLines()
                    } else {
                        self.notifyFailure(code: 1009, message: "线路获取失败")
                    }
                }
            }
        }
    }

    private func fetchConfig(from url: URL, completion: @escaping (Result<[Line], Error>) -> Void) {
        AF.request(url, requestModifier: { $0.timeoutInterval = requestTimeout })
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        guard let base64 = String(data: data, encoding: .utf8) else {
                            completion(.failure(LineDetectorError.invalidPayload))
                            return
                        }
                        guard let decoded = DataCoders.decodeBase64String(base64) else {
                            completion(.failure(LineDetectorError.invalidPayload))
                            return
                        }
                        let config = try DataCoders.decodeJSON(RemoteConfig.self, from: decoded)
                        let httpsLines = config.lines.filter { $0.apiBaseURL.scheme?.hasPrefix("http") == true }
                        completion(.success(httpsLines))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func sanitize(_ urlString: String) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("http") else { return nil }
        let random = Int.random(in: 1...100_000)
        return URL(string: "\(trimmed)?\(random)")
    }

    private func verifyURL(for line: Line) -> URL? {
        var components = URLComponents(url: line.apiBaseURL, resolvingAgainstBaseURL: false)
        var path = components?.path ?? ""
        if !path.hasSuffix("/") {
            path.append("/")
        }
        path.append("v1/api/verify")
        components?.path = path
        components?.queryItems = [URLQueryItem(name: "rd", value: String(Int.random(in: 1...100_000)))]
        return components?.url
    }

    private func isValidResponse(_ data: Data) -> Bool {
        guard let string = String(data: data, encoding: .utf8) else { return false }
        return string.contains("tenantId\\":\(tenantId)")
    }

    private func finishSuccessfully(with line: Line) {
        guard !isResolved else { return }
        isResolved = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let url = line.apiBaseURL
            if let host = url.host {
                let port = url.port ?? (url.scheme == "https" ? 443 : 80)
                let lineString = (port == 80 || port == 443) ? host : "\(host):\(port)"
                self.delegate?.lineDetector(self, didSelect: lineString)
            } else {
                self.delegate?.lineDetector(self, didSelect: url.absoluteString)
            }
        }
    }

    private func notifyFailure(code: Int, message: String) {
        guard !isResolved else { return }
        isResolved = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.lineDetector(self, didFailWith: SDKResult(code: code, message: message))
        }
    }

    private func shouldRetry() -> Bool {
        guard retryCount < maxRetries else { return false }
        retryCount += 1
        return true
    }

    private func notifyRetryAttempt(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.lineDetector(self, didFailWith: SDKResult(code: 1009, message: "线路获取失败，重试\(count)"))
        }
    }
}

enum LineDetectorError: Error {
    case invalidPayload
}

import Foundation
import Alamofire

public enum ReachabilityStatus: Equatable {
    case notReachable
    case unknown
    case ethernetOrWiFi
    case cellular
}

protocol ReachabilityMonitorDelegate: AnyObject {
    func reachabilityMonitor(_ monitor: ReachabilityMonitor, didChange status: ReachabilityStatus)
}

final class ReachabilityMonitor {
    weak var delegate: ReachabilityMonitorDelegate?

    private let manager: NetworkReachabilityManager?
    private let queue = DispatchQueue(label: "com.qichatkit.reachability")

    init(host: String = "www.bing.com") {
        manager = NetworkReachabilityManager(host: host)
    }

    func start() {
        manager?.startListening(onQueue: queue) { [weak self] status in
            guard let self else { return }
            let mappedStatus: ReachabilityStatus
            switch status {
            case .notReachable:
                mappedStatus = .notReachable
            case .unknown:
                mappedStatus = .unknown
            case .reachable(.ethernetOrWiFi):
                mappedStatus = .ethernetOrWiFi
            case .reachable(.cellular):
                mappedStatus = .cellular
            }
            self.delegate?.reachabilityMonitor(self, didChange: mappedStatus)
        }
    }

    func stop() {
        manager?.stopListening()
    }
}

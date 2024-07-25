//
//  NetworkManager.swift
//  TeneasyChatSDK_iOS
//
//  Created by Xuefeng on 25/7/24.
//

import Foundation
import Alamofire

public enum NetworkManagerStatus {
    case notReachable
    case unknown
    case ethernetOrWiFi
    case cellular
}

protocol NetworkManagerDelegate: AnyObject {
    func networkRechabilityStatus(status: NetworkManagerStatus)
}

public class NetworkManager {
    
    weak var delegate: NetworkManagerDelegate? = nil
    
    private let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.bing.com")

    func startNetworkReachabilityObserver() {
        
        // start listening
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] status in
            
            var networkStatus: NetworkManagerStatus = .unknown
            switch status {
                case .notReachable:
                    networkStatus = .notReachable
                case .unknown :
                    networkStatus = .unknown
                case .reachable(.ethernetOrWiFi):
                    networkStatus = .ethernetOrWiFi
                case .reachable(.cellular):
                    networkStatus = .cellular
            }
            self?.delegate?.networkRechabilityStatus(status: networkStatus)
            
        })
        


    }
    
    func stopNetworkReachabilityObserver() {
        reachabilityManager?.stopListening()
    }
    
}

//
//  Config.swift
//  TeneasyChatSDK_iOS
//
//  Created by Xuefeng on 17/4/24.
//

import Foundation
import HandyJSON

struct AppConfig: Codable, HandyJSON  {
     init() {
    }
    
    var code: Int = 0
    var version: String = ""
    var name: String = ""
    var token: String = ""
    var publicKey: String = ""
    var lines: [Line] = []
}

struct Line: Codable, HandyJSON  {
    var VITE_API_BASE_URL: String = ""
    var VITE_WSS_HOST: String = ""
    var VITE_IMG_URL: String = ""
}

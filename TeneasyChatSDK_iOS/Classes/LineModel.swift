//
//  BWConfigModel.swift
//  TeneasyChatSDK_iOS
//
//  Created by Xuefeng on 14/4/24.
//

import Foundation


struct BWConfigModel: Codable {
  let code: Int
  let data: [ServerConfig]

  struct ServerConfig: Codable {
    let viteAPIBaseURL: String? // Optional to handle potential missing value
    let viteWssHost1: String?    // Optional to handle potential missing value
    let viteWssHost2: String?    // Optional to handle potential missing value
    let viteImageURL: String?    // Optional to handle potential missing value
    let version: String?        // Optional to handle potential missing value
    let name: String?           // Optional to handle potential missing value
    let token: String?          // Optional to handle potential missing value
    let publicKey: String?      // Optional to handle potential missing value
  }
}

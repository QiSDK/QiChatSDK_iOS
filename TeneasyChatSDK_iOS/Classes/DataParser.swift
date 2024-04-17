//
//  DataParser.swift
//  TeneasyChatSDK_iOS
//
//  Created by Xuefeng on 14/4/24.
//

import Foundation
func loadFromLocal<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

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
}

func load<T: Decodable>(_ data: Data) -> T {
   // let data =  Data(data)
   
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(data) as \(T.self):\n\(error)")
    }
}

func encodeStringToBase64(_ base64String: String) -> Data? {
 
  guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
    return nil
  }
  return data
}

func decodeBase64ToString(_ base64Data: Data) -> String? {
  guard let decodedString = String(data: base64Data, encoding: .utf8) else {
    return nil
  }
  return decodedString
}

func base64ToString(base64String: String) -> String? {
    if let data = Data(base64Encoded: base64String) {
        if let decodedString = String(data: data, encoding: .utf8) {
            return decodedString
        }
    }
    return nil
}

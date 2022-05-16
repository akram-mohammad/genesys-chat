//
// ChatServiceSettings.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary

/// A custom subclass of `GmsServiceSettings` for Chat.
///
/// Made `Codable` for preference persistence.
class ChatServiceSettings: GmsServiceSettings, Codable {
    public let useCometClient: Bool
    public let enableWebsocket: Bool
    
    init(_ serviceName: String,
         useCometClient: Bool,
         enableWebsocket: Bool = true,
         additionalParameters: [String : ParameterValue] = [String: ParameterValue]()) throws {
        self.useCometClient = useCometClient
        self.enableWebsocket = enableWebsocket
        try super.init(serviceName, additionalParameters: additionalParameters)
    }

    // MARK: - Codable
    class CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        required init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        required convenience init?(intValue: Int) {
            self.init(stringValue: "\(intValue)")
            self.intValue = intValue
        }
        
        static let useCometClient = CodingKeys(stringValue: "useCometClient")!
        static let enableWebsocket = CodingKeys(stringValue: "enableWebsocket")!
        static let serviceName = CodingKeys(stringValue: "serviceName")!
        static let prefix = "parameters."
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serviceName, forKey: CodingKeys.serviceName)
        try container.encode(useCometClient, forKey: CodingKeys.useCometClient)
        try container.encode(enableWebsocket, forKey: CodingKeys.enableWebsocket)
        for (key, value) in additionalParameters {
            let codingKey = CodingKeys(stringValue: "\(CodingKeys.prefix)\(key)")!
            if value is Int {
                try container.encode(value as! Int, forKey: codingKey)
            } else if value is Bool {
                try container.encode(value as! Bool, forKey: codingKey)
            } else if value is Double {
                try container.encode(value as! Double, forKey: codingKey)
            } else {
                try container.encode((value as CustomStringConvertible).description, forKey: codingKey)
            }
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let serviceName = try values.decode(String.self, forKey: CodingKeys.serviceName)
        let useCometClient = try values.decodeIfPresent(Bool.self, forKey: CodingKeys.useCometClient) ?? false
        let enableWebsocket = try values.decodeIfPresent(Bool.self, forKey: CodingKeys.enableWebsocket) ?? true
        var properties = [String: ParameterValue]()
        for key in values.allKeys {
            let keyStr = key.stringValue
            if keyStr.starts(with: CodingKeys.prefix) {
                let substrStart = keyStr.index(keyStr.startIndex, offsetBy: CodingKeys.prefix.count)
                let myKey = String(keyStr[substrStart...keyStr.endIndex])
                
                let value: ParameterValue
                do {
                    value = try values.decode(Bool.self, forKey: key)
                } catch {
                    do {
                        value = try values.decode(Int.self, forKey: key)
                    } catch {
                        do {
                            value = try values.decode(Double.self, forKey: key)
                        } catch {
                            do {
                                value = try values.decode(String.self, forKey: key)
                            } catch {
                                throw error
                            }
                        }
                    }
                }
                properties[myKey] = value
            }
        }
        try self.init(serviceName, useCometClient: useCometClient, enableWebsocket: enableWebsocket, additionalParameters: properties)
    }
}

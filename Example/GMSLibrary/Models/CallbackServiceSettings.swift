//
// CallbackServiceSettings.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//

import Foundation
import GMSLibrary

/// A custom subclass of `GmsServiceSettings` for Callback.
///
/// Made `Codable` for preference persistence.
class CallbackServiceSettings: GmsServiceSettings, Codable {
    
    /// Type of callback.
    public let callbackType: CallbackType
    
    /// Target of the callback.
    public let target: String
    
    init(_ serviceName: String,
         callbackType: CallbackType,
         target: String,
         additionalParameters: [String : ParameterValue] = [String: ParameterValue]()) throws {
        self.callbackType = callbackType
        
        if target.isEmpty {
            throw GmsApiError.missingGmsSettingsValue(key: "target")
        }
        self.target = target
        try super.init(serviceName, additionalParameters: additionalParameters)
    }
    
    func clone(withServiceName serviceName: String) throws -> CallbackServiceSettings {
        return try CallbackServiceSettings(serviceName,
                                           callbackType: callbackType,
                                           target: target,
                                           additionalParameters: additionalParameters)
    }
    
    func clone(withCallbackType callbackType: CallbackType) throws -> CallbackServiceSettings {
        return try CallbackServiceSettings(serviceName,
                                           callbackType: callbackType,
                                           target: target,
                                           additionalParameters: additionalParameters)
    }
    
    func clone(withTarget target: String) throws -> CallbackServiceSettings {
        return try CallbackServiceSettings(serviceName,
                                           callbackType: callbackType,
                                           target: target,
                                           additionalParameters: additionalParameters)
    }
    
    func clone(withAdditionalParameters additionalParameters: [String: ParameterValue]) throws -> CallbackServiceSettings {
        return try CallbackServiceSettings(serviceName,
                                           callbackType: callbackType,
                                           target: target,
                                           additionalParameters: additionalParameters)
    }

    /// Additional parameters to include in callback start
    override var additionalParameters: [String: ParameterValue] {
        var properties = super.additionalParameters
        properties["_target"] = target
        if let calldirection = callbackType.callDirection {
            properties["_call_direction"] = calldirection.rawValue
        }
        if let waitForAgent = callbackType.waitForAgent {
            properties["_wait_for_agent"] = waitForAgent
        }
        if let waitForUserConfirm = callbackType.waitForUserConfirm {
            properties["_wait_for_user_confirm"] = waitForUserConfirm
        }
        if let media = callbackType.media {
            properties["_media_type"] = media
        }
        return properties
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
        
        static let callbackType = CodingKeys(stringValue: "callbackType")!
        static let target = CodingKeys(stringValue: "target")!
        static let serviceName = CodingKeys(stringValue: "serviceName")!
        static let prefix = "parameters."
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serviceName, forKey: CodingKeys.serviceName)
        try container.encode(callbackType, forKey: CodingKeys.callbackType)
        try container.encode(target, forKey: CodingKeys.target)
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
        let callbackType = try values.decode(CallbackType.self, forKey: CodingKeys.callbackType)
        let target = try values.decode(String.self, forKey: CodingKeys.target)
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
        try self.init(serviceName, callbackType: callbackType, target: target, additionalParameters: properties)
    }
}

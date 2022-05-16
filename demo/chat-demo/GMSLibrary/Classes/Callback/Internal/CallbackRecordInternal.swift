//
//  CallbackRecordInternal.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-09.
//

import Foundation

/// Internal implementation of CallbackRecord to make it Codable.
public class CallbackRecordInternal: CallbackRecord, Codable {
    // MARK: - Codable

    class CodingKeys: AnyCodingKey {
        static let callbackId = CodingKeys(stringValue: "_id")!
        static let desiredTime = CodingKeys(stringValue: "_desired_time")!
        static let callbackState = CodingKeys(stringValue: "_callback_state")!
        static let expirationTime = CodingKeys(stringValue: "_expiration_time")!
        static let customerNumber = CodingKeys(stringValue: "_customer_number")!
        static let url = CodingKeys(stringValue: "url")!
        static let callbackReason = CodingKeys(stringValue: "_callback_reason")!
        static let namedKeys = [
            callbackId.stringValue: callbackId,
            desiredTime.stringValue: desiredTime,
            callbackState.stringValue: callbackState,
            expirationTime.stringValue: expirationTime,
            customerNumber.stringValue: customerNumber,
            url.stringValue: url,
            callbackReason.stringValue: callbackReason
        ]

        static func isNamedKey(_ name: String) -> Bool {
            return namedKeys[name] != nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callbackId, forKey: CodingKeys.callbackId)
        try container.encodeIfPresent(desiredTime?.iso8601 ?? nil, forKey: CodingKeys.desiredTime)
        try container.encodeIfPresent(callbackState, forKey: CodingKeys.callbackState)
        try container.encodeIfPresent(customerNumber, forKey: CodingKeys.customerNumber)
        try container.encodeIfPresent(expirationTime?.iso8601 ?? nil, forKey: CodingKeys.expirationTime)
        try container.encodeIfPresent(callbackReason, forKey: CodingKeys.callbackReason)
        try container.encodeIfPresent(url, forKey: CodingKeys.url)
        for key in properties.keys where !CodingKeys.isNamedKey(key) {
            try container.encode(properties[key], forKey: CodingKeys(stringValue: key)!)
        }
    }

    public required init(from decoder: Decoder) throws {
        debugPrint("[CallbackRecordInternal] decode")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let callbackId = try values.decode(String.self, forKey: .callbackId)
        debugPrint("[CallbackRecordInternal] callbackId=\(callbackId)")
        let desiredTimeStr = try values.decodeIfPresent(String.self, forKey: .desiredTime)
        let desiredTime = desiredTimeStr?.iso8601 ?? nil
        let callbackState = try values.decodeIfPresent(String.self, forKey: .callbackState)
        let customerNumber = try values.decodeIfPresent(String.self, forKey: .customerNumber)
        let expirationTimeStr = try values.decodeIfPresent(String.self, forKey: .expirationTime)
        let expirationTime = expirationTimeStr?.iso8601 ?? nil
        let callbackReason = try values.decodeIfPresent(String.self, forKey: .callbackReason)
        let url = try values.decodeIfPresent(String.self, forKey: .url)
        var properties = [String: String]()
        for key in values.allKeys where !CodingKeys.isNamedKey(key.stringValue) {
            properties[key.stringValue] = try values.decode(String.self, forKey: key)
        }
        super.init(
            callbackId: callbackId,
            desiredTime: desiredTime,
            callbackState: callbackState,
            expirationTime: expirationTime,
            customerNumber: customerNumber,
            url: url,
            callbackReason: callbackReason,
            properties: properties
        )
    }
}

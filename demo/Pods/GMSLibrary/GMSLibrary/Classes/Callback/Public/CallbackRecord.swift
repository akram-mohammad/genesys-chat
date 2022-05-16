//
//  CallbackRecord.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Foundation

/// Callback record.
public class CallbackRecord: CustomStringConvertible, Hashable {
    /// Callback service ID.
    public let callbackId: String

    /// Desired time of the callback.  Nil if not returned.
    public let desiredTime: Date?

    /// Callback state.  Nil if not returned.
    public let callbackState: String?

    /// Expiration time of the callback.  Nil if not returned.
    public let expirationTime: Date?

    /// Customer phone number to call back.  Nil if not returned.
    public let customerNumber: String?

    /// Callback completion reason.  Nil if not returned.
    public let callbackReason: String?

    /// URL of the callback record.  Nil if not returned.
    public let url: String?

    /// Additional properties associated with the callback.
    public let properties: [String: String]

    init(
        callbackId: String,
        desiredTime: Date? = nil,
        callbackState: String? = nil,
        expirationTime: Date? = nil,
        customerNumber: String? = nil,
        url: String? = nil,
        callbackReason: String? = nil,
        properties: [String: String] = [String: String]()
    ) {
        self.callbackId = callbackId
        self.desiredTime = desiredTime
        self.callbackState = callbackState
        self.expirationTime = expirationTime
        self.customerNumber = customerNumber
        self.url = url
        self.callbackReason = callbackReason
        self.properties = properties
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: CallbackRecord.self) + "@\(hashValue)[" +
            "callbackId=\(callbackId)," +
            "desiredTime=\(desiredTime?.iso8601 ?? "nil")," +
            "callbackState=\(callbackState ?? "nil")," +
            "expirationTime=\(expirationTime?.iso8601 ?? "nil")," +
            "customerNumber=\(customerNumber ?? "nil")," +
            "url=\(url ?? "nil")," +
            "callbackReason=\(callbackReason ?? "nil")," +
            "properties=\(properties)]"
    }

    public static func == (lhs: CallbackRecord, rhs: CallbackRecord) -> Bool {
        return lhs.callbackId == rhs.callbackId && lhs.desiredTime == rhs.desiredTime &&
            lhs.callbackState == rhs.callbackState && lhs.callbackReason == rhs.callbackReason &&
            lhs.customerNumber == rhs.customerNumber && lhs.properties == rhs.properties &&
            lhs.url == rhs.url && lhs.expirationTime == rhs.expirationTime
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callbackId)
        hasher.combine(desiredTime)
        hasher.combine(callbackState)
        hasher.combine(expirationTime)
        hasher.combine(customerNumber)
        hasher.combine(url)
        hasher.combine(callbackReason)
        hasher.combine(properties)
    }
}

//
//  CallbackAvailabilityV2Slot.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Foundation

/// A single time slot returned by Query Availability V2 request.
open class CallbackAvailabilityV2Slot: Hashable, CustomStringConvertible {
    /// Time slot timestamp
    public let utcTime: Date

    /// Time slot in local time in ISO8601 format without timezone, if `timezone`
    /// provided in the Query Availability V2 request.
    public let localTime: String?

    /// Current capacity of this time slot.
    public let capacity: Int

    /// Total capacity of this time slot.
    public let total: Int

    init(utcTime: Date, localTime: String?, capacity: Int, total: Int) throws {
        self.utcTime = utcTime
        self.localTime = localTime
        self.capacity = capacity
        self.total = total
    }

    // MARK: - Equatable

    public static func == (lhs: CallbackAvailabilityV2Slot, rhs: CallbackAvailabilityV2Slot) -> Bool {
        return lhs.utcTime == rhs.utcTime && lhs.localTime == rhs.localTime &&
            lhs.capacity == rhs.capacity && lhs.total == rhs.total
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(utcTime)
        hasher.combine(localTime)
        hasher.combine(capacity)
        hasher.combine(total)
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: CallbackAvailabilityV2Slot.self) + "@\(hashValue)[" +
            "utcTime=\(utcTime.iso8601)," +
            "localTime=\(localTime ?? "nil")," +
            "capacity=\(capacity)," +
            "total=\(total)]"
    }
}

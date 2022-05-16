//
//  CallbackAvailabilityV2Result.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Foundation

/// Result from Query Availability V2 request.
open class CallbackAvailabilityV2Result: Hashable, CustomStringConvertible {
    private let mySlots: [CallbackAvailabilityV2Slot]

    /// Duration of each time slot, in minutes.
    public let durationMin: Int

    /// Time zone for `localTime` of each `AvailabilityV2Slot`, if provided
    public let timezone: String?

    init(slots: [CallbackAvailabilityV2Slot], durationMin: Int, timezone: String?) throws {
        mySlots = slots
        self.durationMin = durationMin
        self.timezone = timezone
    }

    /// Time slots returned by Query Availability V2 request.
    public var slots: [CallbackAvailabilityV2Slot] {
        return mySlots
    }

    // MARK: - Equatable

    public static func == (lhs: CallbackAvailabilityV2Result, rhs: CallbackAvailabilityV2Result) -> Bool {
        return lhs.durationMin == rhs.durationMin && lhs.timezone == rhs.timezone && lhs.slots == rhs.slots
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(durationMin)
        hasher.combine(timezone)
        hasher.combine(slots)
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: CallbackAvailabilityV2Result.self) + "@\(hashValue)[" +
            "slots=\(slots),duration=\(durationMin),timezone=\(timezone ?? "nil")]"
    }
}

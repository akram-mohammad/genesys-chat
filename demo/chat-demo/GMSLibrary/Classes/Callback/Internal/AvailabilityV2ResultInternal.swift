//
//  AvailabilityV2ResultInternal.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-09.
//

import Foundation

/// Callback availablity result (v2)
class AvailabilityV2ResultInternal: CallbackAvailabilityV2Result, Codable {
    let mySlots: [AvailabilityV2SlotInternal]
    public override var slots: [CallbackAvailabilityV2Slot] {
        return mySlots as [CallbackAvailabilityV2Slot]
    }

    init(slots: [AvailabilityV2SlotInternal], durationMin: Int, timezone: String?) throws {
        mySlots = slots
        try super.init(slots: slots, durationMin: durationMin, timezone: timezone)
    }

    // MARK: - AvailabilityV2ResultInternal.Codable

    enum CodingKeys: String, CodingKey {
        case durationMin
        case timezone
        case slots
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(durationMin, forKey: .durationMin)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(mySlots, forKey: .slots)
    }

    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let durationMin = try values.decode(Int.self, forKey: .durationMin)
        debugPrint("[AvailabilityV2ResultInternal] durationMin: \(durationMin)")
        let timezone = try values.decodeIfPresent(String.self, forKey: .timezone)
        debugPrint("[AvailabilityV2ResultInternal] timezone: \(timezone ?? "nil")")
        let slots = try values.decodeIfPresent([AvailabilityV2SlotInternal].self, forKey: .slots) ??
            [AvailabilityV2SlotInternal]()
        debugPrint("[AvailabilityV2ResultInternal] slots: \(slots)")
        try self.init(slots: slots, durationMin: durationMin, timezone: timezone)
    }
}

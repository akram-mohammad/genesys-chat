//
//  AvailabilityV2SlotInternal.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-09.
//

import Foundation

/// Callback availability slot (v2)
class AvailabilityV2SlotInternal: CallbackAvailabilityV2Slot, Codable {
    fileprivate init(utcTimeStr: String, localTime: String?, capacity: Int, total: Int) throws {
        guard let utcTime = utcTimeStr.iso8601 else {
            throw GmsApiError.invalidDateFormat(key: "utcTime", value: utcTimeStr)
        }
        if let localTime = localTime, localTime.iso8601 == nil, "\(localTime)Z".iso8601 == nil {
            throw GmsApiError.invalidDateFormat(key: "localTime", value: localTime)
        }
        try super.init(utcTime: utcTime, localTime: localTime, capacity: capacity, total: total)
    }

    // MARK: - AvailabilityV2SlotInternal.Codable

    enum CodingKeys: String, CodingKey {
        case utcTime
        case localTime
        case capacity
        case total
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(utcTime, forKey: .utcTime)
        try container.encode(localTime, forKey: .localTime)
        try container.encode(capacity, forKey: .capacity)
        try container.encode(total, forKey: .total)
    }

    public required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let utcTime = try values.decode(String.self, forKey: .utcTime)
        let capacity = try values.decode(Int.self, forKey: .capacity)
        let total = try values.decode(Int.self, forKey: .total)
        let localTime = try values.decodeIfPresent(String.self, forKey: .localTime)
        try self.init(utcTimeStr: utcTime, localTime: localTime, capacity: capacity, total: total)
    }
}

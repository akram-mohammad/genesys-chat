//
//  ProposedAvailabilityV1.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-09.
//

import Foundation

/// Proposed Callback Availability (v1)
class ProposedAvailabilityV1: CustomStringConvertible, Hashable, Codable {
    var slots = [Date: Int]()

    init?(_ slots: [Date: Int]) {
        self.slots = slots
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: ProposedAvailabilityV1.self) + "@\(hashValue)[slots=\(slots)]"
    }

    // MARK: - Codable

    class CodingKeys: AnyCodingKey {
        required init?(stringValue: String) {
            if stringValue.iso8601 != nil {
                super.init(stringValue: stringValue)
            }
            return nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for key in slots.keys {
            if let codingKey = CodingKeys(stringValue: key.iso8601),
                let value = Int(slots[key]!.description) {
                try container.encode(value, forKey: codingKey)
            }
        }
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: AnyCodingKey.self)
        for key in values.allKeys {
            if let date = key.stringValue.iso8601 {
                if let value = try? values.decode(Int.self, forKey: key) {
                    slots[date] = value
                } else if let str = try? values.decode(String.self, forKey: key), let value = Int(str) {
                    slots[date] = value
                }
            }
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ProposedAvailabilityV1, rhs: ProposedAvailabilityV1) -> Bool {
        if lhs.slots.keys != rhs.slots.keys {
            return false
        }
        for key in lhs.slots.keys where lhs.slots[key]?.description != rhs.slots[key]?.description {
            return false
        }
        return true
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        for key in slots.keys.sorted() {
            hasher.combine(key)
            hasher.combine(slots[key]?.description)
        }
    }
}

//
//  GmsCallbackErrorResponse.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-05.
//

import Foundation

/// Internal implementation of GmsCallbackException to make it Codable.
class GmsCallbackErrorResponse: GmsCallbackException, Codable {
    // MARK: - Codable

    class CodingKeys: AnyCodingKey {
        static let exception = CodingKeys(stringValue: "exception")!
        static let code = CodingKeys(stringValue: "code")!
        static let phrase = CodingKeys(stringValue: "phrase")!
        static let message = CodingKeys(stringValue: "message")!
        static let availability = CodingKeys(stringValue: "availability")!

        static let namedKeys = [
            exception.stringValue: exception,
            code.stringValue: code,
            phrase.stringValue: phrase,
            message.stringValue: message,
            availability.stringValue: availability
        ]

        static func isNamedKey(_ stringValue: String) -> Bool {
            return namedKeys[stringValue] != nil
        }

        static func isNamedKey(_ codingKey: CodingKeys) -> Bool {
            return namedKeys[codingKey.stringValue] != nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(exception, forKey: CodingKeys.exception)
        try container.encode(code, forKey: CodingKeys.code)
        try container.encodeIfPresent(phrase, forKey: CodingKeys.phrase)
        try container.encodeIfPresent(message, forKey: CodingKeys.message)
        if let availability = self.proposedAvailability, let proposed = ProposedAvailabilityV1(availability) {
            try container.encode(proposed, forKey: CodingKeys.availability)
        }
        for key in additionalProperties.keys {
            try container.encode(additionalProperties[key]!.description, forKey: CodingKeys(stringValue: key)!)
        }
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let exception = try values.decodeIfPresent(String.self, forKey: CodingKeys.exception)
        let code = try values.decode(Int.self, forKey: CodingKeys.code)
        let phrase = try values.decodeIfPresent(String.self, forKey: CodingKeys.phrase)
        let message = try values.decodeIfPresent(String.self, forKey: CodingKeys.message)
        let proposedAvailability: [Date: Int]?
        if let availability = try values.decodeIfPresent(ProposedAvailabilityV1.self, forKey: CodingKeys.availability) {
            proposedAvailability = availability.slots
        } else {
            proposedAvailability = nil
        }
        var properties = [String: String]()
        for key in values.allKeys {
            if !CodingKeys.isNamedKey(key) {
                properties[key.stringValue] = try values.decode(String.self, forKey: key)
            }
        }
        super.init(
            exception, code: code, phrase: phrase, message: message,
            availability: proposedAvailability, additionalProperties: properties
        )
    }
}

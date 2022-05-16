//
//  GmsCallbackException.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Foundation

/// Java exception returned by GMS.
public class GmsCallbackException: CustomStringConvertible, Hashable {
    /// Name of the exception thrown.
    public let exception: String?

    /// Error code.
    public let code: Int?

    /// Phrase describing the error.  (Since GMS API 8.5.2.)
    public let phrase: String?

    /// Error message.
    public let message: String?

    /// Proposed availability.  Only returned if trying to schedule a callback
    /// outside of business hours or for a time slot with full capacity.
    public let proposedAvailability: [Date: Int]?

    /// Any additional properties returned by the error message.
    public let additionalProperties: [String: String]

    init(
        _ exception: String?,
        code: Int? = nil,
        phrase: String? = nil,
        message: String? = nil,
        availability: [Date: Int]? = nil,
        additionalProperties: [String: String] = [String: String]()
    ) {
        self.exception = exception
        self.code = code
        self.phrase = phrase
        self.message = message
        proposedAvailability = availability
        self.additionalProperties = additionalProperties
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var content = "exception=\(exception ?? "nil")," +
            "code=\(code?.description ?? "nil")," +
            "phrase=\(phrase ?? "nil")," +
            "message=\(message ?? "nil")"
        for key in additionalProperties.keys {
            content += ",\(key)=\(additionalProperties[key]!)"
        }
        return String(describing: GmsCallbackException.self) + "@\(hashValue)[\(content)]"
    }

    // MARK: - Equatable

    public static func == (lhs: GmsCallbackException, rhs: GmsCallbackException) -> Bool {
        if lhs.exception != rhs.exception ||
            lhs.code != rhs.code ||
            lhs.phrase != rhs.phrase ||
            lhs.message != rhs.message ||
            lhs.additionalProperties != rhs.additionalProperties {
            return false
        }
        if lhs.proposedAvailability == nil, rhs.proposedAvailability == nil {
            return true
        }

        guard let lslots = lhs.proposedAvailability, let rslots = rhs.proposedAvailability else {
            return false
        }

        if lslots.keys.sorted() != rslots.keys.sorted() {
            return false
        }

        for key in lslots.keys where lslots[key]?.description != rslots[key]?.description {
            return false
        }
        return true
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(exception)
        hasher.combine(code)
        hasher.combine(phrase)
        hasher.combine(message)
        hasher.combine(additionalProperties)
        var proposed: ProposedAvailabilityV1?
        if let availability = proposedAvailability {
            proposed = ProposedAvailabilityV1(availability)
        }
        hasher.combine(proposed)
    }
}

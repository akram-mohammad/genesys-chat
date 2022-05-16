//
//  ChatV2Message.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

/// Chat message (v2).
public class ChatV2Message: CustomStringConvertible, Hashable, Codable {
    /// Sender of the message.
    public let from: ChatV2Participant

    /// Index of the chat message in the session.  Starts with 1.
    public let index: Int?

    /// Type of message.
    public let type: ChatV2MessageType

    /// Timestamp of the message.
    public let utcTime: Date

    /// Custom message type (optional).
    public let messageType: String?

    /// Message text.
    public let text: String?

    /// User data.
    public let userData: [String: String]

    /**
     Creates a new chat message object.
     
     - parameters:
       - from: The sender of this message.
       - index: Index, or transcript position, of this message in the chat session.
       - type: Type of message.
       - utcTime: Timestamp of the message.
       - messageType: Any arbitrary type the sender set. Sees ChatV2 documentation.
       - text: Text of the message.
       - userData: Any additional user data attached to the message.
     */
    init(
        _ from: ChatV2Participant,
        index: Int?,
        type: ChatV2MessageType,
        utcTime: Date,
        messageType: String?,
        text: String?,
        userData: [String: String]
    ) {
        self.from = from
        self.index = index
        self.type = type
        self.utcTime = utcTime
        self.messageType = messageType
        self.text = text
        self.userData = userData
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: ChatV2Message.self) + "@\(hashValue)[" +
            "from=\(from),index=\(index?.description ?? "nil"),type=\(type),utcTime=\(utcTime.iso8601)," +
            "messageType=\(messageType ?? "nil"),text=\(text ?? "nil")" +
            "userData=\(userData)]"
    }

    // MARK: - Equatable

    public static func == (lhs: ChatV2Message, rhs: ChatV2Message) -> Bool {
        return lhs.from == rhs.from && lhs.index == rhs.index && lhs.type == rhs.type &&
            lhs.utcTime == rhs.utcTime && lhs.messageType == rhs.messageType &&
            lhs.text == rhs.text && lhs.userData == rhs.userData
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(index)
        hasher.combine(type)
        hasher.combine(utcTime)
        hasher.combine(messageType)
        hasher.combine(text)
        hasher.combine(userData)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case from
        case index
        case type
        case utcTime
        case messageType
        case text
        case userData
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(from, forKey: .from)
        try container.encode(index, forKey: .index)
        try container.encode(type, forKey: .type)
        try container.encode(Int64(utcTime.timeIntervalSince1970 * 1000), forKey: .utcTime)
        try container.encodeIfPresent(messageType, forKey: .messageType)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encode(userData, forKey: .userData)
    }

    public required init(from decoder: Decoder) throws {
        debugPrint("[ChatV2Message] init decode")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        from = try values.decode(ChatV2Participant.self, forKey: .from)
        debugPrint("[ChatV2Message] from: \(from)")
        index = try values.decodeIfPresent(Int.self, forKey: .index)
        type = try values.decode(ChatV2MessageType.self, forKey: .type)
        let utcTimeMs = try values.decode(Int64.self, forKey: .utcTime)
        utcTime = Date(timeIntervalSince1970: Double(utcTimeMs) / 1000)
        messageType = try values.decodeIfPresent(String.self, forKey: .messageType)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        let userData = try values.decodeIfPresent([String: String].self, forKey: .userData)
        if let userData = userData {
            self.userData = userData
        } else {
            self.userData = [String: String]()
        }
    }
}

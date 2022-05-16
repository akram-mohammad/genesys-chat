//
//  ChatV2Response.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

/// Server response for the chat session (V2)
public class ChatV2Response: CustomStringConvertible, Hashable, Codable {

    /// Chat session ID.
    public let chatId: String

    /// Status code of the chat request.  0 means success.
    public let statusCode: Int

    /// Chat messages returned.  Which messages are returned depends on
    /// the value of `transcriptPosition` of the request.
    public let messages: [ChatV2Message]

    /// Whether the chat session has ended.
    public let chatEnded: Bool?

    /// Host alias of the user.
    public let alias: String?

    /// Expected position of the next chat message after `messages`.
    /// To receive new messages only in the next request, use this
    /// value in `transcriptPosition`.
    public let nextPosition: Int?

    /// User ID.
    public let userId: String?

    /// Secure key of the current chat session.
    public let secureKey: String?

    /// Any additional user data attached to the chat session.
    /// File upload limits are returned in userData.
    public let userData: [String: String]

    init(
        _ chatId: String,
        statusCode: Int,
        alias: String?,
        chatEnded: Bool?,
        userId: String?,
        secureKey: String?,
        nextPosition: Int?,
        messages: [ChatV2Message],
        userData: [String: String]
    ) {
        self.chatId = chatId
        self.statusCode = statusCode
        self.alias = alias
        self.userId = userId
        self.secureKey = secureKey
        self.nextPosition = nextPosition
        self.chatEnded = chatEnded
        self.messages = messages
        self.userData = userData
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: ChatV2Response.self) + "@\(hashValue)[" +
            "chatId=\(chatId),statusCode=\(statusCode),alias=\(alias ?? "nil")," +
            "userId=\(userId ?? "nil"),secureKey=\(secureKey ?? "nil")," +
            "chatEnded=\(chatEnded?.description ?? "nil")," +
            "nextPosition=\(nextPosition?.description ?? "nil")," +
            "userData=\(userData),messages=\(messages)]"
    }

    // MARK: - Equatable

    public static func == (lhs: ChatV2Response, rhs: ChatV2Response) -> Bool {
        return lhs.chatId == rhs.chatId &&
            lhs.statusCode == rhs.statusCode &&
            lhs.alias == rhs.alias &&
            lhs.userId == rhs.userId &&
            lhs.secureKey == rhs.secureKey &&
            lhs.nextPosition == rhs.nextPosition &&
            lhs.chatEnded == rhs.chatEnded &&
            lhs.messages == rhs.messages &&
            lhs.userData == rhs.userData
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(chatId)
        hasher.combine(statusCode)
        hasher.combine(alias)
        hasher.combine(userId)
        hasher.combine(secureKey)
        hasher.combine(nextPosition)
        hasher.combine(chatEnded)
        hasher.combine(messages)
        hasher.combine(userData)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case chatId
        case statusCode
        case alias
        case chatEnded
        case userId
        case secureKey
        case nextPosition
        case messages
        case userData
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(alias, forKey: .alias)
        try container.encodeIfPresent(secureKey, forKey: .secureKey)
        try container.encodeIfPresent(chatEnded, forKey: .chatEnded)
        try container.encodeIfPresent(nextPosition, forKey: .nextPosition)
        if !messages.isEmpty {
            try container.encode(messages, forKey: .messages)
        }
        if !userData.isEmpty {
            try container.encode(userData, forKey: .userData)
        }
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        chatId = try values.decode(String.self, forKey: .chatId)
        statusCode = try values.decode(Int.self, forKey: .statusCode)
        alias = try values.decodeIfPresent(String.self, forKey: .alias)
        chatEnded = try values.decodeIfPresent(Bool.self, forKey: .chatEnded)
        userId = try values.decodeIfPresent(String.self, forKey: .userId)
        secureKey = try values.decodeIfPresent(String.self, forKey: .secureKey)
        nextPosition = try values.decodeIfPresent(Int.self, forKey: .nextPosition)
        if let messages = try values.decodeIfPresent([ChatV2Message].self, forKey: .messages) {
            self.messages = messages
        } else {
            messages = [ChatV2Message]()
        }
        if let userData = try values.decodeIfPresent([String: String].self, forKey: .userData) {
            self.userData = userData
        } else {
            userData = [String: String]()
        }
    }
}

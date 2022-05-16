//
//  ChatV2Participant.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

/// Participant who sent the chat message.
public class ChatV2Participant: CustomStringConvertible, Hashable, Codable {
    /// Nickname of the participant
    public let nickname: String

    /// ID of the participant
    public let participantId: Int

    /// Type of the participant
    public let type: String

    init(nickname: String, participantId: Int, type: String) {
        self.nickname = nickname
        self.participantId = participantId
        self.type = type
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        return String(describing: ChatV2Participant.self) + "@\(hashValue)[" +
            "nickname=\(nickname),participantId=\(participantId),type=\(type)]"
    }

    // MARK: - Equatable

    public static func == (lhs: ChatV2Participant, rhs: ChatV2Participant) -> Bool {
        return lhs.nickname == rhs.nickname && lhs.participantId == rhs.participantId &&
            lhs.type == rhs.type
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(nickname)
        hasher.combine(participantId)
        hasher.combine(type)
    }
}

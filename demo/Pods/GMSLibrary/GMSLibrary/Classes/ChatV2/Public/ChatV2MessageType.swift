//
//  ChatV2MessageType.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

/// Type of chat message.
public enum ChatV2MessageType: String, Hashable, Codable {
    /// Participant joined the chat session.
    case participantJoined = "ParticipantJoined"

    /// Participant left the chat session.
    case participantLeft = "ParticipantLeft"

    /// Text chat message.
    case message = "Message"

    /// URL sent to or received from chat message.
    case pushUrl = "PushUrl"

    /// Typing started.
    case typingStarted = "TypingStarted"

    /// Typing stopped.
    case typingStopped = "TypingStopped"

    /// Nickname updated.
    case nicknameUpdated = "NicknameUpdated"

    /// File was successfully uploaded.
    case fileUploaded = "FileUploaded"

    /// File was sucessfully deleted.  This is not sent as FCM notification.
    case fileDeleted = "FileDeleted"

    /// A custom notice.  This is not sent as FCM notification.
    case customNotice = "CustomNotice"

    /// A standard notice.  This is not sent as FCM notification.
    case notice = "Notice"

    /// The user has been idle in chat session for a specific period of time;
    /// the chat session will close soon if the user make no further action.
    /// This is only used for FCM notification.
    case idleAlert = "IdleAlert"

    /// The chat session has closed due to user inactivity.  This is only used
    /// for FCM notification.
    case idleClose = "IdleClose"
}

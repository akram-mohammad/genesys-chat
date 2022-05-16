//
// CallbackType.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//

import Foundation

/// Callback type.
///
/// This enum is made `Codable` for preference persistence.
enum CallbackType: String, Codable {
    case VOICE_NOW_USERORIG = "VOICE-NOW-USERORIG"
    case VOICE_WAIT_USERORIG = "VOICE-WAIT-USERORIG"
    case VOICE_NOW_USERTERM = "VOICE-NOW-USERTERM"
    case VOICE_WAIT_USERTERM = "VOICE-WAIT-USERTERM"
    case VOICE_SCHEDULED_USERTERM = "VOICE-SCHEDULED-USERTERM"
    case CHAT_NOW = "CHAT-NOW"
    case CHAT_WAIT = "CHAT-WAIT"
    case CUSTOM = "CUSTOM"
    
    var isScheduled : Bool? {
        if self == .CUSTOM {
            return nil
        }
        return self.rawValue.contains("SCHEDULED")
    }
    
    var callDirection: CallDirection? {
        if self == .CUSTOM {
            return nil
        } else if self.rawValue.contains("USERORIG") {
            return .userOriginated
        } else {
            return .userTerminated
        }
    }
    
    var media: String? {
        if self == .CUSTOM {
            return nil
        } else if self.rawValue.contains("VOICE") {
            return "voice"
        } else {
            return "chat"
        }
    }
    
    var waitForAgent: Bool? {
        if self == .CUSTOM {
            return nil
        } else if self.rawValue.contains("NOW") {
            return false
        } else {
            return true
        }
    }
    
    var waitForUserConfirm: Bool? {
        if self == .CUSTOM {
            return nil
        } else if self.rawValue.contains("NOW") {
            return false
        } else {
            return true
        }
    }
    
    static let allTypes: [CallbackType] = [
        .VOICE_NOW_USERORIG,
        .VOICE_WAIT_USERORIG,
        .VOICE_NOW_USERTERM,
        .VOICE_WAIT_USERTERM,
        .VOICE_SCHEDULED_USERTERM,
        .CHAT_NOW,
        .CHAT_WAIT,
        // Custom type is not yet supported in UI.
        // .CUSTOM
    ]
}

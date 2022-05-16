//
// ServicePreference.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//

import Foundation
import GMSLibrary

/// Service-level preferences.
///
/// Made `Codable` for preference persistence.
class ServicePreferences: Codable {
    enum CodingKeys: String, CodingKey {
        case callbackService = "GMSCallbackService"
        case chatService = "GMSChatService"
        case userSettings = "GMSUserSettings"
    }
    
    var callbackService: CallbackServiceSettings
    var chatService: ChatServiceSettings
    var userSettings: GmsUserSettings
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callbackService, forKey: .callbackService)
        try container.encode(chatService, forKey: .chatService)
        try container.encode(userSettings, forKey: .userSettings)
    }
    
    init(callbackService: CallbackServiceSettings, chatService: ChatServiceSettings, userSettings: GmsUserSettings) {
        self.callbackService = callbackService
        self.chatService = chatService
        self.userSettings = userSettings
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        callbackService = try values.decode(CallbackServiceSettings.self, forKey: .callbackService)
        chatService = try values.decode(ChatServiceSettings.self, forKey: .chatService)
        userSettings = try values.decode(GmsUserSettings.self, forKey: .userSettings)
    }
}

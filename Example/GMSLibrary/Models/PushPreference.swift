//
// PushPreference.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary

class PushPreference: Codable {
    enum CodingKeys: String, CodingKey {
        case type = "GMSPushNotificationType"
        case debug = "GMSPushNotificationDebug"
        case language = "GMSPushNotificationLanguage"
        case provider = "GMSPushNotificationProvider"
    }
    
    enum PushType: String, Codable {
        case none
        case fcm
    }
    
    let type: PushType
    let debug: Bool?
    let language: String?
    let provider: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(debug, forKey: .debug)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(provider, forKey: .provider)
    }
    
    init(settings: GmsPushNotificationSettings) {
        switch settings {
        case .none:
            self.type = .none
            self.debug = nil
            self.language = nil
            self.provider = nil
        case let .fcm(_, debug, language, provider):
            self.type = .fcm
            self.debug = debug
            self.language = language
            self.provider = provider
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(PushType.self, forKey: .type)
        debug = try values.decodeIfPresent(Bool.self, forKey: .debug)
        language = try values.decodeIfPresent(String.self, forKey: .language)
        provider = try values.decodeIfPresent(String.self, forKey: .provider)
    }
    
    var settings: GmsPushNotificationSettings {
        switch type {
        case .none:
            return .none
        case .fcm:
            return .fcm(AppDelegate.shared.fcmToken, debug: debug, language: language, provider: provider)
        }
    }
}

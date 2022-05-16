//
// Preferences.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary

class Preferences: Codable {
    enum CodingKeys: String, CodingKey {
        case hostname = "GMSHost"
        case port = "GMSPort"
        case app = "GMSApp"
        case secureProtocol = "GMSUseSecureProtocol"
        case gmsUser = "GMSUser"
        case apiKey = "GMSApiKey"
        case pushSettings = "GMSPushNotificationSettings"
        case authSettings = "GMSAuthenticationSettings"
        case serviceSettings = "GMSServiceSettings"
        case additionalHeaders = "GMSAdditionalHTTPHeaders"
    }
    
    let hostname: String
    let port: Int?
    let app: String
    let secureProtocol: Bool
    let gmsUser: String?
    let apiKey: String?
    let pushSettings: PushPreference
    let authSettings: AuthPreference
    let serviceSettings: ServicePreferences
    let additionalHeaders: [HTTPHeaderPreference]
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hostname, forKey: .hostname)
        try container.encodeIfPresent(port, forKey: .port)
        try container.encode(app, forKey: .app)
        try container.encode(secureProtocol, forKey: .secureProtocol)
        try container.encodeIfPresent(gmsUser, forKey: .gmsUser)
        try container.encodeIfPresent(apiKey, forKey: .apiKey)
        try container.encode(pushSettings, forKey: .pushSettings)
        try container.encode(authSettings, forKey: .authSettings)
        try container.encode(serviceSettings, forKey: .serviceSettings)
        try container.encode(additionalHeaders,  forKey: .additionalHeaders)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hostname = try values.decode(String.self, forKey: .hostname)
        port = try values.decodeIfPresent(Int.self, forKey: .port)
        app = try values.decode(String.self, forKey: .app)
        secureProtocol = try values.decode(Bool.self, forKey: .secureProtocol)
        gmsUser = try values.decodeIfPresent(String.self, forKey: .gmsUser)
        apiKey = try values.decodeIfPresent(String.self, forKey: .apiKey)
        pushSettings = try values.decode(PushPreference.self, forKey: .pushSettings)
        authSettings = try values.decode(AuthPreference.self, forKey: .authSettings)
        serviceSettings = try values.decode(ServicePreferences.self, forKey: .serviceSettings)
        if let headers = try values.decodeIfPresent([HTTPHeaderPreference].self, forKey: .additionalHeaders) {
            additionalHeaders = headers
        } else {
            additionalHeaders = [HTTPHeaderPreference]()
        }
    }
    
    init(serverSettings: GmsServerSettings, callbackService: CallbackServiceSettings, chatService: ChatServiceSettings, userSettings: GmsUserSettings) {
        hostname = serverSettings.hostname
        port = serverSettings.port
        app = serverSettings.app
        secureProtocol = serverSettings.secureProtocol
        gmsUser = serverSettings.gmsUser
        apiKey = serverSettings.apiKey
        pushSettings = PushPreference(settings: serverSettings.pushSettings)
        authSettings = AuthPreference(settings: serverSettings.authSettings)
        serviceSettings = ServicePreferences(callbackService: callbackService, chatService: chatService, userSettings: userSettings)
        var headers = [HTTPHeaderPreference]()
        for (field, value) in serverSettings.additionalHeaders {
            headers.append(HTTPHeaderPreference(field: field, value: value))
        }
        additionalHeaders = headers
    }
    
    func getServerSettings() throws -> GmsServerSettings {
        var headers = [(field: String, value: String)]()
        for header in additionalHeaders {
            headers.append((field: header.field, value: header.value))
        }
        return try GmsServerSettings(hostname: hostname,
                                     port: port,
                                     app: app,
                                     secureProtocol: secureProtocol,
                                     gmsUser: gmsUser,
                                     apiKey: apiKey,
                                     authSettings: authSettings.settings,
                                     pushSettings: pushSettings.settings,
                                     additionalHeaders: headers)
    }
    
    func getUserSettings() -> GmsUserSettings {
        return serviceSettings.userSettings
    }
    
    func getChatServiceSettings() -> ChatServiceSettings {
        return serviceSettings.chatService
    }
    
    func getCallbackServiceSettings() -> CallbackServiceSettings {
        return serviceSettings.callbackService
    }
}


//
// AuthPreference.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-17
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary

class AuthPreference: Codable {
    enum CodingKeys: String, CodingKey {
        case type = "GMSAuthType"
        case user = "GMSAuthUser"
        case password = "GMSAuthPassword"
    }
    
    enum AuthType: String, Codable {
        case none
        case basic
    }
    var type: AuthType
    var user: String?
    var password: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(password, forKey: .password)
    }
    
    init(settings: GmsAuthSettings) {
        switch settings {
        case .none:
            self.type = .none
        case let .basic(user, password):
            self.type = .basic
            self.user = user
            self.password = password
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decode(AuthType.self, forKey: .type)
        user = try values.decodeIfPresent(String.self, forKey: .user)
        password = try values.decodeIfPresent(String.self, forKey: .password)
    }
    
    var settings: GmsAuthSettings {
        switch type {
        case .none:
            return .none
        case.basic:
            if let user = user, let password = password {
                return GmsAuthSettings.basic(user: user, password: password)
            }
            return .none
        }
    }
}

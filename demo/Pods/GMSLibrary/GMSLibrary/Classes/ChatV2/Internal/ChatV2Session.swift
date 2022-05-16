//
//  ChatV2Session.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-12.
//

import Foundation

struct ChatV2Session {
    let service: GmsServiceSettings
    let server: GmsServerSettings
    let chatId: String
    let identity: ChatV2Identity
    let chatEnded: Bool?

    init (_ service: GmsServiceSettings, _ server: GmsServerSettings, chatId: String, identity: ChatV2Identity) {
        self.service = service
        self.server = server
        self.chatId = chatId
        self.identity = identity
        self.chatEnded = false
    }

    init(_ service: GmsServiceSettings, _ server: GmsServerSettings, from response: ChatV2Response) {
        self.service = service
        self.server = server
        self.chatId = response.chatId
        self.chatEnded = response.chatEnded
        self.identity = ChatV2Identity(from: response)
    }
}

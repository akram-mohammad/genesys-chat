//
//  ChatV2Identity.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Foundation

struct ChatV2Identity: CustomStringConvertible, Hashable {
    public let userId: String?
    public let secureKey: String?
    public let alias: String?

    init(from response: ChatV2Response) {
        self.userId = response.userId
        self.secureKey = response.secureKey
        self.alias = response.alias
    }

    init(secureKey: String, userId: String?, alias: String?) {
        self.userId = userId
        self.secureKey = secureKey
        self.alias = alias
    }

    public var description: String {
        return String(describing: ChatV2Identity.self) + "@\(hashValue)[" +
            "userId=\(userId ?? "nil"),secureKey=\(secureKey ?? "nil"),alias=\(alias ?? "nil")]"
    }
}

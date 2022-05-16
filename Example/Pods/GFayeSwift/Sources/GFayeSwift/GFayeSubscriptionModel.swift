//
//  GFayeSubscriptionModel.swift
//  Pods
//
//  Created by Shams Ahmed on 25/04/2016.
//
//  Updated by Cindy Wong on 2019-06-25.
//  Copyright (c) 2019 Cindy Wong.
//

import Foundation
import SwiftyJSON

public enum GFayeSubscriptionModelError: Error {
    case conversationError
    case clientIdNotValid
}

// MARK: 
// MARK: GFayeSubscriptionModel

///  Subscription Model
open class GFayeSubscriptionModel {

    /// Subscription URL
    public let subscription: String

    /// Channel type for request
    public let channel: BayeuxChannel

    /// Uniqle client id for socket
    open var clientId: String?

    /// ext
    open var ext: [String:String] = [String:String]()
    
    /// Model must conform to Hashable
    open var hashValue: Int {
        return subscription.hashValue
    }

    // MARK: 
    // MARK: Init

    public init(subscription: String, channel: BayeuxChannel=BayeuxChannel.subscribe, clientId: String?, ext: [String:String] = [String:String]()) {
        self.subscription = subscription
        self.channel = channel
        self.clientId = clientId
        self.ext = ext
    }

    // MARK: 
    // MARK: JSON

    ///  Return Json string from model
    open func jsonString() throws -> String {
        do {
            guard let model = try JSON(toDictionary()).rawString() else {
                throw GFayeSubscriptionModelError.conversationError
            }

            return model
        } catch {
            throw GFayeSubscriptionModelError.clientIdNotValid
        }
    }

    // MARK: 
    // MARK: Helper

    ///  Create dictionary of model object, Subclasses should override method to return custom model
    open func toDictionary() throws -> [String: Any] {
        guard let clientId = clientId else {
            throw GFayeSubscriptionModelError.clientIdNotValid
        }

        var dict: [String: Any] = [Bayeux.channel.rawValue: channel.rawValue,
                Bayeux.clientId.rawValue: clientId,
                Bayeux.subscription.rawValue: subscription]
        if !ext.isEmpty {
            dict[Bayeux.ext.rawValue] = ext
        }
        return dict
    }
}

// MARK: 
// MARK: Description

extension GFayeSubscriptionModel: CustomStringConvertible {

    public var description: String {
        return "GFayeSubscriptionModel: \((try? self.toDictionary())?.description ?? "nil" )"
    }
}

// MARK: 
// MARK: Equatable

public func == (lhs: GFayeSubscriptionModel, rhs: GFayeSubscriptionModel) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

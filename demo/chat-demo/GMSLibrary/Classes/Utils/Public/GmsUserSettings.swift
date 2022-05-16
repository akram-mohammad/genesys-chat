//
//  GmsUserSettings.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-12.
//

import Foundation


/**
 Basic end-user profile.
 */
public struct GmsUserSettings: Codable {
    /// User phone number. Used by Callback.
    public var phoneNumber: String?
    
    /// First name of the user. Used by Chat V2.
    public var firstName: String?
    
    /// Last name of the user. Used by Chat V2.
    public var lastName: String?
    
    /// Nickname of the user. Used by Chat V2.
    public var nickname: String?
    
    /// Email address of the user. Used by Chat V2.
    public var email: String?

    public init() {}
}

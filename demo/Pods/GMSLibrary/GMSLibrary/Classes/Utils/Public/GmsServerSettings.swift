//
//  GmsServerSettings.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-12.
//

import Foundation

/**
 Server-level settings meant to be internal to the application.
 
 This is an immutable object. If the settings change, any existing clients will
 continue to use the old values they are configured with.
 */
public class GmsServerSettings {

    /// Host name of GMS server.
    public let hostname: String
    
    /// Port number of GMS server. Defaults to 80 for HTTP, 443 for HTTPS.
    public let port: Int?
    
    /// GMS app name.
    public let app: String
    
    /// Whether to connect using HTTPS (true) or HTTP (false)
    public let secureProtocol: Bool

    /// Optional value for HTTP header field `gms_user`. The header is not sent if this value is `nil`.
    public let gmsUser: String?

    /// Optional value for HTTP header fields `apiKey` and `x-api-key`. The header is not sent if this value is `nil`.
    public let apiKey: String?

    /// Any additional HTTP headers to send for all requests.
    public let additionalHeaders: [(field: String, value: String)]

    /// Push notification settings.
    public let pushSettings: GmsPushNotificationSettings
    
    /// Authentication settings.
    public let authSettings: GmsAuthSettings

    /**
     Create an immutable object describing the server-level settings.
     
     - Parameters:
       - hostname: Host name of GMS server.
       - port: Port number of the GMS server. Defaults to 443 for HTTPS, 80 for HTTP.
       - app: GMS app name. Defaults to `genesys`.
       - secureProtocol: Whether to use HTTPS (true) or HTTP (false).
       - gmsUser: Value to use for the optional HTTP header field `gms_user`.
       - apiKey: Value to use for the optional HTTP header fields `apiKey` and `x-api-key`.
       - authSettings: Authentication settings.
       - pushSettings: Push notification settings.
       - additionalHeaders: Additional HTTP headers to send.
     */
    public init(hostname: String,
                port: Int? = nil,
                app: String = "genesys",
                secureProtocol: Bool = true,
                gmsUser: String? = nil,
                apiKey: String? = nil,
                authSettings: GmsAuthSettings = .none,
                pushSettings: GmsPushNotificationSettings = .none,
                additionalHeaders: [(field: String, value: String)] = []
                ) throws {
        if hostname.isEmpty {
            throw GmsApiError.missingGmsSettingsValue(key: "hostname")
        }
        self.hostname = hostname
        if let port = port, (port <= 0 || port > 65536) {
                throw GmsApiError.invalidParameter(key: "port", value: port.description)
        }
        self.port = port
        if app.isEmpty {
            throw GmsApiError.missingGmsSettingsValue(key: "app")
        }
        self.gmsUser = gmsUser
        self.app = app
        self.secureProtocol = secureProtocol
        self.apiKey = apiKey
        self.pushSettings = pushSettings
        self.authSettings = authSettings
        self.additionalHeaders = additionalHeaders
    }

    /**
     Creates a copy of this `GmsServerSettings` object with an updated FCM token.
     
     If FCM is not currently configured for this object, returns `self`.
     
     - parameters:
       - token: New FCM token.
     - returns:
       - If FCM is enabled, returns a copy of this `GmsServerSettings` object with this
         updated FCM token. Otherwise, returns `self`.
     */
    public func updateFcmToken(_ token: String) throws -> GmsServerSettings {
        switch self.pushSettings {
        case .none:
            return self
        case let .fcm(_, debug, language, provider):
            let pushSettings = GmsPushNotificationSettings.fcm(token,
                                                               debug: debug,
                                                               language: language,
                                                               provider: provider)
            return try GmsServerSettings(hostname: self.hostname,
                                     port: self.port,
                                     app: self.app,
                                     secureProtocol: self.secureProtocol,
                                     gmsUser: self.gmsUser,
                                     apiKey: self.apiKey,
                                     authSettings: self.authSettings,
                                     pushSettings: pushSettings,
                                     additionalHeaders: additionalHeaders)
        }
    }
    
    // MARK: private
    
    /// Returns the base URL of GMS instance provided
    var baseUrl: String? {
        let proto = (secureProtocol) ? "https" : "http"
        let portPart: String
        if let port = port {
            portPart = ":\(port)"
        } else {
            portPart = ""
        }
        let appPart = app.replacingOccurrences(of: #"(^/+|/+$)"#, with: "", options: .regularExpression)
        let baseUrl = "\(proto)://\(hostname)\(portPart)/\(appPart)"
        debugPrint("[GmsSettings] baseUrl = \(baseUrl)")
        return baseUrl
    }


}

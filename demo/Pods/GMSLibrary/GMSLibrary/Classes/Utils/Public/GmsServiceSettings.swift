//
//  GmsSettings.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-02.
//

import Foundation

public typealias ParameterValue = Codable & CustomStringConvertible

/**
 Service-level settings meant to be internal to the application.

 This is an immutable object. If the settings change, any existing clients will
 continue to use the old values they are configured with.
 */
open class GmsServiceSettings {
    /// Name of the service as defined in GMS.
    public let serviceName: String

    /// Additional parameters for the service.
    open var additionalParameters: [String: ParameterValue] {
        return properties
    }

    let properties: [String: ParameterValue]

    /**
     Create an immutable object describing the service-level settings.
     
     - Parameters:
       - serviceName: Name of the service to use.
       - additionalParameters: Additional parameters for the service.
     */
    public init(
        _ serviceName: String,
        additionalParameters: [String: ParameterValue] = [String: ParameterValue]()) throws {
        if serviceName.isEmpty {
            throw GmsApiError.missingGmsSettingsValue(key: "serviceName")
        }
        self.serviceName = serviceName
        self.properties = additionalParameters
    }
}

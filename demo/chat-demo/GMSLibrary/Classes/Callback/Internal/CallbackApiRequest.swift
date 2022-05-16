//
//  CallbackApiRequest.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-06.
//

import Alamofire
import Foundation
import SwiftyJSON

extension String {
    var urlSafe: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
}

public struct EmptyData {}

enum CallbackApiRequest {
    /// Starts a new callback
    case startCallback(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        phoneNumber: String,
        desiredTime: Date?,
        properties: [String: Any])

    /// Cancels an existing callback
    case cancelCallback(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        _ serviceId: String,
        discardOrsFailure: Bool?)

    /// Reshedules an existing callback
    case rescheduleCallback(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        _ serviceId: String,
        newDesiredTime: Date?,
        properties: [String: String]
    )

    /// Query scheduled time slot availability (V1)
    case queryAvailabilityV1(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        start: Date?,
        numberOfDays: Int?,
        end: Date?,
        maxTimeSlots: Int?
    )

    /// Query scheduled time slot availability (V2)
    case queryAvailabilityV2(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        start: Date?,
        startMs: Int64?,
        numberOfDays: Int?,
        end: Date?,
        endMs: Int64?,
        maxTimeSlots: Int?,
        timezone: String?,
        reportBusy: Bool?
    )

    /// Query callback(s) on a single service by the provided properties
    case queryCallback(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        operand: CallbackQueryOperand?,
        properties: [String: String]
    )

    /// Query callback by ID
    case queryCallbackById(
        _ settings: GmsServiceSettings,
        _ serverSettings: GmsServerSettings,
        _ serviceId: String)
}

extension CallbackApiRequest: ApiRequest {
    /// HTTP method for the request
    var method: HTTPMethod {
        switch self {
        case .startCallback:
            return .post
        case .cancelCallback:
            return .delete
        case .rescheduleCallback:
            return .put
        default:
            return .get
        }
    }

    private func getEncoded(_ str: String, _ name: String) throws -> String {
        guard !str.isEmpty, let encoded = str.urlSafe else {
            let error = GmsApiError.invalidParameter(key: name, value: str)
            debugPrint("[CallbackApiRequest] getEncoded(): \(error)")
            throw error
        }
        return encoded
    }

    /// URL path of the request
    func getPath() throws -> String {
        let serviceName = serviceSettings.serviceName
        switch self {
        case .startCallback:
            let name = try getEncoded(serviceName, "serviceName")
            return "/1/service/callback/\(name)"
        case .cancelCallback(_, _, let serviceId, _):
            let name = try getEncoded(serviceName, "serviceName")
            let svcId = try getEncoded(serviceId, "serviceId")
            return "/1/service/callback/\(name)/\(svcId)"
        case .rescheduleCallback(_, _, let serviceId, _, _):
            let name = try getEncoded(serviceName, "serviceName")
            let svcId = try getEncoded(serviceId, "serviceId")
            return "/1/service/callback/\(name)/\(svcId)"
        case .queryAvailabilityV1:
            let name = try getEncoded(serviceName, "serviceName")
            return "/1/service/callback/\(name)/availability"
        case .queryAvailabilityV2:
            let name = try getEncoded(serviceName, "serviceName")
            return "/2/service/callback/\(name)/availability"
        case .queryCallback:
            let name = try getEncoded(serviceName, "serviceName")
            return "/1/service/callback/\(name)"
        case .queryCallbackById:
            return "/1/service/callback"
        }
    }

    /// Query string parameters for the current request
    var parameters: Parameters {
        var parameters = Parameters()
        switch self {
        case let .cancelCallback(_, _, _, discardOrsFailure):
            if let discard = discardOrsFailure {
                parameters["discard_ors_failure"] = discard
            }
        case let .queryAvailabilityV1(_, _, start, numberOfDays, end, maxTimeSlots):
            if let start = start {
                parameters["start"] = start.iso8601
            }
            if let numberOfDays = numberOfDays {
                parameters["number-of-days"] = numberOfDays
            }
            if let end = end {
                parameters["end"] = end.iso8601
            }
            if let maxTimeSlots = maxTimeSlots {
                parameters["max-time-slots"] = maxTimeSlots
            }
        case let .queryAvailabilityV2(
            _, _, start,
            startMs,
            numberOfDays,
            end,
            endMs,
            maxTimeSlots,
            timezone,
            reportBusy
        ):
            if let start = start {
                parameters["start"] = start.iso8601
            }
            if let startMs = startMs {
                parameters["start-ms"] = startMs
            }
            if let numberOfDays = numberOfDays {
                parameters["number-of-days"] = numberOfDays
            }
            if let end = end {
                parameters["end"] = end.iso8601
            }
            if let endMs = endMs {
                parameters["end-ms"] = endMs
            }
            if let maxTimeSlots = maxTimeSlots {
                parameters["max-time-slots"] = maxTimeSlots
            }
            if let timezone = timezone {
                parameters["timezone"] = timezone
            }
            if let reportBusy = reportBusy {
                parameters["report-busy"] = reportBusy
            }
        case let .queryCallback(_, _, operand, properties):
            if let operand = operand {
                parameters["operand"] = operand.rawValue
            }
            for key in properties.keys {
                parameters[key] = properties[key]
            }
        case let .queryCallbackById(_, _, serviceId):
            parameters["_id"] = serviceId
        default:
            return [:]
        }
        return parameters
    }

    /// Content type of the request body, if needed
    var contentType: ContentType? {
        switch self {
        case .startCallback:
            return .json
        case .rescheduleCallback:
            return .json
        default:
            return nil
        }
    }

    /// Accepted content type(s) for the response body of the current request
    var acceptedContentTypes: [ContentType]? {
        switch self {
        case .startCallback:
            return [.json]
        case .rescheduleCallback:
            return [.json]
        case .queryAvailabilityV1:
            return [.json]
        case .queryAvailabilityV2:
            return [.json]
        case .queryCallback:
            return [.json]
        case .queryCallbackById:
            return [.json]
        default:
            return nil
        }
    }

    /// HTTP request body
    func getContentBody() throws -> Data? {
        var data: Data?
        switch self {
        case let .startCallback(
            service, _,
            phoneNumber,
            desiredTime,
            properties
        ):
            if phoneNumber.isEmpty {
                throw GmsApiError.invalidParameter(key: "phoneNumber", value: phoneNumber)
            }
            var dict: [String: Any] = ["_customer_number": phoneNumber]
            if let desiredTime = desiredTime {
                dict["_desired_time"] = desiredTime.iso8601
            }
            dict.merge(properties) { current, _ in current }
            dict.merge(service.additionalParameters) { current, _ in current }
            data = try JSON(dict).rawData()
        case let .rescheduleCallback(_, _, _, newDesiredTime, properties):
            var dict = [String: Any]()
            if let newDesiredTime = newDesiredTime {
                dict["_new_desired_time"] = newDesiredTime.iso8601
            }
            dict.merge(properties) { current, _ in current }
            data = try JSON(dict).rawData()
        default:
            data = nil
        }
        return data
    }

    /// GMS service settings
    var serviceSettings: GmsServiceSettings {
        switch self {
        case .startCallback(let settings, _, _, _, _):
            return settings
        case .cancelCallback(let settings, _, _, _):
            return settings
        case .rescheduleCallback(let settings, _, _, _, _):
            return settings
        case .queryAvailabilityV1(let settings, _, _, _, _, _):
            return settings
        case .queryAvailabilityV2(let settings, _, _, _, _, _, _, _, _, _):
            return settings
        case .queryCallback(let settings, _, _, _):
            return settings
        case .queryCallbackById(let settings, _, _):
            return settings
        }
    }

    /// GMS server settings
    var serverSettings: GmsServerSettings {
        switch self {
        case .startCallback(_, let settings, _, _, _):
            return settings
        case .cancelCallback(_, let settings, _, _):
            return settings
        case .rescheduleCallback(_, let settings, _, _, _):
            return settings
        case .queryAvailabilityV1(_, let settings, _, _, _, _):
            return settings
        case .queryAvailabilityV2(_, let settings, _, _, _, _, _, _, _, _):
            return settings
        case .queryCallback(_, let settings, _, _):
            return settings
        case .queryCallbackById(_, let settings, _):
            return settings
        }
    }
}

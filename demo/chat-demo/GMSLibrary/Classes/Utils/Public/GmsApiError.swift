//
//  GmsApiError.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-08.
//

import Alamofire
import Foundation

/**
 Exceptions for GMSLibrary.
 */
public enum GmsApiError: Error, CustomStringConvertible {
    /// Missing settings.
    case missingGmsSettings
    
    /// Missing service name in `GmsServiceSettings`.
    case missingServiceName
    
    /// Missing authentication parameters in `GmsAuthSettings`.
    case missingAuthenticationParameters
    
    /// Invalid authentication parameters in `GmsAuthSettings`.
    case invalidAuthenticationParameters
    
    /// Callback ID required but not specified.
    case missingCallbackId

    /**
     Missing a required GMS settings value.
     
     - parameters:
       - key: The key GMS settings that is missing.
     */
    case missingGmsSettingsValue(key: String)
    
    /**
     Invalid parameter.
     
     - parameters:
       - key: The key of the invalid parameter.
       - value: The value of the invalid parameter.
     */
    case invalidParameter(key: String, value: String?)
    
    /**
     Invalid date format. ISO-8601 formatted date string is expected.
     
     - parameters:
       - key: Key of the field with invalid date format.
       - value: The received value that is not recognized as ISO-8601.
     */
    case invalidDateFormat(key: String, value: String)
    
    /**
     Exception is thrown by GMS.
     
     - parameters:
       - exception: The exception thrown by GMS.
     */
    case gmsExceptionThrown(exception: GmsCallbackException)
    
    /**
     Invalid response received.
     
     - parameters:
       - data: Data recevied.
     */
    case invalidResponse(data: Data?)
    
    /**
     Invalid HTTP status code received.
     
     - parameters:
       - statusCode: HTTP status code received, if any.
       - error: Any additional error received.
     */
    case invalidHttpStatusCode(statusCode: Int?, error: Error?)
    
    /**
     The resource requested is not found.
     */
    case notFound
    
    /**
     Chat error response received.
     
     - parameters:
       - response: Chat response received.
     */
    case chatErrorStatus(response: ChatV2Response)
    
    /**
     Chat session has already ended.
     */
    case chatEnded
    
    /**
     Failed to encode message or data.
     
     - parameters:
       - error: Error received.
     */
    case encodingError(error: Error)
    
    /**
     In a chat session, the file ID requested is not found.
     
     - parameters:
       - response: Chat response received.
     */
    case chatFileIdNotFound(response: ChatV2Response)
    
    /**
     Failed to download a requested file.
     
     - parameters:
       - response: Response received.
     */
    case downloadError(response: DefaultDownloadResponse?)
    
    /**
     Unsupported operation.
     
     - parameters:
       - request: API request to send.
       - operation: Operation requested.
     */
    case unsupportedOperation(request: ApiRequest, operation: String)
    
    /**
     Generic CometD client error.
     
     - parameters:
       - error: CometD client error.
     */
    case cometClientError(error: Error)
    
    /**
     Failed to connect to server via CometD.
     */
    case cometConnectFailed
    
    /**
     Chat session has not yet started.
     */
    case chatSessionNotStarted
    
    /**
     File error for CometD chat session.
    
     - parameters:
       - error: Error received.
     */
    case cometFileError(error: Error?)

    /**
     Returns a readable string description of the error.
     
     - returns: String description of the error.
     */
    public var description: String {
        switch self {
        case .missingGmsSettings:
            return "Missing GMS Settings"
        case .missingServiceName:
            return "Missing Service Name"
        case .missingAuthenticationParameters:
            return "Missing Authentication Parameters"
        case .invalidAuthenticationParameters:
            return "Invalid Authentication Parameters"
        case .missingCallbackId:
            return "Missing Callback ID"
        case let .missingGmsSettingsValue(key):
            return "GMS Settings field \(key) is not set"
        case let .invalidParameter(key, value):
            return "Invalid parameter key=\(key), value=\(value ?? "nil")"
        case let .invalidDateFormat(key, value):
            return "Invalid date format for key=\(key), value=\(value)"
        case let .gmsExceptionThrown(exception):
            return "GMS exception thrown: \(exception)"
        case let .invalidResponse(data):
            return "Invalid response from GMS: \(String(describing: data))"
        case let .invalidHttpStatusCode(statusCode, error):
            let code: String
            if let statusCode = statusCode {
                code = "\(statusCode)"
            } else {
                code = "[unknown]"
            }
            let errorMsg: String
            if let error = error {
                errorMsg = String(describing: error)
            } else {
                errorMsg = "[unknown]"
            }
            return "Invalid HTTP Status Code \(code), Error \(errorMsg)"
        case .notFound:
            return "The requested item cannot be found"
        case let .chatErrorStatus(response):
            return "Chat error (response=\(response))"
        case .chatEnded:
            return "Chat ended"
        case let .encodingError(error):
            let errorMsg = String(describing: error)
            return "Error encoding multi-part form data request: \(errorMsg)"
        case let .chatFileIdNotFound(response):
            return "File ID not returned in chat response: \(response)"
        case let .downloadError(response):
            return "Download error: \(String(describing: response ?? nil))"
        case let .unsupportedOperation(request, operation):
            return "Unsupported operation \(operation) for \(request)"
        case let .cometClientError(error):
            let errorMsg = String(describing: error)
            return "Comet client error \(errorMsg)"
        case .cometConnectFailed:
            return "Comet client failed to connect"
        case .chatSessionNotStarted:
            return "Comet chat session not yet started"
        case let .cometFileError(error):
            let errorMsg: String
            if let error = error {
                errorMsg = String(describing: error)
            } else {
                errorMsg = "[unknown]"
            }
            return "Comet chat file operation error \(errorMsg)"
        }
    }

    var invalidOrMissingKey: String? {
        switch self {
        case let .missingGmsSettingsValue(key):
            return key
        case .invalidDateFormat(let key, _):
            return key
        case .invalidParameter(let key, _):
            return key
        default:
            return nil
        }
    }

    var invalidResponse: Data? {
        switch self {
        case let .invalidResponse(data):
            return data
        default: return nil
        }
    }

    var httpStatusCode: Int? {
        switch self {
        case .invalidHttpStatusCode(let statusCode, _):
            return statusCode
        default:
            return nil
        }
    }

    var errorReturned: Error? {
        switch self {
        case let .invalidHttpStatusCode(_, error):
            return error
        default:
            return nil
        }
    }

    var gmsExceptionReturned: GmsCallbackException? {
        switch self {
        case let .gmsExceptionThrown(exception):
            return exception
        default:
            return nil
        }
    }
}

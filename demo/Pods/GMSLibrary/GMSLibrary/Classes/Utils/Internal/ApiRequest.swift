import Alamofire
import Foundation

/// API helper
public protocol ApiRequest: URLRequestConvertible {
    var method: HTTPMethod { get }
    var parameters: Parameters { get }
    var contentType: ContentType? { get }
    var acceptedContentTypes: [ContentType]? { get }
    func getPath() throws -> String
    func getContentBody() throws -> Data?
    var isUpload: Bool { get }
    var serviceSettings: GmsServiceSettings { get }
    var serverSettings: GmsServerSettings { get }
    func buildUrlRequest() throws -> URLRequest
    func appendMultipartFormData(formData: MultipartFormData) throws
}

/// HTTP header fields which may be used
public enum HTTPHeaderField: String {
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case apiKey = "apikey"
    case xApiKey = "x-api-key"
    case gmsUser = "gms_user"
    case authentication = "Authentication"
    case contactCenterId = "ContactCenterId"
}

/// Content types which may be used
public struct ContentType: LosslessStringConvertible, Hashable {
    public let stringValue: String
    public init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    public var description: String {
        return stringValue
    }

    static let json = ContentType("application/json")
    static let formData = ContentType("multipart/form-data")
    static let formUrlEncoded = ContentType("application/x-www-form-urlencoded")
}

extension ApiRequest {
    var isUpload: Bool {
        return contentType == ContentType.formData
    }

    fileprivate func setHttpHeaders(_ urlRequest: inout URLRequest) throws {
        if let contentType = contentType {
            urlRequest.setValue(contentType.stringValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        }

        if let acceptedContentTypes = acceptedContentTypes {
            for type in acceptedContentTypes {
                urlRequest.setValue(type.stringValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
            }
        }

        if let gmsUser = serverSettings.gmsUser {
            urlRequest.setValue(gmsUser, forHTTPHeaderField: HTTPHeaderField.gmsUser.rawValue)
        }

        if let apiKey = serverSettings.apiKey {
            urlRequest.setValue(apiKey, forHTTPHeaderField: HTTPHeaderField.apiKey.rawValue)
            urlRequest.setValue(apiKey, forHTTPHeaderField: HTTPHeaderField.xApiKey.rawValue)
        }

        if let authorizationHeader = serverSettings.authSettings.authorizationHeader {
            urlRequest.setValue(authorizationHeader.value, forHTTPHeaderField: authorizationHeader.key)
        }

        for (field, value) in serverSettings.additionalHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
    }

    func buildUrlRequest() throws -> URLRequest {
        var urlRequest: URLRequest

        guard let baseUrl = serverSettings.baseUrl else {
            throw GmsApiError.missingGmsSettingsValue(key: "baseUrl")
        }
        let url = try baseUrl.asURL()
        debugPrint("[ApiRequest] url = \(url)")
        let path = try getPath()
        debugPrint("[ApiRequest] getPath() = \(path)")
        urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        try setHttpHeaders(&urlRequest)

        return urlRequest
    }

    func addParameters(request: inout URLRequest) throws {
        var encoding: URLEncoding
        if let contentType = contentType, contentType == ContentType.formUrlEncoded {
            encoding = URLEncoding(destination: .httpBody, arrayEncoding: .noBrackets, boolEncoding: .literal)
        } else {
            encoding = URLEncoding(destination: .queryString, arrayEncoding: .noBrackets, boolEncoding: .literal)
        }
        request = try encoding.encode(request, with: parameters)
    }

    func addBody(request: inout URLRequest) throws {
        if let contentType = contentType, contentType == ContentType.formUrlEncoded {
            return // don't add body
        }
        if let body = try getContentBody() {
            request.httpBody = body
        }
    }

    /// Returns the URLRequest representation of the current object
    func asURLRequest() throws -> URLRequest {
        var urlRequest = try buildUrlRequest()
        try addParameters(request: &urlRequest)
        try addBody(request: &urlRequest)

        debugPrint("[ApiRequest] URLRequest = \(urlRequest)")
        return urlRequest
    }

    func appendMultipartFormData(formData: MultipartFormData) throws {
        throw GmsApiError.unsupportedOperation(request: self, operation: "appendMultipartFormData")
    }
}

//
//  ChatV2ApiRequest.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-09.
//

import Alamofire
import Foundation

enum ChatV2ApiRequest {
    /// Requests a new chat session
    case requestChat(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        _ user: GmsUserSettings,
        subject: String?,
        userData: [String: String])

    /// Sends a chat message
    case sendMessage(
        _ session: ChatV2Session,
        message: String,
        messageType: String?,
        transcriptPosition: Int?
    )

    /// Starts typing
    case startTyping(
        _ session: ChatV2Session,
        message: String?
    )

    /// Stops typing
    case stopTyping(
        _ session: ChatV2Session,
        message: String?
    )

    /// Refresh chat
    case refresh(
        _ session: ChatV2Session,
        transcriptPosition: Int?
    )

    /// Disconnect chat
    case disconnect(
        _ session: ChatV2Session
    )

    /// Push URL
    case pushUrl(
        _ session: ChatV2Session,
        url: URL
    )

    /// Update nickname
    case updateNickname(
        _ session: ChatV2Session,
        user: GmsUserSettings
    )

    /// Custom notice
    case customNotice(
        _ session: ChatV2Session,
        messsage: String
    )

    /// Update user data
    case updateData(
        _ session: ChatV2Session,
        userData: [String: String]
    )

    /// Get file limits
    case getFileLimits(
        _ session: ChatV2Session
    )

    /// Upload file with URL
    case uploadFileURL(
        _ session: ChatV2Session,
        fileURL: URL,
        fileDescription: String?,
        userData: [String: String]
    )

    /// Upload file as Data
    case uploadFileData(
        _ session: ChatV2Session,
        fileName: String,
        mimeType: String,
        fileData: Data,
        fileDescription: String?,
        userData: [String: String]
    )

    /// Download file
    case downloadFile(
        _ session: ChatV2Session,
        _ fileId: String
    )

    /// Delete file
    case deleteFile(
        _ session: ChatV2Session,
        _ fileId: String
    )
}

extension ChatV2ApiRequest: ApiRequest {

    /// HTTP method for the request
    var method: HTTPMethod {
        return .post
    }

    private func getEncoded(_ str: String, _ name: String) throws -> String {
        guard !str.isEmpty, let encoded = str.urlSafe else {
            let error = GmsApiError.invalidParameter(key: name, value: str)
            debugPrint("[ChatV2ApiRequest] getEncoded(): \(error)")
            throw error
        }
        return encoded
    }

    var operation: String? {
        switch self {
        case .requestChat:
            return nil
        case .sendMessage:
            return "send"
        case .startTyping:
            return "startTyping"
        case .stopTyping:
            return "stopTyping"
        case .refresh:
            return "refresh"
        case .disconnect:
            return "disconnect"
        case .pushUrl:
            return "pushUrl"
        case .updateNickname:
            return "updateNickname"
        case .updateData:
            return "updateData"
        case .customNotice:
            return "customNotice"
        case .getFileLimits:
            return "file/limits"
        case .uploadFileURL:
            return "file"
        case .uploadFileData:
            return "file"
        case .downloadFile:
            return "file"
        case .deleteFile:
            return "file"
        }
    }

    var session: ChatV2Session? {
        switch self {
        case .requestChat:
            return nil
        case let .customNotice(session, _):
            return session
        case let .deleteFile(session, _):
            return session
        case let .disconnect(session):
            return session
        case let .downloadFile(session, _):
            return session
        case let .getFileLimits(session):
            return session
        case let .pushUrl(session, _):
            return session
        case let .refresh(session, _):
            return session
        case let .sendMessage(session, _, _, _):
            return session
        case let .stopTyping(session, _):
            return session
        case let .startTyping(session, _):
            return session
        case let .updateData(session, _):
            return session
        case let .updateNickname(session, _):
            return session
        case let .uploadFileURL(session, _, _, _):
            return session
        case let .uploadFileData(session, _, _, _, _, _):
            return session
        }
    }

    var serviceSettings: GmsServiceSettings {
        switch self {
        case let .requestChat(service, _, _, _, _):
            return service
        default:
            return session!.service
        }
    }

    var serverSettings: GmsServerSettings {
        switch self {
        case let .requestChat(_, server, _, _, _):
            return server
        default:
            return session!.server
        }
    }
    var serviceName: String {
        switch self {
        case let .requestChat(service, _, _, _, _):
            return service.serviceName
        default:
            return session!.service.serviceName
        }
    }

    /// URL path of the request
    func getPath() throws -> String {
        let name = try getEncoded(serviceName, "serviceName")
        let basePath = "/2/chat/\(name)"
        switch self {
        case .requestChat:
            return basePath
        case let .downloadFile(_, fileId):
            let chatId = try getEncoded(self.chatId!, "chatId")
            return "\(basePath)/\(chatId)/\(operation!)/\(try getEncoded(fileId, "fileId"))/download"
        case let .deleteFile(_, fileId):
            let chatId = try getEncoded(self.chatId!, "chatId")
            return "\(basePath)/\(chatId)/\(operation!)/\(try getEncoded(fileId, "fileId"))/delete"
        default:
            let chatId = try getEncoded(self.chatId!, "chatId")
            return "\(basePath)/\(chatId)/\(operation!)"
        }
    }

    var chatId: String? {
        switch self {
        case .requestChat:
            return nil
        default:
            return session!.chatId
        }
    }

    var identity: ChatV2Identity? {
        switch self {
        case .requestChat:
            return nil
        default:
            return session!.identity
        }
    }

    var message: String? {
        switch self {
        case .sendMessage(_, let message, _, _):
            return message
        case let .startTyping(_, message):
            return message
        case let .stopTyping(_, message):
            return message
        case let .customNotice(_, message):
            return message
        default:
            return nil
        }
    }

    /// Query string parameters for the current request
    var parameters: Parameters {
        var parameters = Parameters()
        if let identity = identity {
            if let userId = identity.userId {
                parameters["userId"] = userId
            }
            if let alias = identity.alias {
                parameters["alias"] = alias
            }
            parameters["secureKey"] = identity.secureKey
        }
        if let message = message {
            parameters["message"] = message
        }

        switch self {
        case let .requestChat(_, _, user, subject, userData):
            if let nickname = user.nickname {
                parameters["nickname"] = nickname
            }
            if let firstname = user.firstName {
                parameters["firstName"] = firstname
            }
            if let lastname = user.lastName {
                parameters["lastName"] = lastname
            }
            if let subject = subject {
                parameters["subject"] = subject
            }
            if let email = user.email {
                parameters["emailAddress"] = email
            }
            for (key, value) in userData {
                parameters["userData[\(key)]"] = value
            }
        case let .sendMessage(_, message, messageType, transcriptPosition):
            parameters["message"] = message
            if let type = messageType {
                parameters["messageType"] = type
            }
            if let pos = transcriptPosition {
                parameters["transcriptPosition"] = pos
            }
        case let .refresh(_, transcriptPosition):
            if let pos = transcriptPosition {
                parameters["transcriptPosition"] = pos
            }
        case let .pushUrl(_, url):
            parameters["pushUrl"] = url.absoluteString
        case let .updateNickname(_, user):
            if let nickname = user.nickname {
                parameters["nickname"] = nickname
            }
        case let .updateData(_, userData):
            for (key, value) in userData {
                parameters["userData[\(key)]"] = value
            }
        default:
            return parameters
        }
        return parameters
    }

    /// Content type of the request body, if needed
    var contentType: ContentType? {
        switch self {
        case .uploadFileURL:
            return .formData
        case .uploadFileData:
            return .formData
        default:
            return .formUrlEncoded
        }
    }

    /// Accepted content type(s) for the response body of the current request
    var acceptedContentTypes: [ContentType]? {
        switch self {
        case .downloadFile:
            return nil
        default:
            return [.json]
        }
    }

    /// HTTP request body
    func getContentBody() throws -> Data? {
        return nil
    }

    func appendMultipartFormData(formData: MultipartFormData) {
        switch self {
        case let .uploadFileURL(_, fileURL, fileDescription, userData):
            if let userId = identity?.userId {
                formData.append(userId.data(using: .utf8)!, withName: "userId")
            }
            if let alias = identity?.alias {
                formData.append(alias.data(using: .utf8)!, withName: "alias")
            }
            if let secureKey = identity?.secureKey {
                formData.append(secureKey.data(using: .utf8)!, withName: "secureKey")
            }
            if let description = fileDescription {
                formData.append(description.data(using: .utf8)!, withName: "userData[file-description]")
            }
            for (key, value) in userData {
                formData.append(value.data(using: .utf8)!, withName: "userData[\(key)]")
            }
            formData.append(fileURL, withName: "file")
        case let .uploadFileData(
            _, fileName,
            mimeType, fileData,
            fileDescription, userData
        ):
            if let userId = identity?.userId {
                formData.append(userId.data(using: .utf8)!, withName: "userId")
            }
            if let alias = identity?.alias {
                formData.append(alias.data(using: .utf8)!, withName: "alias")
            }
            if let secureKey = identity?.secureKey {
                formData.append(secureKey.data(using: .utf8)!, withName: "secureKey")
            }
            if let description = fileDescription {
                formData.append(description.data(using: .utf8)!, withName: "userData[file-description]")
            }
            for (key, value) in userData {
                formData.append(value.data(using: .utf8)!, withName: "userData[\(key)]")
            }
            formData.append(fileData, withName: "file", fileName: fileName, mimeType: mimeType)
        default: break
        }
    }

    func asURLRequest() throws -> URLRequest {
        switch self {
        case .uploadFileURL:
            return try buildUrlRequest()
        default:
            var request = try buildUrlRequest()
            try addParameters(request: &request)
            try addBody(request: &request)
            return request
        }
    }
}

//
//  ChatV2CometApiRequest.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-15.
//

import Foundation
import Alamofire

enum ChatV2CometApiRequest {
    /// Requests a new chat session
    case requestChat(
        _ service: GmsServiceSettings,
        _ server: GmsServerSettings,
        _ user: GmsUserSettings,
        subject: String?,
        userData: [String: String])

    /// Requests notifications
    case requestNotifications(
        _ session: ChatV2Session,
        transcriptPosition: Int?,
        userData: [String: String]
    )

    /// Sends a chat message
    case sendMessage(
        _ session: ChatV2Session,
        message: String,
        messageType: String?
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
        message: String?
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

    /// Chat view going into the background
    case background(
        _ session: ChatV2Session,
        _ transcriptPosition: Int
    )
}

extension ChatV2CometApiRequest: ApiRequest {
    var method: HTTPMethod {
        return .post
    }

    var contentType: ContentType? {
        switch self {
        case .uploadFileURL:
            return .formData
        case .uploadFileData:
            return .formData
        case .getFileLimits:
            return .formUrlEncoded
        case .downloadFile:
            return .formUrlEncoded
        case .deleteFile:
            return .formUrlEncoded
        default:
            return nil
        }
    }

    var acceptedContentTypes: [ContentType]? {
        switch self {
        case .getFileLimits:
            return [.json]
        case .deleteFile:
            return [.json]
        case .uploadFileData:
            return [.json]
        case .uploadFileURL:
            return [.json]
        default:
            return nil
        }
    }

    var isFileRequest: Bool {
        switch self {
        case .getFileLimits:
            return true
        case .uploadFileURL:
            return true
        case .uploadFileData:
            return true
        case .downloadFile:
            return true
        case .deleteFile:
            return true
        default:
            return false
        }
    }
    func getPath() throws -> String {
        if !isFileRequest {
            return "\(serverSettings.baseUrl!)/cometd"
        } else {
            return "\(serverSettings.baseUrl!)/2/chat-ntf"
        }
    }

    func getContentBody() throws -> Data? {
        return nil
    }

    var operation: String {
        switch self {
        case .requestChat:
            return "requestChat"
        case .requestNotifications:
            return "requestNotifications"
        case .sendMessage:
            return "sendMessage"
        case .startTyping:
            return "startTyping"
        case .stopTyping:
            return "stopTyping"
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
            return "fileGetsLimits"
        case .downloadFile:
            return "fileDownload"
        case .deleteFile:
            return "fileDelete"
        case .uploadFileURL:
            return "" // not used
        case .uploadFileData:
            return "" // not used
        case .background:
            return "" // not used
        }
    }

    var session: ChatV2Session? {
        switch self {
        case .requestChat:
            return nil
        case let .customNotice(session, _):
            return session
        case let .disconnect(session):
            return session
        case let .pushUrl(session, _):
            return session
        case let .requestNotifications(session, _, _):
            return session
        case let .sendMessage(session, _, _):
            return session
        case let .stopTyping(session, _):
            return session
        case let .startTyping(session, _):
            return session
        case let .updateData(session, _):
            return session
        case let .updateNickname(session, _):
            return session
        case let .getFileLimits(session):
            return session
        case let .uploadFileURL(session, _, _, _):
            return session
        case let .uploadFileData(session, _, _, _, _, _):
            return session
        case let .downloadFile(session, _):
            return session
        case let .deleteFile(session, _):
            return session
        case let .background(session, _):
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
        case .sendMessage(_, let message, _):
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
    var parameters: [String: Any] {
        var parameters = [String: Any]()
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

        switch serverSettings.authSettings {
        case let .basic(user, password):
            if let data = "\(user):\(password)".data(using: .utf8) {
                let credential = data.base64EncodedString(options: [])
                parameters["auth"] = [ "encoded": credential ]
            }
        default:
            break
        }
        parameters["operation"] = operation
        switch self {
        case let .requestChat(_, _, user, subject, userData):
            var data = [String: String]()
            switch serverSettings.pushSettings {
            case let .fcm(token, debug, lang, provider):
                data["push_notification_deviceid"] = token
                data["push_notification_type"] = "fcm"
                if let debug = debug {
                    data["push_notification_debug"] = debug.description
                }
                if let lang = lang {
                    data["push_notification_language"] = lang
                }
                if let provider = provider {
                    data["push_notification_provider"] = provider
                }
            default:
                break
            }
            data.merge(userData) { (_, new) in new }
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
            if !data.isEmpty {
                parameters["userData"] = data
            }
        case let .requestNotifications(_, transcriptPosition, userData):
            if let pos = transcriptPosition {
                parameters["transcriptPosition"] = pos
            }
            if !userData.isEmpty {
                parameters["userData"] = userData
            }
        case let .sendMessage(_, message, messageType):
            parameters["message"] = message
            if let type = messageType {
                parameters["messageType"] = type
            }
        case let .pushUrl(_, url):
            parameters["pushUrl"] = url.absoluteString
        case let .updateNickname(_, user):
            if let nickname = user.nickname {
                parameters["nickname"] = nickname
            }
        case let .updateData(_, userData):
            if !userData.isEmpty {
                parameters["userData"] = userData
            }
        case let .downloadFile(_, fileId):
            parameters["fileId"] = fileId
        case let .deleteFile(_, fileId):
            parameters["fileId"] = fileId
        default:
            return parameters
        }
        return parameters
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

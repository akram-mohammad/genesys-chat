//
//  ChatV2PromiseApiClient.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-10.
//

import Alamofire
import Foundation
import Promises

/// This is a basic, Promise-based ChatV2 client without CometD.
/// Consumer of this client is responsible for storing everything
/// related to the chat session and keeping the session alive.
public struct ChatV2PromiseApiClient {
    private static let apiClient: ApiClientProtocol = APIClient()

    /// GMS settings to be used by this client.
    public var serviceSettings: GmsServiceSettings
    public var serverSettings: GmsServerSettings
    public var userSettings: GmsUserSettings

    /// Create a new instance of `ChatV2PromiseApiClient`.
    public init(serviceSettings: GmsServiceSettings, serverSettings: GmsServerSettings, userSettings: GmsUserSettings) {
        self.serviceSettings = serviceSettings
        self.serverSettings = serverSettings
        self.userSettings = userSettings
    }

    /// Request a chat session using the Chat V2 API.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - subject: Subject of the chat session.
    ///     - userData: Additional user data to associate with the chat session.
    public func requestChat(
        on queue: DispatchQueue,
        subject: String? = nil,
        userData: [String: String] = [String: String]()
    ) -> Promise<ChatV2Response> {
        let request = ChatV2ApiRequest.requestChat(
            serviceSettings, serverSettings, userSettings,
            subject: subject,
            userData: userData
        )
        return performRequest(on: queue, request: request)
    }

    /// Sends a text chat message.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - message: Text of the message.
    ///     - messageType: Type of the message.
    ///     - transcriptPosition: Request server to return all messages beginning
    ///       at this position.  If set to 0, returns no messages.
    public func sendMessage(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        message: String,
        messageType: String? = nil,
        transcriptPosition: Int? = nil
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.sendMessage(session,
            message: message,
            messageType: messageType,
            transcriptPosition: transcriptPosition
        )
        return performRequest(on: queue, request: request)
    }

    /// Starts typing.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - message: Optional message to send to server as the text currently in text box.
    public func startTyping(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        message: String? = nil
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.startTyping(session, message: message)
        return performRequest(on: queue, request: request)
    }

    /// Stops typing.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - message: Optional message to send to server as the text currently in text box.
    public func stopTyping(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        message: String? = nil
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.stopTyping(session, message: message)
        return performRequest(on: queue, request: request)
    }

    /// Refresh chat session.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - transcriptPosition: Index position in the transcript starting from which the
    ///       messages should be retrieved.
    ///         - 0 = no messages
    ///         - 1 = all messages (default)
    ///         - 2 or higher = all messages starting from the number provided
    public func refreshChat(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        transcriptPosition: Int? = nil
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.refresh(session, transcriptPosition: transcriptPosition)
        return performRequest(on: queue, request: request)
    }

    /// Disconnect chat session.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    public func disconnect(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.disconnect(session)
        return performRequest(on: queue, request: request)
    }

    /// Push URL to the chat session.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - url: URL to push
    public func pushUrl(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        url: URL
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.pushUrl(session, url: url)
        return performRequest(on: queue, request: request)
    }

    /// Updates the displayed nickname of the current user.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    public func updateDisplayName(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.updateNickname(session, user: userSettings)
        return performRequest(on: queue, request: request)
    }

    /// Sends a custom notice to the chat session.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - notice: Custom notice to send to the chat session.
    public func sendCustomNotice(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        notice: String
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.customNotice(session, messsage: notice)
        return performRequest(on: queue, request: request)
    }

    /// Updates user data of the chat session.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - userData: Updated user data.
    public func updateUserData(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        userData: [String: String]
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.updateData(session, userData: userData)
        return performRequest(on: queue, request: request)
    }

    /// Retrieves the file management limits imposed by the server.
    ///
    /// - returns:
    /// A `Promise` of a `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    public func getFileLimits(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String
    ) -> Promise<ChatV2FileLimits> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.getFileLimits(session)
        return Promise<ChatV2FileLimits> { fulfill, reject in
            try ChatV2PromiseApiClient.apiClient.request(
                ChatV2Resource(
                    request: request
                ),
                on: queue
            ) { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] getFileLimits completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2PromiseApiClient] getFileLimits succeeded: \(response)")
                        if let message = response.messages.first(where: {
                            $0.type == .notice &&
                                $0.text == "file-client-cfg-get"
                        }) {
                            do {
                                fulfill(try ChatV2FileLimits(userData: message.userData))
                            } catch {
                                debugPrint(
                                    "[ChatV2PromiseApiClient] " +
                                    "getFileLimits fail to convert message.userData: " +
                                    "\(message.userData)")
                                reject(GmsApiError.chatErrorStatus(response: response))
                            }
                        } else {
                            debugPrint("[ChatV2PromiseApiClient] " +
                                "getFileLimits cannot find file limits response message: " +
                                "\(response.userData)")
                        }
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2PromiseApiClient] getFileLimits failed: \(error)")
                        reject(error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] getFileLimits failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }

    /// Uploads a file.
    ///
    /// - returns:
    /// A `Promise` of the uploaded file ID.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error
    /// was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - fileURL: File to be uploaded.
    ///     - fileDescription: Optional description of the file.
    ///     - userData: Additional user data.
    public func uploadFile(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        fileURL: URL,
        fileDescription: String? = nil,
        userData: [String: String] = [String: String]()
    ) -> Promise<String> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.uploadFileURL(
            session,
            fileURL: fileURL,
            fileDescription: fileDescription,
            userData: userData
        )
        let resource = ChatV2Resource(request: request)
        return Promise<String> { fulfill, reject in
            try ChatV2PromiseApiClient.apiClient.multipartFormDataUpload(
                resource, on: queue,
                encodingErrorHandler: { error in reject(error) },
                encodingCompletionHandler: { _ in },
                completion: { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] performRequest completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2PromiseApiClient] performRequest succeeded: \(response)")
                        if let fileId = response.userData["file-id"] {
                            fulfill(fileId)
                        } else {
                            reject(GmsApiError.chatFileIdNotFound(response: response))
                        }
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2PromiseApiClient] performRequest failed: \(error)")
                        reject(error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] performRequest failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        )
        }
    }

    /// Uploads a file.
    ///
    /// - returns:
    /// A `Promise` of the uploaded file ID.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error
    /// was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - fileURL: File to be uploaded.
    ///     - fileDescription: Optional description of the file.
    ///     - userData: Additional user data.
    public func uploadFile(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        fileDescription: String? = nil,
        userData: [String: String] = [String: String]()
    ) -> Promise<String> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.uploadFileData(
            session,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData,
            fileDescription: fileDescription,
            userData: userData
        )
        let resource = ChatV2Resource(request: request)
        return Promise<String> { fulfill, reject in
            try ChatV2PromiseApiClient.apiClient.multipartFormDataUpload(
                resource,
                on: queue,
                encodingErrorHandler: { error in reject(error) },
                encodingCompletionHandler: { _ in  },
                completion: { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] performRequest completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2PromiseApiClient] performRequest succeeded: \(response)")
                        if let fileId = response.userData["file-id"] {
                            fulfill(fileId)
                        } else {
                            reject(GmsApiError.chatFileIdNotFound(response: response))
                        }
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2PromiseApiClient] performRequest failed: \(error)")
                        reject(error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] performRequest failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            })
        }
    }

    /// Download a file from the chat session.
    ///
    /// - returns:
    /// A `Promise` of the downloaded file path.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error
    /// was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - fileId: ID of the file to download.
    public func downloadFile(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        fileId: String
    ) -> Promise<URL> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.downloadFile(session, fileId)
        let resource = ChatV2FileDownloadResource(request: request)
        return Promise<URL> { fulfill, reject in
            try ChatV2PromiseApiClient.apiClient.download(
                resource,
                on: queue,
                requestBuiltHandler: { _ in },
                completion: { (statusCode: Int?, result: Result<URL>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] downloadFile completion handler")
                switch result {
                case let .success(path):
                    fulfill(path)
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] downloadFile failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            })
        }
    }

    /// Deletes a file from the chat session.
    ///
    /// - returns:
    /// A `Promise` of the `ChatV2Response` object.  The promise would be resolved
    /// when the request is successfully completed, or rejected if any error
    /// was encountered.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - chatId: ID of the chat session.
    ///     - userId: User ID assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - alias: Host alias assigned by the server to the current user.
    ///       Deprecated in GMS 8.5.112.
    ///     - secureKey: Secure key assigned by the server to the current user.
    ///     - fileId: ID of the file to be deleted.
    public func deleteFile(
        on queue: DispatchQueue,
        chatId: String,
        userId: String?,
        alias: String?,
        secureKey: String,
        fileId: String
    ) -> Promise<ChatV2Response> {
        let session = ChatV2Session(
            serviceSettings,
            serverSettings,
            chatId: chatId,
            identity: ChatV2Identity(secureKey: secureKey,
                                     userId: userId,
                                     alias: alias))
        let request = ChatV2ApiRequest.deleteFile(session, fileId)
        return performRequest(on: queue, request: request)
    }

    private func performRequest(on queue: DispatchQueue, request: ChatV2ApiRequest) -> Promise<ChatV2Response> {
        return Promise<ChatV2Response> { fulfill, reject in
            try ChatV2PromiseApiClient.apiClient.request(
                ChatV2Resource(
                    request: request
                ),
                on: queue
            ) { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] performRequest completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2PromiseApiClient] performRequest succeeded: \(response)")
                        fulfill(response)
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2PromiseApiClient] performRequest failed: \(error)")
                        reject(error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] performRequest failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        reject(GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        reject(error)
                    }
                }
            }
        }
    }
}

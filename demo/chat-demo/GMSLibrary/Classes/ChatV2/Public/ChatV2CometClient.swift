//
//  ChatV2CometClient.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-15.
//

import Foundation
import GFayeSwift
import SwiftyJSON
import Alamofire

/**
 CometD connection type supported.
 */
public enum CometConnectionType: String {
    case longPolling = "long-polling"
    case callbackPolling = "callback-polling"
    case iFrame = "iframe"
    case webSocket = "websocket"
    
    public static let allValues = [longPolling, callbackPolling, iFrame, webSocket]
}

extension CometConnectionType {
    func convert() -> BayeuxConnection {
        BayeuxConnection.init(rawValue: rawValue)!
    }
    
    static func convert(_ array: [CometConnectionType]) -> [BayeuxConnection] {
        return array.map { $0.convert() }
    }
}

/**
  Delegate-based Chat V2 CometD client.
 
  Use `GmsServerSettings` to configure general GMS settings, such as hostname, port, HTTP or HTTPS, and authentication parameters. See documentation of class for details.
 
  `GmsServiceSettings` is for the settings specifically related to the chat service configured in GMS.
 
  User settings, such as display name and email, are configured in `GmsUserSettings`.

  Upon receiving events via CometD, the associated function of `ChatV2Delegate` would be called.
 */
public class ChatV2CometClient: ChatV2Client, GFayeClientDelegate {

    private let queue = DispatchQueue(label: "com.genesys.gms.chat.comet", qos: .utility, attributes: .concurrent)
    private static let apiClient: ApiClientProtocol = APIClient()

    var pendingRequests = [ChatV2CometApiRequest]()

    var cometClient: GFayeClient?
    var isSubscribed = false
    var isChatStarted = false
    var session: ChatV2Session?
    
    /**
     Whether the chat client is currently disconnected from CometD server.
     */
    public var isBackground = false

    var uploadRequests = [String: UploadRequest]()
    var downloadRequests = [String: DownloadRequest]()

    var cometUrl: String {
        return "\(serverSettings.baseUrl!)/cometd"
    }

    var channel: String {
        return "/service/chatV2/\(serviceSettings.serviceName)"
    }

    /**
     ChatV2 Comet client delegate.
     */
    public let delegate: ChatV2Delegate

    /**
     Chat session ID returned by GMS.
     */
    public var chatId: String? {
        if let session = session {
            return session.chatId
        }
        return nil
    }

    /**
     Chat host aliase used for the session.
     */
    public var alias: String? {
        if let session = session {
            return session.identity.alias
        }
        return nil
    }

    /**
     User ID used for the chat seesion.
     */
    public var userId: String? {
        if let session = session {
            return session.identity.userId
        }
        return nil
    }

    /**
     Secure key for the chat session.
     */
    public var secureKey: String? {
        if let session = session {
            return session.identity.secureKey
        }
        return nil
    }

    /**
     Whether the chat session is currently connected.
     */
    public var isConnected: Bool {
        return isChatStarted
    }

    let serviceSettings: GmsServiceSettings
    let serverSettings: GmsServerSettings
    var userSettings: GmsUserSettings
    var allowedConnectionTypes: [CometConnectionType]

    /**
      Creates a new instance of the chat client.
     
      - Parameters:
        - serviceSettings: GMS chat service configurations.
        - serverSettings: GMS server configurations.
        - userSettings: Current user information.
        - delegate: Delegate to handle events from chat.
     */
    required public init(serviceSettings: GmsServiceSettings,
                         serverSettings: GmsServerSettings,
                         userSettings: GmsUserSettings,
                         delegate: ChatV2Delegate) {
        self.serviceSettings = serviceSettings
        self.serverSettings = serverSettings
        self.userSettings = userSettings
        self.delegate = delegate
        self.allowedConnectionTypes = [
            CometConnectionType.longPolling,
            CometConnectionType.callbackPolling,
            CometConnectionType.iFrame,
            CometConnectionType.webSocket
        ]
    }

    /**
      Creates a new instance of the chat client.
     
      - Parameters:
        - serviceSettings: GMS chat service configurations.
        - serverSettings: GMS server configurations.
        - userSettings: Current user information.
        - allowedConnectionTypes: Types of CometD connection allowed.
        - delegate: Delegate to handle events from chat.
     */
    public init(serviceSettings: GmsServiceSettings,
                serverSettings: GmsServerSettings,
                userSettings: GmsUserSettings,
                allowedConnectionTypes: [CometConnectionType],
                delegate: ChatV2Delegate) throws {
        self.serviceSettings = serviceSettings
        self.serverSettings = serverSettings
        self.userSettings = userSettings
        self.delegate = delegate
        if allowedConnectionTypes.isEmpty {
            throw GmsApiError.invalidParameter(key: "allowedConnectionTypes", value: "<empty>")
        }
        self.allowedConnectionTypes = allowedConnectionTypes
    }

    /**
      Request a chat session using the Chat V2 API.
   
      - Parameters:
        - queue: Dispatch queue to perform the request.
        - subject: Subject of the chat session.
        - userData: Additional user data to associate with the chat session.
     */
    public func requestChat(
        on queue: DispatchQueue?,
        subject: String? = nil,
        userData: [String: String] = [String: String]()
        ) {
        let request = ChatV2CometApiRequest.requestChat(
            serviceSettings, serverSettings, userSettings,
            subject: subject,
            userData: userData
        )
        sendRequest(request: request)
    }

    /**
      Resume a running chat session using the Chat V2 Comet API.
   
      - Parameters:
        - queue: Dispatch queue to perform the request.
        - chatId: ID of the chat session.
        - userId: User ID.
        - alias: Host alias.
        - secureKey: Secure Key of the chat session.
        - transcriptPosition: Request the transcript starting at the provided position.
        - userData: Additional user data to associate with the chat session.
     */
    public func requestNotifications(
        on queue: DispatchQueue?,
        chatId: String,
        userId: String,
        alias: String,
        secureKey: String,
        transcriptPosition: Int? = nil,
        userData: [String: String] = [String: String]()) {
        let request = ChatV2CometApiRequest.requestNotifications(
            ChatV2Session(serviceSettings, serverSettings,
                          chatId: chatId,
                          identity: ChatV2Identity(secureKey: secureKey,
                                                   userId: userId,
                                                   alias: alias)),
            transcriptPosition: transcriptPosition,
            userData: userData)
        sendRequest(request: request)
    }

    /**
      Puts the current chat session into the background using the Chat V2 Comet API.
     
      When it succeeds, the client is no longer connected to the chat session.
     
      If push notifications are configured on both the server and the client, as well as
      enabled for the chat session, notifications are sent to the client when messages and
      activities happen on the chat session while the session is in the background.
     */
    public func background(
        on queue: DispatchQueue?,
        transcriptPosition: Int
        ) throws {
        debugPrint("[ChatV2CometClient] background")
        let session = self.queue.sync(execute: { return self.session })
        if session == nil {
            throw GmsApiError.chatSessionNotStarted
        }

        // disconnect from comet server
        if let client = cometClient {
            isBackground = true
            client.disconnectFromServer(ext: ["transcriptPosition": transcriptPosition.description])
        }
    }

    /**
      Sends a message to the chat session using the Chat V2 Comet API.
    
      - parameters:
        - queue: Dispatch queue to perform the request.
        - message: Message to send
        - messageType: Type of message; user-defined.
        - transcriptPosition: Transcript position.
    
      - throws:
        - GmsApiError.chatSessionNotStarted if there are no active chat session.
    */
    public func sendMessage(
        on queue: DispatchQueue?,
        message: String,
        messageType: String? = nil,
        transcriptPosition: Int? = nil) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.sendMessage(session, message: message, messageType: messageType)
        sendRequest(request: request)
    }

    /**
      Notifies the chat session the current user has started typing.
     
      - parameters:
        - queue: Dispatch queue to perform the request.
        - message: Message being typed
     
      - throws:
        - GmsApiError.chatSessionNotStarted if there are no active chat session.
     */
    public func startTyping(
        on queue: DispatchQueue?,
        message: String? = nil) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.startTyping(session, message: message)
        sendRequest(request: request)
    }

    /**
      Notifies the chat session the current user has stopped typing.
     
      - parameters:
          - queue: Dispatch queue to perform the request.
          - message: Message being typed
     
      - throws:
          - GmsApiError.chatSessionNotStarted if there are no active chat session.
     */
    public func stopTyping(
        on queue: DispatchQueue?,
        message: String? = nil) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.stopTyping(session, message: message)
        sendRequest(request: request)
    }

    /// Sends a URL to the chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - url: URL to send
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    public func pushUrl(
        on queue: DispatchQueue?,
        url: URL) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.pushUrl(session, url: url)
        sendRequest(request: request)
    }

    /// Sends a custom notice to the chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - message: Content of the custom notice.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    public func customNotice(
        on queue: DispatchQueue?,
        message: String? = nil) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.customNotice(session, message: message)
        sendRequest(request: request)
    }

    /// Updates the nickname of the current user.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - nickname: new nickname.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    public func updateNickname(on queue: DispatchQueue?, nickname: String) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        userSettings.nickname = nickname
        let request = ChatV2CometApiRequest.updateNickname(session, user: userSettings)
        sendRequest(request: request)
    }

    /// Updates the user data associated with the current session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - userData: new or updated user data.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    public func updateData(on queue: DispatchQueue?, userData: [String: String]) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.updateData(session, userData: userData)
        sendRequest( request: request)
    }

    /// Terminates the current chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    public func disconnect(on queue: DispatchQueue?) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.disconnect(session)
        sendRequest(request: request)
    }

    /// Retrieves the file management limits imposed by the server.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    public func getFileLimits(
        on queue: DispatchQueue?) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.getFileLimits(session)
        try ChatV2CometClient.apiClient.request(
            ChatV2CometResource(
                request: request
            ),
            on: queue
        ) { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
            debugPrint("[ChatV2CometClient] getFileLimits completion handler")
            switch result {
            case let .success(response):
                if let status = statusCode, status == 200 {
                    debugPrint("[ChatV2CometClient] getFileLimits succeeded: \(response)")
                    if let message = response.messages.first(where: {
                        $0.type == .notice &&
                            $0.text == "file-client-cfg-get"
                    }) {
                        do {
                            self.delegate.fileLimitsReceived(
                                session.service.serviceName,
                                chatId: session.chatId,
                                secureKey: session.identity.secureKey,
                                fileLimits: try ChatV2FileLimits(userData: message.userData))
                        } catch {
                            debugPrint(
                                "[ChatV2CometClient] " +
                                    "getFileLimits fail to convert message.userData: " +
                                "\(message.userData)")
                            self.delegate.fileLimitsFailed(
                                session.service.serviceName,
                                chatId: session.chatId,
                                secureKey: session.identity.secureKey,
                                error: GmsApiError.chatErrorStatus(response: response))
                        }
                    } else {
                        debugPrint("[ChatV2CometClient] " +
                            "getFileLimits cannot find file limits response message: " +
                            "\(response.userData)")
                    }
                } else {
                    let error = GmsApiError.invalidHttpStatusCode(
                        statusCode: statusCode,
                        error: GmsApiError.chatErrorStatus(response: response)
                    )
                    debugPrint("[ChatV2CometClient] getFileLimits failed: \(error)")
                    self.delegate.fileLimitsFailed(
                        session.service.serviceName,
                        chatId: session.chatId,
                        secureKey: session.identity.secureKey,
                        error: error)
                }
            case let .failure(error):
                debugPrint("[ChatV2CometClient] getFileLimits failed with error: \(error)")
                if let status = statusCode, status != 200 {
                    self.delegate.fileLimitsFailed(
                        session.service.serviceName,
                        chatId: session.chatId,
                        secureKey: session.identity.secureKey,
                        error: GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                } else {
                    self.delegate.fileLimitsFailed(
                        session.service.serviceName,
                        chatId: session.chatId,
                        secureKey: session.identity.secureKey,
                        error: error)
                }
            }
        }
    }

    /// Uploads a file.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - returns:
    ///     - A uniquely identifying ID of the upload request.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - fileURL: File to be uploaded.
    ///     - fileDescription: Optional description of the file.
    ///     - userData: Additional user data.
    public func uploadFile(
        on queue: DispatchQueue,
        fileURL: URL,
        fileDescription: String? = nil,
        userData: [String: String] = [String: String]()
        ) throws -> String {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.uploadFileURL(
            session,
            fileURL: fileURL,
            fileDescription: fileDescription,
            userData: userData)
        let requestId = UUID().uuidString
        let resource = ChatV2CometResource(request: request)
        try ChatV2CometClient.apiClient.multipartFormDataUpload(
            resource, on: queue,
            encodingErrorHandler: { error in
                self.delegate.fileUploadFailed(
                    session.service.serviceName,
                    chatId: session.chatId,
                    secureKey: session.identity.secureKey,
                    requestId: requestId,
                    error: error) },
            encodingCompletionHandler: { request in self.queue.sync { self.uploadRequests[requestId] = request } },
            completion: { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2CometClient] performRequest completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2CometClient] performRequest succeeded: \(response)")
                        if let fileId = response.userData["file-id"] {
                            self.delegate.fileUploaded(session.service.serviceName,
                                                       chatId: session.chatId,
                                                       secureKey: session.identity.secureKey,
                                                       requestId: requestId,
                                                       fileId: fileId)
                        } else {
                            self.delegate.fileUploadFailed(session.service.serviceName,
                                                           chatId: session.chatId,
                                                           secureKey: session.identity.secureKey,
                                                           requestId: requestId,
                                                           error: GmsApiError.chatFileIdNotFound(response: response))
                        }
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2CometClient] performRequest failed: \(error)")
                        self.delegate.fileUploadFailed(session.service.serviceName,
                                                       chatId: session.chatId,
                                                       secureKey: session.identity.secureKey,
                                                       requestId: requestId,
                                                       error: error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2CometClient] performRequest failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        self.delegate.fileUploadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            error: GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        self.delegate.fileUploadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            error: error)
                    }
                }
        })
        return requestId
    }

    /// Uploads data as file.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - returns:
    ///     - A uniquely identifying ID of the upload request.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - fileURL: File to be uploaded.
    ///     - fileDescription: Optional description of the file.
    ///     - userData: Additional user data.
    public func uploadFile(
        on queue: DispatchQueue,
        fileName: String,
        mimeType: String,
        fileData: Data,
        fileDescription: String? = nil,
        userData: [String: String] = [String: String]()
        ) throws -> String {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let requestId = UUID().uuidString
        let request = ChatV2CometApiRequest.uploadFileData(
            session,
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData,
            fileDescription: fileDescription,
            userData: userData
        )
        let resource = ChatV2CometResource(request: request)
        try ChatV2CometClient.apiClient.multipartFormDataUpload(
            resource, on: queue,
            encodingErrorHandler: { error in
                self.delegate.fileUploadFailed(
                    session.service.serviceName,
                    chatId: session.chatId,
                    secureKey: session.identity.secureKey,
                    requestId: requestId,
                    error: error) },
            encodingCompletionHandler: { request in self.queue.sync { self.uploadRequests[requestId] = request } },
            completion: { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
                debugPrint("[ChatV2CometClient] performRequest completion handler")
                switch result {
                case let .success(response):
                    if let status = statusCode, status == 200 {
                        debugPrint("[ChatV2CometClient] performRequest succeeded: \(response)")
                        if let fileId = response.userData["file-id"] {
                            self.delegate.fileUploaded(session.service.serviceName,
                                                       chatId: session.chatId,
                                                       secureKey: session.identity.secureKey,
                                                       requestId: requestId,
                                                       fileId: fileId)
                        } else {
                            self.delegate.fileUploadFailed(session.service.serviceName,
                                                           chatId: session.chatId,
                                                           secureKey: session.identity.secureKey,
                                                           requestId: requestId,
                                                           error: GmsApiError.chatFileIdNotFound(response: response))
                        }
                    } else {
                        let error = GmsApiError.invalidHttpStatusCode(
                            statusCode: statusCode,
                            error: GmsApiError.chatErrorStatus(response: response)
                        )
                        debugPrint("[ChatV2CometClient] performRequest failed: \(error)")
                        self.delegate.fileUploadFailed(session.service.serviceName,
                                                       chatId: session.chatId,
                                                       secureKey: session.identity.secureKey,
                                                       requestId: requestId,
                                                       error: error)
                    }
                case let .failure(error):
                    debugPrint("[ChatV2CometClient] performRequest failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        self.delegate.fileUploadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            error: GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        self.delegate.fileUploadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            error: error)
                    }
                }
        })
        return requestId
    }

    /// Download a file from the chat session.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - returns:
    ///     - A uniquely identifying ID of the download request.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - fileId: ID of the file to download.
    public func downloadFile(
        on queue: DispatchQueue,
        fileId: String
        ) throws -> String {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let requestId = UUID().uuidString
        let request = ChatV2CometApiRequest.downloadFile(session, fileId)
        let resource = ChatV2CometFileDownloadResource(request: request)
        try ChatV2CometClient.apiClient.download(
            resource,
            on: queue,
            requestBuiltHandler: { request in
                self.queue.sync(execute: { self.downloadRequests[requestId] = request }) },
            completion: { (statusCode: Int?, result: Result<URL>) -> Void in
                debugPrint("[ChatV2PromiseApiClient] downloadFile completion handler")
                switch result {
                case let .success(path):
                    self.delegate.fileDownloaded(session.service.serviceName,
                                                 chatId: session.chatId,
                                                 secureKey: session.identity.secureKey,
                                                 requestId: requestId,
                                                 fileId: fileId,
                                                 fileURL: path)
                case let .failure(error):
                    debugPrint("[ChatV2PromiseApiClient] downloadFile failed with error: \(error)")
                    if let status = statusCode, status != 200 {
                        self.delegate.fileDownloadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            fileId: fileId,
                            error: GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                    } else {
                        self.delegate.fileDownloadFailed(
                            session.service.serviceName,
                            chatId: session.chatId,
                            secureKey: session.identity.secureKey,
                            requestId: requestId,
                            fileId: fileId,
                            error: error)
                    }
                }
        })
        return requestId
    }

    /// Deletes a file from the chat session.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - fileId: ID of the file to be deleted.
    public func deleteFile(
        on queue: DispatchQueue,
        fileId: String
        ) throws {
        guard let session = self.queue.sync(execute: { return self.session }) else {
            throw GmsApiError.chatSessionNotStarted
        }
        let request = ChatV2CometApiRequest.deleteFile(session, fileId)
        try ChatV2CometClient.apiClient.request(
            ChatV2CometResource(
                request: request
            ),
            on: queue
        ) { (statusCode: Int?, result: Result<ChatV2Response>) -> Void in
            debugPrint("[ChatV2PromiseApiClient] performRequest completion handler")
            switch result {
            case let .success(response):
                if let status = statusCode, status == 200 {
                    debugPrint("[ChatV2PromiseApiClient] performRequest succeeded: \(response)")
                    self.delegate.fileDeleted(session.service.serviceName,
                                              chatId: session.chatId,
                                              secureKey: session.identity.secureKey,
                                              fileId: fileId)
                } else {
                    let error = GmsApiError.invalidHttpStatusCode(
                        statusCode: statusCode,
                        error: GmsApiError.chatErrorStatus(response: response)
                    )
                    debugPrint("[ChatV2PromiseApiClient] performRequest failed: \(error)")
                    self.delegate.fileDeleteFailed(session.service.serviceName,
                                                   chatId: session.chatId,
                                                   secureKey: session.identity.secureKey,
                                                   fileId: fileId,
                                                   error: error)
                }
            case let .failure(error):
                debugPrint("[ChatV2PromiseApiClient] performRequest failed with error: \(error)")
                if let status = statusCode, status != 200 {
                    self.delegate.fileDeleteFailed(
                        session.service.serviceName,
                        chatId: session.chatId,
                        secureKey: session.identity.secureKey,
                        fileId: fileId,
                        error: GmsApiError.invalidHttpStatusCode(statusCode: status, error: error))
                } else {
                    self.delegate.fileDeleteFailed(
                        session.service.serviceName,
                        chatId: session.chatId,
                        secureKey: session.identity.secureKey,
                        fileId: fileId,
                        error: error)
                }
            }
        }
    }

    // MARK: private functions
    
    private func sendRequest(request: ChatV2CometApiRequest) {
        debugPrint("[ChatV2CometClient] sendRequest \(request.parameters)")
        self.queue.sync {
            if self.cometClient == nil {
                debugPrint("[ChatV2CometClient] no existing client; connect to server first")
                self.cometClient = GFayeClient(aGFayeURLString: cometUrl, channel: channel, connectionTypes: CometConnectionType.convert(self.allowedConnectionTypes)) { msg in
                    self.messageReceived(message: msg)
                }
                self.cometClient?.delegate = self
                self.cometClient?.connectToServer()
                pendingRequests.append(request)
            } else if !self.isSubscribed {
                let subscriptionState = self.cometClient?.subscribeToChannel(channel)
                switch subscriptionState {
                case .subscribed?:
                    debugPrint("[ChatV2CometClient] subscribed; sending pending requests")
                    isSubscribed = true
                    while !pendingRequests.isEmpty {
                        let first = pendingRequests.removeFirst()
                        cometClient?.sendMessage(first.parameters, channel: self.channel)
                    }
                default:
                    debugPrint("[ChatV2CometClient] not yet subscribed; queue pending request")
                    pendingRequests.append(request)
                }
            } else {
                cometClient?.sendMessage(request.parameters, channel: self.channel)
            }
        }
    }

    func messageReceived(message: GFayeMessage) {
        let json = JSON(message)
        debugPrint("[ChatV2CometClient] message received: \(String(describing: json.rawString()))")

        if message["successful"] != nil {
            debugPrint("[ChatV2CometClient] This is an ack of a message sent; dropping")
            return
        }
        let decoder = JSONDecoder()
        let response: ChatV2Response
        do {
            response = try decoder.decode(ChatV2Response.self, from: json.rawData())
        } catch {
            delegate.parsingError(serviceSettings.serviceName, message: message)
            return
        }

        if session == nil && !(response.chatEnded ?? true) {
            session = ChatV2Session(serviceSettings, serverSettings, from: response)
            debugPrint("[ChatV2CometClient] create Chat session object for this client and send to delegate")
            delegate.chatSessionActive(serviceSettings.serviceName,
                                       chatId: response.chatId,
                                       userId: response.userId,
                                       alias: response.alias,
                                       secureKey: response.secureKey)
        } else if isBackground {
            debugPrint("[ChatV2CometClient] Chat session resumed")
            self.isSubscribed = true
            self.isChatStarted = true
            self.isBackground = false
            delegate.chatSessionResumed(serviceSettings.serviceName,
                                        chatId: response.chatId,
                                        secureKey: response.secureKey)
        }
        if response.statusCode != 0 {
            debugPrint("[ChatV2CometClient] error received")
            delegate.errorReceived(serviceSettings.serviceName,
                                   chatId: response.chatId,
                                   error: GmsApiError.chatErrorStatus(response: response))
        }

        for message in response.messages {
            debugPrint("[ChatV2CometClient] send message to delegate")
            delegate.messageReceived(serviceSettings.serviceName,
                                     chatId: response.chatId,
                                     secureKey: response.secureKey,
                                     message: message)
        }

        if response.chatEnded ?? true {
            debugPrint("[ChatV2CometClient] chat session ended; disconnecting Comet session")
            let chatId = response.chatId
            let secureKey = response.secureKey ?? session?.identity.secureKey
            // disconnect
            queue.sync {
                if self.cometClient != nil {
                    self.cometClient?.disconnectFromServer()
                    self.cometClient = nil
                }
                self.isSubscribed = false
                self.isChatStarted = false
                self.session = nil
            }
            delegate.chatSessionEnded(serviceSettings.serviceName, chatId: chatId, secureKey: secureKey)
        } else {
            isChatStarted = true
        }
    }

    // MARK: - GFayeClientDelegate

    public func messageReceived(_ client: GFayeClient, messageDict: GFayeMessage, channel: String) {
        messageReceived(message: messageDict)
    }

    public func pongReceived(_ client: GFayeClient) {
        debugPrint("[ChatV2CometClient] pong")
    }
    public func connectedToServer(_ client: GFayeClient) {
        debugPrint("[ChatV2CometClient] connectedToServer")
    }

    public func disconnectedFromServer(_ client: GFayeClient) {
        debugPrint("[ChatV2CometClient] disconnectedFromServer")
        queue.sync {
            cometClient = nil
            isSubscribed = false
        }
    }

    public func connectionFailed(_ client: GFayeClient) {
        debugPrint("[ChatV2CometClient] connectionFailed")
        queue.sync {
            cometClient = nil
            isSubscribed = false
        }
        delegate.connectionError(self, error: GmsApiError.cometConnectFailed)
    }

    public func didSubscribeToChannel(_ client: GFayeClient, channel: String) {
        debugPrint("[ChatV2CometClient] didSubscribeToChannel")
        if channel == self.channel {
            queue.sync {
                isSubscribed = true
                while !pendingRequests.isEmpty {
                    let first = pendingRequests.removeFirst()
                    cometClient?.sendMessage(first.parameters, channel: self.channel)
                }
            }
        }
    }

    public func didUnsubscribeFromChannel(_ client: GFayeClient, channel: String) {
        debugPrint("[ChatV2CometClient] didUnsubscribeFromChannel")
        if channel == self.channel {
            queue.sync {
                isSubscribed = false
            }
        }
    }

    public func subscriptionFailedWithError(_ client: GFayeClient, error: SubscriptionError) {
        debugPrint("[ChatV2CometClient] subscriptionFailedWithError")
        queue.sync {
            cometClient = nil
            isSubscribed = false
        }
        delegate.connectionError(self, error: GmsApiError.cometClientError(error: error))
    }

    public func fayeClientError(_ client: GFayeClient, error: Error) {
        debugPrint("[ChatV2CometClient] fayeClientError")
        delegate.connectionError(self, error: GmsApiError.cometClientError(error: error))
    }
}

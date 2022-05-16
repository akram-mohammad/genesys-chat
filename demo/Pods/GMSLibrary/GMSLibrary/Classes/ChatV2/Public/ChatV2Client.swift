//
// ChatV2Client.swift
// GMSLibrary
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//

import Foundation

/**
  Chat V2 client protocol implemented by the delegate-based CometD client `ChatV2CometClient`.
 */
public protocol ChatV2Client {
    
    /**
      Chat session ID returned by GMS.
     */
    var chatId: String? { get }

    /**
      Chat host aliase used for the session.
     */
    var alias: String? { get }

    /**
      User ID used for the chat seesion.
     */
    var userId: String? { get }

    /**
      Secure key for the chat session.
     */
    var secureKey: String? { get }

    /**
      Whether the chat session is currently connected.
     */
    var isConnected: Bool { get }

    /**
      Creates a new instance of the chat client.
     
      - Parameters:
        - serviceSettings: GMS chat service configurations.
        - serverSettings: GMS server configurations.
        - userSettings: Current user information.
        - delegate: Delegate to handle events from chat.
     */
    init(serviceSettings: GmsServiceSettings,
         serverSettings: GmsServerSettings,
         userSettings: GmsUserSettings,
         delegate: ChatV2Delegate)

    /**
      Request a chat session using the Chat V2 API.
 
      - Parameters:
        - queue: Dispatch queue to perform the request.
        - subject: Subject of the chat session.
        - userData: Additional user data to associate with the chat session.
    */
    func requestChat(on queue: DispatchQueue?, subject: String?, userData: [String: String]) throws

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
    func sendMessage(on queue: DispatchQueue?, message: String, messageType: String?, transcriptPosition: Int?) throws

    /**
      Notifies the chat session the current user has started typing.
     
      - parameters:
        - queue: Dispatch queue to perform the request.
        - message: Message being typed
     
      - throws:
        - GmsApiError.chatSessionNotStarted if there are no active chat session.
     */
    func startTyping(on queue: DispatchQueue?, message: String?) throws

    /**
      Notifies the chat session the current user has stopped typing.
     
      - parameters:
          - queue: Dispatch queue to perform the request.
          - message: Message being typed
     
      - throws:
          - GmsApiError.chatSessionNotStarted if there are no active chat session.
     */
    func stopTyping(on queue: DispatchQueue?, message: String?) throws

    /// Sends a URL to the chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - url: URL to send
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    func pushUrl(on queue: DispatchQueue?, url: URL) throws

    /// Sends a custom notice to the chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - message: Content of the custom notice.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    func customNotice(on queue: DispatchQueue?, message: String?) throws

    /// Updates the nickname of the current user.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - nickname: new nickname.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    func updateNickname(on queue: DispatchQueue?, nickname: String) throws

    /// Updates the user data associated with the current session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///     - userData: new or updated user data.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    func updateData(on queue: DispatchQueue?, userData: [String: String]) throws

    /// Terminates the current chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    func disconnect(on queue: DispatchQueue?) throws

    /// Retrieves the file management limits imposed by the server.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to perform the request.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    func getFileLimits(on queue: DispatchQueue?) throws

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
    func uploadFile(
        on queue: DispatchQueue,
        fileURL: URL,
        fileDescription: String?,
        userData: [String: String]) throws -> String

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
    func uploadFile(
        on queue: DispatchQueue,
        fileName: String,
        mimeType: String,
        fileData: Data,
        fileDescription: String?,
        userData: [String: String]) throws -> String

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
    func downloadFile(on queue: DispatchQueue,
                      fileId: String) throws -> String

    /// Deletes a file from the chat session.
    ///
    /// - throws:
    ///     - GmsApiError.chatSessionNotStarted if there are no active chat session.
    ///
    /// - parameters:
    ///     - queue: Dispatch queue to use.
    ///     - fileId: ID of the file to be deleted.
    func deleteFile(on queue: DispatchQueue,
                    fileId: String) throws
}

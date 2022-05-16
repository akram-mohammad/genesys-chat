//
//  ChatV2Delegate.swift
//  GMSLibrary
//
//  Created by Cindy Wong on 2019-07-15.
//

import Foundation
import GFayeSwift

/// Chat V2 client delegate.
///
/// A controller of a Chat V2 session should implement this delegate
/// protocol.
public protocol ChatV2Delegate: AnyObject {
    /// This function is called when the chat session becomes active.
    /// This is the result of `requestChat` operation.
    ///
    /// - parameters:
    ///     - service: Name of the chat service.
    ///     - chatId: Chat session ID.
    ///     - userId: User ID for the current user assigned by the server.
    ///     - alias: Host alias assigned by the server.
    ///     - secureKey: Secure key assigned by the server.
    func chatSessionActive(_ service: String, chatId: String?, userId: String?, alias: String?, secureKey: String?)

    /// This function is called when the chat session has resumed.
    /// This is the result of `requestNotifications` operation.
    ///
    /// - parameters:
    ///     - service: Name of the chat service.
    ///     - chatId: Chat session ID.
    ///     - secureKey: Secure key assigned by the server.
    func chatSessionResumed(_ service: String, chatId: String?, secureKey: String?)

    /// This function is called when the chat session has ended.
    /// This could be the result of a `disconnect` operation by the user, or
    /// an action by the agent, or server terminating the session due to
    /// inactivity.
    ///
    /// - parameters:
    ///     - service: Name of the chat service.
    ///     - chatId: Chat session ID.
    ///     - secureKey: Secure key assigned by the server.
    func chatSessionEnded(_ service: String, chatId: String?, secureKey: String?)

    /// This function is called when a new message is received.
    /// The message could be sent by the current user or other parties, including
    /// the server.  The message may be of different types, such as a text chat
    /// message, a file attached to the chat session, participant joining or leaving,
    /// etc. See `ChatV2MessageType` for all the possible messages.
    func messageReceived(_ service: String, chatId: String?, secureKey: String?, message: ChatV2Message)

    /// This function is called when the result from the server cannot be parsed.
    func parsingError(_ service: String, message: [String: Any])

    /// This function is called when an error was received.
    func errorReceived(_ service: String, chatId: String?, error: Error)

    /// This function is called when there is a connection error.
    func connectionError(_ client: ChatV2CometClient, error: Error?)

    // MARK: - File Management

    /// This function is called when the file limits has been returned by the server.
    func fileLimitsReceived(_ service: String, chatId: String?, secureKey: String?, fileLimits: ChatV2FileLimits)

    /// This function is called when the request for file limits has failed.
    func fileLimitsFailed(_ service: String, chatId: String?, secureKey: String?, error: Error?)

    /// This function is called when the file upload request associated with `requestId`
    /// has successfully been uploaded.
    func fileUploaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String)

    /// This function is called when the file upload request associated with `requestId`
    /// has failed.
    func fileUploadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, error: Error?)

    /// This function is called when the file has been successfully downloaded.
    func fileDownloaded(_ service: String,
                        chatId: String?,
                        secureKey: String?,
                        requestId: String,
                        fileId: String,
                        fileURL: URL)

    /// This function is called when the file download has failed.
    func fileDownloadFailed(_ service: String,
                            chatId: String?,
                            secureKey: String?,
                            requestId: String,
                            fileId: String,
                            error: Error?)

    /// This function is called when the file has been successfully deleted.
    func fileDeleted(_ service: String, chatId: String?, secureKey: String?, fileId: String)

    /// This function is called when the file download has failed.
    func fileDeleteFailed(_ service: String, chatId: String?, secureKey: String?, fileId: String, error: Error?)
}

extension ChatV2Delegate {
    func chatSessionActive(_ service: String, chatId: String?, userId: String?, alias: String?, secureKey: String?) { }
    func chatSessionResumed(_ service: String, chatId: String?, secureKey: String?) { }
    func chatSessionEnded(_ service: String, chatId: String?, secureKey: String?) { }
    func messageReceived(_ service: String, chatId: String?, secureKey: String?, message: ChatV2Message) { }
    func parsingError(_ service: String, message: [String: Any]) { }
    func errorReceived(_ service: String, chatId: String?, error: Error) { }
    func connectionError(_ client: ChatV2CometClient, error: Error?) { }
    func fileLimitsReceived(_ service: String, chatId: String?, secureKey: String?, fileLimits: ChatV2FileLimits) { }
    func fileLimitsFailed(_ service: String, chatId: String?, secureKey: String?, error: Error?) { }
    func fileUploaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String) { }
    func fileUploadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, error: Error?) { }

    func fileDownloaded(_ service: String,
                        chatId: String?,
                        secureKey: String?,
                        requestId: String,
                        fileId: String,
                        fileURL: URL) { }
    
    func fileDownloadFailed(_ service: String,
                            chatId: String?,
                            secureKey: String?,
                            requestId: String,
                            fileId: String,
                            error: Error?) { }

    func fileDeleted(_ service: String, chatId: String?, secureKey: String?, fileId: String) { }
    func fileDeleteFailed(_ service: String, chatId: String?, secureKey: String?, fileId: String, error: Error?) { }
}

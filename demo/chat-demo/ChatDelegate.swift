//
//  ChatDelegate.swift
//  chat-demo

import UIKit
import GMSLibrary

// ChatV2Delegate implementation for CometD client only.
// The different functions will be called when the described event happens.
class ChatDelegate: ChatV2Delegate {

    var chatVC: ChatViewController?
    var appDelegate: AppDelegate?
    
    init() {
        self.appDelegate = (UIApplication.shared.delegate as! AppDelegate)
    }
    
    // Chat session has started successfully.
    func chatSessionActive(_ service: String, chatId: String?, userId: String?, alias: String?, secureKey: String?) {
        debugPrint("[ChatDelegate] chatSessionActive")
        if let vc = chatVC {
            vc.chatId = chatId
            vc.userId = userId
            vc.alias = alias
            vc.secureKey = secureKey
            vc.connected()
        }
    }
    
    // Chat session has resumed successfully.
    func chatSessionResumed(_ service: String, chatId: String?, secureKey: String?) {
        debugPrint("[ChatDelegate] chatSessionResumed")
        if let vc = chatVC {
            vc.chatId = chatId
            vc.secureKey = secureKey
            vc.resumed()
        }
    }
    
    // Chat session has ended.
    func chatSessionEnded(_ service: String, chatId: String?, secureKey: String?) {
        debugPrint("[ChatDelegate] chatSessionEnded")
        if let vc = chatVC {
            vc.ended()
        }
    }
    
    // A message is received. This could be an actual text message, or other types of notifications.
    // See ChatViewController.messageReceived() for different types of messages.
    func messageReceived(_ service: String, chatId: String?, secureKey: String?, message: ChatV2Message) {
        debugPrint("[ChatDelegate] messageReceived")
        if let vc = chatVC {
            vc.messageReceived(message)
        }
    }
    
    // When a message is received but GSMLibrary fails to parse it.
    func parsingError(_ service: String, message: [String : Any]) {
        debugPrint("[ChatDelegate] parsingError: \(message)")
        if let vc = chatVC {
            vc.parsingError()
        }
    }
    
    // When an error was received from chat.
    func errorReceived(_ service: String, chatId: String?, error: Error) {
        debugPrint("[ChatDelegate errorReceived: \(error)")
        if let vc = chatVC {
            vc.errorReceived()
        }
    }
    
    // When there is a connection error.
    func connectionError(_ client: ChatV2CometClient, error: Error?) {
        debugPrint("[ChatDelegate connectionError: \(String(describing: error))")
        if let vc = chatVC {
            vc.connectionError()
        }

    }
    
    // Result from ChatV2CometClient.getFileLimits() call.
    func fileLimitsReceived(_ service: String, chatId: String?, secureKey: String?, fileLimits: ChatV2FileLimits) {
        // not implemented in demo
    }
    
    // ChatV2CometClient.getFileLimits() failed.
    func fileLimitsFailed(_ service: String, chatId: String?, secureKey: String?, error: Error?) {
        // not implemented in demo
    }
    
    // Result from uploading a file using ChatV2CometClient.uploadFile()
    func fileUploaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String) {
        // not implemented in demo
    }

    // ChatV2CometClient.uploadFile() failed.
    func fileUploadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, error: Error?) {
        // not implemented in demo
    }
    
    // Result from downloading a files using ChatV2CometClient.downloadFile()
    func fileDownloaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, fileURL: URL) {
        // not implemented in demo
    }
    
    // ChatV2CometClient.downloadFile() failed.
    func fileDownloadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, error: Error?) {
        // not implemented in demo
    }
    
    // Result from deleting a file using ChatV2CometClient.deleteFile()
    func fileDeleted(_ service: String, chatId: String?, secureKey: String?, fileId: String) {
        // not implemented in demo
    }
    
    // ChatV2CometClient.deleteFile() failed.
    func fileDeleteFailed(_ service: String, chatId: String?, secureKey: String?, fileId: String, error: Error?) {
        // not implemented in demo
    }
    
    
}

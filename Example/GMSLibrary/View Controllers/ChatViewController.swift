//
// ChatViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary
import UIKit

class ChatViewController : UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ChatV2Delegate, SettingsUpdateDelegate {
    let chatSessionQueue = DispatchQueue(label: "com.genesys.gms.chatviewcontroller", qos: .default)
    
    var appDelegate: AppDelegate?

    var usingComet: Bool = false
    
    var cometClient: ChatV2CometClient?
    var chatClient: ChatV2PromiseApiClient?

    var chatConnectVC : ChatConnectViewController?

    var fileLimits: ChatV2FileLimits?

    var chatId: String?
    var userId: String?
    var alias: String?
    var secureKey: String?
    var refreshTimer: RepeatingTimer?

    var messages = [ChatV2Message]()
    var transcriptPosition = 0
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var chatMessagesTableView: UITableView!
    @IBOutlet weak var startChatButton: UIBarButtonItem!
    @IBOutlet weak var endChatButton: UIBarButtonItem!
    @IBOutlet weak var messageTextField: UITextField!
//    @IBOutlet weak var attachmentButton: UIButton!  // TODO
    @IBOutlet weak var sendMessageButton: UIButton!

    @IBAction func endChatPressed(_ sender: Any) {
        print("[ChatViewController] endChatPressed")
        messageTextField.resignFirstResponder()
        let k = chatSessionQueue.sync { self.secureKey }
        guard let secureKey = k else {
            print("[ChatViewController] chat not connected; returning")
            return
        }
        let alert = UIAlertController(title: "End Chat?", message: "Are you sure shou want to end this chat session?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Chat", style: .destructive, handler: { _ in
                self.statusLabel.text = "Ending chat session..."
                self.activityIndicator.startAnimating()
            if self.usingComet {
                self.endCometChat()
            } else {
                self.endPromiseChat(secureKey: secureKey)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // TODO
    @IBAction func attachmentPressed(_ sender: Any) {
        print("[ChatViewController] attachmentPressed")
    }
    
    @IBAction func sendMessagePressed(_ sender: Any) {
        print("[ChatViewController] sendMessagePressed")
        if usingComet {
            if let client = cometClient, let message = messageTextField.text, !message.isEmpty {
                do {
                    try client.sendMessage(on: .global(qos: .userInitiated), message: message)
                } catch {
                    let alert = UIAlertController(title: "Send Message Failed",
                                                  message: "The message cannot be sent due to error: \(error)",
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            chatSessionQueue.sync {
                if let client = chatClient, let secureKey = secureKey, let message = messageTextField.text, !message.isEmpty {
                    let promise = client.sendMessage(on: .global(qos: .userInitiated),
                                                     chatId: chatId!,
                                                     userId: userId,
                                                     alias: alias,
                                                     secureKey: secureKey,
                                                     message: message,
                                                     transcriptPosition: transcriptPosition)
                    promise.timeout(30).then { response in
                        self.statusLabel.text = "Message Sent"
                        self.messageTextField.text = ""
                        self.updateFromResponse(response)
                    }.catch { error in
                        let alert = UIAlertController(title: "Send Message Failed",
                                                      message: "The message cannot be sent due to error: \(error)",
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("[ChatViewController] prepare segue \(segue)")
        let destination = segue.destination
        if destination is ChatConnectViewController {
            let vc = destination as! ChatConnectViewController
            vc.chatVC = self
            self.chatConnectVC = vc
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = AppDelegate.shared
        appDelegate!.addSettingsUpdateDelegate(delegate: self)
        settingsUpdated()
    
        // TODO display messages
        chatMessagesTableView.dataSource = self
        chatMessagesTableView.delegate = self
        messageTextField.delegate = self
        
        usingComet = appDelegate?.chatServiceSettings?.useCometClient ?? true
        
        if isConnected() {
            startChatButton.isEnabled = false
            endChatButton.isEnabled = true
            messageTextField.isEnabled = true
//            attachmentButton.isEnabled = true
            sendMessageButton.isEnabled = true
            chatMessagesTableView.reloadData()
            chatMessagesTableView.scrollToBottom()
        } else {
            startChatButton.isEnabled = false
            endChatButton.isEnabled = false
            messageTextField.isEnabled = false
//            attachmentButton.isEnabled = false
            sendMessageButton.isEnabled = false
        
            performSegue(withIdentifier: "showConnectChatSegue", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isConnected() {
            startChatButton.isEnabled = false
            endChatButton.isEnabled = true
            messageTextField.isEnabled = true
            //            attachmentButton.isEnabled = true
            sendMessageButton.isEnabled = true
            chatMessagesTableView.reloadData()
            chatMessagesTableView.scrollToBottom()
        }

        // only if chat is not started
        if usingComet, let client = cometClient, client.isBackground {
            client.requestNotifications(
                on: .global(qos: .utility),
                chatId: self.chatId!,
                userId: self.userId!,
                alias: self.alias!,
                secureKey: self.secureKey!,
                transcriptPosition: self.transcriptPosition)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        debugPrint("[ChatViewController] viewWillDisappear")
        // put chat on sleep
        if usingComet && isConnected(), let client = cometClient {
            do {
                try client.background(on: .global(qos: .userInitiated), transcriptPosition: transcriptPosition)
            } catch {
                print("[ChatViewController] Chat session cannot be put in the background")
            }
        }
    }

    func isConnected() -> Bool {
        if !usingComet {
            let k = chatSessionQueue.sync { self.secureKey }
            return k != nil
        }
        if let client = cometClient {
            return client.isConnected
        }
        return false
    }
    
    func isBackground() -> Bool {
        if usingComet, let client = cometClient {
            return client.isBackground
        }
        return false
    }
    
    func chatEnded() {
        debugPrint("[ChatViewController] chatEnded")
        if let timer = refreshTimer {
            timer.suspend() // don't refresh chat again
            refreshTimer = nil
        }
        
        let alert = UIAlertController(title: "Chat Ended", message: "The chat session has ended.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.chatSessionQueue.sync {
                self.endChatButton.isEnabled = false
                self.sendMessageButton.isEnabled = false
                self.statusLabel.text = "Disconnected"
                self.messageTextField.isEnabled = false
                self.startChatButton.isEnabled = true
                self.alias = nil
                self.userId = nil
                self.chatId = nil
                self.secureKey = nil
                self.transcriptPosition = 0
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func connected() {
        debugPrint("[ChatViewController] connected")
        if isConnected() {
            startChatButton.isEnabled = false
            endChatButton.isEnabled = true
            messageTextField.isEnabled = true
            //            attachmentButton.isEnabled = true
            sendMessageButton.isEnabled = true
            statusLabel.text = "Connected"
        } else {
            startChatButton.isEnabled = false
            endChatButton.isEnabled = false
            messageTextField.isEnabled = false
            //            attachmentButton.isEnabled = false
            sendMessageButton.isEnabled = false
        }
        chatMessagesTableView.reloadData()
        chatMessagesTableView.scrollToBottom()

        // add refresh delay
        if !usingComet {
            delayRefresh()
        }
    }

    func endCometChat() {
        debugPrint("[ChatViewController] endCometChat")
        if let client = cometClient {
            do {
                try client.disconnect(on: .global(qos: .userInitiated))
            } catch {
                let alert = UIAlertController(title: "Chat Cannot Be Ended",
                                              message: "The chat session cannot be ended due to error: \(error)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func endPromiseChat(secureKey: String) {
        debugPrint("[ChatViewController] endPromiseChat")
        let promise = self.chatClient!.disconnect(on: .global(qos: .userInitiated),
                                                  chatId: self.chatId!,
                                                  userId: self.userId!,
                                                  alias: self.alias!,
                                                  secureKey: secureKey)
        promise.timeout(30).then { response in
            self.updateFromResponse(response)
            if !(response.chatEnded ?? false) {
                let alert = UIAlertController(title: "Chat Cannot Be Ended",
                                              message: "The chat session cannot be ended due to unknown server error.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            }.catch { error in
                let alert = UIAlertController(title: "Chat Cannot Be Ended",
                                              message: "The chat session cannot be ended due to error: \(error)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateFromResponse(_ response: ChatV2Response) {
        for msg in response.messages {
            messageReceived(message: msg)
        }
        if let nextPos = response.nextPosition {
            chatSessionQueue.sync { self.transcriptPosition = nextPos }
        }
        if response.chatEnded ?? false {
            self.chatEnded()
        } else {
            chatSessionQueue.sync {
                self.chatId = response.chatId
                self.userId = response.userId
                self.secureKey = response.secureKey
                self.alias = response.alias
            }
        }
        self.chatMessagesTableView.reloadData()
        chatMessagesTableView.scrollToBottom()
    }

    func delayRefresh() {
        let k = chatSessionQueue.sync { self.secureKey }
        if let secureKey = k {
            refreshTimer = RepeatingTimer(timeInterval: 5)
            refreshTimer!.eventHandler = {
                debugPrint("[ChatViewController] refreshing chat")
                let promise = self.chatSessionQueue.sync { self.chatClient!.refreshChat(
                    on: .global(qos: .utility),
                    chatId: self.chatId!,
                    userId: self.userId,
                    alias: self.alias,
                    secureKey: secureKey,
                    transcriptPosition: self.transcriptPosition) }
                promise.timeout(30).then { response in
                    debugPrint("[ChatViewController] new messages received: \(response.messages)")
                    self.updateFromResponse(response)
                    }.catch { error in
                        let alert = UIAlertController(title: "Refresh Chat Failed",
                                                      message: "The chat session cannot be refreshed due to error: \(error)",
                            preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                }
            }
            refreshTimer!.resume()
        }
    }
    
    // MARK: - UITableViewController
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatMessagesTableView.dequeueReusableCell(withIdentifier: "messageCell") as! ChatMessageTableViewCell
        let row = indexPath.row
        if row < 0 || row >= messages.count {
            // WARN and return
        }
        let message = messages[row]
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        let ts = formatter.string(from: message.utcTime)
        let color: UIColor
        if message.from.type.uppercased() == "CLIENT" {
            color = UIColor.init(red: 0, green: 0.23, blue: 0.54, alpha: 1)
        } else {
            color = UIColor.init(red: 0.77, green: 0.24, blue: 0.16, alpha: 1)
        }
        let sender = NSMutableAttributedString(string: "[\(ts)] \(message.from.nickname): ")
        sender.addAttribute(.strokeColor, value: color, range: NSMakeRange(0, sender.length))
        sender.addAttribute(.foregroundColor, value: color, range: NSMakeRange(0, sender.length))
        cell.senderLabel.attributedText = sender

        var msgStr: NSMutableAttributedString
        switch message.type {
        case .participantJoined:
            msgStr = NSMutableAttributedString(string: "joined the chat session")
            let range = NSMakeRange(0, msgStr.length)
            msgStr.addAttribute(.font, value: UIFont(name: "Roboto-Italic", size: 12)!, range: range)
            msgStr.addAttribute(.strokeColor, value: color, range: range)
            msgStr.addAttribute(.foregroundColor, value: color, range: range)
        case .participantLeft:
            msgStr = NSMutableAttributedString(string: "left the chat session")
            let range = NSMakeRange(0, msgStr.length)
            msgStr.addAttribute(.font, value: UIFont(name: "Roboto-Italic", size: 12)!, range: range)
            msgStr.addAttribute(.strokeColor, value: color, range: range)
            msgStr.addAttribute(.foregroundColor, value: color, range: range)
        case .message:
            msgStr = NSMutableAttributedString(string: message.text!)
            let range = NSMakeRange(0, msgStr.length)
            msgStr.addAttribute(.font, value: UIFont(name: "Roboto-Regular", size: 12)!, range: range)
            msgStr.addAttribute(.strokeColor, value: color, range: range)
            msgStr.addAttribute(.foregroundColor, value: color, range: range)
        case .pushUrl:
            msgStr = NSMutableAttributedString()
            let str1 = NSMutableAttributedString(string: "sent an URL: ")
            str1.addAttributes([
                .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                .underlineColor: color,
                .font: UIFont(name: "Roboto-Italic", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str1.length))
            let str2 = NSMutableAttributedString(string: message.text!)
            str2.addAttributes([
                .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                .underlineColor: color,
                .font: UIFont(name: "Roboto-Regular", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str2.length))
            msgStr.append(str1)
            msgStr.append(str2)
        case .nicknameUpdated:
            msgStr = NSMutableAttributedString(string: "changed name to \"\(message.from.nickname)\"")
            let range = NSMakeRange(0, msgStr.length)
            msgStr.addAttribute(.font, value: UIFont(name: "Roboto-Italic", size: 12)!, range: range)
            msgStr.addAttribute(.strokeColor, value: color, range: range)
            msgStr.addAttribute(.foregroundColor, value: color, range: range)
        case .fileUploaded:
            msgStr = NSMutableAttributedString()
            if let filename = message.userData["file-name"] {
                let str1 = NSMutableAttributedString(string: "uploaded a file: ")
                    str1.addAttributes([
                    .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                    .underlineColor: color,
                    .font: UIFont(name: "Roboto-Italic", size: 12)!,
                    .strokeColor: color,
                    .foregroundColor: color
                    ], range: NSMakeRange(0, str1.length))
                msgStr.append(str1)
                let str2 = NSMutableAttributedString(string: filename)
                str2.addAttributes([
                    .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                    .underlineColor: color,
                    .font: UIFont(name: "Roboto-Regular", size: 12)!,
                    .strokeColor: color,
                    .foregroundColor: color
                    ], range: NSMakeRange(0, str2.length))
                msgStr.append(str2)
            } else {
                let str1 = NSMutableAttributedString(string: "uploaded a file")
                str1.addAttributes([
                    .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                    .underlineColor: color,
                    .font: UIFont(name: "Roboto-Italic", size: 12)!,
                    .strokeColor: color,
                    .foregroundColor: color
                    ], range: NSMakeRange(0, str1.length))
                msgStr.append(str1)
            }
        case .fileDeleted:
            msgStr = NSMutableAttributedString(string: "deleted a file")
            let range = NSMakeRange(0, msgStr.length)
            msgStr.addAttribute(.font, value: UIFont(name: "Roboto-Italic", size: 12)!, range: range)
            msgStr.addAttribute(.strokeColor, value: color, range: range)
            msgStr.addAttribute(.foregroundColor, value: color, range: range)
        case .customNotice:
            msgStr = NSMutableAttributedString()
            let str1 = NSMutableAttributedString(string: "sent a custom notice: ")
            str1.addAttributes([
                .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                .underlineColor: color,
                .font: UIFont(name: "Roboto-Italic", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str1.length))
            let str2 = NSMutableAttributedString(string: message.text!)
            str2.addAttributes([
                .font: UIFont(name: "Roboto-Bold", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str2.length))
            msgStr.append(str1)
            msgStr.append(str2)
        case .notice:
            msgStr = NSMutableAttributedString()
            let str1 = NSMutableAttributedString(string: "sent a notice: ")
            str1.addAttributes([
                .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                .underlineColor: color,
                .font: UIFont(name: "Roboto-Italic", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str1.length))
            let str2 = NSMutableAttributedString(string: message.text!)
            str2.addAttributes([
                .font: UIFont(name: "Roboto-Bold", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, str2.length))
            msgStr.append(str1)
            msgStr.append(str2)
        default:
            msgStr = NSMutableAttributedString(string: "unknown message type received")
            msgStr.addAttributes([
                .underlineStyle: NSUnderlineStyle.styleNone.rawValue,
                .underlineColor: color,
                .font: UIFont(name: "Roboto-Italic", size: 12)!,
                .strokeColor: color,
                .foregroundColor: color
                ], range: NSMakeRange(0, msgStr.length))
        }
        cell.messageLabel.attributedText = msgStr
        // set cell height
        cell.messageLabel.frame.size.height = cell.messageLabel.optimalHeight
        
        cell.frame.size.height =
            cell.senderLabel.frame.size.height +
            cell.messageLabel.frame.size.height +
            8 + 8
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        if messages[row].type == .fileUploaded {
            // TODO download the file
            
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendMessagePressed(textField)
        return true
    }

    // MARK: - ChatV2Delegate
    
    func chatSessionActive(_ service: String, chatId: String?, userId: String?, alias: String?, secureKey: String?) {
        debugPrint("[ChatViewController] chatSessionActive")
        messages.removeAll()
        self.chatId = chatId
        self.userId = userId
        self.alias = alias
        self.secureKey = secureKey
        if let chatConnectVC = chatConnectVC {
            chatConnectVC.connected()
        }
    }

    func chatSessionResumed(_ service: String, chatId: String?, secureKey: String?) {
        debugPrint("[ChatViewController] chatSessionResumed")
        self.chatId = chatId
        self.secureKey = secureKey
        startChatButton.isEnabled = false
        endChatButton.isEnabled = true
        messageTextField.isEnabled = true
        //            attachmentButton.isEnabled = true
        sendMessageButton.isEnabled = true
        statusLabel.text = "Resumed"
    }

    func chatSessionEnded(_ service: String, chatId: String?, secureKey: String?) {
        debugPrint("[ChatViewController] chatSessionEnded")
        self.chatEnded()
    }
    
    func messageReceived(_ service: String = "", chatId: String? = nil, secureKey: String? = nil, message: ChatV2Message) {
        debugPrint("[ChatViewController] messageReceived")
        if message.type != .typingStarted &&
            message.type != .typingStopped &&
            !self.messages.contains(where: { (m) -> Bool in
                    m.index == message.index
            }) {
            debugPrint("[ChatViewController] append message \(message)")
            // clear text field from self
            if message.from.type.uppercased() == "CLIENT" && message.type == .message {
                messageTextField.text = ""
            }
            if let index = message.index, index >= transcriptPosition {
                transcriptPosition = index + 1
            }
            self.messages.append(message)
            chatMessagesTableView.reloadData()
            chatMessagesTableView.scrollToBottom()
        }
    }
    
    func parsingError(_ service: String, message: [String : Any]) {
        debugPrint("[ChatViewController] parsingError")
        let alert = UIAlertController(title: "Parsing Error",
                                      message: "Faile to parse message: \(message)",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func errorReceived(_ service: String, chatId: String?, error: Error) {
        debugPrint("[ChatViewController] errorReceived")
        let alert = UIAlertController(title: "Error Received",
                                      message: "Error received from server: \(error)",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func connectionError(_ client: ChatV2CometClient, error: Error?) {
        debugPrint("[ChatViewController] connectionError")
        if let chatConnectVC = chatConnectVC {
            chatConnectVC.connectFailed(error: error)
        }
    }
    
    func fileLimitsReceived(_ service: String, chatId: String?, secureKey: String?, fileLimits: ChatV2FileLimits) {
        debugPrint("[ChatViewController] fileLimitsReceived")
    }
    
    func fileLimitsFailed(_ service: String, chatId: String?, secureKey: String?, error: Error?) {
        debugPrint("[ChatViewController] fileLimitsFailed")
    }
    
    func fileUploaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String) {
        debugPrint("[ChatViewController] fileUploaded")
    }
    
    func fileUploadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, error: Error?) {
        debugPrint("[ChatViewController] fileUploadFailed")
    }
    
    func fileDownloaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, fileURL: URL) {
        debugPrint("[ChatViewController] fileDownloaded")
    }
    
    func fileDownloadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, error: Error?) {
        debugPrint("[ChatViewController] fileDownloadFailed")
    }
    
    func fileDeleted(_ service: String, chatId: String?, secureKey: String?, fileId: String) {
        debugPrint("[ChatViewController] fileDeleted")
    }
    
    func fileDeleteFailed(_ service: String, chatId: String?, secureKey: String?, fileId: String, error: Error?) {
        debugPrint("[ChatViewController] connectionError")
    }

    // MARK: - SettingsUpdateDelegate
    func settingsUpdated() {
        // update clients
        if isConnected() {
            let alert = UIAlertController(
                title: "Settings Updated",
                message: "Settings have been updated. Current chat session will end. Please start a new chat session.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if self.usingComet {
                    self.endCometChat()
                } else {
                    let k = self.chatSessionQueue.sync { self.secureKey }
                    if let key = k {
                        self.endPromiseChat(secureKey: key)
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
            usingComet = appDelegate?.chatServiceSettings?.useCometClient ?? true
        }
        chatClient = ChatV2PromiseApiClient(serviceSettings: appDelegate!.chatServiceSettings!,
                                            serverSettings: appDelegate!.serverSettings!,
                                            userSettings: appDelegate!.userSettings!)
        var connectionTypes: [CometConnectionType] = [.longPolling, .callbackPolling, .iFrame]
        if !appDelegate!.chatServiceSettings!.enableWebsocket {
            connectionTypes.append(.webSocket)
        }
        do {
        cometClient = try ChatV2CometClient(serviceSettings: appDelegate!.chatServiceSettings!,
                                        serverSettings: appDelegate!.serverSettings!,
                                        userSettings: appDelegate!.userSettings!,
                                        allowedConnectionTypes: connectionTypes,
                                        delegate: self)
        } catch {
            debugPrint("[ChatViewController] This should not happen because connectionTypes is never empty")
        }
    }
}

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
/// Copied from https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
class RepeatingTimer {
    
    let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRows(inSection: sections - 1)
        if (rows > 0) {
            let indexPath = IndexPath(row: rows - 1, section: sections - 1)
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

//
//  ChatViewController.swift
//  chat-demo

import Foundation
import GMSLibrary
import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate {
    let chatSessionQueue = DispatchQueue(label: "com.genesys.gms.chatviewcontroller", qos: .default)

    var transcript = ""
    var appDelegate: AppDelegate?
    
    var chatId: String?
    var userId: String?
    var alias: String?
    var secureKey: String?
    var messages = [ChatV2Message]()
    var transcriptPosition = 0
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var chatSessionTextView: UITextView!

    // Sends message in messageTextField to GMS chat session
    @IBAction func sendButton(_ sender: Any) {
        if let client = appDelegate!.cometClient, let message = messageTextField.text, !message.isEmpty {
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
    }
    
    // Terminates chat session
    @IBAction func endChatButton(_ sender: Any) {
        print("[ChatViewController] endChatPressed")
        messageTextField.resignFirstResponder()
        let k = chatSessionQueue.sync { self.secureKey }
        guard let _ = k else {
            print("[ChatViewController] chat not connected; returning")
            return
        }
        let alert = UIAlertController(title: "End Chat?", message: "Are you sure shou want to end this chat session?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Chat", style: .destructive, handler: { _ in
            self.statusLabel.text = "Ending chat session..."
            self.endCometChat()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        messageTextField.delegate = self
        appDelegate!.chatDelegate!.chatVC = self
    }

    // If the view becomes visible again after a chat session is sent to the background,
    // send requestNotifications to resume session actively
    override func viewWillAppear(_ animated: Bool) {
        if let client = appDelegate!.cometClient, client.isBackground {
            client.requestNotifications(
                on: .global(qos: .utility),
                chatId: self.chatId!,
                userId: self.userId!,
                alias: self.alias!,
                secureKey: self.secureKey!,
                transcriptPosition: self.transcriptPosition)
        }
    }
    
    // If the view disappears and the chat session is still connected, puts chat session
    // on sleep
    override func viewWillDisappear(_ animated: Bool) {
        debugPrint("[ChatViewController] viewWillDisappear")
        // put chat on sleep
        if isConnected(), let client = appDelegate!.cometClient {
            do {
                try client.background(on: .global(qos: .userInitiated), transcriptPosition: transcriptPosition)
            } catch {
                print("[ChatViewController] Chat session cannot be put in the background")
            }
        }
    }
    
    func isConnected() -> Bool {
        if let client = appDelegate!.cometClient {
            return client.isConnected
        }
        return false
    }
    
    func isBackground() -> Bool {
        if let client = appDelegate!.cometClient {
            return client.isBackground
        }
        return false
    }
    
    // closes the current chat session
    func endCometChat() {
        debugPrint("[ChatViewController] endCometChat")
        if let client = appDelegate!.cometClient {
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
    
    // appends to the transcript showing in a very simple text view
    func addMessage(_ message: ChatV2Message) {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        let ts = formatter.string(from: message.utcTime)
        var str = "[\(ts)] \(message.from.nickname)"
        switch message.type {
        case .participantJoined:
            str = str + " <joined session>"
        case .participantLeft:
            str = str + " <left session>"
        case .message:
            str = str + ": \(message.text!)"
        case .pushUrl:
            str = str + " <sent URL>: \(message.text!)"
        case .nicknameUpdated:
            str = "[\(ts)] <changed nickname>: \(message.from.nickname)"
        case .fileUploaded:
            if let filename = message.userData["file-name"] {
                str = str + " <uploaded a file>: \(filename))"
            } else {
                str = str + " <uploaded a file>"
            }
        case .fileDeleted:
            str = str + " <deleted a file>"
        case .customNotice:
            str = str + " <sent a custom notice>: \(message.text!)"
        case .notice:
            str = str + " <sent a notice>: \(message.text!)"
        default:
            str = str + " <unknown message type received>"
        }
        transcript = transcript + "\(str)\n"
        chatSessionTextView.reloadInputViews()
    }
    
    // MARK: called by ChatDelegate
    func connected() {
        statusLabel.text = "Chat session started"
        transcript = ""
        chatSessionTextView.reloadInputViews()
    }
    
    func resumed() {
        statusLabel.text = "Chat session resumed"
    }
    
    func ended() {
        statusLabel.text = "Chat session ended"
        messageTextField.text = ""
        messageTextField.isEnabled = false
    }
    
    func messageReceived(_ message: ChatV2Message) {
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
            self.addMessage(message)
        }
        statusLabel.text = ""
    }
    
    func parsingError() {
        transcript = transcript + "<PARSING ERROR ENCOUNTERED>\n"
    }
    
    func errorReceived() {
        transcript = transcript + "<ERROR RECEIVED>\n"
    }
    
    func connectionError() {
        transcript = transcript + "<CONNECTION ERROR>\n"
    }
}

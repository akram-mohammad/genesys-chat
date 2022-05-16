//
// ChatConnectViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-19
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary
import UIKit
import Promises

class ChatConnectViewController: UIViewController, UITextFieldDelegate {
    
    var chatVC: ChatViewController?
    
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func startSessionPressed(_ sender: Any) {
        debugPrint("[ChatConnectViewController] startSessionPressed")
        startSessionButton.isEnabled = false
        subjectTextField.isEnabled = false
        activityIndicator.startAnimating()

        let subject: String?
        if let subjectStr = subjectTextField.text, !subjectStr.isEmpty {
            subject = subjectStr
        } else {
            subject = nil
        }

        if let chatVC = chatVC {
            if !chatVC.usingComet {
                if let client = chatVC.chatClient {
                    let promise = client.requestChat(on: .global(qos: .userInitiated), subject: subject)
                    promise.timeout(30).then { response in
                        chatVC.messages.removeAll()
                        chatVC.updateFromResponse(response)
                        self.connected()
                    }.catch { error in
                        self.connectFailed(error: error)
                    }
                } else {
                    debugPrint("[ChatConnectViewController] client not initialized; request ignored")
                }
            } else {
                debugPrint("[ChatConnectViewController] use comet")
                if let client = chatVC.cometClient {
                    client.requestChat(on: .global(qos: .userInitiated), subject: subject)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("[ChatConnectViewController] viewDidLoad")
        startSessionButton.isEnabled = true
        subjectTextField.isEnabled = true
        subjectTextField.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        debugPrint("[ChatConnectViewController] viewDidDisappear")
        super.viewDidDisappear(animated)
    }
    
    func connectFailed(error: Error?) {
        debugPrint("[ChatConnectViewController] connectFailed")
        activityIndicator.stopAnimating()
        let message: String
        if let error = error {
            message = "Error received: \(String(describing: error))"
        } else {
            message = "Unknown error received"
        }
        let alert = UIAlertController(
            title: "Failed to Start Chat",
            message: message,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.startSessionButton.isEnabled = true
            self.subjectTextField.isEnabled = true
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func connected() {
        debugPrint("[ChatConnectViewController] connected")
        activityIndicator.stopAnimating()
        self.dismiss(animated: true, completion: nil)
        chatVC!.connected()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        startSessionPressed(textField)
        return true
    }
}

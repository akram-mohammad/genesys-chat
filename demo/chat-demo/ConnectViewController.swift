//
//  ViewController.swift
//  chat-demo

import Foundation
import UIKit

import GMSLibrary
import Promises

class ConnectViewController: UIViewController {
    
    var appDelegate: AppDelegate?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var subjectField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    @IBAction func startChatButton(_ sender: Any) {
        debugPrint("[ConnectViewController] Start Chat pressed")
        let name = nameField.text
        let email = emailField.text
        let subject = subjectField.text

        appDelegate!.connect(nickname: name, email: email, subject: subject, connectViewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("[ConnectViewController] viewDidLoad")
    }

    func connected() {
        debugPrint("[ConnectViewController] connected")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "chatViewController") as? UIViewController {
            self.present(viewController, animated: true, completion: nil)
        }
    }
}


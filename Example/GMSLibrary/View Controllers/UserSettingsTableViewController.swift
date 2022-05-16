//
//  UserSettingsViewController.swift
//  GMSLibrary_Example
//
//  Created by Cindy Wong on 2019-07-15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import GMSLibrary

class UserSettingsTableViewController : UITableViewController, UITextFieldDelegate {
    var appDelegate = AppDelegate.shared
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBAction func SavePressed(_ sender: Any) {
        if appDelegate.userSettings == nil {
            appDelegate.userSettings = GmsUserSettings()
        }
        appDelegate.userSettings?.phoneNumber = phoneNumberTextField.text
        appDelegate.userSettings?.firstName = firstNameTextField.text
        appDelegate.userSettings?.lastName = lastNameTextField.text
        appDelegate.userSettings?.nickname = nicknameTextField.text
        appDelegate.userSettings?.email = emailTextField.text
        
        phoneNumberTextField.resignFirstResponder()
        firstNameTextField.resignFirstResponder()
        lastNameTextField.resignFirstResponder()
        nicknameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        
        // save preferences
        appDelegate.savePreferences()
        let alert = UIAlertController(title: "User Settings Saved", message: "The user settings has been saved.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate.userSettingsViewController = self
        if let userSettings = appDelegate.userSettings {
            phoneNumberTextField.text = userSettings.phoneNumber
            firstNameTextField.text = userSettings.firstName
            lastNameTextField.text = userSettings.lastName
            nicknameTextField.text = userSettings.nickname
            emailTextField.text = userSettings.email
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case phoneNumberTextField:
            firstNameTextField.becomeFirstResponder()
        case firstNameTextField:
            lastNameTextField.becomeFirstResponder()
        case lastNameTextField:
            nicknameTextField.becomeFirstResponder()
        case nicknameTextField:
            emailTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

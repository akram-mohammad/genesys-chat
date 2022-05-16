//
//  AppSettingsTableViewController.swift
//  GMSLibrary_Example
//
//  Created by Cindy Wong on 2019-07-15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import GMSLibrary

class AppSettingsTableViewController: UITableViewController, UITextFieldDelegate {
    var appDelegate: AppDelegate?
    
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var appTextField: UITextField!
    @IBOutlet weak var useSecureProtocolSwitch: UISwitch!

    @IBOutlet weak var useBasicAuthSwitch: UISwitch!
    @IBOutlet weak var authUserTextField: UITextField!
    @IBOutlet weak var authPasswordTextField: UITextField!
    @IBOutlet weak var authPasswordTableCell: UITableViewCell!
    @IBOutlet weak var authUserTableCell: UITableViewCell!

    @IBOutlet weak var gmsUserTextField: UITextField!
    @IBOutlet weak var apiKeyTextField: UITextField!
    
    @IBOutlet weak var allowPushSwitch: UISwitch!
    @IBOutlet weak var pushDebugSwitch: UISwitch!
    @IBOutlet weak var pushLanguageTextField: UITextField!
    @IBOutlet weak var pushProviderTextField: UITextField!
    
    @IBOutlet weak var callbackServiceTextField: UITextField!
    @IBOutlet weak var callbackTargetTextField: UITextField!
    @IBOutlet weak var chatServiceTextField: UITextField!
    @IBOutlet weak var useCometSwitch: UISwitch!
    @IBOutlet weak var enableWebsocketSwitch: UISwitch!
    
    
    @IBAction func useCometSwitchChanged(_ sender: Any) {
        enableWebsocketSwitch.isEnabled = useCometSwitch.isOn
    }
    
    @IBAction func useBasicAuthSwitchChanged(_ sender: Any) {
        enableBasicAuth(useBasicAuthSwitch.isOn)
    }
    
    @IBAction func allowPushSwitchChanged(_ sender: Any) {
        enablePush(allowPushSwitch.isOn)
    }
    
    @IBAction func SavePressed(_ sender: Any) {
        guard let appDelegate = appDelegate else {
                print("[AppSettingsTableViewController] settings missing; returning")
                return
        }
        hostTextField.resignFirstResponder()
        portTextField.resignFirstResponder()
        appTextField.resignFirstResponder()
        authUserTextField.resignFirstResponder()
        authPasswordTextField.resignFirstResponder()
        gmsUserTextField.resignFirstResponder()
        apiKeyTextField.resignFirstResponder()
        pushLanguageTextField.resignFirstResponder()
        pushProviderTextField.resignFirstResponder()
        callbackServiceTextField.resignFirstResponder()
        callbackTargetTextField.resignFirstResponder()
        chatServiceTextField.resignFirstResponder()
        let hostStr = hostTextField.text ?? ""
        let portStr = portTextField.text ?? ""
        let appStr = appTextField.text ?? ""
        let authUserStr = authUserTextField.text ?? ""
        let authPasswordStr = authPasswordTextField.text ?? ""
        let gmsUserStr = gmsUserTextField.text ?? ""
        let apiKeyStr = apiKeyTextField.text ?? ""
        let pushLangStr = pushLanguageTextField.text ?? ""
        let pushProviderStr = pushProviderTextField.text ?? ""
        let callbackStr = callbackServiceTextField.text ?? ""
        let targetStr = callbackTargetTextField.text ?? ""
        let chatStr = chatServiceTextField.text ?? ""
        
        let newAuthSettings: GmsAuthSettings
        let newPushSettings: GmsPushNotificationSettings
        if useBasicAuthSwitch.isOn {
            newAuthSettings = GmsAuthSettings.basic(user: authUserStr, password: authPasswordStr)
        } else {
            newAuthSettings = GmsAuthSettings.none
        }
        if allowPushSwitch.isOn {
            newPushSettings = GmsPushNotificationSettings.fcm(appDelegate.fcmToken, debug: pushDebugSwitch.isOn, language: pushLangStr, provider: pushProviderStr)
        } else {
            newPushSettings = GmsPushNotificationSettings.none
        }
        
        var port: Int? = nil
        if !portStr.isEmpty {
            port = Int(portStr)
            if port == nil {
                let alert = UIAlertController(title: "Invalid port number", message: "Port \(portStr) is not a valid number", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return
            }
        }

        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: hostStr, port: port, app: appStr, secureProtocol: useSecureProtocolSwitch.isOn, gmsUser: gmsUserStr, apiKey: apiKeyStr, authSettings: newAuthSettings, pushSettings: newPushSettings)
        } catch GmsApiError.missingGmsSettingsValue(let key) {
            let alert = UIAlertController(title: "Missing Settings", message: "Required settings \"\(key)\" is not set" , preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        } catch GmsApiError.invalidParameter(let key, let value) {
            let alert = UIAlertController(title: "Invalid Settings", message: "\"\(value ?? "")\" is not a valid value for \"\(key)\"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        } catch {
            let alert = UIAlertController(title: "Unexpected error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let callbackSettings: CallbackServiceSettings
        let chatSettings: ChatServiceSettings
        do {
            callbackSettings = try CallbackServiceSettings(callbackStr, callbackType: appDelegate.callbackServiceSettings!.callbackType, target: targetStr, additionalParameters: appDelegate.callbackServiceSettings!.additionalParameters)
            chatSettings = try ChatServiceSettings(chatStr, useCometClient: useCometSwitch.isOn, enableWebsocket: enableWebsocketSwitch.isOn)
        } catch GmsApiError.missingGmsSettingsValue(let key) {
            let alert = UIAlertController(title: "Missing Settings", message: "Required settings \"\(key)\" is not set" , preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        } catch GmsApiError.invalidParameter(let key, let value) {
            let alert = UIAlertController(title: "Invalid Settings", message: "\"\(value ?? "")\" is not a valid value for \"\(key)\"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        } catch {
            let alert = UIAlertController(title: "Unexpected error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        appDelegate.serverSettings = serverSettings
        appDelegate.callbackServiceSettings = callbackSettings
        appDelegate.chatServiceSettings = chatSettings
        appDelegate.savePreferences()
        
        let alert = UIAlertController(title: "App Settings Saved", message: "The application settings has been saved.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = AppDelegate.shared
        appDelegate.appSettingsViewController = self
        self.appDelegate = appDelegate
        enableBasicAuth(false)
        enablePush(false)
        if let serverSettings = appDelegate.serverSettings {
            hostTextField.text = serverSettings.hostname
            portTextField.text = serverSettings.port?.description ?? ""
            appTextField.text = serverSettings.app
            useSecureProtocolSwitch.isOn = serverSettings.secureProtocol
            
            switch serverSettings.authSettings {
                case let .basic(user, password):
                    enableBasicAuth(true)
                    authUserTextField.text = user
                    authPasswordTextField.text = password
                default:
                    break
            }
            
            gmsUserTextField.text = serverSettings.gmsUser
            apiKeyTextField.text = serverSettings.apiKey
            
            switch serverSettings.pushSettings {
                case let .fcm(_, debug, language, provider):
                    pushDebugSwitch.isOn = debug ?? false
                    pushLanguageTextField.text = language
                    pushProviderTextField.text = provider
                    enablePush(true)
                default:
                    break
            }
        }
        
        if let callback = appDelegate.callbackServiceSettings {
            callbackServiceTextField.text = callback.serviceName
            callbackTargetTextField.text = (callback.additionalParameters["_target"] as! String?) ?? ""
        }
        
        if let chat = appDelegate.chatServiceSettings {
            chatServiceTextField.text = chat.serviceName
        }
//        useCometSwitch.isOn = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func enableBasicAuth(_ enabled: Bool) {
        if enabled {
            useBasicAuthSwitch.isOn = true
            authUserTextField.isEnabled = true
            authUserTableCell.isHidden = false
            authPasswordTextField.isEnabled = true
            authPasswordTableCell.isHidden = false
        } else {
            useBasicAuthSwitch.isOn = false
            authUserTableCell.isHidden = true
            authUserTextField.isEnabled = false
            authPasswordTableCell.isHidden = true
            authPasswordTextField.isEnabled = false
        }
        tableView.reloadData()
    }
    
    func enablePush(_ enabled: Bool) {
        if enabled {
            allowPushSwitch.isOn = true
            pushDebugSwitch.isEnabled = true
            pushLanguageTextField.isEnabled = true
            pushProviderTextField.isEnabled = true
        } else {
            allowPushSwitch.isOn = false
            pushDebugSwitch.isEnabled = false
            pushLanguageTextField.isEnabled = false
            pushProviderTextField.isEnabled = false
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        print("[AppSettingsTableView] heightForRowAt \(indexPath)")
        if indexPath.section == 1 && !useBasicAuthSwitch.isOn && indexPath.row > 0 {
            return 0.0
        } else if indexPath.section == 3 && !allowPushSwitch.isOn && indexPath.row > 0 {
            return 0.0
        }
        return 44.0
    }

}

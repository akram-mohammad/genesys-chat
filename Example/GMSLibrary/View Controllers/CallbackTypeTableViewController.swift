//
// CallbackTypeTableViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit

class CallbackTypeTableViewController: UITableViewController {
    var appDelegate: AppDelegate?
    var callbackVC: CallbackTableViewController?
    
    override func viewDidLoad() {
        print("[CallbackTypeTableViewController] viewDidLoad")
        super.viewDidLoad()
        appDelegate = AppDelegate.shared
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CallbackType.allTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "callbackTypeCell", for: indexPath)
        let row = indexPath.row

        let callbackType = CallbackType.allTypes[row]

        print("[CallbackTypeTableViewController] cellForRow \(callbackType)")

        cell.textLabel?.text = callbackType.rawValue

        if let appDelegate = appDelegate,
            let settings = appDelegate.callbackServiceSettings,
            settings.callbackType == callbackType {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        print("[CallbackTypeTableViewController] didSelectRowAt: \(row)")

        if row >= CallbackType.allTypes.count || row < 0 {
            print("[CallbackTypeTableViewController] index out of bounds; returning")
            return
        }
        let callbackType = CallbackType.allTypes[row]

        if appDelegate!.callbackServiceSettings != nil {
            do {
                let newSettings = try appDelegate!.callbackServiceSettings!.clone(withCallbackType: callbackType)
                appDelegate!.callbackServiceSettings = newSettings
            } catch {
                print("[CallbackTypeTableViewController] error caught when updating callback settings: \(error)")
            }
        } else {
            print("[CallbackTypeTableViewController] no callback settings in appDelegate; ignored")
        }
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("[CallbackTypeTableViewController] viewDidDisappear")
        if let appDelegate = appDelegate {
            print("[CallbackTypeTableViewController] updating preferences in persistent storage")
            appDelegate.savePreferences()
        }
    }
}

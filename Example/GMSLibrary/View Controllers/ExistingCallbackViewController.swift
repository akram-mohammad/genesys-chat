//
// ExistingCallbackViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-22
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import GMSLibrary
import UIKit

class ExistingCallbackViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        var callbacks: [CallbackRecord]?
        var appDelegate: AppDelegate?
        
        @IBOutlet weak var callbackRecordsTable: UITableView!
        @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        @IBAction func refreshPressed(_ sender: Any) {
            self.reload()
    }
    
    override func viewDidLoad() {
        print("[ExistingCallbackViewController] viewDidLoad")
        super.viewDidLoad()
        
        callbackRecordsTable.delegate = self
        callbackRecordsTable.dataSource = self
        
        appDelegate = AppDelegate.shared
        self.reload()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("[ExistingCallbackViewController] numberOfRowsInSection")
        if let callbacks = callbacks {
            if callbacks.isEmpty {
                return 1
            }
            return callbacks.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let emptyCell = tableView.dequeueReusableCell(withIdentifier: "noCallbackCell")!
        if let callbacks = callbacks, !callbacks.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "callbackRecordCell")!
            let row = indexPath.row
            print("[ExistingCallbackViewController] cellForRowAt \(row)")
                if row >= callbacks.count || row < 0 {
                print("[ExistingCallbackViewController] index out of bounds; returning")
                return emptyCell
            }

                let record = callbacks[row]
            
            let isCompleted = record.callbackState == "COMPLETED"
            let attribStr = NSMutableAttributedString(string: record.desiredTime!.localeString)
            if isCompleted {
                attribStr.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attribStr.length))
            }
            cell.textLabel?.attributedText = attribStr
            let detail = isCompleted && record.callbackReason != nil ? "State: \(record.callbackState!) - \(record.callbackReason!)" : "State: \(record.callbackState!)"
            cell.detailTextLabel?.text = detail
            return cell
        }
        return emptyCell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Cancel Callback") { (action, indexPath) in
            let row = indexPath.row
            if self.callbacks == nil || row >= self.callbacks!.count || row < 0 {
                print("[ExistingCallbackViewController] deleteAction - index out of bounds; returning")
                return
            }
            let record = self.callbacks![row]
            let alert = UIAlertController(
                title: "Cancel callback?",
                message: "Are you sure you want to cancel the callback at \(record.desiredTime!)]?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel Callback", style: .destructive, handler: { _ in
                self.cancel(record.callbackId, desiredTime: record.desiredTime!)
                self.reload()
            }))
            alert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        // only return for actual callbacks
        if let callbacks = callbacks, !callbacks.isEmpty, callbacks[indexPath.row].callbackState != "COMPLETED" {
            return [delete]
        }
    
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reload()
    }
    
    func reload() {
        guard let appDelegate = appDelegate,
            let callbackClient = appDelegate.callbackClient,
            let userSettings = appDelegate.userSettings else {
            print("[ExistingCallbackViewController] appDelegate/client not set up; returning")
            return
        }
        
        if userSettings.phoneNumber == nil || userSettings.phoneNumber!.isEmpty {
            let alert = UIAlertController(
                title: "Phone Number Not Set",
                message: "Phone number is not set in User Settings.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Update Now", style: .default, handler: { _ in
                self.tabBarController!.selectedIndex = 2
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let promise = callbackClient.queryCallback(on: .global(qos: .utility),
                                                   properties: ["_customer_number": userSettings.phoneNumber!])
        promise.timeout(30).then { records in
            self.callbacks = try records.sorted {lhs, rhs throws -> Bool in
                return lhs.desiredTime! > rhs.desiredTime!
        }
            self.callbackRecordsTable.reloadData()
            }.catch { error in
                let alert = UIAlertController(
                    title: "Query Callback Error",
                    message: "Error encountered when querying existing callback for \(userSettings.phoneNumber!): \(error)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    func cancel(_ callbackId: String, desiredTime: Date) {
        guard let appDelegate = appDelegate,
            let callbackClient = appDelegate.callbackClient else {
                print("[ExistingCallbackViewController] appDelegate/client not set up; returning")
                return
        }
        let promise = callbackClient.cancelCallback(on: .global(qos: .utility), serviceId: callbackId)
        promise.timeout(30).then { _ in
            self.reload()
            }.catch { error in
                let alert = UIAlertController(
                    title: "Cancel Callback Error",
                    message: "Error encountered when cancelling existing callback at \(desiredTime.localeString): \(error)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.reload()
        }
    }
}

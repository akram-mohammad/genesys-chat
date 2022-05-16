//
//  CallbackTableViewController.swift
//  GMSLibrary_Example
//
//  Created by Cindy Wong on 2019-07-15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import GMSLibrary


class CallbackTableViewController : UITableViewController {

    var appDelegate: AppDelegate?
    var desiredTime: Date?
    var availabilityChecked: Date?
    var properties = [String: String]()
    
    @IBOutlet weak var callbackTypeLabel: UILabel!
    
    @IBOutlet weak var desiredTimeLabel: UILabel!
    
    @IBOutlet weak var desiredTimeCell: UITableViewCell!
    
    @IBOutlet weak var requestCallbackButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func requestCallbackPressed(_ sender: Any) {
        debugPrint("[CallbackTableViewController] Callback requested")
        guard let appDelegate = appDelegate else {
            print("[CallbackTableViewController] appDelegate not set")
            return
        }
        guard let userSettings = appDelegate.userSettings else {
            print("[CallbackTableViewController] user settings not set")
            return
        }
        guard let phoneNumber = userSettings.phoneNumber else {
            print("[CallbackTableViewController] phone number not set")
            return
        }
        guard let client = appDelegate.callbackClient else
        {
            print("[CallbackTableViewController] callback Client not set")
            return
        }
        
        let promise = client.startCallback(on: .global(qos: .utility), phoneNumber: phoneNumber, desiredTime: desiredTime, properties: properties)

        self.activityIndicator.startAnimating()
        self.requestCallbackButton.isEnabled = false

        promise.timeout(30).then { id in
            debugPrint("[CallbackTableViewController] Callback booked: \(id)")
            self.activityIndicator.stopAnimating()
            self.requestCallbackButton.isEnabled = true
            let alert = UIAlertController(title: "Callback Requested", message: "A \(self.callbackTypeLabel.text!) callback\( self.desiredTime != nil ? " at \(self.desiredTime!.localeString)" : "" ) to \"\(appDelegate.userSettings!.phoneNumber!)\" was successfully requested.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in self.navigationController?.popViewController(animated: true)}))
            self.present(alert, animated: true, completion: nil)
            
            }.catch { error in
                debugPrint("[CallbackTableViewController] error caught: \(error)")
                self.activityIndicator.stopAnimating()
                self.requestCallbackButton.isEnabled = true
                let alert = UIAlertController(title: "Request Callback Failed", message: "Failed to request callback: error=\(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("[CallbackTableViewController] viewDidDisappear()")
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("[CallbackTableViewController] viewDidLoad()")
        appDelegate = AppDelegate.shared

        guard let appDelegate = appDelegate,
            let userSettings = appDelegate.userSettings else {
                print("[CallbackTableViewController] appDelegate/user settings not set; returning")
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
            self.present(alert, animated: true, completion: nil)
        }
        refresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("[CallbackTableViewController] viewDidAppear()")
        super.viewDidAppear(animated)
        refresh()
    }

    func refresh() {
        print("[CallbackTableViewController] refresh()")
        guard let appDelegate = appDelegate,
            let settings = appDelegate.callbackServiceSettings else {
                print("[CallbackTableViewController] settings missing; returning")
                return
        }
        let callbackType = settings.callbackType
        callbackTypeLabel.text = callbackType.rawValue
        desiredTimeCell.isHidden = true
        if let isScheduled = callbackType.isScheduled, isScheduled {
            desiredTimeCell.isHidden = false
            if let desiredTime = desiredTime {
                print("[CallbackTableViewController] desired time set: \(desiredTime.localeString)")
                desiredTimeLabel.text = desiredTime.localeString
                requestCallbackButton.isEnabled = true
            } else {
                print("[CallbackTableViewController] desired time not set")
                desiredTimeLabel.text = "Query Availability"
                requestCallbackButton.isEnabled = false
            }
        } else {
            print("[CallbackTableViewController] not scheduled")
            requestCallbackButton.isEnabled = true
        }
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        print("[CallbackTableViewController] heightForRowAt \(indexPath)")
        guard let appDelegate = appDelegate,
            let settings = appDelegate.callbackServiceSettings else {
                print("[CallbackTableViewController] settings missing; returning")
                return 0.0
        }
        let callbackType = settings.callbackType
        if let isScheduled = callbackType.isScheduled, indexPath.row == 1 && !isScheduled {
            return 0.0
        } else if !requestCallbackButton.isEnabled && indexPath.row == 3 {
            return 0.0
        }
        return 44.0
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("[CallbackTableViewController] prepare for \(String(describing: segue.identifier))")
        let destination = segue.destination
        if destination is DesiredTimeTableViewController {
            let vc = destination as! DesiredTimeTableViewController
            vc.callbackVC = self
            vc.slots = nil
            self.desiredTime = nil
        } else if destination is CallbackTypeTableViewController {
            let vc = destination as! CallbackTypeTableViewController
            vc.callbackVC = self
        } else if destination is AdditionalDataViewController {
            let vc = destination as! AdditionalDataViewController
            vc.callbackVC = self
        }
        
    }
    
}

//
// DesiredTimeTableViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit
import GMSLibrary

extension Date {
    var localeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: self)
    }
}

class DesiredTimeTableViewController: UITableViewController {
    var appDelegate: AppDelegate?
    
    var callbackVC: CallbackTableViewController?
    
    var slots: CallbackAvailabilityV2Result?
    
    func refresh() {
        tableView.reloadData()
    }

    override func viewDidLoad() {
        print("[DesiredTimeTableViewController] viewDidLoad()")
        super.viewDidLoad()
        appDelegate = AppDelegate.shared
        if slots == nil {
            // immediately transition to choose new desired time
             performSegue(withIdentifier: "showQueryAvailabilitySegue", sender: self)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let slots = slots {
            return slots.slots.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("[DesiredTimeTableViewController] cellForRowAt \(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeSlotCell", for: indexPath)
        let row = indexPath.row
        if let slots = slots,
            !slots.slots.isEmpty,
            row >= 0 && row < slots.slots.count {
            let current = slots.slots[row]
            let time = current.utcTime
            cell.textLabel?.text = time.localeString
            cell.detailTextLabel?.text = "Slots available: \(current.capacity)/\(current.total)"
            if let callbackVC = callbackVC,
                let desiredTime = callbackVC.desiredTime,
                desiredTime == time {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("[DesiredTimeTableViewController] didSelectRowAt \(indexPath)")
        let row = indexPath.row
        if let slots = slots,
            !slots.slots.isEmpty,
            row >= 0 && row < slots.slots.count,
            let callbackVC = callbackVC {
            let current = slots.slots[row]
            callbackVC.desiredTime = current.utcTime
        }
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let callbackVC = callbackVC {
            if let desiredTime = callbackVC.desiredTime {
                callbackVC.desiredTimeLabel.text = desiredTime.localeString
            } else {
                callbackVC.desiredTimeLabel.text = "Query Availability"
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        debugPrint("[DesiredTimeTableViewController] prepare \(segue.identifier ?? "N/A")")
        let destination = segue.destination
        if destination is DesiredTimePickerViewController {
            let vc = destination as! DesiredTimePickerViewController
            vc.desiredTimeVC = self
        }
    }
}

//
// DesiredTimePickerViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-19
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit

class DesiredTimePickerViewController: UIViewController {
    
    var appDelegate: AppDelegate?
    
    var desiredTimeVC: DesiredTimeTableViewController?
    
    @IBOutlet weak var desiredTimeLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func dateChanged(_ sender: Any) {
        desiredTimeLabel.text = datePicker.date.localeString
    }
    
    @IBAction func queryAvailabilityPressed(_ sender: Any) {
        debugPrint("[DesiredTimePickerViewController] queryAvailabilityPressed")
        if let appDelegate = appDelegate,
            let client = appDelegate.callbackClient,
            let desiredTimeVC = desiredTimeVC {
            let promise = client.queryAvailabilityV2(on: .global(qos: .utility),
                                                     start: datePicker.date, numberOfDays: 5, maxTimeSlots: 5)
            activityIndicator.startAnimating()
            
            promise.then { result in
                desiredTimeVC.slots = result
                debugPrint("[DesiredTimePickerViewController] availability returned: \(result)")
                desiredTimeVC.refresh()
                self.activityIndicator.stopAnimating()
                self.dismiss(animated: true, completion: nil)
            }.catch { error in
                self.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Query Availabilty Failed", message: "Failed to query availability: error=\(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minuteInterval = 5
        datePicker.minimumDate = Date()
        datePicker.maximumDate = Date(timeIntervalSinceNow: 7 * 24 * 60 * 60)
        desiredTimeLabel.text = datePicker.date.localeString
        appDelegate = AppDelegate.shared
    }
}

class DesiredTimeDatePicker: UIDatePicker {
    override func layoutSubviews() {
        super.layoutSubviews()
        setValue(UIColor.white, forKey: "textColor")
        setValue(false, forKey: "highlightsToday")
    }
}

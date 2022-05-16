//
// AdditionalDataViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit

class AdditionalDataViewController : UITableViewController {
    var keyToEdit: String?
    var callbackVC: CallbackTableViewController?
    
    override func viewDidLoad() {
        print("[AdditionalDataViewController] viewDidLoad")
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("[AdditionalDataViewController] numberOfRowsInSection")
        guard let callbackVC = callbackVC else {
            print("[AdditionalDataViewController] callback VC; exiting")
            return 0
        }
        return callbackVC.properties.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "additionalParameterViewCell")!
        let row = indexPath.row
        print("[AdditionalDataViewController] cellForRowAt \(row)")
        guard let callbackVC = callbackVC else {
            print("[AdditionalDataViewController] callback VC; exiting")
            return cell
        }
        if row >= callbackVC.properties.count || row < 0 {
            print("[AdditionalDataViewController] index out of bounds; returning")
            return cell
        }
        
        let key = callbackVC.properties.keys.sorted()[row]
        let value = callbackVC.properties[key]!
        
        print("[AdditionalDataViewController] key:\(key), value:\(value)")
        
        cell.textLabel?.text = key
        cell.detailTextLabel?.text = value.description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let row = indexPath.row
            guard let callbackVC = self.callbackVC else {
                print("[AdditionalDataViewController] callback VC; exiting")
                return
            }
            if row >= callbackVC.properties.count || row < 0 {
                print("[AdditionalDataViewController] deleteAction - index out of bounds; returning")
                return
            }
            let key = callbackVC.properties.keys.sorted()[row]
            let value = callbackVC.properties[key]!
            let alert = UIAlertController(title: "Delete Key \(key)?", message: "Are you sure you want to delete additional parameter [key=\(key), value=\(value)]?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                callbackVC.properties.removeValue(forKey: key)
                self.tableView.reloadData()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        let edit = UITableViewRowAction(style: .default, title: "Edit") {
            (action, indexPath) in
            let row = indexPath.row
            guard let callbackVC = self.callbackVC else {
                print("[AdditionalDataViewController] callback VC; exiting")
                return
            }
            if row >= callbackVC.properties.count || row < 0 {
                print("[AdditionalDataViewController] index out of bounds; returning")
                return
            }
            self.keyToEdit = callbackVC.properties.keys.sorted()[row]
            self.performSegue(withIdentifier: "editAdditionalDataSegue", sender: indexPath)
        }
        return [delete, edit]
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("[AdditionalDataViewController] didSelectRowAt \(indexPath)")
        self.keyToEdit = callbackVC!.properties.keys.sorted()[indexPath.row]
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("[AdditionalDataViewController] sending segue: \(segue)")
        let destination = segue.destination
        if let identifier = segue.identifier, identifier == "addAdditionalDataSegue" {
            keyToEdit = nil
        }

        if destination is AdditionalDataEditTableViewController {
            let vc = destination as! AdditionalDataEditTableViewController
            vc.additionalDataVC = self
            vc.callbackVC = callbackVC
            vc.keyToEdit = keyToEdit
            print("[AdditionalDataViewController] key to edit \(keyToEdit ?? "nil")")
        }
    }
    

}

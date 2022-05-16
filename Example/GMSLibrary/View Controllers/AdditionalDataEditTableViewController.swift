//
// AdditionalDataEditViewController.swift
// GMSLibrary_Example
//
// Created by Cindy Wong on 2019-07-18
// Copyright © 2019 Genesys.  All rights reserved.
//


import Foundation
import UIKit

class AdditionalDataEditTableViewController : UITableViewController, UITextFieldDelegate {
    var additionalDataVC: AdditionalDataViewController?
    var callbackVC: CallbackTableViewController?
    var keyToEdit: String?
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var valueTextField: UITextField!

    @IBAction func savePressed(_ sender: Any) {
        print("[AdditionalDataEditViewController] savePressed")
        guard let key = keyTextField.text, !key.isEmpty else {
            let alert = UIAlertController(title: "Empty Key", message: "The key for the additional data cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            navigationController?.popViewController(animated: true)
            return
        }
        
        guard let value = valueTextField.text, !value.isEmpty else {
            let alert = UIAlertController(title: "Empty Value", message: "The value for the additional data cannot be empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            navigationController?.popViewController(animated: true)
            return
        }
        
        guard let callbackVC = self.callbackVC else {
            print("[AdditionalDataEditViewController] callback view controller not found; returning")
            return
        }
        
        var save = true
        if keyToEdit == nil && callbackVC.properties[key] != nil {
            let alert = UIAlertController(title: "Key Already Exists", message: "The key \"\(key)\" already exists.  Replace its value with \"\(value)\"?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Replace", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in save = false }))
            present(alert, animated: true, completion: nil)
        } else if let oldKey = keyToEdit, key != oldKey {
            let alert = UIAlertController(title: "Key Changed", message: "The key has changed from \"\(oldKey)\" to \"\(key)\".  Remove the previous key?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Remove", style: .default, handler: { _ in callbackVC.properties.removeValue(forKey: oldKey) } ))
            alert.addAction(UIAlertAction(title: "Replace", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in save = false }))
            present(alert, animated: true, completion: nil)
        }
        
        if save {
            callbackVC.properties[key] = value
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        print("[AdditionalDataEditViewController] viewDidLoad")

        if let callbackVC = callbackVC, let key = keyToEdit, let value = callbackVC.properties[key] {
            keyTextField.text = key
            valueTextField.text = value.description
        } else {
            keyTextField.text = ""
            valueTextField.text = ""
        }
        
        keyTextField.delegate = self
        valueTextField.delegate = self
        
        keyTextField.addTarget(valueTextField, action: #selector(becomeFirstResponder), for: .editingDidEndOnExit)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == keyTextField {
            valueTextField.becomeFirstResponder()
        }
        return true
    }
}

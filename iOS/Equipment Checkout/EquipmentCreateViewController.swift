//
//  EquipmentCreateViewController.swift
//  iOS
//
//  Created by John Kotz on 7/15/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import DALI

class EquipmentCreateViewController: FormViewController {
    var scanAndListViewController: EquipmentScanAndListViewController?
    
    @objc func cancelPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func submitPressed() {
        var dict = [String: Any]()
        form.allRows.forEach { (row) in
            guard let tag = row.tag, var value = row.baseValue else {
                return
            }
            
            if tag == "type", let val = value as? String {
                value = val.lowercased()
                dict.removeValue(forKey: "totalStock")
            } else if tag == "totalStock" && dict["type"] as? String == "single" {
                return
            }
            
            dict[tag] = value
        }
        
        guard let name = dict["name"] as? String, dict["description"] != nil else {
            return
        }
        
        // Create the equipment with the given info
        DALIEquipment.create(withName: name, extraInfo: dict).mainThreadFuture.onSuccess { (equipment) in
            CATransaction.begin()
            // Once the pop animation is complete...
            CATransaction.setCompletionBlock {
                // Show the newly created equipment
                self.scanAndListViewController?.performSegue(withIdentifier: "detailEquipment", sender: equipment)
            }
            self.navigationController?.popViewController(animated: true)
            CATransaction.commit()
        }.onFail { (error) in
            // Ran into an error
            // TODO: Handle this better
            let alert = UIAlertController(title: "Encountered error",
                                          message: error.localizedDescription,
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Done", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Equipment"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(cancelPressed))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit",
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(submitPressed))
        
        form +++ Section("General")
            <<< TextRow { row in
                row.tag = "name"
                row.add(rule: RuleRequired())
                row.validationOptions = [.validatesOnChange]
                row.title = "Name*"
                row.placeholder = "eg. Meticulous Manitee"
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            <<< TextRow { row in
                row.tag = "description"
                row.add(rule: RuleRequired())
                row.validationOptions = [.validatesOnChange]
                row.title = "Description*"
                row.placeholder = "eg. iPad Pro"
            }.cellUpdate { cell, row in
                if !row.isValid {
                    cell.titleLabel?.textColor = .red
                }
            }
            <<< TextRow { row in
                row.tag = "password"
                row.title = "Password"
                row.placeholder = "eg. ●●●●●●"
            }
            <<< EquipmentCreateIconPickerRow { row in
                row.tag = "iconName"
                row.cell.height = { 130 }
            }
        +++ Section("Details")
            <<< TextRow { row in
                row.tag = "make"
                row.title = "Make"
                row.placeholder = "eg. Apple"
            }
            <<< TextRow { row in
                row.tag = "model"
                row.title = "Model"
                row.placeholder = "eg. MT952LL/A"
            }
            <<< TextRow { row in
                row.tag = "serialNumber"
                row.title = "Serial Number"
                row.add(rule: RuleRequired())
                row.validationOptions = [.validatesOnChange]
                row.placeholder = "eg. XXXXXXXXXXXX"
            }
        +++ Section("Extras")
            <<< SegmentedRow<String> { row in
                row.title = "Type"
                row.tag = "type"
                row.options = ["Single", "Collection"]
                row.value = "Single"
            }
            <<< StepperRow { row in
                row.title = "Number available"
                row.tag = "totalStock"
                row.value = 2
                row.hidden = Condition.function(["type"], { form in
                    guard let value = (form.rowBy(tag: "type") as? SegmentedRow<String>)?.value else {
                        return false
                    }
                    return value == "Single"
                })
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard DALIMember.current?.isAdmin ?? false else {
            let alert = UIAlertController(title: "Admins Only",
                                          message: "Creating new equipment can only be done by an admin." +
                                                   " Contact core or staff to register a new device",
                                          preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel) { (_) in
                self.navigationController?.popViewController(animated: true)
            })
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
}

extension UINavigationController {
    var rootViewController: UIViewController? {
        return self.navigationController?.viewControllers.first
    }
}

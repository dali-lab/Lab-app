//
//  CheckOutConfirmViewController.swift
//  iOS
//
//  Created by John Kotz on 9/17/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import FutureKit
import DALI

class CheckOutConfirmViewController: UITableViewController {
    var equipment: DALIEquipment!
    var checkouts: [DALIEquipment.CheckOutRecord]?
    
    override func viewDidLoad() {
        self.title = equipment.name
        
        let flexSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButtonItem = UIBarButtonItem(title: "Check Out", style: .done, target: self, action: #selector(CheckOutConfirmViewController.checkOutPressed))
        let flexSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([flexSpace1, barButtonItem, flexSpace2], animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 + (self.showPasswordCell() ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if self.showPasswordCell() && section == 1 {
            return 1
        }
        
        var numCheckouts = self.equipment.lastCheckedOut != nil ? 2 : 0
        if let checkouts = checkouts {
            numCheckouts = checkouts.count
        }
        return numCheckouts
    }
    
    @objc func checkOutPressed() {
        let alertTuple = datePickerAlert(title: "Expected Return Date:", datePickerMode: .date)
        alertTuple.datePicker.minimumDate = Date()
        
        alertTuple.alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertTuple.alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            self.checkOut(endDate: alertTuple.datePicker.date)
        }))
        
        self.present(alertTuple.alert, animated: true, completion: nil)
    }
    
    func checkOut(endDate: Date) {
        let _ = self.equipment.checkout(expectedEndDate: endDate).onSuccess { (record) in
            DALIEquipment.equipment(for: self.equipment.qrID).onSuccess(block: { (equipment) in
                self.equipment = equipment
                self.tableView.reloadData()
            })
        }
    }
    
    func showPasswordCell() -> Bool {
        return self.equipment.password != nil
    }
    
    func checkOutRecord(for index: Int) -> DALIEquipment.CheckOutRecord? {
        if let checkouts = checkouts {
            return checkouts[index]
        }
        return index == 0 ? equipment.lastCheckedOut : nil
    }
    
    func indexPathIsLoadMore(_ indexPath: IndexPath) -> Bool {
        return self.equipment.lastCheckedOut != nil && checkouts == nil && indexPath.row == 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 86
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "titleCell")
            
            let titleCell = cell as! CheckOutConfirmViewTitleCell
            titleCell.titleLabel.text = equipment.name
            titleCell.subtitleLabel.text = equipment.qrID
        } else if self.showPasswordCell() && indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "passwordCell")
            
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: "passwordCell")
            }
            
            cell.textLabel?.text = "Password"
            cell.detailTextLabel?.text = "••••••"
        } else if self.indexPathIsLoadMore(indexPath) {
            cell = tableView.dequeueReusableCell(withIdentifier: "moreCell")
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "checkoutCell")
            
            let checkOutCell = cell as! CheckOutConfirmViewCheckOutCell
            if let record = self.checkOutRecord(for: indexPath.row) {
                checkOutCell.checkOutRecord = record
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.indexPathIsLoadMore(indexPath) {
            let _ = self.equipment.getHistory().onSuccess { (records) in
                self.checkouts = records
                tableView.reloadData()
            }
            
            let cell = tableView.cellForRow(at: indexPath)
            cell?.textLabel?.textColor = UIColor.clear
            cell?.selectionStyle = .none
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

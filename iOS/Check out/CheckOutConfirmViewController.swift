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
    var barButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.title = equipment.name
        
        let flexSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barButtonItem = UIBarButtonItem(title: "Check Out", style: .done, target: self, action: #selector(CheckOutConfirmViewController.checkOutPressed))
        let flexSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([flexSpace1, barButtonItem, flexSpace2], animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
        
        self.updateUI(animated: false)
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
    
    func updateUI(animated: Bool) {
        var barButtonTitle = "Check Out"
        if isCheckedOut() {
            barButtonTitle = "Checked Out"
            if canReturn() {
                barButtonTitle = "Return"
            }
        }
        
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.barButtonItem.isEnabled = !self.disableCheckout()
            self.barButtonItem.title = barButtonTitle
        }
    }
    
    @objc func checkOutPressed() {
        if !isCheckedOut() {
            let alert = UIAlertController(title: "Expected Return Date:", message: nil, preferredStyle: .actionSheet)
            var date: Date = Date()
            alert.addDatePicker(mode: .date, date: Date(), minimumDate: Date()) { (output) in
                date = output
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
                self.checkOut(endDate: date)
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else if canReturn() {
            let alert = UIAlertController(title: "Return \(equipment.name)?", message: "Make sure you put it back in its proper place in the lab", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Return", style: .default, handler: { (_) in
                self.returnEquipment()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func reloadEquipment() {
        let _ = self.equipment.reload().onSuccess(block: { (equipment) in
            self.updateUI(animated: true)
            self.tableView.reloadData()
        })
    }
    
    func showErrorAlert(action: String, error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to \(action) \(equipment.name): \(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func returnEquipment() {
        let future = self.equipment.returnEquipment()
        
        future.onFail { (error) in
            self.showErrorAlert(action: "return", error: error)
        }
        
        future.onComplete { (_) in
            self.reloadEquipment()
        }
    }
    
    func checkOut(endDate: Date) {
        let future = self.equipment.checkout(expectedEndDate: endDate)
        
        future.onFail { (error) in
            self.showErrorAlert(action: "check out", error: error)
        }
        
        future.onComplete { (_) in
            self.reloadEquipment()
        }
    }
    
    func showPasswordCell() -> Bool {
        return self.equipment.password != nil
    }
    
    func canReturn() -> Bool {
        return isCheckedOut() && equipment.lastCheckedOut!.member == DALIMember.current! || DALIMember.current!.isAdmin
    }
    
    func isCheckedOut() -> Bool {
        return equipment.lastCheckedOut != nil && equipment.lastCheckedOut!.endDate == nil
    }
    
    func disableCheckout() -> Bool {
        return isCheckedOut() && !canReturn()
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
        } else if showPasswordCell() ? indexPath.section == 2 : indexPath.section == 1 {
            if let record = self.checkOutRecord(for: indexPath.row), record.endDate == nil {
                return 64
            }
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "titleCell")
            
            let titleCell = cell as! CheckOutConfirmViewTitleCell
            titleCell.titleLabel.text = equipment.name
            titleCell.subtitleLabel.text = equipment.id
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
            guard let record = self.checkOutRecord(for: indexPath.row) else {
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
            }
            
            if record.endDate == nil {
                cell = tableView.dequeueReusableCell(withIdentifier: "checkedOutCell")
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "checkoutCell")
            }
            
            let checkOutCell = cell as! CheckOutConfirmViewCheckOutCell
            checkOutCell.checkOutRecord = record
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

//
//  EquipmentDetailTableViewController.swift
//  iOS
//
//  Created by John Kotz on 12/19/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import RLBAlertsPickers
import FutureKit

class EquipmentDetailTableViewController: UITableViewController {
    var equipment: DALIEquipment!
    var checkOuts: [DALIEquipment.CheckOutRecord]?
    var passwordIsReveiled = false
    
    fileprivate var cellTypes = [[CellType]]()
    var sectionTitles = [String?]()
    
    override func viewDidLoad() {
        updateView()
    }
    
    // MARK: - UITableViewController overrides
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypes[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionTitles[section] == nil ? 0 : 30
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = cellTypes[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID.identifier)
        
        if let cell = cell as? EquipmentDetailTableViewCell {
            cell.equipment = equipment
            cell.type = cellID
        }
        if case CellType.checkOutButton(let title, let enabled) = cellID {
            cell?.textLabel?.text = title
            cell?.textLabel?.textColor = enabled ? UIColor.blue : UIColor.gray
        } else if case CellType.password = cellID {
            if passwordIsReveiled {
                cell?.detailTextLabel?.text = equipment.password
            } else {
                cell?.detailTextLabel?.text = String(repeating: "●", count: equipment.password!.count)
            }
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellType = cellTypes[indexPath.section][indexPath.row]
        var deselectAnimated = true
        
        if case CellType.checkOutButton(_, let enabled) = cellType {
            if !enabled {
                deselectAnimated = false
            } else {
                if let lastCheckOut = equipment.lastCheckedOut, equipment.isCheckedOut, lastCheckOut.member == DALIMember.current {
                    returnPressed()
                } else if !equipment.isCheckedOut {
                    checkoutPressed()
                }
            }
        } else if case CellType.loadMore = cellType {
            loadMore()
        } else if case CellType.password = cellType {
            passwordIsReveiled = !passwordIsReveiled
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        tableView.deselectRow(at: indexPath, animated: deselectAnimated)
    }
    
    // MARK: - Updating the view
    
    func updateView(animated: Bool = true) {
        cellTypes.removeAll()
        sectionTitles.removeAll()
        
        sectionTitles.append(nil)
        cellTypes.append([.title])
        
        if equipment.password != nil {
            sectionTitles.append("Notes")
            cellTypes.append([.password])
        }
        
        if let lastCheckout = equipment.lastCheckedOut {
            let checkOuts = self.checkOuts ?? [lastCheckout]
            sectionTitles.append("History")
            cellTypes.append(checkOuts.map({ (record) -> CellType in
                if record.endDate == nil {
                    return .currentCheckout(name: record.member.name, start: record.startDate, end: record.expectedReturnDate)
                } else {
                    return .pastCheckout(name: record.member.name, start: record.startDate, end: record.endDate!)
                }
            }))
            
            if self.checkOuts == nil {
                cellTypes[cellTypes.count - 1].append(.loadMore)
            }
        }
        
        sectionTitles.append("Actions")
        let canReturn = equipment.lastCheckedOut != nil && equipment.isCheckedOut && equipment.lastCheckedOut?.member == DALIMember.current
        let enabled = !equipment.isCheckedOut || equipment.lastCheckedOut?.member == DALIMember.current
        
        cellTypes.append([.checkOutButton(title: canReturn ? "Return" : "Check out", enabled: enabled)])
        
        self.tableView.reloadData()
    }
    
    func loadMore() {
        equipment.getHistory().onSuccess { (records) in
            self.checkOuts = records
            DispatchQueue.main.async {
                self.updateView()
            }
        }.onFail { (error) in
            let alert = UIAlertController(title: "Failed to get history", message: "Couldn't retrieve the check-out history", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkout(with endDate: Date) {
        equipment.checkout(expectedEndDate: endDate).onSuccess { (record) -> Future<DALIEquipment> in
            return self.equipment.reload()
        }.onSuccess { (equipment) in
            self.equipment = equipment
            if self.checkOuts != nil {
                self.loadMore()
            } else {
                DispatchQueue.main.async {
                    self.updateView()
                }
            }
        }.onFail { (error) in
            DispatchQueue.main.async {
                self.errorAlert(with: "Failed to check out", error: error)
            }
        }
    }
    
    func checkoutPressed() {
        let alert = UIAlertController(title: "When will you return \(equipment.name)?", message: nil, preferredStyle: .actionSheet)
        
        var savedDate: Date = Date()
        alert.addDatePicker(mode: .date, date: savedDate, minimumDate: Date(), maximumDate: nil) { (date) in
            savedDate = date
        }
        
        alert.addAction(UIAlertAction(title: "Check out", style: .default, handler: { (_) in
            self.checkout(with: savedDate)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func returnPressed() {
        equipment.returnEquipment().onSuccess { (_) in
            return self.equipment.reload()
        }.onSuccess { (equipment) in
            self.equipment = equipment
            if self.checkOuts != nil {
                self.loadMore()
            } else {
                DispatchQueue.main.async {
                    self.updateView()
                }
            }
        }.onFail { (error) in
            DispatchQueue.main.async {
                self.errorAlert(with: "Failed to return", error: error)
            }
        }
    }
    
    func errorAlert(with title: String, error: Error) {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

/**
 The type of cell to show
 */
fileprivate enum CellType {
    case title
    case password
    case currentCheckout(name: String, start: Date, end: Date?)
    case pastCheckout(name: String, start: Date, end: Date)
    case loadMore
    case checkOutButton(title: String, enabled: Bool)
    
    var identifier: String {
        switch self {
        case .title: return "titleCell"
        case .password: return "passwordCell"
        case .currentCheckout(_, _, _): return "currentCheckoutCell"
        case .pastCheckout(_, _, _): return "pastCheckoutCell"
        case .loadMore: return "moreCell"
        case .checkOutButton: return "checkOutButtonCell"
        }
    }
}

/// An abstraction of the cell
class EquipmentDetailTableViewCell: UITableViewCell {
    var equipment: DALIEquipment? = nil
    fileprivate var type: CellType? = nil
}

class EquipmentDetailTableViewTitleCell: EquipmentDetailTableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    
    override func awakeFromNib() {
        self.selectionStyle = .none
    }
    
    override var equipment: DALIEquipment? {
        didSet {
            titleLabel.text = equipment?.name
            idLabel.text = equipment?.id
        }
    }
}

class EquipmentDetailTableViewCheckOutCell: EquipmentDetailTableViewCell {
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()
    
    override fileprivate var type: CellType? {
        didSet {
            if let type = type, case CellType.pastCheckout(let name, let start, let end) = type {
                let df = dateFormatter
                textLabel?.text = name
                detailTextLabel?.text = "\(df.string(from: start)) - \(df.string(from: end))"
            }
        }
    }
}

class EquipmentDetailTableViewCurrentCheckOutCell: EquipmentDetailTableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateRangeLabel: UILabel!
    @IBOutlet weak var returnLabel: UILabel!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()
    
    override fileprivate var type: CellType? {
        didSet {
            if let type = type, case CellType.currentCheckout(let name, let start, let end) = type {
                let df = dateFormatter
                nameLabel?.text = name
                dateRangeLabel?.text = "\(df.string(from: start)) - Now"
                
                var returnByString = "Unknown"
                if let end = end {
                    returnByString = df.string(from: end)
                }
                returnLabel.text = "Return by: \(returnByString)"
            }
        }
    }
}
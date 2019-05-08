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
import NotificationCenter

/**
 A table view which shows data about the equipment and allows checking out and returning
 */
class EquipmentDetailTableViewController: UITableViewController {
    /// The equipment this view represents
    var equipment: DALIEquipment!
    /// The loaded list of checkout history
    var checkOuts: [DALIEquipment.CheckOutRecord]?
    /// The password is reveiled (the password feild is by default hidden)
    var passwordIsReveiled = false
    var observer: Observation?
    
    /// The configurations for all the cell
    private var cellConfigurations = [(configs: [CellConfiguration], sectionTitle: String?)]()
    
    override func viewDidLoad() {
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observer = equipment.observe { (_) in
            self.updateView()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        observer?.stop()
    }
    
    // =========================================================
    // MARK: - Updating the view
    
    /**
     Update the table view with all known data about the equipment
     TODO: Make transition animated
     
     - parameter animated: Animate the transition (right now does nothing)
     */
    func updateView(animated: Bool = true) {
        cellConfigurations.removeAll()
        cellConfigurations.append((configs: [.title], sectionTitle: nil))
        
        if let returnDate = equipment.lastCheckedOut?.expectedReturnDate {//
            let checkOut = equipment.lastCheckedOut
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            
            cellConfigurations[0].configs.append(.button(title: "Return Date: \(df.string(from: returnDate))",
                                                         enabled: checkOut?.member == DALIMember.current,
                                                         type: .updateReturnDateButton))
        }
        
        // MARK: Members checking out
        var notesCells: [CellConfiguration] = []
        if equipment.password != nil { // PASSWORD
            notesCells.append(.password)
        }
        if let make = equipment.make { // MAKE
            notesCells.append(.note(title: "Make", value: make))
        }
        if let model = equipment.model { // MODEL
            notesCells.append(.note(title: "Model", value: model))
        }
        if let serialNumber = equipment.serialNumber { // SERIAL NUMBER
            notesCells.append(.note(title: "Serial Number", value: serialNumber))
        }
        if notesCells.count >= 1 {
            cellConfigurations.append((configs: notesCells, sectionTitle: "Notes"))
        }
        
        // MARK: Check out history
        if let lastCheckout = equipment.lastCheckedOut {
            let checkOuts = self.checkOuts ?? [lastCheckout]
            
            // Generate the configurations
            var checkOutConfigs = checkOuts.sorted(by: { (record1, record2) -> Bool in
                return record1.startDate > record2.startDate
            }).map({ (record) -> CellConfiguration in
                if record.endDate == nil {
                    return .checkout(name: record.member.name, start: record.startDate, end: nil)
                } else {
                    return .checkout(name: record.member.name, start: record.startDate, end: record.endDate!)
                }
            })
            
            // Add a load more button if have no extra history data
            if self.checkOuts == nil && equipment.hasHistory {
                checkOutConfigs.append(.button(title: "Load More...", enabled: true, type: .loadMoreButton))
            }
            cellConfigurations.append((configs: checkOutConfigs, sectionTitle: "History"))
        }
        
        // MARK: Members checking out
        if equipment.checkingOutUsers.count > 0 {
            // Get the frequency of each member occuring in this list
            let memberFrequency = equipment.checkingOutUsers.reduce(into: [String: Int]()) { (result, member) in
                if result[member.id] == nil {
                    result[member.id] = 0
                }
                result[member.id]! += 1
            }
            
            // Generate a single .note config for each member in the list, with a frequency tag if it's more than 1
            let membersCellConfigs = memberFrequency.compactMap { (element) -> CellConfiguration? in
                return .note(title: element.key, value: element.value != 1 ? "x\(element.value)" : "")
            }
            
            cellConfigurations.append((configs: membersCellConfigs, sectionTitle: "Members checking out"))
        }
        
        // MARK: Actions
        var actionButtons = [CellConfiguration]()
        
        // Compute some booleans describing if the device can be checked-out or returned
        let singleTypeCanReturn = equipment.lastCheckedOut != nil &&
            equipment.isCheckedOut &&
            equipment.lastCheckedOut?.member == DALIMember.current
        let canReturn = singleTypeCanReturn || equipment.checkingOutUsers.contains(where: { (member) -> Bool in
            return member == DALIMember.current
        })
        let canForceReturn = equipment.isCheckedOut && !canReturn && (DALIMember.current?.isAdmin ?? false)
        
        // Using booleans, add to action buttons accordingly
        if canReturn {
            actionButtons.append(.button(title: "Return",
                                                 enabled: true,
                                                 type: .returnButton))
        }
        if canForceReturn {
            actionButtons.append(.button(title: "Force return",
                                         enabled: true,
                                         type: .forceReturnButton))
        }
        if !equipment.isCheckedOut || !canReturn && !canForceReturn {
            actionButtons.append(.button(title: "Check out",
                                                 enabled: !equipment.isCheckedOut,
                                                 type: .checkOutButton))
        }
        
        // Commit the action buttons if needed
        if actionButtons.count > 0 {
            cellConfigurations.append((configs: actionButtons, sectionTitle: "Actions"))
        }
        
        self.tableView.reloadData()
    }
    
    // =========================================================
    // MARK: - Data
    
    /**
     Load history of check-outs
     */
    func loadHistory() {
        equipment.getHistory().onSuccess { (records) in
            self.checkOuts = records
            DispatchQueue.main.async {
                self.updateView()
            }
        }.onFail { _ in
            let alert = UIAlertController(title: "Failed to get history",
                                          message: "Couldn't retrieve the check-out history",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /**
     Checkout this equipment
     
     - parameter endDate: The date when the device is expected to be returned (not necessary for collections)
     */
    func checkout(with endDate: Date?) {
        equipment.checkout(expectedEndDate: endDate).onSuccess { _ -> Future<DALIEquipment> in
            return self.equipment.reload()
        }.mainThreadFuture.onSuccess { (equipment) in
            self.equipment = equipment
            AppDelegate.shared.checkedOut(equipment: equipment)
            if self.checkOuts != nil {
                self.loadHistory()
            } else {
                self.updateView()
            }
        }.onFail { (error) in
            self.errorAlert(with: "Failed to check out", error: error)
        }
    }
    
    /**
     Update the equipment's return date
     
     - parameter returnDate: The return date to assign to the equipment
     */
    func update(returnDate: Date) -> Future<DALIEquipment> {
        return equipment.update(returnDate: returnDate).onSuccess { _ -> Future<DALIEquipment> in
            AppDelegate.shared.checkedOut(equipment: self.equipment)
            return self.equipment.reload()
        }.onFail { (error) in
            self.errorAlert(with: "Failed to update return date", error: error)
        }
    }
    
    /**
     Return the equipment
     */
    func returnEquipment() -> Future<DALIEquipment> {
        return equipment.returnEquipment().onSuccess { (_) in
            return self.equipment.reload()
        }.mainThreadFuture.onSuccess { (_) in
            self.updateView()
            return self.equipment
        }.onFail { (error) in
            self.errorAlert(with: "Failed to return", error: error)
        }
    }
    
    // =========================================================
    // MARK: - UITableViewController overrides
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellConfigurations.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellConfigurations[section].configs.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return cellConfigurations[section].sectionTitle
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellConfigurations[section].sectionTitle == nil ? 0 : 30
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellConfig = cellConfigurations[indexPath.section].configs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellConfig.identifier)
        
        // If it is one of cells that is a subclass of the config class
        if let cell = cell as? EquipmentDetailTableViewCell {
            cell.equipment = equipment
            cell.type = cellConfig
        }
        
        // In other special cases...
        if case CellConfiguration.button(let title, let enabled, _) = cellConfig {
            // A button cell
            cell?.textLabel?.text = title
            cell?.textLabel?.textColor = enabled ? UIColor.blue : UIColor.gray
            cell?.selectionStyle = enabled ? .default : .none
        } else if case CellConfiguration.password = cellConfig {
            // A password cell. It should only reveal the password when you tap the cell
            if passwordIsReveiled {
                cell?.detailTextLabel?.text = equipment.password
            } else {
                cell?.detailTextLabel?.text = String(repeating: "●", count: equipment.password!.count)
            }
        } else if case CellConfiguration.note(let title, let value) = cellConfig {
            // A simple note cell
            cell?.textLabel?.text = title
            cell?.detailTextLabel?.text = value
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellConfig = cellConfigurations[indexPath.section].configs[indexPath.row]
        var deselectAnimated = true
        
        if case CellConfiguration.button(_, let enabled, let type) = cellConfig {
            if !enabled {
                deselectAnimated = false
            } else {
                switch type {
                case .returnButton: _ = returnEquipment()
                case .checkOutButton: checkOutPressed()
                case .updateReturnDateButton: changeReturnDatePressed()
                case .loadMoreButton: loadHistory()
                case .forceReturnButton: forceReturnButtonPressed()
                }
            }
        } else if case CellConfiguration.password = cellConfig {
            passwordIsReveiled = !passwordIsReveiled
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        tableView.deselectRow(at: indexPath, animated: deselectAnimated)
    }
    
    // =========================================================
    // MARK: - User Interaction
    
    /**
     The update return date cell button was pressed
     */
    func changeReturnDatePressed() {
        guard let returnDate = equipment.lastCheckedOut?.expectedReturnDate else {
            return
        }
        
        let alert = UIAlertController(title: "When will you return \(equipment.name)?",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        // Add a date picker and get the date whenever it's changed
        var savedDate = Date()
        alert.addDatePicker(mode: .date, date: returnDate, minimumDate: Date(), maximumDate: nil) { savedDate = $0 }
        
        // Alert Buttons
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (_) in
            self.update(returnDate: savedDate).mainThreadFuture.onSuccess { _ in
                self.updateView()
            }.onFail { (error) in
                self.handleError(error: error, fromFunction: "changeReturnDatePressed")
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     The button allowing an admin to force the return of the device was pressed
     */
    func forceReturnButtonPressed() {
        guard DALIMember.current?.isAdmin ?? false else {
            return
        }
        
        let alert = UIAlertController(title: "Force return?",
                                      message: "Use your admin privileges to force this device to be returned",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Return", style: .destructive) { (_) in
            self.returnEquipment().onFail { (error) in
                self.handleError(error: error, fromFunction: "forceReturnButtonPressed")
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     The check-out table view cell was pressed
     */
    func checkOutPressed() {
        if equipment.type == .collection {
            // If it's a collection we don't need a return date
            checkout(with: nil)
            return
        }
        
        let alert = UIAlertController(title: "When will you return \(equipment.name)?",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        // Get the date from the date picker
        var savedDate: Date = Date()
        alert.addDatePicker(mode: .date, date: savedDate, minimumDate: Date(), maximumDate: nil) { savedDate = $0 }
        
        // Alert buttons
        alert.addAction(UIAlertAction(title: "Check out", style: .default, handler: { (_) in
            self.checkout(with: savedDate)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func errorAlert(with title: String, error: Error) {
        DispatchQueue.main.async { // In case the caller is outside of main thread
            let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleError(error: Error, fromFunction: String) {
        // TODO: Implement
    }
}

/**
 The type of cell to show
 */
private enum CellConfiguration {
    case title
    case password
    case checkout(name: String, start: Date, end: Date?)
    case note(title: String, value: String)
    case button(title: String, enabled: Bool, type: ActionButtonType)
    
    var identifier: String {
        switch self {
        case .title: return "titleCell"
        case .password: return "passwordCell"
        case .checkout: return "pastCheckoutCell"
        case .note: return "noteCell"
        case .button: return "checkOutButtonCell"
        }
    }
}

private enum ActionButtonType {
    case checkOutButton
    case returnButton
    case updateReturnDateButton
    case loadMoreButton
    case forceReturnButton
}

/// An abstraction of the cell
class EquipmentDetailTableViewCell: UITableViewCell {
    var equipment: DALIEquipment?
    fileprivate var type: CellConfiguration?
}

class TitleCell: EquipmentDetailTableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        self.selectionStyle = .none
    }
    
    override var equipment: DALIEquipment? {
        didSet {
            if let iconName = equipment?.iconName {
                iconImageView.image = UIImage(named: iconName)
            } else {
                iconImageView.image = nil
            }
            iconImageView.isHidden = iconImageView.image == nil
            
            titleLabel.text = equipment?.name
            var detailsThings = [String]()
            if let description = equipment?.description {
                detailsThings.append(description)
            } else if let make = equipment?.make, let model = equipment?.model {
                detailsThings.append("\(make) \(model)")
            }
            
            if let serialNumber = equipment?.serialNumber {
                detailsThings.append("SN: \(serialNumber)")
            } else {
                detailsThings.append("ID: \(equipment?.id ?? "null")")
            }
            
            detailLabel.text = detailsThings.joined(separator: " | ")
        }
    }
}

class CheckOutCell: EquipmentDetailTableViewCell {
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df
    }()
    
    override fileprivate var type: CellConfiguration? {
        didSet {
            self.selectionStyle = .none
            if let type = type, case CellConfiguration.checkout(let name, let start, let end) = type {
                let df = dateFormatter
                let endString = end != nil ? df.string(from: end!) : "Now"
                textLabel?.text = name
                detailTextLabel?.text = "\(df.string(from: start)) - \(endString)"
            }
        }
    }
}

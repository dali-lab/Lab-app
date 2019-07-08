//
//  CheckOutListTableViewController.swift
//  iOS
//
//  Created by John Kotz on 12/19/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class EquipmentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    var filterView: EquipmentFilterView!
    var searchBar: UISearchBar!
    /// Used by the EquipmentScanAndListViewController to keep this view at some tallness at minumum
    let minimumTallness: CGFloat = 20
    
    /// The view controller containing this and the scanning view
    lazy var equipmentVC: EquipmentScanAndListViewController? = {
        return self.parent as? EquipmentScanAndListViewController
    }()
    
    /// The equipment pulled from the server
    var equipment: [DALIEquipment] = []
    /// Equipment split into sections and filtered
    var filteredEquipment = [Section: [DALIEquipment]]()
    /// Equipment split into sections
    var sectionedEquipment = [Section: [DALIEquipment]]()
    var sections: [Section] {
        return Section.all.filter({ (section) -> Bool in
            return filteredEquipment[section] != nil && filteredEquipment[section]!.count > 0
        })
    }
    
    var selectedIconName: String?
    var equipmentListener: Observation?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        filterView = Bundle.main.loadNibNamed("EquipmentFilterView",
                                              owner: self,
                                              options: nil)?.first as? EquipmentFilterView
        filterView.equipmentListViewController = self
        searchBar = filterView.searchBar
        updateSearchResults(with: nil)
        tableView.tableHeaderView = filterView
        
        searchBar.delegate = self
        self.updateData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        equipmentListener = DALIEquipment.observeAllEquipment { (_) in
            self.updateData()
        }
    }
    
    // MARK: - API
    
    /**
     The EquipmentScanAndListViewController will notify this view which position the view is in
     
     - parameter position: The current position of this card view on the view
     */
    public func cardDidReach(position: EquipmentScanAndListViewController.CardPostion) {
        tableView.isScrollEnabled = position == .tall
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        equipmentVC?.set(cardPosition: .max)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults(with: searchText)
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEquipment[sections[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = filteredEquipment[sections[indexPath.section]]![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "checkOutCell")
        
        if let cell = cell as? EquipmentCell {
            cell.equipment = device
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        equipmentVC?.showDetailView(for: filteredEquipment[sections[indexPath.section]]![indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    // MARK: - Helpers
    
    func filter(equipment: DALIEquipment, string: String) -> Bool {
        let isIconSame = selectedIconName == nil || equipment.iconName == selectedIconName
        guard !string.isEmpty else {
            return isIconSame
        }
        
        let lowerString = string.lowercased()
        let inName = equipment.name.lowercased().contains(lowerString)
        let inDescription = equipment.description?.lowercased().contains(lowerString) ?? false
        let inIcon = equipment.iconName?.lowercased().contains(lowerString) ?? false
        
        return (inName || inDescription || inIcon) && isIconSame
    }
    
    func updateSearchResults(with text: String?) {
        filteredEquipment.removeAll(keepingCapacity: false)
        filteredEquipment = sectionedEquipment.mapValues({ (list) in
            return list.filter { (equipment) -> Bool in
                return filter(equipment: equipment, string: text ?? "")
            }
        })
        
        self.tableView.reloadData()
    }
    
    func filterSelectedIcon(named iconName: String?) {
        selectedIconName = iconName
        updateSearchResults(with: searchBar.text)
    }
    
    func updateData() {
        _ = DALIEquipment.allEquipment().onSuccess { (equipment) -> [String] in
            self.equipment = equipment
            return self.equipment.compactMap { (equipment) -> String? in
                return equipment.iconName
            }.unique().sorted()
        }.mainThreadFuture.onSuccess { (iconNames) in
            self.sectionedEquipment[.youCheckedOut] = self.equipment.filter({ (device) -> Bool in
                return device.isCheckedOut && device.lastCheckedOut?.member == DALIMember.current
            })
            self.sectionedEquipment[.available] = self.equipment.filter({ (device) -> Bool in
                return !device.isCheckedOut
            })
            self.sectionedEquipment[.checkedOut] = self.equipment.filter({ (device) -> Bool in
                return device.isCheckedOut && device.lastCheckedOut?.member != DALIMember.current
            })
            self.filterView.update(with: iconNames)
            self.updateSearchResults(with: self.searchBar.text)
        }
    }
    
    // MARK: - Section
    
    /**
     An enumeration describing the different sections shown in this table view
     */
    enum Section {
        /// The equipment you checked out
        case youCheckedOut
        /// Equipment available for check out
        case available
        /// Things checked out by other people
        case checkedOut
        
        static let all: [Section] = [.youCheckedOut, .available, .checkedOut]
        var title: String {
            switch self {
            case .youCheckedOut: return "You Checked Out"
            case .available: return "Available"
            case .checkedOut: return "Checked Out"
            }
        }
    }
}

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

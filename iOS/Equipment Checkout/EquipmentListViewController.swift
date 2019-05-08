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
    var topLevelController: EquipmentScanAndListViewController? {
        return self.parent as? EquipmentScanAndListViewController
    }
    var equipment: [DALIEquipment] = []
    var splitEquipment: [[DALIEquipment]] {
        return [
            equipment.filter({ (device) -> Bool in
                return !device.isCheckedOut
            }),
            equipment.filter({ (device) -> Bool in
                return device.isCheckedOut
            })
        ]
    }
    var filteredEquipment = [[DALIEquipment]]()
    var selectedIconName: String?
    var listener: Observation?
    
    var minimumTallness: CGFloat {
        return 20
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listener = DALIEquipment.observeAllEquipment { (_) in
            self.updateData()
        }
    }
    
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
    
    deinit {
        listener?.stop()
    }
    
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
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        topLevelController?.set(cardPosition: .max)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults(with: searchText)
    }
    
    func updateSearchResults(with text: String?) {
        filteredEquipment.removeAll(keepingCapacity: false)
        filteredEquipment = splitEquipment.map { (equipment) in
            return equipment.filter { (equipment) -> Bool in
                return filter(equipment: equipment, string: text ?? "")
            }
        }
        
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
            self.filterView.update(with: iconNames)
            self.updateSearchResults(with: self.searchBar.text)
        }
    }
    
    func cardDidReach(position: EquipmentScanAndListViewController.CardPostion) {
        tableView.isScrollEnabled = position == .tall
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.all[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEquipment[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = filteredEquipment[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "checkOutCell")
        
        if let cell = cell as? EquipmentCell {
            cell.equipment = device
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        topLevelController?.showDetailView(for: filteredEquipment[indexPath.section][indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    enum Section {
        case available
        case checkedOut
        
        static let all: [Section] = [.available, .checkedOut]
        var title: String {
            switch self {
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

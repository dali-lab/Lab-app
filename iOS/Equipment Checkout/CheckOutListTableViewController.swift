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

class CheckOutListTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var topLevelController: CheckOutTopLevelViewController? {
        return self.parent as? CheckOutTopLevelViewController
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
    
    var minimumTallness: CGFloat {
        return 20
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateData()
    }
    
    override func viewDidLoad() {
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        self.updateData()
    }
    
    func updateData() {
        _ = DALIEquipment.allEquipment().onSuccess { (equipment) in
            self.equipment = equipment
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func cardDidReach(position: CheckOutTopLevelViewController.CardPostion) {
        tableView.isScrollEnabled = position == .tall
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.all[section].title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return splitEquipment[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = splitEquipment[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "checkOutCell")
        
        if let cell = cell as? EquipmentCell {
            cell.equipment = device
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        topLevelController?.showDetailView(for: splitEquipment[indexPath.section][indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 20 : 30
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

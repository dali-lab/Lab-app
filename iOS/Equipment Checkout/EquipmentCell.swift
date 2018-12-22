//
//  EquipmentCell.swift
//  iOS
//
//  Created by John Kotz on 12/19/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class EquipmentCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var detailLabel2: UILabel!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df
    }()
    
    var equipment: DALIEquipment? {
        didSet {
            guard let equipment = equipment else {
                return
            }
            
            titleLabel.text = equipment.name
            if equipment.isCheckedOut {
                guard let checkOut = equipment.lastCheckedOut else {
                    return
                }
                
                if DALIMember.current == checkOut.member {
                    detailLabel.text = "Checked out by: You"
                } else {
                    detailLabel.text = "Checked out by: \(checkOut.member.name)"
                }
                
                var dateString = "Unknown"
                if let endDate = checkOut.projectedEndDate {
                    dateString = dateFormatter.string(from: endDate)
                }
                detailLabel2.text = "Expected return: \(dateString)"
            } else {
                if let checkOut = equipment.lastCheckedOut {
                    detailLabel.text = "Last checked out: \(checkOut.member.name)"
                } else {
                    detailLabel.text = "Available"
                }
                detailLabel2?.text = nil
            }
        }
    }
}

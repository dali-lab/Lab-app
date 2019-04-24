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
    @IBOutlet weak var iconImageView: UIImageView!
    
    lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df
    }()
    
    var equipment: DALIEquipment? {
        didSet {
            guard let equipment = equipment else { return }
            
            // Assign the name and icon to the titleLabel and iconImageView
            titleLabel.text = equipment.name
            iconImageView.image = equipment.iconName != nil ? UIImage(named: equipment.iconName!) : nil
            detailLabel.text = "Available"
            
            switch equipment.type {
            case .single: // If the equipment is a single device
                let checkOut = equipment.lastCheckedOut
                
                // Configure the detail label
                // "Available" if it has never been checked out
                // "Last checked out: \(member name)" if it is available
                // "Checked out by: \(member name)" if checked out
                if let checkOut = checkOut {
                    let isYou = DALIMember.current == checkOut.member
                    let memberText = isYou ? "You" : checkOut.member.name
                    let startingText = equipment.isCheckedOut ? "Checked out by" : "Last checked out"
                    
                    detailLabel.text = "\(startingText): \(memberText)"
                }
                
                // Get an expected return date string
                var dateString = "Unknown"
                if let endDate = checkOut?.expectedReturnDate {
                    dateString = dateFormatter.string(from: endDate)
                }
                detailLabel2.text = "Expected return: \(dateString)"
                detailLabel2.isHidden = !equipment.isCheckedOut
            
            case .collection: // If the equipment is a collection of items
                let numAvailable = equipment.totalStock - equipment.checkingOutMembers.count
                detailLabel.text = "\(numAvailable)/\(equipment.totalStock) Available"
                detailLabel2.isHidden = true
            }
        }
    }
}

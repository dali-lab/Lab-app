//
//  EquipmentFilterViewIconCell.swift
//  iOS
//
//  Created by John Kotz on 5/2/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation

class EquipmentFilterIconCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var selectionView: UIView!
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.selectionView.alpha = self.isSelected ? 1.0 : 0
                self.image.tintColor = self.isSelected ? UIColor.white : UIColor.black
                self.image.alpha = self.isSelected ? 0.7 : 0.5
            }
        }
    }
}

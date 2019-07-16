//
//  EquipmentCreateIconPickerRow.swift
//  iOS
//
//  Created by John Kotz on 7/15/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import Eureka

public class EquipmentCreateIconPickerCell: Cell<String>, CellType,
                                            UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    
    let images = ["iphone", "ipad", "ipad pro", "charger", "android phone", "alexa",
                  "keyboard", "laptop", "mouse", "raspberry", "smart watch", "stylus", "vr"]
    
    public override func setup() {
        super.setup()
        collectionView.register(UINib(nibName: "EquipmentFilterIconCell", bundle: nil),
                                forCellWithReuseIdentifier: "cell")
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.flashScrollIndicators()
    }
    
    public override func update() {
        super.update()
        collectionView.flashScrollIndicators()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = images[indexPath.row]
        row.value = item
        row.updateCell()
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? EquipmentFilterIconCell {
            cell.image.image = UIImage(named: images[indexPath.row])
        }
        
        return cell
    }
}

public final class EquipmentCreateIconPickerRow: Row<EquipmentCreateIconPickerCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
        cellProvider = CellProvider<EquipmentCreateIconPickerCell>(nibName: "EquipmentCreateIconPickerRow")
    }
}

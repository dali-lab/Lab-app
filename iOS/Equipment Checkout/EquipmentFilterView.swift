//
//  EquipmentFilterView.swift
//  iOS
//
//  Created by John Kotz on 5/2/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit

class EquipmentFilterView: UIView,
                           UICollectionViewDelegate,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var equipmentListViewController: CheckOutListTableViewController?
    var iconNames = [String]()
    var selectedIndexPath: IndexPath?
    var filterOpen = false
    
    override func awakeFromNib() {
        collectionView.register(UINib(nibName: "EquipmentFilterIconCell", bundle: nil),
                                forCellWithReuseIdentifier: "cell")
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func update(with iconNames: [String]) {
        self.iconNames = iconNames
        self.collectionView.reloadData()
    }
    
    @IBAction func filterButtonPressed(_ sender: Any) {
        filterOpen = !filterOpen
        if let selectedIndexPath = selectedIndexPath {
            collectionView.deselectItem(at: selectedIndexPath, animated: true)
        }
        selectedIndexPath = nil
        equipmentListViewController?.filterSelectedIcon(named: nil)
        collectionView.isHidden = !filterOpen
        
        var frame = self.frame
        frame.size.height = self.filterOpen ? 135 : 78
        self.frame = frame
        if let vc = self.equipmentListViewController {
            vc.tableView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iconNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.inset(by: collectionView.contentInset).height
        return CGSize(width: height, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let cell = cell as? EquipmentFilterIconCell {
            cell.image.image = UIImage(named: iconNames[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndexPath == indexPath {
            collectionView.deselectItem(at: indexPath, animated: true)
            selectedIndexPath = nil
            equipmentListViewController?.filterSelectedIcon(named: nil)
        } else {
            selectedIndexPath = indexPath
            equipmentListViewController?.filterSelectedIcon(named: iconNames[indexPath.row])
        }
    }
}

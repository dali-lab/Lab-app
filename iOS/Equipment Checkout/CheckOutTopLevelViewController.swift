//
//  CheckOutTopLevelViewController.swift
//  iOS
//
//  Created by John Kotz on 12/18/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI

class CheckOutTopLevelViewController: UIViewController {
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var cardTallnessConstraint: NSLayoutConstraint!
    @IBOutlet weak var cardView: CornerRadiusAndShadowView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var cardViewController: CheckOutListTableViewController?
    var qrViewController: CheckOutQRViewController?
    
    var cardPosition: CardPostion = .half
    var visibleAreaSize: CGSize {
        let frame = view.frame
        var inset: CGRect!
        if #available(iOS 11.0, *) {
            inset = frame.inset(by: view.safeAreaInsets)
        } else {
            let navBarHeight = navigationController!.navigationBar.frame.height
            inset = frame
            inset.origin.y += navBarHeight
            inset.size.height -= navBarHeight
        }
        inset.origin.y += 16
        inset.size.height -= 16
        return inset.size
    }
    var tallnessAtDragStart: CGFloat?
    var dragging = false
    
    override func viewDidLoad() {
        self.title = "Equipment"
        blurView.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        set(cardPosition: cardPosition, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !dragging {
            set(cardPosition: cardPosition, animated: false)
        }
    }
    
    // MARK: - API
    
    func set(cardTallness tallness: CGFloat) {
        cardTallnessConstraint.constant = -tallness
        qrViewController?.inactive = tallness == self.tallness(for: CardPostion.max)
        view.layoutIfNeeded()
        
        let max = self.tallness(for: .max)
        let min = self.tallness(for: .min)
        let percent = (tallness - min) / (max - min)
        blurView.alpha = percent
    }
    
    func tallness(for position: CardPostion) -> CGFloat {
        let min = cardViewController?.minimumTallness ?? 0
        return max(visibleAreaSize.height * CGFloat(position.percentVisible), min)
    }
    
    func showDetailView(for equipment: DALIEquipment) {
        self.performSegue(withIdentifier: "detailEquipment", sender: equipment)
    }
    
    enum CardPostion: String {
        case tall
        case half
        
        var percentVisible: Double {
            switch self {
            case .tall: return 1.0
            case .half: return 0.4
            }
        }
        
        var up: CardPostion? {
            switch self {
            case .tall: return nil
            case .half: return .tall
            }
        }
        var down: CardPostion? {
            switch self {
            case .half: return nil
            case .tall: return .half
            }
        }
        
        static let all: [CardPostion] = [.tall, .half]
        static let min: CardPostion = .half
        static let max: CardPostion = .tall
    }
    
    // MARK: - UI
    
    @IBAction func cardDidPan(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            dragging = true
            tallnessAtDragStart = -cardTallnessConstraint.constant
        } else if sender.state == .changed {
            let translation = sender.translation(in: cardView)
            let cappedTallness = cap(tallness: tallnessAtDragStart! - translation.y)
            
            set(cardTallness: cappedTallness)
        } else {
            dragging = false
            tallnessAtDragStart = nil
            let velocity = sender.velocity(in: cardView)
            var destinationPosition: CardPostion?
            
            if abs(velocity.y) > 0 {
                destinationPosition = velocity.y < 0 ? cardPosition.up : cardPosition.down
            } else {
                var minDifference = CGFloat.greatestFiniteMagnitude
                for position in CardPostion.all {
                    let tallness = self.tallness(for: position)
                    let diff = abs((-cardTallnessConstraint.constant) - tallness)
                    if diff < minDifference {
                        minDifference = diff
                        destinationPosition = position
                    }
                }
            }
            
            if let position = destinationPosition {
                set(cardPosition: position)
            } else {
                set(cardPosition: cardPosition)
            }
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? CheckOutListTableViewController {
            cardViewController = dest
        } else if let dest = segue.destination as? CheckOutQRViewController {
            qrViewController = dest
        } else if let dest = segue.destination as? EquipmentDetailTableViewController {
            dest.equipment = sender as? DALIEquipment
        }
    }
    
    // MARK: - Helpers
    
    func cardDidReach(position: CardPostion) {
        cardViewController?.cardDidReach(position: position)
    }
    
    func cap(tallness: CGFloat) -> CGFloat {
        let minTallness = self.tallness(for: CardPostion.min)
        let maxTallness = self.tallness(for: CardPostion.max)
        return max(min(tallness, maxTallness), minTallness)
    }
    
    func set(cardPosition position: CardPostion, velocity: CGFloat = 0, animated: Bool = true) {
        cardPosition = position
        func block() {
            self.set(cardTallness: self.tallness(for: position))
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: block) { (_) in
                self.cardDidReach(position: position)
            }
        } else {
            block()
            self.cardDidReach(position: position)
        }
    }
}

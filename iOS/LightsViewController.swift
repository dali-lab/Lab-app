//
//  LightViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 9/18/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import SCLAlertView
import ChromaColorPicker

/**
 View controller showing the interface for seeing and changing the state of the lights
 */
class LightsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LightsViewColorPickerCellDelegate {
    @IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var groupTitle: UILabel!
	@IBOutlet weak var viewHeight: NSLayoutConstraint!
	@IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var lightsMapView: UIView!
    @IBOutlet weak var lightsMap: UIImageView!
	@IBOutlet weak var onSwitch: UISwitch!
    @IBOutlet weak var selectionIndicator: UIView!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var podsButton: UIButton!
	@IBOutlet var overlays: [UIImageView]!
	
    var lightGroups: [DALILights.Group] = []
	var lightsObservation: Observation?
	var overlayLightsMap: UIImageView?
	var selectedGroup: DALILights.Group?
    var scenes: [String]? {
        guard let group = selectedGroup else {
            return nil
        }
        
        var scenes = group.scenes.filter { (scene) -> Bool in
            return scene.lowercased().range(of: "default") == nil
        }
        if scenes.count < group.scenes.count {
            scenes.insert("Default", at: 0)
        }
        return scenes
    }
    
    // Values tracking the placement of the card
	var lastTranslation = CGPoint()
	var min: CGFloat = 0
    
    // MARK: - Lifecycle
	
	override func viewDidLoad() {
		for overlay in overlays {
			overlay.isHidden = true
		}
        let val = self.view.frame.height - (self.lightsMapView.frame.maxY + 20)
		min = max(val, 20)
		viewHeight.constant = min
		self.onSwitch.isHidden = true
		tableView.separatorStyle = .none
	}
	
	override func viewWillAppear(_ animated: Bool) {
		lightsObservation = DALILights.oberserveAll { (groups) in
			self.lightGroups = groups
			self.updateGroups()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		lightsObservation?.stop()
	}
    
    // MARK: - Actions
    
    @IBAction func groupButtonPressed(_ sender: UIButton) {
        var newGroup: DALILights.Group?
        if let accessibilityLabel = sender.accessibilityLabel {
            let group = getGroup(for: accessibilityLabel)
            newGroup = group?.name != selectedGroup?.name ? group : nil
        } else {
            newGroup = nil
        }
        
        selectedGroup = newGroup
        self.onSwitch.isHidden = (newGroup == nil)
        self.tableView.reloadData()
        
        guard let group = newGroup else {
            groupTitle.text = "NO GROUP SELECTED"
            UIView.animate(withDuration: 0.3, animations: {
                self.overlayLightsMap?.alpha = 0.0
                self.selectionIndicator.alpha = 0.0
            }, completion: { (_) in
                self.overlayLightsMap?.removeFromSuperview()
                self.overlayLightsMap = nil
                self.selectionIndicator.alpha = 1.0
                self.selectionIndicator.isHidden = true
            })
            return
        }
        
        updateAllAndPodsButtons(withNewGroup: group)
        groupTitle.text = group.formattedName.uppercased()
        self.onSwitch.isOn = group.isOn
        
        let imageLabel = sender.accessibilityLabel ?? "nil"
        showSelection(using: UIImage(named: "lights selection \(imageLabel.lowercased())"))
        
        if self.viewHeight.constant != min {
            self.viewHeight.constant = min
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
	
	@IBAction func done(_ sender: Any) {
		self.navigationController?.dismiss(animated: true) {}
	}
	
	@IBAction func dragged(_ sender: UIPanGestureRecognizer) {
		let max: CGFloat = [500, self.view.frame.height - 100].min()!
		
		if sender.state == .began || sender.state == .changed {
			// Still dragging
			let translation = sender.translation(in: self.view)
			if viewHeight.constant - translation.y > min {
				if viewHeight.constant - translation.y < max {
					viewHeight.constant -= translation.y
				} else {
					viewHeight.constant = max
				}
			} else {
				viewHeight.constant = min
			}
			
			sender.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
			self.lastTranslation = translation
		} else {
			// Released
			if viewHeight.constant >= max {
				viewHeight.constant = max
			} else if viewHeight.constant <= min {
				viewHeight.constant = min
			} else {
				UIView.setAnimationCurve(.linear)
				
				if abs(lastTranslation.y) > 2 {
					// We had some momentum...
					// If it was negative then it was upwards
                    animate(toTop: lastTranslation.y < 0, translation: lastTranslation.y, min: min, max: max)
				} else {
					// No momentum, so we will use whichever is closest
					// If the space between the bottom and the center is greater than that of the top, then it is closer to the top
					animate(toTop: abs(min - viewHeight.constant) > abs(max - viewHeight.constant),
                            translation: nil,
                            min: min,
                            max: max)
				}
			}
		}
	}
    
    @IBAction func powerChanged(_ sender: Any) {
        selectedGroup?.set(on: self.onSwitch.isOn).onFail { (error) in
            SCLAlertView().showError("Encountered an error", subTitle: "\(error.localizedDescription)")
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return selectedGroup != nil ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sectionFor(indexPath.section) {
        case .scenes: return 44
        case .color: return 300
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionNum: Int) -> Int {
        switch sectionFor(sectionNum) {
        case .scenes:
            return selectedGroup != nil ? selectedGroup!.scenes.count : 0
        case .color:
            return selectedGroup != nil ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionNum: Int) -> String? {
        return sectionFor(sectionNum).title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sectionFor(indexPath.section) {
        case .scenes:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
            cell.textLabel?.text = scenes![indexPath.row].capitalized
            cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            if scenes![indexPath.row].lowercased() == selectedGroup?.scene?.lowercased() {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            return cell
        case .color:
            var cell = tableView.dequeueReusableCell(withIdentifier: "colorPicker") as? LightsViewColorPickerCell
            if cell == nil {
                let nib = UINib.init(nibName: "LightsViewColorPickerCell", bundle: nil)
                tableView.register(nib, forCellReuseIdentifier: "colorPicker")
                cell = tableView.dequeueReusableCell(withIdentifier: "colorPicker") as? LightsViewColorPickerCell
            }
            
            var selectedColor: UIColor?
            if let color = selectedGroup?.color {
                selectedColor = UIColor.init(hex: color.replacingOccurrences(of: "#", with: ""), alpha: 1.0)
            }
            
            cell?.selectionStyle = .none
            cell?.setUp(color: selectedColor, delegate: self)
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sectionFor(indexPath.section) {
        case .scenes:
            guard let group = selectedGroup, let scenes = scenes else {
                return
            }
            
            group.set(scene: scenes[indexPath.row]).onSuccess { (_) in
                self.tableView.reloadData()
                }.onFail { (error) in
                    SCLAlertView().showError("Encountered error", subTitle: "\(error.localizedDescription)")
            }
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    // MARK: - LightsViewColorPickerCellDelegate
    
    func colorDidChange(to color: UIColor) {
        selectedGroup?.set(color: color.toHex()).onFail { (error) in
            SCLAlertView().showError("Encountered an error", subTitle: "\(error.localizedDescription)")
        }
    }
    
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        colorDidChange(to: color)
    }
    
    // MARK: - Helpers
    
    func sectionFor(_ section: Int) -> Section {
        return Section.all[section]
    }
	
	func updateGroups() {
		var map: [String: UIImageView] = [:]
		
		for overlay in self.overlays {
			map[overlay.accessibilityLabel!] = overlay
		}
		
		for group in lightGroups {
			if group.name == selectedGroup?.name {
				selectedGroup = group
			}
			
			if let imageView = map[group.name] {
				imageView.isHidden = !group.isOn
				if let avgColor = group.avgColor?.replacingOccurrences(of: "#", with: "") {
					imageView.image = (imageView.image?.withRenderingMode(.alwaysTemplate))!
					imageView.tintColor = UIColor(hex: avgColor, alpha: 1.0)
				}
			}
		}
		
		self.tableView.reloadData()
	}
    
    func getGroup(for accessibilityLabel: String) -> DALILights.Group? {
        let map = lightGroups.reduce(into: [String: DALILights.Group]()) { (result, group) in
            result[group.name] = group
        }
        
        switch accessibilityLabel {
        case "all": return DALILights.Group.all
        case "pods": return DALILights.Group.pods
        default: return map[accessibilityLabel]
        }
    }
    
    fileprivate func updateAllAndPodsButtons(withNewGroup group: DALILights.Group) {
        let isAll = group.name == DALILights.Group.all.name
        let isPods = group.name == DALILights.Group.pods.name
        
        if let allButton = allButton, let podsButton = podsButton, isAll || isPods {
            let button = isAll ? allButton : podsButton
            let selectionIndicatorFrame = CGRect(x: button.frame.origin.x + button.titleLabel!.frame.origin.x,
                                                 y: button.frame.origin.y + button.frame.height,
                                                 width: button.titleLabel!.frame.width,
                                                 height: 2)
            
            if selectionIndicator.isHidden {
                self.selectionIndicator.frame = selectionIndicatorFrame
                self.selectionIndicator.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.selectionIndicator.alpha = 1.0
                })
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.selectionIndicator.frame = selectionIndicatorFrame
                })
            }
            self.selectionIndicator.isHidden = false
        } else if !self.selectionIndicator.isHidden {
            self.selectionIndicator.alpha = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                self.selectionIndicator.alpha = 0.0
            }, completion: { (_) in
                self.selectionIndicator.alpha = 1.0
                self.selectionIndicator.isHidden = true
            })
        }
    }
    
    fileprivate func showSelection(using image: UIImage?) {
        if let image = image, let overlayLightsMap = overlayLightsMap {
            let oldMap = UIImageView(frame: self.lightsMap.frame)
            oldMap.image = overlayLightsMap.image
            oldMap.alpha = overlayLightsMap.alpha
            overlayLightsMap.image = image
            overlayLightsMap.alpha = 0.0
            self.lightsMapView.addSubview(oldMap)
            
            UIView.animate(withDuration: 0.3, animations: {
                oldMap.alpha = 0.0
                overlayLightsMap.alpha = 0.5
            }, completion: { (_) in
                oldMap.removeFromSuperview()
            })
        } else if let image = image {
            self.overlayLightsMap = UIImageView(frame: self.lightsMap.frame)
            self.overlayLightsMap!.image = image
            self.overlayLightsMap!.alpha = 0.0
            self.lightsMapView.addSubview(self.overlayLightsMap!)
            UIView.animate(withDuration: 0.3, animations: {
                self.overlayLightsMap!.alpha = 0.5
            })
        } else if let overlayLightsMap = self.overlayLightsMap {
            UIView.animate(withDuration: 0.3, animations: {
                overlayLightsMap.alpha = 0.0
            }, completion: { (_) in
                overlayLightsMap.removeFromSuperview()
                self.overlayLightsMap = nil
            })
        }
    }
    
    func animate(toTop: Bool, translation: CGFloat?, min: CGFloat, max: CGFloat) {
        var duration = 0.3
        
        if let translation = translation, abs(translation) > 10 {
            duration = 0.15
        }
        
        if toTop {
            self.viewHeight.constant = max
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            })
        } else {
            self.viewHeight.constant = min
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - Configuration
    
    enum Section {
        case scenes
        case color
        
        static let all: [Section] = [.scenes, .color]
        var title: String {
            switch self {
            case .scenes: return "Scenes"
            case .color: return "Color"
            }
        }
    }
}

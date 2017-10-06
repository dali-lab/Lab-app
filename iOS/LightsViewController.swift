
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

class LightsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
	
	var observation: Observation?
	var groups: [DALILights.Group] = []
	var overlayLightsMap: UIImageView?
	
	var selectedGroup : DALILights.Group?
	var lastTranslation = CGPoint()
	var min: CGFloat = 0
	
	override func viewDidLoad() {
		for overlay in overlays {
			overlay.isHidden = true
		}
		min = [self.view.frame.height - (self.lightsMapView.frame.maxY + 20), 20].max()!
		viewHeight.constant = min
		self.onSwitch.isHidden = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		observation = DALILights.oberserveAll { (groups) in
			self.groups = groups
			self.updateGroups()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		observation?.stop()
	}
	
	@IBAction func done(_ sender: Any) {
		self.navigationController?.dismiss(animated: true) {
			
		}
	}
	
	@IBAction func dragged(_ sender: UIPanGestureRecognizer) {
		let max: CGFloat = [500, self.view.frame.height - 100].min()!
		
		if sender.state == .began || sender.state == .changed {
			// Still dragging
			let translation = sender.translation(in: self.view)
			if (viewHeight.constant - translation.y > min) {
				if (viewHeight.constant - translation.y < max) {
					viewHeight.constant = viewHeight.constant - translation.y
				}else{
					viewHeight.constant = max
				}
			}else {
				viewHeight.constant = min
			}
			
			sender.setTranslation(CGPoint(x: 0, y: 0), in: self.view)
			self.lastTranslation = translation
		}else {
			// Released
			if(viewHeight.constant >= max) {
				viewHeight.constant = max
			}else if (viewHeight.constant <= min) {
				viewHeight.constant = min
			}else{
				UIView.setAnimationCurve(.linear)
				
				func animate(toTop: Bool, translation: CGFloat?) {
					var duration = 0.3
					
					if let translation = translation, abs(translation) > 10 {
						duration = 0.15
					}
					
					if toTop {
						self.viewHeight.constant = max;
						UIView.animate(withDuration: duration, animations: {
							self.view.layoutIfNeeded()
						})
					}else{
						self.viewHeight.constant = min;
						UIView.animate(withDuration: duration, animations: {
							self.view.layoutIfNeeded()
						})
					}
				}
				
				if (abs(lastTranslation.y) > 2) {
					// We had some momentum...
					// If it was negative then it was upwards
					animate(toTop: lastTranslation.y < 0, translation: lastTranslation.y)
				}else{
					// No momentum, so we will use whichever is closest
					// If the space between the bottom and the center is greater than that of the top, then it is closer to the top
					animate(toTop: abs(min - viewHeight.constant) > abs(max - viewHeight.constant), translation: nil)
				}
			}
		}
	}
	
	func updateGroups() {
		var map: [String:UIImageView] = [:]
		
		for overlay in self.overlays {
			map[overlay.accessibilityLabel!] = overlay
		}
		
		for group in groups {
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
	
	@IBAction func powerChanged(_ sender: Any) {
		selectedGroup?.set(on: self.onSwitch.isOn, callback: { (success, error) in
			if error != nil {
				SCLAlertView().showError("Encountered an error", subTitle: "")
			}
		})
	}
	
	@IBAction func buttonPressed(_ sender: UIButton) {
		var map: [String: DALILights.Group] = [:]
		
		for group in groups {
			map[group.name] = group
		}
		
		let prevGroup = selectedGroup
		if sender.accessibilityLabel == "all" {
			selectedGroup = DALILights.Group.all
			groupTitle.text = DALILights.Group.all.name.uppercased()
			self.onSwitch.isHidden = false
            self.tableView.reloadData()
		}else if sender.accessibilityLabel == "pods" {
			selectedGroup = DALILights.Group.pods
			groupTitle.text = DALILights.Group.pods.name.uppercased()
			self.onSwitch.isHidden = false
			self.tableView.reloadData()
		}else if let group = map[sender.accessibilityLabel!] {
			selectedGroup = group
			groupTitle.text = group.formattedName.uppercased().replacingOccurrences(of: "POD:", with: "")
			self.tableView.reloadData()
			self.onSwitch.isHidden = false
		}else{
			self.onSwitch.isHidden = true
		}
		
		
		if selectedGroup?.name == prevGroup?.name {
			selectedGroup = nil
			self.onSwitch.isHidden = true
            self.tableView.reloadData()
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
		
		var image: UIImage!
        var button: UIButton! = nil
		switch sender.accessibilityLabel! {
		case "all":
			image = #imageLiteral(resourceName: "lights_all_overlay")
            button = allButton
		case "conference":
			image = #imageLiteral(resourceName: "lights_conference_overlay")
		case "tvspace":
			image = #imageLiteral(resourceName: "lights_tvspace_overlay")
		case "workstations":
			image = #imageLiteral(resourceName: "lights_workstations_overlay")
		case "kitchen":
			image = #imageLiteral(resourceName: "lights_kitchen")
		case "pods":
			image = #imageLiteral(resourceName: "lights_pods_overlay")
            button = podsButton
		default:
			image = nil
		}
        
        if sender.accessibilityLabel!.range(of: "pod:") != nil {
            if sender.accessibilityLabel == "pod:appa" {
                image = #imageLiteral(resourceName: "lights_pod_appa_overlay")
            }else if sender.accessibilityLabel == "pod:momo" {
                image = #imageLiteral(resourceName: "lights_pod_momo_overlay")
            }else if sender.accessibilityLabel == "pod:pabu" {
                image = #imageLiteral(resourceName: "lights_pod_pabu_overlay")
            }
        }
        
        if let button = button {
            if selectionIndicator.isHidden {
                self.selectionIndicator.frame = CGRect(x: button.frame.origin.x + button.titleLabel!.frame.origin.x, y: button.frame.origin.y + button.frame.height, width: button.titleLabel!.frame.width, height: 2)
                self.selectionIndicator.alpha = 0.0
                self.selectionIndicator.isHidden = false
                UIView.animate(withDuration: 0.3, animations: {
                    self.selectionIndicator.alpha = 1.0
                })
            }else{
                UIView.animate(withDuration: 0.3, animations: {
                    self.selectionIndicator.frame = CGRect(x: button.frame.origin.x + button.titleLabel!.frame.origin.x, y: button.frame.origin.y + button.frame.height, width: button.titleLabel!.frame.width, height: 2)
                })
            }
        }else if !self.selectionIndicator.isHidden {
            self.selectionIndicator.alpha = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                self.selectionIndicator.alpha = 0.0
            }, completion: { (_) in
                self.selectionIndicator.alpha = 1.0
                self.selectionIndicator.isHidden = true
            })
        }
		
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
		}else if let image = image {
			self.overlayLightsMap = UIImageView(frame: self.lightsMap.frame)
			self.overlayLightsMap!.image = image
			self.overlayLightsMap!.alpha = 0.0
			self.lightsMapView.addSubview(self.overlayLightsMap!)
			UIView.animate(withDuration: 0.3, animations: {
				self.overlayLightsMap!.alpha = 0.5
			})
		}else if let overlayLightsMap = self.overlayLightsMap {
			UIView.animate(withDuration: 0.3, animations: {
				overlayLightsMap.alpha = 0.0
			}, completion: { (_) in
				overlayLightsMap.removeFromSuperview()
				self.overlayLightsMap = nil
			})
		}
		
		if self.viewHeight.constant != min {
			self.viewHeight.constant = min;
			UIView.animate(withDuration: 0.3, animations: {
				self.view.layoutIfNeeded()
			})
		}
	}
	
	func getScenes(_ group: DALILights.Group) -> [String] {
		var scenes = group.scenes.filter { (scene) -> Bool in
			return scene.lowercased().range(of: "default") == nil
		}
		
		if scenes.count < group.scenes.count {
			scenes.insert("Default", at: 0)
		}
		
		return scenes
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return selectedGroup != nil ? 2 : 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return selectedGroup != nil ? selectedGroup!.scenes.count : 0
		case 1:
			return selectedGroup != nil ? 1 : 0
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Scenes"
		case 1:
			return "Color"
		default:
			return "Unknown"
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		
		switch indexPath.section {
		case 0:
			cell.textLabel?.text = getScenes(selectedGroup!)[indexPath.row].capitalized
			
			if getScenes(selectedGroup!)[indexPath.row].lowercased() == selectedGroup?.scene?.lowercased() {
				tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}else{
				tableView.deselectRow(at: indexPath, animated: true)
			}
			break
		case 1:
			let newCell = UITableViewCell(style: .subtitle, reuseIdentifier: "colorCell")
			newCell.accessoryType = .disclosureIndicator
			newCell.textLabel?.text = "Color"
			newCell.detailTextLabel?.text = selectedGroup?.color
			
			cell = newCell
			break
		default:
			cell.textLabel?.text = "Unknown cell"
		}
		
		cell.backgroundColor = #colorLiteral(red: 0.9672333598, green: 0.9401755622, blue: 0.9525935054, alpha: 1)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section != 2 {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		switch indexPath.section {
		case 0:
			if let group = selectedGroup {
				group.set(scene: self.getScenes(group)[indexPath.row], callback: { (success, error) in
					if error != nil {
						SCLAlertView().showError("Encountered error", subTitle: "")
					}
					
					self.tableView.reloadData()
				})
			}
			break
		case 1:
			let alert = SCLAlertView()
			let textField = alert.addTextField()
			alert.addButton("Set color", action: {
				self.selectedGroup?.set(color: textField.text!, callback: { (success, error) in
					if error != nil {
						SCLAlertView().showError("Unsupported color", subTitle: "")
					}
					
					self.tableView.reloadData()
				})
			})
			
			alert.showInfo("Enter a color", subTitle: "")
			break
		default:
			return
		}
	}
}

extension UIColor {
	convenience init(hex: String, alpha: CGFloat) {
		let scanner = Scanner(string: hex)
		scanner.scanLocation = 0
		
		var rgbValue: UInt64 = 0
		
		scanner.scanHexInt64(&rgbValue)
		
		let r = (rgbValue & 0xff0000) >> 16
		let g = (rgbValue & 0xff00) >> 8
		let b = rgbValue & 0xff
		
		self.init(
			red: CGFloat(r) / 0xff,
			green: CGFloat(g) / 0xff,
			blue: CGFloat(b) / 0xff, alpha: alpha
		)
	}
}

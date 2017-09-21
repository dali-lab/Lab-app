
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
	@IBOutlet var buttons: [UIButton]!
	@IBOutlet weak var groupTitle: UILabel!
	@IBOutlet weak var viewHeight: NSLayoutConstraint!
	@IBOutlet weak var bottomView: UIView!
	@IBOutlet weak var allButton: UIButton!
	@IBOutlet weak var podsButton: UIButton!
	
	var observation: Observation?
	var groups: [DALILights.Group] = []
	
	var selectedGroup : DALILights.Group?
	var lastTranslation = CGPoint()
	var min: CGFloat = 0
	
	override func viewDidLoad() {
		min = [self.view.frame.height - (allButton.frame.origin.y + allButton.frame.height), 20].max()!
		viewHeight.constant = min
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
		var map: [String: UIButton] = [:]
		
		for button in buttons {
			map[button.accessibilityLabel!] = button
		}
		
		for group in groups {
			if let button = map[group.name] {
				button.backgroundColor = !group.isOn ? #colorLiteral(red: 0.4270302057, green: 0.4328257143, blue: 0.4326381683, alpha: 0.5) : #colorLiteral(red: 0.4348880351, green: 0.4349654913, blue: 0.4348778129, alpha: 0)
				
				if let color = group.avgColor, group.isOn {
					if button.backgroundColor != UIColor(hex: color.replacingOccurrences(of: "#", with: ""), alpha: 0.5) {
						UIView.animate(withDuration: 1.0, animations: {
							button.backgroundColor = UIColor(hex: color.replacingOccurrences(of: "#", with: ""), alpha: 0.5)
						})
					}
				}
			}
			
			if group.name == selectedGroup?.name {
				selectedGroup = group
			}
		}
		
		self.tableView.reloadData()
	}
	
	func powerChanged(isOn: Bool) {
		selectedGroup?.set(on: isOn, callback: { (success, error) in
			if error != nil {
				SCLAlertView().showError("Encountered an error", subTitle: "")
			}
		})
	}
	
	@IBAction func buttonPressed(_ sender: UIButton) {
		var map: [String: DALILights.Group] = [:]
		podsButton.isEnabled = true
		allButton.isEnabled = true
		
		for group in groups {
			map[group.name] = group
		}
		
		if let group = map[sender.accessibilityLabel!] {
			selectedGroup = group
			groupTitle.text = group.formattedName
			self.tableView.reloadData()
		}
		
		if self.viewHeight.constant != min {
			self.viewHeight.constant = min;
			UIView.animate(withDuration: 0.3, animations: {
				self.view.layoutIfNeeded()
			})
		}
	}
	
	@IBAction func podsButtonPressed(_ sender: UIButton) {
		podsButton.isEnabled = false
		allButton.isEnabled = true
		
		self.selectedGroup = DALILights.Group.pods
		groupTitle.text = DALILights.Group.pods.formattedName
		self.tableView.reloadData()
	}
	
	@IBAction func allButtonPressed(_ sender: UIButton) {
		podsButton.isEnabled = true
		allButton.isEnabled = false
		
		self.selectedGroup = DALILights.Group.all
		groupTitle.text = DALILights.Group.all.formattedName
		self.tableView.reloadData()
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return selectedGroup != nil ? 3 : 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return selectedGroup != nil ? 1 : 0
		case 1:
			return selectedGroup != nil ? 1 : 0
		case 2:
			return selectedGroup != nil ? selectedGroup!.scenes.count : 0
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Power"
		case 1:
			return "Color"
		case 2:
			return "Scenes"
		default:
			return "Unknown"
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		
		switch indexPath.section {
		case 0:
			let newCell = tableView.dequeueReusableCell(withIdentifier: "powerCell", for: indexPath) as! PowerCell
			
			newCell.powerSwitch.isOn = selectedGroup?.isOn ?? false
			newCell.delegate = self
			newCell.selectionStyle = .none
			
			cell = newCell
			break
		case 1:
			let newCell = UITableViewCell(style: .subtitle, reuseIdentifier: "colorCell")
			newCell.accessoryType = .disclosureIndicator
			newCell.textLabel?.text = "Color"
			newCell.detailTextLabel?.text = selectedGroup?.color
			
			cell = newCell
			break
		case 2:
			cell.textLabel?.text = selectedGroup?.scenes[indexPath.row].capitalized
			
			if selectedGroup?.scenes[indexPath.row] == selectedGroup?.scene {
				tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}else{
				tableView.deselectRow(at: indexPath, animated: true)
			}
			break
		default:
			cell.textLabel?.text = "Unknown cell"
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section != 2 {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		switch indexPath.section {
		case 0:
			return
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
		case 2:
			if let group = selectedGroup {
				group.set(scene: group.scenes[indexPath.row], callback: { (success, error) in
					if error != nil {
						SCLAlertView().showError("Encountered error", subTitle: "")
					}
					
					self.tableView.reloadData()
				})
			}
			break
		default:
			return
		}
	}
}

class PowerCell : UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var powerSwitch: UISwitch!
	
	var delegate: LightsViewController?
	
	@IBAction func valueChanged(_ sender: UISwitch) {
		delegate?.powerChanged(isOn: sender.isOn)
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

//
//  ViewController.swift
//  DALI Lab tvOS
//
//  Created by John Kotz on 6/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import DALI

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ViewProtocol {
	func startSlideshow() {
		self.performSegue(withIdentifier: "startSlideshow", sender: nil)
	}
	
	func endSlideshow() {
		
	}
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var peopleInLabLabel: UILabel!
	@IBOutlet weak var peopleInLabView: UIView!
	@IBOutlet weak var foodLabel: UILabel!
	@IBOutlet weak var peopleInLabViewHeight: NSLayoutConstraint!
	@IBOutlet weak var overlayContainer: UIView!
	
	let wrapLabel = UILabel()
	let fadeIn = #imageLiteral(resourceName: "Fadein")
	let fadeOut = #imageLiteral(resourceName: "Fadeout")
	let nonFaded = #imageLiteral(resourceName: "nonFaded")
	
	var events = [DALIEvent]()
	var tim: DALILocation.Tim?
	var people: [DALIMember] = []
	
	var sharedObserver: Observation?
	var timObserver: Observation?
	var upcomingObserver: Observation?
	var foodObserver: Observation?
	
	var memberEnterObservation: Observation?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		memberEnterObservation = DALILocation.observeMemberEnter { (member) in
			self.showOverlay(member: member.name)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		
		self.peopleInLabLabel.text = "People in the lab: Loading..."
		sharedObserver = DALILocation.Shared.observe { (people, _) in
			DispatchQueue.main.async {
				if let people = people {
					self.people = people
					
					self.updateLabel()
				}
			}
		}
		
		timObserver = DALILocation.Tim.observe(callback: { (tim, _) in
			if let tim = tim {
				self.tim = tim
				DispatchQueue.main.async {
					self.updateLabel()
				}
			}
		})
		AppDelegate.shared.currentView = self
		
		upcomingObserver = DALIEvent.observeUpcoming { (events, error) in
			DispatchQueue.main.async {
				if let error = error {
					print("Encountered error: \(error)")
					return
				}
				
				guard let events = events else {
					return
				}
				
				self.events = events.sorted(by: { (event1, event2) -> Bool in
					return event1.start < event2.start
				})
				self.tableView.reloadData()
			}
		}
		
		self.foodLabel.text = "Loading..."
		foodObserver = DALIFood.observeFood(callback: { (food) in
			self.foodLabel.text = food ?? "No food tonight"
		})
	}
	
	func showOverlay(member: String) {
		let effectView = UIVisualEffectView()
		effectView.frame = self.overlayContainer.frame
		self.overlayContainer.addSubview(effectView)
		let label = UILabel()
		label.text = "Welcome \(member)! 👋"
		label.font = UIFont(name: "Avenir Next", size: 50.0)
		label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		label.alpha = 0.0
		label.sizeToFit()
		label.frame = CGRect(x: self.overlayContainer.frame.origin.x - label.frame.width,
                             y: self.overlayContainer.frame.height / 2,
                             width: label.frame.width,
                             height: label.frame.height)
		self.overlayContainer.addSubview(label)
		
		UIView.animate(withDuration: 0.5, animations: {
			effectView.effect = UIBlurEffect(style: .dark)
			label.alpha = 1.0
			label.frame = CGRect(x: self.overlayContainer.frame.width/2 - label.frame.width/2,
                                 y: self.overlayContainer.frame.height / 2 - label.frame.height / 2,
                                 width: label.frame.width,
                                 height: label.frame.height)
		}, completion: { (_) in
			UIView.animate(withDuration: 0.5, delay: 10, options: [], animations: {
				label.frame = CGRect(x: self.overlayContainer.frame.width,
                                     y: self.overlayContainer.frame.height / 2 - label.frame.height / 2,
                                     width: label.frame.width,
                                     height: label.frame.height)
				label.alpha = 0.0
				effectView.alpha = 0
			}, completion: { (_) in
				effectView.removeFromSuperview()
				label.removeFromSuperview()
			})
		})
	}
	
	func updateLabel() {
		self.peopleInLabLabel.text = ""
		var names = [String]()
		for person in people {
			names.append(person.name)
		}
		
		if let tim = tim, tim.inDALI {
			names.append("Tim Tregubov")
		}
		
		names.sort()
		
		if names.count > 0 {
			var text = ""
			
			var first = true
			for name in names {
				if !first {
					text += ", "
				}
				first = false
				text += name
			}
			
			self.peopleInLabLabel.text = "People in the lab: \(text)"
		} else {
			self.peopleInLabLabel.text = "No people in the lab"
		}
		
		if let tim = tim, tim.inOffice {
			self.peopleInLabLabel.text = "Tim is in his office; \(self.peopleInLabLabel.text!)"
		}
		
		self.peopleInLabLabel.lineBreakMode = .byWordWrapping
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		upcomingObserver?.stop()
		sharedObserver?.stop()
		timObserver?.stop()
		foodObserver?.stop()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventCell
		cell.event = events[indexPath.row]
		
		return cell
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return events.count
	}
}

//
//  ViewController.swift
//  DALI Lab tvOS
//
//  Created by John Kotz on 6/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

import UIKit
import DALI

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var peopleInLabLabel: UILabel!
	@IBOutlet weak var peopleInLabView: UIView!
	let wrapLabel = UILabel()
	let fadeIn = #imageLiteral(resourceName: "Fadein")
	let fadeOut = #imageLiteral(resourceName: "Fadeout")
	let nonFaded = #imageLiteral(resourceName: "nonFaded")
	
	var events = [DALIEvent]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.peopleInLabLabel.text = "People in the lab: Loading..."
		DALILocation.Shared.get { (people, error) in
			DispatchQueue.main.async {
				if let people = people, people.count > 0 {
					var text = ""
					
					var first = true
					for person in people {
						if !first {
							text += ", "
						}
						first = false
						text += person.name
					}
					
					self.peopleInLabLabel.text = "People in the lab: \(text)"
				} else {
					self.peopleInLabLabel.text = "No people in the lab"
				}
			}
		}
		
		DALIEvent.getUpcoming { (events, error) in
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


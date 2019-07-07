//
//  MainViewController.swift
//  
//
//  Created by John Kotz on 6/25/17.
//
//

import Foundation
import UIKit
import SCLAlertView
import UserNotifications
import DALI
import EmitterKit
import OneSignal

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AlertShower {
	@IBOutlet weak var daliImage: UIImageView!
	@IBOutlet weak var internalView: UIView!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var peopleButton: UIButton!
	@IBOutlet weak var foodLabel: UILabel!
    @IBOutlet weak var lightButton: UIButton!
    
	var viewShown = false
	var loginTransformAnimationDone = false
    var locationListener: Listener?
	var animationDone: (() -> Void)?
	
	var eventsObserver: Observation?
	var foodObserver: Observation?
	
	var events = [[DALIEvent]]()
	var sections = [String]()
    
    // MARK: - Lifecycle
	
	override func viewDidLoad() {
        super.viewDidLoad()
		if signedIn {
            locationListener = BeaconController.shared.locationChangedEvent.on { (location) in
                self.received(location: location)
            }
			
			foodObserver = DALIFood.observeFood { (food) in
				DispatchQueue.main.async {
					self.foodLabel.text = food == nil ? "No Food Tonight" : "Food Tonight: \(food!)"
				}
			}
            eventsObserver = DALIEvent.observeUpcoming { (events, error) in
                self.received(events: events, error: error)
            }
        } else {
            eventsObserver = DALIEvent.observePublicUpcoming { (events, error) in
                self.received(events: events, error: error)
            }
        }
		
		AppDelegate.shared.mainViewController = self
		tableView.estimatedRowHeight = 140
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateView(animated: animated)
        if !viewShown {
            startAnimation()
        }
    }
    
    func updateView(animated: Bool) {
        animateThis(animated, duration: 0.3) {
            self.peopleButton.isHidden = !signedIn
            self.peopleButton.isEnabled = signedIn
            self.lightButton.isHidden = !signedIn
            self.lightButton.isEnabled = signedIn
            self.foodLabel.isHidden = !signedIn
            self.foodLabel.text = ""
            if signedIn {
                self.received(location: BeaconController.shared.currentLocation)
            } else {
                self.locationLabel.text = "Not signed in"
            }
        }
        
        BeaconController.shared.updateLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let dest = nav.topViewController as? CheckinViewController {
            dest.event = sender as? DALIEvent
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    deinit {
        eventsObserver?.stop()
        foodObserver?.stop()
    }
    
    // MARK: - Actions
    
    @IBAction func settingsButtonPressed(_ sender: UIButton) {
        if signedIn {
            self.performSegue(withIdentifier: "showSettings", sender: nil)
        } else {
            let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false))
            alert.addButton("Sign In", action: {
                (UIApplication.shared.delegate as! AppDelegate).signOut()
            })
            alert.addButton("Nah...", action: {
                
            })
            
            alert.showInfo("Sign In?", subTitle: "")
        }
    }
    
    // MARK: - AlertShower
	
	func showAlert(alert: SCLAlertView, title: String, subTitle: String, color: UIColor, image: UIImage) {
		animationDone = { () in
            DispatchQueue.main.async {
                _ = alert.showCustom(title, subTitle: subTitle, color: color, icon: image)
            }
		}
	}
    
    // MARK: - UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
        
        if let cell = cell as? MainViewControllerEventCell {
            cell.event = events[indexPath.section][indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return MainViewControllerEventsListHeaderView(title: sections[section],
                                                      active: events[section].count > 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let event = events[indexPath.section][indexPath.row]
		let alert = SCLAlertView(appearance: SCLAlertView.noCloseButton)
        
        // Everyone can add it to their calendar
		alert.addButton("Add to your calendar") {
			tableView.deselectRow(at: indexPath, animated: true)
			
			CalendarController.shared.event = event
			CalendarController.shared.showCalendarChooser(on: self)
		}
        
        // Special things for members...
        if let member = DALIMember.current {
            if event.isNow {
                alert.addButton("Enable Checkin") {
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.performSegue(withIdentifier: "showCheckin", sender: event)
                }
            }
            
            if member.isAdmin {
                alert.addButton("Notify members") {
                    self.notifyMembersPressed(on: event)
                }
            }
        }
        
        // Cancel
		alert.addButton("Cancel") {
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		alert.showInfo("Whats up?", subTitle: "What do you want to do with \(event.name)?")
		tableView.deselectRow(at: indexPath, animated: true)
	}
    
    // MARK: - Helpers
    
    /// The button to notify members was pressed. Confirm this is really what they want
    func notifyMembersPressed(on event: DALIEvent) {
        let alert = SCLAlertView(appearance: SCLAlertView.noCloseButton)
        
        alert.addButton("Yes!") {
            self.notifyMembers(on: event)
        }
        
        alert.addButton("Actually no...", action: {})
        alert.showNotice("Really notify?",
                         subTitle: "This will notify all DALI member devices that are signed in" +
                                   " about the time (in hours, or mintues if < 1 hour) until event" +
                                   " starts. Are you sure you want to this?")
    }
    
    /// Notify all members of the upcoming event (and how long until then)
    func notifyMembers(on event: DALIEvent) {
        var time: Int = Calendar.current.dateComponents([.minute], from: Date(), to: event.start).minute ?? 0
        var units = "minutes"
        
        if time >= 60 {
            units = "hours"
            time = Calendar.current.dateComponents([.hour], from: Date(), to: event.start).hour ?? 0
            
            if time == 1 {
                units = "hour"
            }
        }
        
        _ = DALIapi.sendSimpleNotification(with: "\(event.name) starts soon!",
            and: "The event \(event.name) is starting in \(time) \(units)",
            to: "signedIn")
    }
    
    /// Did receive information about where the phone is
    func received(location: String?) {
        DispatchQueue.main.async {
            if let location = location {
                self.locationLabel.text = "In \(location)"
            } else {
                self.locationLabel.text = "Not in DALI Lab"
            }
        }
    }
    
    /// Events were received. Process them and update the view
    func received(events: [DALIEvent]?, error: Error?) {
        guard let eventsArr = events else { return }
        if let error = error {
            print("Failed to get events! Reason:")
            
            switch error {
            case DALIError.General.Unauthorized: print("Unauthorized")
            default: print("Unknown: \(error)")
            }
            
            return
        }
        
        let events = eventsArr.sorted(by: { (event1, event2) -> Bool in
            return event1.start < event2.end
        })
        
        self.events.removeAll()
        var today = [DALIEvent]()
        var week = [DALIEvent]()
        var next = [DALIEvent]()
        
        let calendar = NSCalendar.current
        let cal = Calendar.current
        var comps = cal.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date())
        comps.weekday = 7 // Saturday
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        let endWeek = cal.date(from: comps)!
        
        // Split the events into today, this week, and next week
        for event in events {
            if calendar.isDateInToday(event.start) || event.isNow {
                today.append(event)
            } else if event.start < endWeek {
                week.append(event)
            } else {
                next.append(event)
            }
        }
        
        if today.count > 0 {
            self.events.append(today)
            self.sections.append("Today")
        }
        self.events.append(week)
        self.sections.append("This Week")
        if next.count > 0 {
            self.events.append(next)
            self.sections.append("Next Week")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    /// Animate from the login or loading screen
    func startAnimation() {
        let mid = self.view.frame.size.height / 2.0
        let top = mid - self.daliImage.frame.height / 2.0
        var transformedTop = top
        if self.loginTransformAnimationDone {
            transformedTop = top - 90
        }
        
        daliImage.center = CGPoint(x: daliImage.center.x,
                                   y: daliImage.center.y + (transformedTop - self.daliImage.frame.origin.x / 2 + 18))
        
        daliImage.transform = CGAffineTransform(scaleX: 3.0/2.0, y: 3.0/2.0)
        internalView.alpha = 0.0
        
        UIView.animateKeyframes(withDuration: 2, delay: 0.5, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.75) {
                // Reset the transform and let the layout take care of the rest
                self.daliImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                self.internalView.alpha = 1.0
            }
        }) { (_) in
            if let animationDone = self.animationDone {
                animationDone()
            }
            self.viewShown = true
        }
    }
}

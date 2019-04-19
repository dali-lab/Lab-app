//
//  TopLevelVotingViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/30/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import DALI
import FutureKit
import EmitterKit

class TopLevelVotingViewController: UITableViewController {
	var pastEvents: [DALIEvent.VotingEvent] = []
	var currentEvents: [DALIEvent.VotingEvent] = []
    var observation: EventListener<[DALIEvent.VotingEvent]>?
	
	override func viewDidLoad() {
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Events", style: .plain, target: nil, action: nil)
        
        _ = self.updateData().mainThreadFuture.onSuccess { (_) in
            self.tableView.reloadData()
        }
        
//        observation = DALIEvent.VotingEvent.observe().on { (_) in
//            let _ = self.updateData().onSuccess(block: { (_) in
//                self.tableView.reloadData()
//            })
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observation?.isListening = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        observation?.isListening = false
    }
    
    func updateData() -> Future<Any> {
//        DALIEvent.VotingEvent.getCurrent { (currentEvents, error) in
//            self.currentEvents = currentEvents
//            let futures = currentEvents.map({ (event) -> Future<Bool> in
//                guard let id = event.id else {
//                    return Future<Bool>(success: false)
//                }
//                let promise = Promise<Bool>()
//                event.haveVoted(callback: { (haveVoted, error) in
//                    let prevHaveVoted = UserDefaults.standard.bool(forKey:  "hasVoted:\(id)")
//                    UserDefaults.standard.set(haveVoted || prevHaveVoted, forKey: "hasVoted:\(id)")
//                    promise.completeWithSuccess(haveVoted || prevHaveVoted)
//                })
//                return promise.future
//            })
//
//            currentPromise.completeUsingFuture(FutureBatch(futures).future.futureAny)
//        }
        
        let future1 = DALIEvent.VotingEvent.getCurrent().onSuccess { (events) -> Future<Any> in
            self.currentEvents = events
            return FutureBatch(self.currentEvents.map({ (event) -> Future<Void> in
                guard let id = event.id else {
                    return Future(success: Void())
                }
                return event.haveVoted().onSuccess { (haveVoted) in
                    let prevHaveVoted = UserDefaults.standard.bool(forKey: "hasVoted:\(id)")
                    UserDefaults.standard.set(haveVoted || prevHaveVoted, forKey: "hasVoted:\(id)")
                }
            })).batchFuture.futureAny
        }
        
        let future2 = DALIEvent.VotingEvent.getReleasedEvents().onSuccess { (events) in
            self.pastEvents = events.sorted(by: { (event1, event2) -> Bool in
                return event1.start > event2.start
            })
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(eventVoteEnteredOrExited(notification:)),
                                               name: Notification.Name.Custom.EventVoteEnteredOrExited,
                                               object: nil)
        
        return FutureBatch([future1, future2]).resultsFuture.futureAny
    }
    
    @objc func eventVoteEnteredOrExited(notification: NSNotification) {
        let entering = notification.userInfo?["entering"] as? Bool ?? false
        // Do work ...
    }
	
	@IBAction func cancel(_ sender: Any) {
		self.dismiss(animated: true) { 
			
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 && currentEvents.count > 0 {
			let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
			
			let formatter = DateFormatter()
			formatter.dateStyle = .long
			
			cell.textLabel?.text = currentEvents[indexPath.row].name
			cell.detailTextLabel?.text = formatter.string(from: currentEvents[indexPath.row].start)
			cell.accessoryType = .disclosureIndicator
			
			return cell
		}
		
		let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		
		cell.textLabel?.text = pastEvents[indexPath.row].name
		cell.detailTextLabel?.text = formatter.string(from: pastEvents[indexPath.row].start)
		cell.accessoryType = .disclosureIndicator
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 || currentEvents.count == 0 {
			return "Past"
		} else {
			return "Now Voting"
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return currentEvents.count > 0 ? 2 : 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 && currentEvents.count > 0 {
			return currentEvents.count
		} else {
			return pastEvents.count
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? ResultsVotingViewController {
            dest.event = sender as? DALIEvent.VotingEvent
		} else if let dest = segue.destination as? OrderedVotingViewController {
            dest.event = sender as? DALIEvent.VotingEvent
		} else if let dest = segue.destination as? UnorderedVotingViewController {
            dest.event = sender as? DALIEvent.VotingEvent
		} else if let dest = segue.destination as? HasVotedViewController {
			dest.event = sender as? DALIEvent.VotingEvent
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 70
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if indexPath.section == 0 && currentEvents.count > 0 {
            let currentEvent = currentEvents[indexPath.row]
            guard let currentEventID = currentEvent.id else {
                return
            }
            
			let hasVoted = UserDefaults.standard.bool(forKey: "hasVoted:\(currentEventID)")
			let ordered = currentEvent.config.ordered
			
			if hasVoted {
				self.performSegue(withIdentifier: "showHasVoted", sender: currentEvent)
			} else if ordered {
				self.performSegue(withIdentifier: "showOrderedVoting", sender: currentEvent)
			} else {
				self.performSegue(withIdentifier: "showUnorderedVoting", sender: currentEvents)
			}
		} else {
			self.performSegue(withIdentifier: "showPastEvent", sender: pastEvents[indexPath.row])
		}
	}
}

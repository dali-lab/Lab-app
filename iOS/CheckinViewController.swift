//
//  CheckinViewController.swift
//  DALI Lab
//
//  Created by John Kotz on 8/21/17.
//  Copyright © 2017 BrunchLabs. All rights reserved.
//

import Foundation
import UIKit
import ProximityKit
import CoreBluetooth
import SCLAlertView
import DALI

class CheckinViewController: UIViewController, CBPeripheralManagerDelegate, UITableViewDelegate, UITableViewDataSource {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		if peripheral.state == .poweredOn {
			if let region = region {
				advertiseDevice(region: region)
			}
		} else {
			SCLAlertView().showError("Bluetooth Off!", subTitle: "Turn on bluetooth to be able to ...")
		}
	}

	@IBOutlet weak var beacon1: UIImageView!
	@IBOutlet weak var beacon2: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var bottomView: UIView!
	
	var members: [DALIMember] = []
	
	var region: CLBeaconRegion?
	var peripheral: CBPeripheralManager!
	var event: DALIEvent!
	var observer: Observation?
	var animating = true
	
	override func viewDidLoad() {
		beacon1.image = #imageLiteral(resourceName: "BeaconDisabled")
		beacon2.image = #imageLiteral(resourceName: "BeaconDisabled")
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                target: self,
                                                                action: #selector(self.done))
		
		bottomView.layer.cornerRadius = 20
		bottomView.layer.shadowRadius = 10
		bottomView.layer.shadowColor = UIColor.black.cgColor
		bottomView.layer.shadowOffset = CGSize.zero
		bottomView.layer.shadowOpacity = 0.4
		titleLabel.text = "Setting up..."
        
        event.enableCheckin().mainThreadFuture.onSuccess { (beaconInfo) in
            guard let major = beaconInfo.major, let minor = beaconInfo.minor else {
                throw DALIError.General.UnexpectedResponse
            }
            
            self.titleLabel.text = "Check In Enabled"
            self.beacon1.image = #imageLiteral(resourceName: "Beacon1")
            self.beacon2.image = #imageLiteral(resourceName: "Beacon2")
            self.animate()
            
            self.region = self.createBeaconRegion(major, minor)
            self.peripheral = CBPeripheralManager(delegate: self, queue: nil)
            _ = DALIEvent.checkIn(major: major, minor: minor)
        }.onFail { _ in
            let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false))
            
            alert.addButton("Done", action: {
                self.navigationController?.dismiss(animated: true, completion: nil)
            })
            
            alert.showError("Encountered error", subTitle: "Couldn't get check-in configuration from the server")
        }
	}
	
	@objc func done() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return members.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		
		cell.textLabel?.text = members[indexPath.row].name
		
		return cell
	}
	
	override func viewWillAppear(_ animated: Bool) {
		UIApplication.shared.isIdleTimerDisabled = true
		observer = event.observeMembersCheckedIn { (members) in
			self.members = members.sorted(by: { (member1, member2) -> Bool in
				return member1.name < member2.name
			})
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		UIApplication.shared.isIdleTimerDisabled = false
		peripheral.stopAdvertising()
		animating = false
		observer?.stop()
	}
	
	func createBeaconRegion(_ major: Int, _ minor: Int) -> CLBeaconRegion? {
		let proximityUUID = UUID(uuidString: checkInRangeID)
		let major: CLBeaconMajorValue = CLBeaconMajorValue(major)
		let minor: CLBeaconMinorValue = CLBeaconMajorValue(minor)
		let beaconID = "com.JohnKotz.DALI.DaliLabApp.CheckinRegion"
		
		return CLBeaconRegion(proximityUUID: proximityUUID!,
		                      major: major, minor: minor, identifier: beaconID)
	}
	
	func advertiseDevice(region: CLBeaconRegion) {
		let peripheralData = region.peripheralData(withMeasuredPower: nil)
		
		peripheral.startAdvertising(((peripheralData as NSDictionary) as! [String: Any]))
	}
	
	func animate() {
		beacon1.alpha = 1.0
		beacon2.alpha = 1.0
		
		UIView.animate(withDuration: 1.0, animations: {
			self.beacon2.alpha = 0.0
		}) { _ in
			UIView.animate(withDuration: 1.0, animations: {
				self.beacon2.alpha = 1.0
			}, completion: { _ in
				if self.animating { self.animate() }
			})
		}
	}
}

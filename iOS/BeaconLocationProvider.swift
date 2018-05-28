//
//  BeaconLocationProvider.swift
//  iOS
//
//  Created by John Kotz on 5/27/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import PromiseKit
import CoreBluetooth

class BeaconLocationProvider: GPSLocationProvider, CBCentralManagerDelegate {
    let bluetoothManager: CBCentralManager
    
    override init() {
        self.bluetoothManager = CBCentralManager(delegate: nil, queue: DispatchQueue(label: "BluetoothLocationProvider_bluetoothManager"))
        super.init()
        self.bluetoothManager.delegate = self
        priority = 5
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    override func requirementsAreMet() -> Bool {
        let locationRequirmentsMet = super.requirementsAreMet()
        return locationRequirmentsMet && bluetoothManager.state == .poweredOn
    }
}

//
//  TrackingModule.swift
//  iOS
//
//  Created by John Kotz on 7/8/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import DALI
import SwiftyJSON

class TrackingModule: NSObject, CLLocationManagerDelegate {
    let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    func startTracking() {
        locationManager.startMonitoring(for: DALIRegion.DALI.region)
        locationManager.startMonitoring(for: DALIRegion.timsOffice.region)
    }
    
    func askForPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func post(beaconRegion: CLRegion, path: String) {
        guard UIApplication.shared.applicationState == .background else {
            print("TrackingModule: canceling: not background")
            return
        }
        
        guard let beaconRegion = beaconRegion as? CLBeaconRegion else {
            print("TrackingModule: canceling: bad region")
            return
        }
        
        guard let url = URL(string: "\(DALIapi.config.serverURL)/api/location/\(path)") else {
            print("TrackingModule: canceling: bad url")
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 100)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(DALIapi.config.token!, forHTTPHeaderField: "authorization")
        guard let data = try? JSON(["uuid": beaconRegion.proximityUUID.uuidString]).rawData() else {
            print("TrackingModule: canceling: bad data")
            return
        }
        request.httpBody = data
        BackgroundSession.shared.start(request)
        print("TrackingModule: started background url session")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion beaconRegion: CLRegion) {
        print("TrackingModule: didEnterRegion \((beaconRegion as! CLBeaconRegion).proximityUUID)")
        self.post(beaconRegion: beaconRegion, path: "enteredRegion")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion beaconRegion: CLRegion) {
        print("TrackingModule: didExitRegion \((beaconRegion as! CLBeaconRegion).proximityUUID)")
        self.post(beaconRegion: beaconRegion, path: "exitedRegionReq")
    }
}
class BackgroundSession: NSObject {
    static let shared = BackgroundSession()
    static let identifier = "com.JohnKotz.DALI.DaliLabApp"
    
    private var session: URLSession!
    
    var savedCompletionHandler: (() -> Void)?
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: BackgroundSession.identifier)
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func start(_ request: URLRequest) {
        session.dataTask(with: request).resume()
//        session.downloadTask(with: request).resume()
    }
}

extension BackgroundSession: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("TrackingModule: completed background url session")
        DispatchQueue.main.async {
            self.savedCompletionHandler?()
            self.savedCompletionHandler = nil
        }
    }
    
    override func attemptRecovery(fromError error: Error, optionIndex recoveryOptionIndex: Int) -> Bool {
        print(error)
        return true
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error)
    }
}

extension BackgroundSession: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            // handle failure here
            print("\(error.localizedDescription)")
        }
    }
}

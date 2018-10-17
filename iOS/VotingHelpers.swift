//
//  VotingHelpers.swift
//  iOS
//
//  Created by John Kotz on 10/16/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import CoreLocation
import FutureKit
import SCLAlertView

public class VotingHelper: NSObject, CLLocationManagerDelegate {
    private static var _shared: VotingHelper?
    public static var shared: VotingHelper {
        if _shared == nil {
            _shared = shared
        }
        return _shared!
    }
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        
        manager.delegate = self
        return manager
    }()
    
    var getLocationAuthorizationStatusPromise: Promise<CLAuthorizationStatus>?
    func getLocationAuthorizationStatus() -> Future<CLAuthorizationStatus> {
        if let prom = getLocationAuthorizationStatusPromise {
            return prom.future
        }
        getLocationAuthorizationStatusPromise = Promise<CLAuthorizationStatus>()
        getLocationAuthorizationStatusPromise?.automaticallyCancel(afterDelay: 20)
        return getLocationAuthorizationStatusPromise!.future
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        getLocationAuthorizationStatusPromise?.completeWithSuccess(status)
        getLocationAuthorizationStatusPromise = nil
        
        if status == .authorizedWhenInUse {
            
        }
    }
    
    var requestWhenInUseAuthorizationPromise: Promise<Bool>?
    func requestWhenInUseAuthorization(on vc: UIViewController) -> Future<Bool> {
        let promise = Promise<Bool>()
        
        let alert = SCLAlertView(appearance: SCLAlertView.SCLAppearance(showCloseButton: false))
        
        alert.addButton("Sure, I want to vote") {
            self.locationManager.requestWhenInUseAuthorization()
        }
        alert.addButton("Never mind") {
            promise.completeWithFail(AuthorizationErrors.canceled)
        }
        
        alert.showWait("Access to location?", subTitle: "In order to keep this event fair you need to confirm you are at the event. To do this, will you grant this app access to your location?")
        return promise.future
    }
    
    enum AuthorizationErrors: Error {
        case canceled
        case notAuthorized
    }
}

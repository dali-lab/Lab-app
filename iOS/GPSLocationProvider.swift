//
//  GPSLocationProvider.swift
//  iOS
//
//  Created by John Kotz on 5/27/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import PromiseKit
import CoreLocation

class GPSLocationProvider: NSObject, LocationProvider, CLLocationManagerDelegate {
    var priority: Int = 3
    
    internal let locationManager: CLLocationManager
    var permissionsRequestResolver: Resolver<Void>?
    var authorizationStatus: CLAuthorizationStatus?
    var trackedRegions: Set<CLRegion> {
        return self.locationManager.monitoredRegions
    }
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    func addTrackedRegion(region: CLCircularRegion) {
        self.locationManager.startMonitoring(for: region)
    }
    
    func startTrackingLocation() {}
    
    func stopTrackingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    func requestRequiredPermissions() -> Promise<Void> {
        return Promise() { resolver in
            if let status = self.authorizationStatus, status != .notDetermined {
                resolver.fulfill(())
            } else {
                locationManager.requestAlwaysAuthorization()
                locationManager.requestWhenInUseAuthorization()
                self.permissionsRequestResolver = resolver
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        if let resolver = self.permissionsRequestResolver {
            resolver.fulfill(())
            self.permissionsRequestResolver = nil
        } else {
            LocationManager.shared.requestProviderReevaluation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        LocationManager.shared.didDetermineState(state: state, for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        LocationManager.shared.didEnterRegion(region: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        LocationManager.shared.didExitRegion(region: region)
    }
    
    func requirementsAreMet() -> Bool {
        let background = UIApplication.shared.applicationState == .background
        let status = self.authorizationStatus
        return status == .authorizedAlways || (status == .authorizedWhenInUse && !background)
    }
}

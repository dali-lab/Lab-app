//
//  LocationManager.swift
//  iOS
//
//  Created by John Kotz on 5/27/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import PromiseKit
import CoreLocation

class LocationManager {
    internal static let processingQueue = DispatchQueue(label: "LocationManager")
    private static var sharedInstance: LocationManager?
    public static var shared: LocationManager {
        return LocationManager.sharedInstance != nil ? LocationManager.sharedInstance! : LocationManager()
    }
    public private(set) var providers = [LocationProvider]()
    public var provider: LocationProvider!
    public let peerAdvertizer = PeerLocationAdvertizer()
    public var namedRegions: Set<NamedRegionSet> = []
    private var regionNames: Dictionary<CLRegion, NamedRegionSet> = [:]
    public var listeners = [LocationManagerListener]()
    internal var insideRegions: Set<CLRegion> = []
    
    private init() {
        LocationManager.sharedInstance = self
    }
    
    public func addNamedRegionSet(namedRegionSet: NamedRegionSet) throws {
        for region in namedRegionSet.regions {
            if self.regionNames[region] != nil {
                throw LocationManager.GeneralError.regionIsAlreadyNamed
            }
        }
        namedRegionSet.regions.forEach { (region) in
            self.regionNames[region] = namedRegionSet
        }
        self.namedRegions.insert(namedRegionSet)
    }
    
    public func addProvider(provider: LocationProvider) {
        self.providers.append(provider)
    }
    
    public func beginTracking() {
        self.requestRequiredPermissions().done {
            self.evaluateProvider()
        }
    }
    
    public func stopTracking() {
        self.provider.stopTrackingLocation()
    }
    
    public func requestRequiredPermissions() -> Promise<Void> {
        return when(resolved: providers.map { (provider) -> Promise<Void> in
            return provider.requestRequiredPermissions()
        }).done({ (result) in })
    }
    
    private func evaluateProvider() {
        LocationManager.processingQueue.async {
            let newProvider = self.providers.map { (provider) -> (requirementsMet: Bool, provider: LocationProvider) in
                return (provider.requirementsAreMet(), provider)
                }.sorted { (result1, result2) -> Bool in
                    if result1.requirementsMet == result2.requirementsMet {
                        return result1.provider.priority > result2.provider.priority
                    }else {
                        return result1.requirementsMet
                    }
                }.first?.provider
            
            DispatchQueue.main.async {
                if newProvider != nil && (self.provider as? PeerLocationProvider) != nil && (newProvider as? PeerLocationProvider) == nil {
                    self.insideRegions.removeAll()
                }
                
                self.provider.stopTrackingLocation()
                self.provider = newProvider
                self.provider.startTrackingLocation()
                
                if (self.provider as? PeerLocationProvider) == nil {
                    self.peerAdvertizer.startAdvertizing()
                } else {
                    self.peerAdvertizer.stopAdvertizing()
                }
            }
        }
    }
    
    func requestProviderReevaluation() {
        self.evaluateProvider()
    }
    
    func didEnterRegion(region: CLRegion) {
        if !insideRegions.insert(region).inserted {
            return
        }
        
        listeners.forEach { (listener) in
            DispatchQueue.main.async {
                listener.didEnter(region: region, in: self.regionNames[region])
            }
        }
    }
    
    func didExitRegion(region: CLRegion) {
        if insideRegions.remove(region) == nil {
            return
        }
        
        listeners.forEach { (listener) in
            DispatchQueue.main.async {
                listener.didExit(region: region, in: self.regionNames[region])
            }
        }
    }
    
    func didDetermineState(state: CLRegionState, for region: CLRegion) {
        var changed = false
        switch state {
        case .inside:
            changed = insideRegions.insert(region).inserted
            break
        case .outside, .unknown:
            changed = insideRegions.remove(region) != nil
            break
        }
        
        if !changed {
            return
        }

        listeners.forEach { (listener) in
            DispatchQueue.main.async {
                listener.didDetermineState(state: state, for: region, in: self.regionNames[region])
            }
        }
    }
    
    func updatePeerAdvertizerIfNeeded() {
        if (self.provider as? PeerLocationProvider) != nil {
            self.peerAdvertizer.sendUpdate(insideRegions: self.insideRegions)
        }
    }
    
    enum GeneralError: Error {
        case regionIsAlreadyNamed
    }
}

struct NamedRegionSet: Hashable {
    let name: String
    let regions: Set<CLRegion>
}

protocol LocationProvider {
    var priority: Int { get }
    func requestRequiredPermissions() -> Promise<Void>
    func requirementsAreMet() -> Bool
    func startTrackingLocation()
    func stopTrackingLocation()
}

protocol LocationManagerListener {
    func didDetermineState(state: CLRegionState, for region: CLRegion, in namedSet: NamedRegionSet?)
    func didEnter(region: CLRegion, in namedSet: NamedRegionSet?)
    func didExit(region: CLRegion, in namedSet: NamedRegionSet?)
}

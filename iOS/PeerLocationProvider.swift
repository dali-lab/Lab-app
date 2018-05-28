//
//  PeerLocationProvider.swift
//  iOS
//
//  Created by John Kotz on 5/27/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import PromiseKit
import MultipeerConnectivity
import CoreLocation

class PeerLocationProvider: NSObject, LocationProvider, MCSessionDelegate, MCNearbyServiceBrowserDelegate {
    var priority: Int = 1
    let me = MCPeerID(displayName: UIDevice.current.name)
    let session: MCSession
    let browser: MCNearbyServiceBrowser
    var advertizing = false
    var connectedPeers: [MCPeerID: Bool] = [:]
    var connectedPeersRegions: [MCPeerID:Set<CLRegion>] = [:]
    
    // MARK: Computed properties
    var inside: Bool {
        var inside = false
        connectedPeers.keys.forEach { (peer) in
            inside = inside || connectedPeers[peer]!
        }
        return inside
    }
    
    // MARK: Functions
    
    private override init() {
        session = MCSession(peer: me)
        browser = MCNearbyServiceBrowser(peer: me, serviceType: "com.JohnKotz.DALI.DaliLabApp")
        super.init()
        session.delegate = self
        browser.delegate = self
    }
    
    // MARK: Receiving
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let theirInside = NSKeyedUnarchiver.unarchiveObject(with: data) as! [CLRegion]
        let set = Set<CLRegion>(theirInside)
        connectedPeersRegions[peerID] = set
        processPeersRegions()
    }
    
    func processPeersRegions() {
        LocationManager.processingQueue.async {
            let minNumberOfPeers = Int(round(Double(session.connectedPeers.count) / 2.0))
            var map = [CLRegion:Int]()
            let outsideSet = Set<CLRegion>()
            session.connectedPeers.forEach { (peer) in
                connectedPeersRegions[peer]?.forEach({ (region) in
                    map[region] = map[region] != nil ? map[region]! + 1 : 1
                    outsideSet.insert(region)
                })
            }
            
            let passingRegions: [CLRegion] = map.filter { (item) -> Bool in
                return item.value >= minNumberOfPeers
                }.map { (item) -> CLRegion in
                    return item.key
            }
            let insideSet = Set<CLRegion>(passingRegions)
            
            let newInside = insideSet.subtracting(LocationManager.shared.insideRegions)
            let newOutside = LocationManager.shared.insideRegions.subtracting(outsideSet)
            
            newInside.forEach { (region) in
                LocationManager.shared.didEnterRegion(region: region)
            }
            
            newOutside.forEach { (region) in
                LocationManager.shared.didExitRegion(region: region)
            }
        }
    }
    
    func startTrackingLocation() {
        browser.startBrowsingForPeers()
    }
    
    func stopTrackingLocation() {
        browser.stopBrowsingForPeers()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        connectedPeers.removeValue(forKey: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to browse")
        print(error)
    }
    
    func requestRequiredPermissions() -> Promise<Void> {
        return Promise { resolver in
            resolver.fulfill(())
        }
    }
    
    func requirementsAreMet() -> Bool {
        return true
    }
    
    // MARK: Other session functions
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

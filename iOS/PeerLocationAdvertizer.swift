//
//  PeerLocationAdvertizer.swift
//  iOS
//
//  Created by John Kotz on 5/27/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import PromiseKit
import MultipeerConnectivity
import CoreLocation
import CoreBluetooth

class PeerLocationAdvertizer: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
    var me: MCPeerID
    var session: MCSession
    var advertizer: MCNearbyServiceAdvertiser
    var advertizing = false
    var displayName: String {
        get { return "" }
        set {
            if advertizing {
                advertizer.stopAdvertisingPeer()
            }
            setup(displayName: newValue)
            if advertizing {
                advertizer.startAdvertisingPeer()
            }
        }
    }
    var connectedPeers: [MCPeerID: Bool] = [:]
    
    // MARK: Computed properties
    var inside: Bool {
        var inside = false
        connectedPeers.keys.forEach { (peer) in
            inside = inside || connectedPeers[peer]!
        }
        return inside
    }
    
    // MARK: Functions
    
    override convenience init() {
        self.init(displayName: UIDevice.current.name)
    }
    
    init(displayName: String) {
        me = MCPeerID(displayName: displayName)
        session = MCSession(peer: me)
        advertizer = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: nil, serviceType: "com.JohnKotz.DALI.DaliLabApp")
        super.init()
        session.delegate = self
        advertizer.delegate = self
    }
    
    private func setup(displayName: String) {
        me = MCPeerID(displayName: displayName)
        session = MCSession(peer: me)
        advertizer = MCNearbyServiceAdvertiser(peer: me, discoveryInfo: nil, serviceType: "com.JohnKotz.DALI.DaliLabApp")
        session.delegate = self
        advertizer.delegate = self
    }
    
    // MARK: Advertizing
    
    func startAdvertizing() {
        advertizing = true
        advertizer.startAdvertisingPeer()
    }
    
    func stopAdvertizing() {
        advertizing = false
        advertizer.stopAdvertisingPeer()
    }
    
    func sendUpdate(insideRegions: Set<CLRegion>) {
        LocationManager.processingQueue.async {
            let array = NSArray(array: Array(insideRegions))
            let data = NSKeyedArchiver.archivedData(withRootObject: array)
            
            do {
                try self.session.send(data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch {
                do {
                    try self.session.send(data, toPeers: self.session.connectedPeers, with: MCSessionSendDataMode.reliable)
                } catch {
                    return
                }
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertize")
        print(error)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == MCSessionState.connected && advertizing {
            self.sendUpdate(insideRegions: LocationManager.shared.insideRegions)
        }
    }
    
    // MARK: Other session functions
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

//
//  DALI Regions.swift
//  iOS
//
//  Created by John Kotz on 5/15/19.
//  Copyright © 2019 BrunchLabs. All rights reserved.
//

import Foundation
import EmitterKit
import CoreLocation

/**
 A region monitored by the app
 */
public enum DALIRegion: String {
    /// Tim's Office
    case timsOffice
    /// The DALI Lab space
    case DALI
    /// An event nearby wants to let users check in
    case checkInEvent
    /// An event nearby wants to let users vote
    case votingEvent
    
    /// All the regions
    public static var all: Set<DALIRegion> = Set([.timsOffice, .DALI, .checkInEvent, .votingEvent])
    
    /// Notification name to listen to
    public var notificationName: NSNotification.Name {
        switch self {
        case .timsOffice: return Notification.Name.Custom.TimsOfficeEnteredOrExited
        case .DALI: return Notification.Name.Custom.EnteredOrExitedDALI
        case .checkInEvent: return Notification.Name.Custom.CheckInEnteredOrExited
        case .votingEvent: return Notification.Name.Custom.EventVoteEnteredOrExited
        }
    }
    
    /// The priority of the region when generating current location summaries
    public var locationTextPriority: Int {
        // Make sure all of these are unique and reflect how important each is.
        // This number will decide which region is surfaced to the user for a summary of their current location.
        switch self {
        case .timsOffice: return 1
        case .DALI: return 2
        case .checkInEvent: return 3
        case .votingEvent: return 4
        }
    }
    
    /// The textual name of the region
    public var name: String {
        switch self {
        case .timsOffice: return "Tim's Office"
        case .DALI: return "DALI Lab"
        case .checkInEvent: return "Check In Event"
        case .votingEvent: return "Voting Event"
        }
    }
    
    /// The CLRegion this region represents
    public var region: CLRegion {
        return CLBeaconRegion(proximityUUID: uuid, identifier: rawValue)
    }
    
    /// The beacon UUID for this region
    public var uuid: UUID {
        switch self {
        case .timsOffice: return UUID(uuidString: "BC832F8A-B9B3-4147-ADC7-9C9BEF02E4DC")!
        case .DALI: return UUID(uuidString: "F2363048-F649-4537-AB7E-4DADB9966544")!
        case .checkInEvent: return UUID(uuidString: "C371F9F9-572D-4D59-956C-5C3DF4BE50B7")!
        case .votingEvent: return UUID(uuidString: "44414C49-4C61-6245-7665-6E74566F7465")!
        }
    }
    
    /// Storage for state change events
    private static var events = [DALIRegion: State.ChangeEvent]()
    /// The state change event
    public var stateEvent: State.ChangeEvent {
        if DALIRegion.events[self] == nil {
            DALIRegion.events[self] = State.ChangeEvent()
        }
        return DALIRegion.events[self]!
    }
    
    // MARK: - Methods
    
    /**
     Listen for changes to the state of this region
     
     - parameter change: The change to the state
     - parameter state: The new state
     - returns: Listener to be used to stop listening
     */
    public func on(_ callback: @escaping (_ change: State.Change, _ now: State) -> Void) -> Listener {
        return stateEvent.on { (tuple) in
            callback(tuple.change, tuple.now)
        }
    }
    
    /**
     Emit the change to the event and anyone listening on NotificationCenter
     
     - parameter change: The change to the state
     - parameter state: The new state
     */
    public func emit(change: State.Change, state: State) {
        NotificationCenter.default.post(name: notificationName,
                                        object: nil,
                                        userInfo: ["change": change, "state": state])
        stateEvent.emit((change, state))
    }
    
    // MARK: - Static functions
    
    /**
     Selects the region with the highest location priority
     
     - parameter set: The regions to search through
     - returns: The region, if there are any regions in the given set
     */
    public static func highestPriority(in set: Set<DALIRegion> = all) -> DALIRegion? {
        return set.sorted { (r1, r2) -> Bool in
            return r1.locationTextPriority > r2.locationTextPriority
        }.first
    }
    
    /**
     Get the region associated with the given UUID
     */
    public static func with(uuid: UUID) -> DALIRegion? {
        switch uuid {
        case DALIRegion.timsOffice.uuid: return .timsOffice
        case DALIRegion.DALI.uuid: return .DALI
        case DALIRegion.checkInEvent.uuid: return .checkInEvent
        case DALIRegion.votingEvent.uuid: return .votingEvent
        default: return nil
        }
    }
    
    /**
     The state of a region. Inside, outside, or unknown
     */
    public enum State {
        case inside
        case outside
        case unknown
        
        /**
         Translate a CLRegionState to a State
         
         - parameter state: The CLRegionState to translate
         - returns: State that corresponds to the given CLRegionState
         */
        public static func from(_ state: CLRegionState) -> State {
            switch state {
            case .inside: return .inside
            case .outside: return .outside
            case .unknown: return .unknown
            }
        }
        
        /**
         A simple event type which describes how the state of a region has changed
         */
        public typealias ChangeEvent = Event<(change: Change, now: State)>
        
        /**
         A kind of change to state that can happen
         */
        public enum Change {
            case entering
            case exiting
            case none
        }
    }
}

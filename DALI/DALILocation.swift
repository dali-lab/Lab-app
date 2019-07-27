//
//  DALILocation.swift
//  DALIapi
//
//  Created by John Kotz on 7/31/17.
//  Copyright © 2017 DALI Lab. All rights reserved.
//

import Foundation
import SwiftyJSON
import SocketIO
import FutureKit

/**
A static struct that contains all location updates and queries

## Example:

	DALILocation.Tim.get { (tim, error) in
	    // ...
	    if tim.inDALI {
	        // ...
	    } else if tim.inOffice {
	        // ...
	    }
	}
*/
public class DALILocation {
	internal static var sharedCallback: (([DALIMember]?, DALIError.General?) -> Void)?
	internal static var lastSharedData: [DALIMember]?
	internal static var enterCallback: ((DALIMember) -> Void)?
	internal static var timCallback: ((Tim?, DALIError.General?) -> Void)?
	internal static var lastTimData: Tim?
	internal static var updatingSocket: SocketIOClient!
	internal static func assertSocket() {
		if updatingSocket == nil {
			updatingSocket = DALIapi.socketManager.socket(forNamespace: "/location")
			
			updatingSocket.on("shared", callback: { (data, ack) in
				guard let arr = data[0] as? [Any] else {
					if let sharedCallback = sharedCallback {
						DispatchQueue.main.async {
							sharedCallback(nil, DALIError.General.UnexpectedResponse)
						}
					}
					return
				}
				
				var outputArr: [DALIMember] = []
				for obj in arr {
					guard let dict = obj as? [String: Any], let user = dict["user"], let member = DALIMember(json:JSON(user)) else {
						if let sharedCallback = sharedCallback {
							DispatchQueue.main.async {
								sharedCallback(nil, DALIError.General.UnexpectedResponse)
							}
						}
						return
					}
					
					outputArr.append(member)
				}
				self.lastSharedData = outputArr
				
				if let sharedCallback = sharedCallback {
					DispatchQueue.main.async {
						sharedCallback(outputArr, nil)
					}
				}
			})
			
			updatingSocket.on("memberEnter", callback: { (data, ack) in
				guard let user = data[0] as? [String: Any], let member = DALIMember(json:JSON(user)) else {
					return
				}
				
				if let enterCallback = enterCallback {
					enterCallback(member)
				}
			})
			
			updatingSocket.on("tim", callback: { (data, ack) in
				guard let dict = data[0] as? [String: Any], let inDALI = dict["inDALI"] as? Bool, let inOffice = dict["inOffice"] as? Bool else {
					if let timCallback = timCallback {
						DispatchQueue.main.async {
							timCallback(nil, DALIError.General.UnexpectedResponse)
						}
					}
					return
				}
				
				let tim = Tim(inDALI: inDALI, inOffice: inOffice)
				Tim.current = tim
				
				self.lastTimData = tim
				
				if let timCallback = timCallback {
					DispatchQueue.main.async {
						timCallback(tim, nil)
					}
				}
			})
			
			updatingSocket.connect()
			updatingSocket.on(clientEvent: .connect, callback: { (data, ack) in
				ServerCommunicator.authenticateSocket(socket: updatingSocket)
			})
		}
	}
	
	/**
	A simple struct that holds booleans that indicate Tim's location. Use it wisely 😉
	*/
	public struct Tim {
		/// The most recent information on tim's location
		public internal(set) static var current: Tim?
		
		/// Tim is in DALI
		public private(set) var inDALI: Bool
		/// Tim in in his office
		public private(set) var inOffice: Bool
		
		/**
		Gets the current data on Tim's Location and returns it.
		
		- parameter callback: Function to be called when the request is complete
		
		## Example:
		
			DALILocation.Tim.get { (tim, error) in 
			    if tim.inDALI {
			        // ...
			    } else if tim.inOffice {
			        // ...
			    }
			}
		*/
		public static func get() -> Future<Tim> {
            return ServerCommunicator.get(url: "\(DALIapi.config.serverURL)/api/location/tim").onSuccess { (response) -> Tim in
                guard let dict = response.json?.dictionary,
                    let inDALI = dict["inDALI"]?.bool,
                    let inOffice = dict["inOffice"]?.bool else {
                    throw response.assertedError
                }
                let tim = Tim(inDALI: inDALI, inOffice: inOffice)
                self.current = tim
                return tim
            }
		}
		
		/**
		Observe tim's location
		
		- parameter callback: Function called when an update on tim's location is received
		- parameter tim: Tim's updated location
		- parameter error: The error, if any, encountered
		*/
		public static func observe(callback: @escaping (_ tim: Tim?, _ error: DALIError.General?) -> Void) -> Observation {
			DALILocation.assertSocket()
			DALILocation.timCallback = callback
			
			if let timData = DALILocation.lastTimData {
				callback(timData, nil)
			}
			
			return Observation(stop: {
				DALILocation.timCallback = nil
				if DALILocation.sharedCallback == nil && DALILocation.enterCallback == nil && DALILocation.updatingSocket != nil {
					if DALILocation.updatingSocket.status != .disconnected {
						DALILocation.updatingSocket.disconnect()
					}
					DALILocation.updatingSocket = nil
				}
			}, id: "timObserver")
		}
		
		/**
		Submit information about tim's location. Will generate an error if user is not tim
		- important: If you call this without a user will `fatalerror`
		
		- parameter inDALI: Tim is in DALI
		- parameter inOffice: Tim is in his office
		- parameter callback: Function called apon completion
		*/
		public static func submit(inDALI: Bool, inOffice: Bool) -> Future<Void> {
			DALIapi.assertUser(funcName: "DALILocation.Tim.submit")
			
			let dict: [String: Any] = [
				"inDALI": inDALI,
				"inOffice": inOffice
			]
			
			do {
                return try ServerCommunicator.post(url: "\(DALIapi.config.serverURL)/api/location/tim", json: JSON(dict)).onSuccess(block: { (response) in
                    if !response.success {
                        throw response.assertedError
                    }
                })
			} catch {
				return Future(fail: error)
			}
		}
	}
	
	/**
	A simple struct that handles getting a list of shared user
	*/
	public struct Shared {
		/**
		Get a list of all the people in the lab who are sharing their location
		
		- parameter callback: Function called apon completion
		*/
		public static func get() -> Future<[DALIMember]> {
            return ServerCommunicator.get(url: "\(DALIapi.config.serverURL)/api/location/shared").onSuccess { (response) -> [DALIMember] in
                guard let array = response.json?.array else {
                    throw DALIError.General.UnexpectedResponse
                }
                
                let outputArr: [DALIMember] = array.compactMap({ (json) -> DALIMember? in
                    guard let dict = json.dictionary,
                        let user = dict["user"] else {
                        return nil
                    }
                    return DALIMember(json: user)
                })
                return outputArr
            }
		}
		
		/**
		Observe the shared locations
		
		- parameter callback: The function called when an update is available
		- parameter members: The update members listed in the lab
		- parameter error: The error, if any, encountered
		*/
		public static func observe(callback: @escaping (_ members: [DALIMember]?, _ error: DALIError.General?) -> Void) -> Observation {
			DALILocation.assertSocket()
			DALILocation.sharedCallback = callback
			
			if let sharedData = DALILocation.lastSharedData {
				callback(sharedData, nil)
			}
			
			return Observation(stop: {
				DALILocation.sharedCallback = nil
				if DALILocation.timCallback == nil && DALILocation.enterCallback == nil && DALILocation.updatingSocket != nil {
					if DALILocation.updatingSocket.status != .disconnected {
						DALILocation.updatingSocket.disconnect()
					}
					DALILocation.updatingSocket = nil
				}
			}, id: "sharedObserver")
		}
		
		/**
		Submit the current location of the user
		- important: Do not run this on an API authenticated program. It will fatal error to protect the server!
		
		- parameter inDALI: The user is in DALI
		- parameter entering: The user is entering DALI
		- parameter callback: Function that is called when done
		*/
		public static func submit(inDALI: Bool, entering: Bool) -> Future<Void> {
			DALIapi.assertUser(funcName: "DALILocation.submit")
			
			let dict: [String: Any] = [
				"inDALI": inDALI,
				"entering": entering,
				"sharing": DALILocation.sharing
			]
			
			do {
                return try ServerCommunicator.post(url: "\(DALIapi.config.serverURL)/api/location/shared", json: JSON(dict)).onSuccess(block: { (response) in
                    if !response.success {
                        throw response.assertedError
                    }
                })
			} catch {
				return Future(fail: error)
			}
		}
	}
	
	/**
	Observe members entering the lab. Will call callback everytime someone is tracked as entering the lab
	
	- parameter callback: Called when someone enters the lab
	- parameter member: The member who entered the lab
	*/
	public static func observeMemberEnter(callback: @escaping (_ member: DALIMember) -> Void) -> Observation {
		DALILocation.assertSocket()
		DALILocation.enterCallback = callback
		
		return Observation(stop: {
			DALILocation.enterCallback = nil
			if DALILocation.timCallback == nil && DALILocation.sharedCallback == nil && DALILocation.updatingSocket != nil {
				if DALILocation.updatingSocket.status != .disconnected {
					DALILocation.updatingSocket.disconnect()
				}
				DALILocation.updatingSocket = nil
			}
		}, id: "enterObserver")
	}
	
	/// The current user is sharing this device's location
	public static var sharing: Bool {
		get {
			return UserDefaults.standard.value(forKey: "DALIapi:sharing") as? Bool ?? DALIapi.config.sharingDefault
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "DALIapi:sharing")
            _ = try? ServerCommunicator.post(url: "\(DALIapi.config.serverURL)/api/location/shared/updatePreference", json: JSON(["sharing": newValue]))
		}
	}
}

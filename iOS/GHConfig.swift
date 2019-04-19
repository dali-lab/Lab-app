//
//  GHConfig.swift
//  GithubTest
//
//  Created by John Kotz on 3/29/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation

struct GHConfig {
    static let clientID = "2c01acc580ed86a709c0"
    static let clientSecret = "df47e98975331198e37bd44c4b06c94716c78820"
    
    static var authToken: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: "authToken")
        } get {
            return UserDefaults.standard.string(forKey: "authToken")
        }
    }
}

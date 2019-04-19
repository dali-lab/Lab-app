//
//  GitHubLogin.swift
//  GithubTest
//
//  Created by John Kotz on 3/29/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import UIKit
import AuthenticationServices
import Alamofire
import FutureKit

class GitHubLoginSession {
    static let loginURL = "https://github.com/login/oauth/authorize"
    static let authURL = "https://github.com/login/oauth/access_token"
    static var isLoggedIn: Bool {
        return GHConfig.authToken != nil
    }
    
    var state = String(format: "%X", Int.random(in: 0...8^16))
    var authSession: ASWebAuthenticationSession?
    var finalPromise: Promise<Void>?
    
    init(scope: String) {
        var urlComponents = URLComponents(string: GitHubLoginSession.loginURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "client_id", value: GHConfig.clientID)
        ]
        
        authSession = ASWebAuthenticationSession(url: urlComponents.url!,
                                                 callbackURLScheme: "dali://") { (url, _) in
            guard let code = url?.queryParameters?["code"] else {
                self.finalPromise?.completeWithFail("Code not received!")
                return
            }
            self.completeAuth(with: code)
        }
    }
    
    func completeAuth(with code: String) {
        var urlComponents = URLComponents(string: GitHubLoginSession.authURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "client_id", value: GHConfig.clientID),
            URLQueryItem(name: "client_secret", value: GHConfig.clientSecret),
            URLQueryItem(name: "code", value: code)
        ]
        
        Alamofire.request(urlComponents.url!,
                          method: .post,
                          headers: ["Accept": "application/json"]).responseJSON { (response) in
            if let value = response.result.value as? [String: String] {
                GHConfig.authToken = value["access_token"]
                self.finalPromise?.completeWithSuccess(Void())
            } else {
                if let error = response.error {
                    self.finalPromise?.completeWithFail(error)
                } else {
                    self.finalPromise?.completeWithFail("Unknown error")
                }
            }
        }
    }
    
    func start() -> Future<Void> {
        finalPromise = Promise<Void>()
        authSession?.start()
        return finalPromise!.future
    }
    
    func cancel() {
        authSession?.cancel()
    }
}

extension URL {
    public var queryParameters: [String: String]? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

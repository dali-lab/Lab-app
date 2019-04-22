//
//  GHRepository.swift
//  GithubTest
//
//  Created by John Kotz on 3/28/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import Alamofire
import FutureKit

struct GHRepository: PagableObject {
    let name: String
    let description: String?
    let openIssues: Int
    let isPrivate: Bool
    
    let notificationsURL: String
    let commitsURL: String
    let collaboratorsURL: String
    let issuesURL: String
    let htmlURL: String
    
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let openIssues = dictionary["open_issues"] as? Int,
              let isPrivate = dictionary["private"] as? Int,
              let notificationsURL = dictionary["notifications_url"] as? String,
              let commitsURL = dictionary["git_commits_url"] as? String,
              let collaboratorsURL = dictionary["collaborators_url"] as? String,
              let issuesURL = dictionary["issues_url"] as? String,
              let htmlURL = dictionary["html_url"] as? String
        else {
            return nil
        }
        
        self.name = name
        self.description = dictionary["description"] as? String
        self.openIssues = openIssues
        self.isPrivate = isPrivate != 0
        
        self.notificationsURL = notificationsURL
        self.commitsURL = commitsURL
        self.collaboratorsURL = collaboratorsURL
        self.issuesURL = issuesURL
        self.htmlURL = htmlURL
    }
    
    init?(data: Any) {
        guard let data = data as? [String: Any] else {
            return nil
        }
        self.init(dictionary: data)
    }
    
    var allIssuesURL: URL {
        return URL(string: issuesURL.replacingOccurrences(of: "{/number}", with: ""))!
    }
    
    func getIssues() -> Future<[GHIssue]> {
        guard let accessToken = GHConfig.authToken else {
            return Future(failWithErrorMessage: "Not logged in")
        }
        let promise = Promise<[GHIssue]>()
        
        Alamofire.request(allIssuesURL, method: .get, parameters: ["access_token": accessToken])
            .responseJSON { (response) in
            if let data = response.result.value as? [[String: Any]] {
                promise.completeWithSuccess(data.compactMap({ (data) -> GHIssue? in
                    return GHIssue(dictionary: data)
                }))
            } else {
                if let error = response.error {
                    promise.completeWithFail(error)
                } else {
                    promise.completeWithFail("Unknown error")
                }
            }
        }
        
        return promise.future
    }
    
    static func get(from url: URL) -> Future<GHRepository> {
        guard let accessToken = GHConfig.authToken else {
            return Future(failWithErrorMessage: "Not logged in")
        }
        
        let promise = Promise<GHRepository>()
        
        Alamofire.request(url, method: .get, parameters: ["access_token": accessToken]).responseJSON { (response) in
            if let data = response.result.value as? [String: Any], let repo = GHRepository(dictionary: data) {
                promise.completeWithSuccess(repo)
            } else {
                if let error = response.error {
                    promise.completeWithFail(error)
                } else {
                    promise.completeWithFail("Unknown error")
                }
            }
        }
        
        return promise.future
    }
}

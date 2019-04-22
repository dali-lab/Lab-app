//
//  GHOrganization.swift
//  GithubTest
//
//  Created by John Kotz on 3/29/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import Alamofire
import FutureKit

struct GHOrganization: PagableObject {
    let name: String
    let description: String?
    
    let url: String
    let reposURL: String
    let membersURL: String
    
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["login"] as? String,
              let url = dictionary["url"] as? String,
              let reposURL = dictionary["repos_url"] as? String,
              let membersURL = dictionary["members_url"] as? String
        else {
            return nil
        }
        
        self.name = name
        var description = dictionary["description"] as? String
        if description == "" {
            description = nil
        }
        
        self.description = description
        self.url = url
        self.reposURL = reposURL
        self.membersURL = membersURL
    }
    
    init?(data: Any) {
        guard let data = data as? [String: Any] else {
            return nil
        }
        self.init(dictionary: data)
    }
    
    func getRepoPager() -> Future<GHPager<GHRepository>> {
        return GHPager(baseURL: URL(string: reposURL)!).setup()
    }
    
    static func getAll() -> Future<[GHOrganization]> {
        let promise = Promise<[GHOrganization]>()
        
        Alamofire.request("https://api.github.com/user/orgs",
                          method: .get,
                          parameters: ["access_token": GHConfig.authToken!]).responseJSON { (response) in
            if let value = response.result.value as? [[String: Any]] {
                promise.completeWithSuccess(value.compactMap({ (data) -> GHOrganization? in
                    return GHOrganization(dictionary: data)
                }))
            } else {
                if let error = response.error {
                    promise.completeWithFail(error)
                } else {
                    promise.completeWithErrorMessage("Unknown error")
                }
            }
        }
        
        return promise.future
    }
}

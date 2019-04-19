//
//  GHIssue.swift
//  GithubTest
//
//  Created by John Kotz on 3/29/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation

struct GHIssue {
    let title: String
    let body: String?
    let number: Int
    let created: Date
    let updated: Date
    
    let numComments: Int
    
    let url: URL
    
    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = NSLocale.current
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return df
    }()
    
    init?(dictionary: [String:Any]) {
        guard
            let title = dictionary["title"] as? String,
            let number = dictionary["number"] as? Int,
            let createdString = dictionary["created_at"] as? String,
            let created = GHIssue.dateFormatter.date(from: createdString),
            let updatedString = dictionary["updated_at"] as? String,
            let updated = GHIssue.dateFormatter.date(from: updatedString),
            let numComments = dictionary["comments"] as? Int,
            let urlString = dictionary["url"] as? String,
            let url = URL(string: urlString)
            else {
                return nil
        }
        
        self.title = title
        self.body = dictionary["body"] as? String
        self.number = number
        self.created = created
        self.updated = updated
        self.numComments = numComments
        self.url = url
    }
}

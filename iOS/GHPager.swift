//
//  GHPager.swift
//  GithubTest
//
//  Created by John Kotz on 3/28/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import FutureKit
import Alamofire

class GHPager<T: PagableObject> {
    let baseURL: URL
    private(set) var itemsPerPage: Int
    
    var numberOfPages: Int?
    var currentPage: Int = 1
    
    init(baseURL: URL, itemsPerPage: Int = 30) {
        self.baseURL = baseURL
        self.itemsPerPage = itemsPerPage
    }
    
    func changeItemsPerPage(itemsPerPage: Int) -> Future<GHPager> {
        self.itemsPerPage = itemsPerPage
        let future = setup()
        
        _ = future.onSuccess { (_) in
            self.currentPage = min(self.currentPage, self.numberOfPages!)
        }
        
        return future
    }
    
    func setup() -> Future<GHPager<T>> {
        guard let authToken = GHConfig.authToken else {
            return Future(failWithErrorMessage: "No auth token configured")
        }
        
        let promise = Promise<GHPager<T>>()
        Alamofire.request(baseURL, method: .get, parameters: ["access_token": authToken]).responseJSON { (response) in
            guard response.error == nil else {
                promise.completeWithFail(response.error!)
                return
            }
            
            guard var linksString: String = response.response!.allHeaderFields["Link"] as? String else {
                self.numberOfPages = 0
                promise.completeWithSuccess(self)
                return
            }
            linksString = linksString.stripCharactersInSet(chars: Array(" \"<>"))
            
            let links = linksString.split(separator: ",")
            for link in links {
                var dataComponents = link.split(separator: ";")
                if dataComponents[1] == "rel=last" {
                    let url = URL(string: String(dataComponents[0]))!
                    self.numberOfPages = Int(url.queryParameters!["page"]!)
                    break
                }
            }
            promise.completeWithSuccess(self)
        }
        
        return promise.future
    }
    
    func next() -> Future<[T]>? {
        guard let numberOfPages = numberOfPages, currentPage < numberOfPages else {
            return nil
        }
        currentPage += 1
        return get(pageAtNumber: currentPage)
    }
    
    func prev() -> Future<[T]>? {
        guard currentPage > 0 else {
            return nil
        }
        currentPage -= 1
        return get(pageAtNumber: currentPage)
    }
    
    func get(pageAtNumber pageNum: Int) -> Future<[T]>? {
        guard let accessToken = GHConfig.authToken, pageNum > 0, pageNum < numberOfPages! else {
            return nil
        }
        let promise = Promise<[T]>()
        
        Alamofire.request(baseURL, method: .get, parameters: ["access_token": accessToken, "page": pageNum])
            .responseJSON { (response) in
            if let value = response.result.value as? [Any] {
                let objects = value.compactMap({ (data) -> T? in
                    return T(data: data)
                })
                promise.completeWithSuccess(objects)
            } else {
                promise.failIfNotCompleted("No value returned")
            }
        }
        
        return promise.future
    }
}

extension String {
    func stripCharactersInSet(chars: [Character]) -> String {
        return self.filter({ !chars.contains($0) })
    }
}

protocol PagableObject {
    init?(data: Any)
}

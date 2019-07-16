//
//  FutureExtension.swift
//  iOS
//
//  Created by John Kotz on 12/22/18.
//  Copyright © 2018 BrunchLabs. All rights reserved.
//

import Foundation
import FutureKit

extension Future {
    /// Creates a new future which will be completed on the main thread only
    public var mainThreadFuture: Future<T> {
        let promise = Promise<T>()
        self.onSuccess { (value) in
            DispatchQueue.main.async {
                promise.completeWithSuccess(value)
            }
        }.onFail { (error) in
            DispatchQueue.main.async {
                promise.completeWithFail(error)
            }
        }.onCancel {
            DispatchQueue.main.async {
                promise.completeWithCancel()
            }
        }
        return promise.future
    }
}

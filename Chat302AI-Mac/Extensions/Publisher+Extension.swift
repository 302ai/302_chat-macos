//
//  Publisher+Extension.swift
//  Chat302AI-Mac
//


import Combine
import Foundation

extension Publisher {
    func toNetworkError() -> AnyPublisher<Output, HFError> {
        self.mapError { error in
            if let error = error as? HFError {
                return error
            } else {
                return HFError.unknown
            }
        }.eraseToAnyPublisher()
    }
}

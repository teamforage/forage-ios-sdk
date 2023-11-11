//
//  Concurrency.swift
//
//
//  Created by Danilo Joksimovic on 2023-11-10.
//

import Foundation

// Global functions should be used judiciously!

/// `awaitResult` is a utility method that bridges the gap between traditional callback-based asynchronous code and the modern Swift 5.5+ async/await pattern.
func awaitResult<T>(_ operation: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        operation { result in
            continuation.resume(with: result)
        }
    }
}

//
//  Repository.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

import Combine

protocol Repository<T> {
    associatedtype T
    var data: AnyPublisher<DataResult<T>, Never> { get }
    func put(data: T)
}

enum DataResult<T> {
    case uninitialized
    case success(data: T)
    case failure(data: T?, error: Error)
    case loading(data: T?)
    
    var data: T? {
        switch self {
        case .uninitialized: nil
        case .success(let data): data
        case .failure(let data, _): data
        case .loading(let data): data
        }
    }
    
    func isLoading() -> Bool {
        if case .loading(_) = self {
            true
        } else {
            false
        }
    }
}


//
//  APIConfig.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import Foundation

struct APIConfig {
    static var baseURL: String {
        #if DEBUG
            return "http://localhost:3000"
        #else
            return "https://your-production-api.com"
        #endif
    }
}

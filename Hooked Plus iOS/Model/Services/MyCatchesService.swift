//
//  MyCatchesService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/23/25.
//

import Alamofire
import _PhotosUI_SwiftUI
import FirebaseAuth
import PhotosUI
import CoreLocation

enum MyCatchesError: Error {
    case authenticationFailed
    case invalidURL
    case imageConversionFailed
    case networkError(String)
    case serverError(Int, String?)
}

enum MyCatchesService {
    
    static func getMyCatches() async throws -> MyCatchesResponse {
        guard let user = Auth.auth().currentUser else {
            throw MyCatchesError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/catches?page=1&limit=50") else {
            throw MyCatchesError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("application/json")
        ]
        
        // Create a custom JSONDecoder with date decoding strategy
         let decoder = JSONDecoder()
         decoder.dateDecodingStrategy = .millisecondsSince1970
        
        // Make the GET request using Alamofire
        let response = await AF.request(url, method: .get, headers: headers)
            .serializingDecodable(MyCatchesResponse.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let catches):
            return catches
        case .failure(let error):
            throw MyCatchesError.networkError(error.localizedDescription)
        }
    }
}

//
//  SpeciesService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/21/25.
//

import Alamofire
import FirebaseAuth

enum SpeciesService {
    static func getSpecies(query: String) async throws -> SpeciesResponse {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/species?q=\(query)") else {
            throw PostUploadError.invalidURL
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
            .serializingDecodable(SpeciesResponse.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let feed):
            return feed
        case .failure(let error):
            throw PostUploadError.networkError(error.localizedDescription)
        }
    }
    
    static func getAllSpecies(query: String, page: Int, limit: Int = 50) async throws -> SpeciesResponse {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Construct URL with pagination parameters
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/species?q=\(query)&page=\(page)&limit=\(limit)") else {
            throw PostUploadError.invalidURL
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
            .serializingDecodable(SpeciesResponse.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let feed):
            return feed
        case .failure(let error):
            throw PostUploadError.networkError(error.localizedDescription)
        }
    }
}

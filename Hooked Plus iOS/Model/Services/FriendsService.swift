//
//  FriendsService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/24/25.
//

import Alamofire
import FirebaseAuth

enum FriendsService {
    static func getSuggestedFriends(query: String, page: Int, limit: Int = 50) async throws -> FriendResponse {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Construct URL with pagination parameters
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/friend/suggestions?q=\(query)&page=\(page)&limit=\(limit)") else {
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
            .serializingDecodable(FriendResponse.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let friends):
            return friends
        case .failure(let error):
            throw PostUploadError.networkError(error.localizedDescription)
        }
    }
}

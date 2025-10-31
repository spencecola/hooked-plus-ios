//
//  FriendsService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/24/25.
//

import Alamofire
import FirebaseAuth

enum FriendError: Error {
    case authenticationFailed
    case invalidURL
    case invalidResponse
    case imageConversionFailed
    case networkError(String)
    case serverError(Int, String?)
}

enum FriendsService {
    
    static func getFriends(query: String, status: String = "accepted", page: Int = 1, limit: Int = 50) async throws -> FriendResponse {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Construct URL with pagination parameters
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/friends?q=\(query)&status=\(status)&page=\(page)&limit=\(limit)") else {
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
    
    static func getSuggestedFriends(query: String, page: Int, limit: Int = 50) async throws -> SuggestedFriendResponse {
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
            .serializingDecodable(SuggestedFriendResponse.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let friends):
            return friends
        case .failure(let error):
            throw PostUploadError.networkError(error.localizedDescription)
        }
    }
    
    static func addFriend(friendId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Construct URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/friend") else {
            throw PostUploadError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("application/json")
        ]
        
        // Request body
        let parameters: [String: String] = [
            "friendId": friendId
        ]
        
        // Make the POST request using Alamofire
        let response = await AF.request(url,
                                      method: .post,
                                      parameters: parameters,
                                      encoding: JSONEncoding.default,
                                      headers: headers)
            .serializingData()
            .response
        
        // Handle the response
        guard let httpResponse = response.response else {
            throw FriendError.invalidResponse
        }
        
        switch response.result {
        case .success:
            guard httpResponse.statusCode == 201 else {
                throw FriendError.invalidResponse
            }
            // Success, no need to return anything
        case .failure(let error):
            throw FriendError.networkError(error.localizedDescription)
        }
    }
    
    static func approveFriend(friendId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Construct URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/friend/approve") else {
            throw PostUploadError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("application/json")
        ]
        
        // Request body
        let parameters: [String: String] = [
            "id": friendId
        ]
        
        // Make the POST request using Alamofire
        let response = await AF.request(url,
                                      method: .post,
                                      parameters: parameters,
                                      encoding: JSONEncoding.default,
                                      headers: headers)
            .serializingData()
            .response
        
        // Handle the response
        guard let httpResponse = response.response else {
            throw FriendError.invalidResponse
        }
        
        switch response.result {
        case .success:
            guard httpResponse.statusCode == 201 else {
                throw FriendError.invalidResponse
            }
            // Success, no need to return anything
        case .failure(let error):
            throw FriendError.networkError(error.localizedDescription)
        }
    }
}

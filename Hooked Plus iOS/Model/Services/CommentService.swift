//
//  CommentService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/3/25.
//

import Alamofire
import FirebaseAuth

// MARK: - Comment Errors
enum CommentError: Error {
    case authenticationFailed
    case invalidURL
    case networkError(String)
    case serverError(Int, String?)
    case decodingFailed(String)
}

// MARK: - Create a comment
struct CreateComment: Codable {
    let userId: String
    let postId: String
    let content: String
}

// MARK: - Comment Models (adjust to match your backend)
struct Comment: Codable, Identifiable {
    var id: String
    var userId: String
    var postId: String
    var content: String
    var createdAt: Date?
    var updatedAt: Date?
    var user: CommentUser
}

struct CommentUser: Codable {
    let firstName: String
    let lastName: String
    let handleName: String
    let profileIcon: String?
}

struct CreateCommentRequest: Codable {
    let content: String
}

struct EditCommentRequest: Codable {
    let content: String
}

struct CommentsResponse: Codable {
    let comments: [Comment]
    let total: Int
}

// MARK: - CommentService
enum CommentService {
    
    private static func authenticatedHeaders() async throws -> HTTPHeaders {
        guard let user = Auth.auth().currentUser else {
            throw CommentError.authenticationFailed
        }
        let idToken = try await user.getIDToken()
        return [
            .authorization(bearerToken: idToken),
            .contentType("application/json")
        ]
    }
    
    private static var baseURL: String { APIConfig.baseURL }
    
    // MARK: Create Comment
    static func createComment(postId: String, content: String) async throws {
        let urlString = "\(baseURL)/v1/user/post/\(postId)/comment"
        guard let url = URL(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        let headers = try await authenticatedHeaders()
        let body = CreateCommentRequest(content: content)
        
        let response = await AF.request(url,
                                        method: .post,
                                        parameters: body,
                                        encoder: JSONParameterEncoder.default,
                                        headers: headers)
            .serializingData()
            .response
        
        switch response.result {
        case .success:
            guard let httpResponse = response.response,
                  (200...299).contains(httpResponse.statusCode) else {
                let status = response.response?.statusCode ?? -1
                let msg = String(data: response.data ?? Data(), encoding: .utf8)
                throw CommentError.serverError(status, msg)
            }
            // Success – no body expected
            return
            
        case .failure(let error):
            throw CommentError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: Edit Comment
    static func editComment(commentId: String, newContent: String) async throws {
        let urlString = "\(baseURL)/v1/user/comment/\(commentId)"
        guard let url = URL(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        let headers = try await authenticatedHeaders()
        let body = EditCommentRequest(content: newContent)
        
        let response = await AF.request(url,
                                        method: .put,
                                        parameters: body,
                                        encoder: JSONParameterEncoder.default,
                                        headers: headers)
            .serializingData()
            .response
        
        switch response.result {
        case .success:
            guard let httpResponse = response.response,
                  (200...299).contains(httpResponse.statusCode) else {
                let status = response.response?.statusCode ?? -1
                let msg = String(data: response.data ?? Data(), encoding: .utf8)
                throw CommentError.serverError(status, msg)
            }
            return
            
        case .failure(let error):
            throw CommentError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: Delete Comment
    static func deleteComment(commentId: String) async throws {
        let urlString = "\(baseURL)/v1/user/comment/\(commentId)"
        guard let url = URL(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        let headers = try await authenticatedHeaders()
        
        let response = await AF.request(url,
                                        method: .delete,
                                        headers: headers)
            .serializingData()
            .response
        
        switch response.result {
        case .success:
            guard let httpResponse = response.response,
                  (200...299).contains(httpResponse.statusCode) else {
                let status = response.response?.statusCode ?? -1
                let msg = String(data: response.data ?? Data(), encoding: .utf8)
                throw CommentError.serverError(status, msg)
            }
            return
            
        case .failure(let error):
            throw CommentError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: Get Comments by Post
    static func getComments(for postId: String,
                            page: Int = 1,
                            limit: Int = 20) async throws -> CommentsResponse {
        
        let urlString = "\(baseURL)/v1/user/post/\(postId)/comments"
        guard var components = URLComponents(string: urlString) else {
            throw CommentError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw CommentError.invalidURL
        }
        
        let headers = try await authenticatedHeaders()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        
        let response = await AF.request(url,
                                        method: .get,
                                        headers: headers)
            .serializingDecodable(CommentsResponse.self, decoder: decoder)
            .response
        
        switch response.result {
        case .success(let commentsResponse):
            return commentsResponse
            
        case .failure(let error):
            if let afError = error.asAFError,
               case .responseSerializationFailed = afError {
                throw CommentError.decodingFailed(error.localizedDescription)
            }
            throw CommentError.networkError(error.localizedDescription)
        }
    }
}

//
//  StoryService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/9/25.
//

import Alamofire
import FirebaseAuth
import Foundation

enum StoryError: Error {
    case authenticationFailed
    case invalidURL
    case videoFileNotFound
    case videoTooLarge
    case networkError(String)
    case serverError(Int, String?)
    case decodingFailed
}

enum StoryService {
    
    // MARK: - Upload a new story
    static func uploadStory(videoURL: URL) async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw StoryError.authenticationFailed
        }
        
        let idToken = try await user.getIDToken()
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/story") else {
            throw StoryError.invalidURL
        }
        
        // Validate video file
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw StoryError.videoFileNotFound
        }
        
        let videoData = try Data(contentsOf: videoURL)
        guard videoData.count <= 50 * 1024 * 1024 else { // 50MB limit example
            throw StoryError.videoTooLarge
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken)
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(
                multipartFormData: { formData in
                    formData.append(
                        videoData,
                        withName: "video",
                        fileName: videoURL.lastPathComponent,
                        mimeType: "video/quicktime"
                    )
                },
                to: url,
                method: .post,
                headers: headers
            )
            .validate(statusCode: 200...299)
            .response { response in
                switch response.result {
                case .success:
                    if let status = response.response?.statusCode, (200...299).contains(status) {
                        continuation.resume(returning: true)
                    } else {
                        let status = response.response?.statusCode ?? -1
                        let message = String(data: response.data ?? Data(), encoding: .utf8)
                        continuation.resume(throwing: StoryError.serverError(status, message))
                    }
                case .failure(let error):
                    continuation.resume(throwing: StoryError.networkError(error.localizedDescription))
                }
            }
        }
    }
    
    // MARK: - Fetch stories for friends
    static func fetchFriendStories() async throws -> [StoryData] {
        guard let user = Auth.auth().currentUser else {
            throw StoryError.authenticationFailed
        }
        
        let idToken = try await user.getIDToken()
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/stories") else {
            throw StoryError.invalidURL
        }
        
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .accept("application/json")
        ]
        
        let response = await AF.request(url, headers: headers)
            .validate(statusCode: 200...299)
            .serializingDecodable([StoryData].self)
            .response
        
        switch response.result {
        case .success(let stories):
            return stories
        case .failure(let error):
            print("Fetch failed: \(error.localizedDescription)")
            if let data = response.data, let message = String(data: data, encoding: .utf8) {
                print("Server response: \(message)")
            }
            throw StoryError.networkError(error.localizedDescription)
        }
    }
}

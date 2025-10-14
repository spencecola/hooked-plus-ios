import Alamofire
import _PhotosUI_SwiftUI
import UIKit
import FirebaseAuth

enum UserError: Error {
    case missingEmail
    case failedToCreate
    case authenticationFailed
    case invalidURL
    case imageConversionFailed
    case networkError(String)
    case serverError(Int, String?)
}

enum UserService {
    static func createUser(email: String, firstName: String, lastName: String, interests: [String]) async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.userAuthenticationRequired) // Handle unauthenticated user
        }

        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Use debug-appropriate base URL
        let url = "\(APIConfig.baseURL)/v1/user"
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("application/json")
        ]
        
        // Request body
        let parameters: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "interests": interests
        ]
        
        // Make async Alamofire request
        let response = await AF.request(url,
                                      method: .post,
                                      parameters: parameters,
                                      encoding: JSONEncoding.default,
                                      headers: headers)
            .validate(statusCode: 200...201) // Accept 200-201 status codes
            .serializingResponse(using: .data) // Handle empty response body
            .response
        
        // Handle response
        switch response.result {
        case .success:
            // Return true for 201 (or 200) with no data expected
            return true
        case .failure(let error):
            print("Request failed: \(error.localizedDescription)")
            if let underlyingError = error.underlyingError as NSError? {
                print("Underlying error: \(underlyingError.domain), code: \(underlyingError.code)")
            }
            if let responseData = response.data, let responseString = String(data: responseData, encoding: .utf8) {
                print("Server response: \(responseString)")
            }
            throw UserError.failedToCreate // Map to custom error
        }
    }
    
    static func uploadProfileIcon(selectedItem: PhotosPickerItem) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw UserError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/profile-icon") else {
            throw UserError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("multipart/form-data")
        ]
        
        // Convert PhotosPickerItem to image data
        guard let data = try await selectedItem.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw UserError.imageConversionFailed
        }
        
        // Ensure image size is within 5MB limit
        guard jpegData.count <= 5 * 1024 * 1024 else {
            throw UserError.imageConversionFailed
        }
        
        // Create multipart form data using Alamofire
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { multipartFormData in
                // Add image
                multipartFormData.append(jpegData, withName: "image", fileName: "profile.jpg", mimeType: "image/jpeg")
            }, to: url, headers: headers)
            .response { response in
                switch response.result {
                case .success:
                    if let httpResponse = response.response,
                       (200...299).contains(httpResponse.statusCode),
                       let data = response.data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let profileIcon = json["profileIcon"] as? String {
                        continuation.resume(returning: profileIcon)
                    } else {
                        let statusCode = response.response?.statusCode ?? -1
                        let errorMessage = String(data: response.data ?? Data(), encoding: .utf8)
                        continuation.resume(throwing: UserError.serverError(statusCode, errorMessage))
                    }
                case .failure(let error):
                    continuation.resume(throwing: UserError.networkError(error.localizedDescription))
                }
            }
        }
    }
}

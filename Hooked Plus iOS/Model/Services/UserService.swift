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
    static func createUser(handleName: String, email: String, firstName: String, lastName: String, interests: [String]) async throws -> Bool {
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
            "handleName": handleName,
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
    
    static func uploadProfileIcon(selectedItem: PhotosPickerItem) async throws -> UserData {
        guard let user = Auth.auth().currentUser else {
            throw UserError.authenticationFailed
        }

        // Firebase ID token
        let idToken = try await user.getIDToken()

        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/profile-icon") else {
            throw UserError.invalidURL
        }

        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("multipart/form-data")
        ]

        // --- Load original data (supports HEIC, JPEG, PNG, RAW→bitmap, iCloud) ---
        guard let data = try await selectedItem.loadTransferable(type: Data.self) else {
            throw UserError.imageConversionFailed
        }

        // Double-check the image is valid (protect against corrupt assets)
        guard UIImage(data: data) != nil else {
            throw UserError.imageConversionFailed
        }

        // --- Determine the file's true type (HEIC/JPEG/PNG/etc) ---
        let contentTypes = selectedItem.supportedContentTypes

        // Pick the most specific type (Photos usually sends only 1)
        let type: UTType = contentTypes.first ?? .image

        // Map UTType → correct MIME type and filename extension
        let fileExtension = type.preferredFilenameExtension ?? "img"
        let mimeType = type.preferredMIMEType ?? "application/octet-stream"

        let fileName = "profile.\(fileExtension)"

        // --- Validate size (<= 5MB) ---
        guard data.count <= 5 * 1024 * 1024 else {
            throw UserError.imageConversionFailed
        }

        // --- Upload multipart ---
        return try await AF.upload(
            multipartFormData: { form in
                form.append(
                    data,
                    withName: "image",
                    fileName: fileName,
                    mimeType: mimeType
                )
            },
            to: url,
            headers: headers
        )
        .serializingDecodable(UserData.self)
        .value
    }

}

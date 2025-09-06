import Alamofire
import FirebaseAuth

enum UserError: Error {
    case missingEmail
    case failedToCreate
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
}

import Alamofire
import _PhotosUI_SwiftUI
import FirebaseAuth
import PhotosUI
import CoreLocation

enum PostUploadError: Error {
    case authenticationFailed
    case invalidURL
    case imageConversionFailed
    case networkError(String)
    case serverError(Int, String?)
}

enum FeedService {
    static func uploadPost(description: String?, tags: [String] = [], selectedItems: [PhotosPickerItem] = [], locationManager: LocationManager = LocationManager()) async throws {
        
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/post") else {
            throw PostUploadError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .authorization(bearerToken: idToken),
            .contentType("multipart/form-data")
        ]
        
        // Convert PhotosPickerItems to image data
        var imageDataArray: [Data] = []
        for item in selectedItems {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let jpegData = image.jpegData(compressionQuality: 0.8) else {
                throw PostUploadError.imageConversionFailed
            }
            // Ensure image size is within 5MB limit
            guard jpegData.count <= 5 * 1024 * 1024 else {
                throw PostUploadError.imageConversionFailed // Consider a specific error for size limit
            }
            imageDataArray.append(jpegData)
        }
        
        // Validate inputs client-side to match backend
        if (description == nil || description!.isEmpty) && imageDataArray.isEmpty {
            throw PostUploadError.serverError(400, "Post must include text or images.")
        }
        
        if let description = description, description.count > 500 {
            throw PostUploadError.serverError(400, "Description must be 500 characters or less.")
        }
        
        for tag in tags {
            if tag.count > 63 {
                throw PostUploadError.serverError(400, "Each tag must be less than 64 characters.")
            }
        }
        
        // Create multipart form data using Alamofire
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { multipartFormData in
                // Add description under content[description]
                if let description = description,
                   let descriptionData = description.data(using: .utf8) {
                    multipartFormData.append(descriptionData, withName: "content[description]")
                }
                
                // Add tags
                for tag in tags {
                    if let tagData = tag.data(using: .utf8) {
                        multipartFormData.append(tagData, withName: "tags")
                    }
                }
                
                // Add location if available
                if let location = locationManager.currentLocation {
                    if let latData = "\(location.coordinate.latitude)".data(using: .utf8) {
                        multipartFormData.append(latData, withName: "location[lat]")
                    }
                    if let lngData = "\(location.coordinate.longitude)".data(using: .utf8) {
                        multipartFormData.append(lngData, withName: "location[lng]")
                    }
                }
                
                // Add images
                for (index, imageData) in imageDataArray.enumerated() {
                    multipartFormData.append(imageData, withName: "images", fileName: "image\(index).jpg", mimeType: "image/jpeg")
                }
            }, to: url, headers: headers)
            .response { response in
                switch response.result {
                case .success:
                    if let httpResponse = response.response,
                       (200...299).contains(httpResponse.statusCode) {
                        continuation.resume(returning: ())
                    } else {
                        let statusCode = response.response?.statusCode ?? -1
                        let errorMessage = String(data: response.data ?? Data(), encoding: .utf8)
                        continuation.resume(throwing: PostUploadError.serverError(statusCode, errorMessage))
                    }
                case .failure(let error):
                    continuation.resume(throwing: PostUploadError.networkError(error.localizedDescription))
                }
            }
        }
    }
    
    static func getFeed() async throws -> FeedResponse {
        guard let user = Auth.auth().currentUser else {
            throw PostUploadError.authenticationFailed
        }
        
        // Get Firebase ID token
        let idToken = try await user.getIDToken()
        
        
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/user/feed") else {
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
            .serializingDecodable(FeedResponse.self, decoder: decoder)
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

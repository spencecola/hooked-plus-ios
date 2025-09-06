//
//  AuthenticationManger+Firestore.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import FirebaseAuth
import FirebaseFirestore

extension AuthManager {
    func createUserDocument(user: User, firstName: String, lastName: String) async throws {
        guard let email = user.email else {
            throw UserError.missingEmail
        }
        
        let created = try await UserService.createUser(email: email, firstName: firstName, lastName: lastName, interests: [])
        if !created {
            throw UserError.failedToCreate
        }
    }
    
    func fetchUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard case .authenticated(let user) = state else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { (document, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let document = document, document.exists, let data = document.data() {
                    completion(.success(data))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
                }
            }
        }
}

//
//  UserData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

struct UserData: Codable, Equatable, Identifiable {
    var id: String  // Keep Identifiable
    var firstName: String
    var lastName: String
    var email: String
    var profileIcon: String?
    
    // Initialize from dictionary — but ID must be present
    init?(dictionary: [String: Any], id: String? = nil) {
        guard let id = id ?? dictionary["id"] as? String, !id.isEmpty else {
            return nil
        }
        
        self.id = id
        self.firstName = dictionary["firstName"] as? String ?? ""
        self.lastName = dictionary["lastName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.profileIcon = dictionary["profileIcon"] as? String
    }
}

/// converts a user data struct into a dictionary to be set within Firestore
extension UserData {
    func toDictionary() -> [String : Any] {
        var dict: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email
        ]
        if let profileIcon = profileIcon {
            dict["profileIcon"] = profileIcon
        }
        return dict
    }
}

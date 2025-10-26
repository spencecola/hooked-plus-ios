//
//  UserData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

struct UserData: Codable, Equatable, Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var profileIcon: String?
    
    init(dictionary: [String : Any]) {
        id = dictionary["id"] as? String ?? ""
        firstName = dictionary["firstName"] as? String ?? ""
        lastName = dictionary["lastName"] as? String ?? ""
        email = dictionary["email"] as? String ?? ""
        profileIcon = dictionary["profileIcon"] as? String
    }
}

/// converts a user data struct into a dictionary to be set within Firestore
extension UserData {
    func toDictionary() -> [String : Any] {
        [
            "id" : id,
            "firstName" : firstName,
            "lastName" : lastName,
            "email" : email,
            "profileIcon" : profileIcon
        ]
    }
}

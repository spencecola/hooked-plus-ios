//
//  UserData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/12/25.
//

struct UserData {
    var firstName: String
    var lastName: String
    var email: String
    var profileIcon: String?
    
    init(dictionary: [String : Any]) {
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
            "firstName" : firstName,
            "lastName" : lastName,
            "email" : email,
            "profileIcon" : profileIcon
        ]
    }
}

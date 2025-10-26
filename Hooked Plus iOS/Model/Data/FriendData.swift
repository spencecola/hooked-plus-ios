//
//  FriendData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/25/25.
//

//struct FriendData: Codable {
//    var firstName: String
//    var lastName: String
//    var email: String
//    var profileIcon: String?
//}

struct FriendResponse: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var users: [UserData]
}

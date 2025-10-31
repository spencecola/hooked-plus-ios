//
//  FriendData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/25/25.
//

// this is similar to UserData but with a friendDocId which ties the user to the friend entry
struct FriendUserData: Codable, Equatable, Identifiable {
    var id: String
    var user: UserData
}

struct FriendResponse: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var users: [FriendUserData]
}

struct SuggestedFriendResponse: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var users: [UserData]
}

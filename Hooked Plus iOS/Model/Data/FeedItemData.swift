//
//  FeedData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/19/25.
//

import Foundation

struct FeedItemContentData: Codable {
    var description: String?
}

struct FeedItemData: Codable, Identifiable {
    var id: String
    var timestamp: Date?
    var handleName: String?
    var firstName: String?
    var lastName: String?
    var profileIcon: String?
    var likeCount: Int?
    var commentCount: Int?
    var content: FeedItemContentData?
    var images: [String]?
}

struct FeedResponse: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var data: [FeedItemData]
}

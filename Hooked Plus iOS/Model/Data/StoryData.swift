//
//  StoryData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/8/25.
//

import Foundation

struct StoryData: Decodable, Identifiable {
    let id = UUID()
    let userId: String
    let videoUrl: String
//    let createdAt: Date
//    let expiresAt: Date
}

struct FriendStoriesData: Decodable, Identifiable {
    var id: String { friendId }
    let friendId: String
    let firstName: String
    let lastName: String
    let profileIcon: String?
    let stories: [StoryData]
}

struct StoriesResponse: Decodable {
    let friendStories: [FriendStoriesData]
}

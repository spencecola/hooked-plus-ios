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
    let userProfileIconUrl: String
    let userFirstName: String
    let userLastName: String
    let videoUrl: String
    let createdAt: Date
    let expiresAt: Date
}

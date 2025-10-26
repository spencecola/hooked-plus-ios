//
//  MyCatchData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/23/25.
//

import Foundation

struct MyCatchData: Codable, Identifiable {
    var id: String
    var species: SpeciesData?
    var createdAt: Date?
    var images: [String]?
    var weather: WeatherData?
}

struct MyCatchesResponse: Codable {
    var page: Int
    var limit: Int
    var catches: [MyCatchData]
}

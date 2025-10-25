//
//  SpeciesData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/21/25.
//

import Foundation

struct SpeciesData: Codable {
    var scientificName: String?
    var taxOCode: String?
    var a3Code: String?
    var issCaap: Int?
    var englishName: String
}

struct SpeciesResponse: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var results: [SpeciesData]
}

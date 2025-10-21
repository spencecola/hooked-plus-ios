//
//  WeatherService.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/15/25.
//

import Foundation
import Alamofire

enum WeatherService {
    static func getWeather(lat: Double, lng: Double) async throws -> WeatherData {
        // Use debug-appropriate base URL
        guard let url = URL(string: "\(APIConfig.baseURL)/v1/weather?lat=\(lat)&lng=\(lng)") else {
            throw PostUploadError.invalidURL
        }
        
        // Headers with Authorization
        let headers: HTTPHeaders = [
            .contentType("application/json")
        ]
        
        // Create a custom JSONDecoder with date decoding strategy
         let decoder = JSONDecoder()
         decoder.dateDecodingStrategy = .millisecondsSince1970
        
        // Make the GET request using Alamofire
        let response = await AF.request(url, method: .get, headers: headers)
            .serializingDecodable(WeatherData.self, decoder: decoder)
            .response
        
        // Handle the response
        switch response.result {
        case .success(let weather):
            return weather
        case .failure(let error):
            throw PostUploadError.networkError(error.localizedDescription)
        }
    }
}

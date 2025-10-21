//
//  WeatherData.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/15/25.
//

struct WeatherData: Codable {
    var latitude: Double
    var longitude: Double
    var temperature_f: Double
    var temperature_c: Double
    var windspeed: Double
    var winddirection: Int
    
    // Computed property for formatted temperature (e.g., "85°F")
    var formattedTemperature: String {
        let roundedTemp = Int(temperature_f.rounded())
        return "\(roundedTemp)°F"
    }
    
    // Computed property for formatted wind speed and direction (e.g., "ESE 5 mph")
    var formattedWind: String {
        let roundedSpeed = Int(windspeed.rounded())
        let direction = windDirectionString(from: winddirection)
        return "\(direction) \(roundedSpeed) mph"
    }
    
    // Helper function to convert wind direction degrees to cardinal direction
    private func windDirectionString(from degrees: Int) -> String {
        let directions = [
            (0..<22.5, "N"),
            (22.5..<67.5, "NE"),
            (67.5..<112.5, "E"),
            (112.5..<157.5, "SE"),
            (157.5..<202.5, "S"),
            (202.5..<247.5, "SW"),
            (247.5..<292.5, "W"),
            (292.5..<337.5, "NW"),
            (337.5..<360, "N")
        ]
        
        return directions.first { range, _ in
            range.contains(Double(degrees))
        }?.1 ?? "N"
    }
}

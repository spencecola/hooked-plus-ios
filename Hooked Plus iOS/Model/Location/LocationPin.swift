//
//  LocationPin.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/13/25.
//

import CoreLocation

struct LocationPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

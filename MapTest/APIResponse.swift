//
//  APIResponse
//  MapTest
//
//  Created by COMATOKI on 2019-07-30.
//  Copyright © 2019 COMATOKI. All rights reserved.
//

import Foundation

struct APIResponse: Codable {
    var status: String?
    var geocodedWaypoints: [Geocoded_waypoint]?
    var routes: [Route]?

    enum CodingKeys: String, CodingKey {
        case status, routes
        case geocodedWaypoints = "geocoded_waypoint"
    }
}

struct Geocoded_waypoint: Codable {
    let geocoderStatus: String?
    let placeId: String?
    let types: [String]?
    
    enum CodingKeys: String, CodingKey {
        case types
        case geocoderStatus = "geocoder_status"
        case placeId = "place_id"
    }
}

struct Route: Codable {
    var bounds: Bound?
    var copyrights: String?
    var legs: [Leg]?
    let overviewPolyline: OverView?
    var summary: String?
    var warnings: [String]?
    var waypointOrder: [String]?
    
    enum CodingKeys: String, CodingKey {
        case copyrights, summary, warnings, bounds, legs
        case overviewPolyline = "overview_polyline"
        case waypointOrder = "waypoint_order"
    }
}

struct OverView: Codable {
    var points: String?
}

struct Bound: Codable {
    var southwest: Location?
    var northeast: Location?
}

struct Leg: Codable {
    let step: [Step]?
    var duration: Time?
    var distance: Time?
    let startLocation: Location?
    let endLocation: Location?
    let startAddress: String?
    let endAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case duration, distance, step
        case startLocation = "start_location"
        case endLocation = "end_location"
        case startAddress = "start_address"
        case endAddress = "end_address"
    }
}

struct Step: Codable {
    let travelMode: String?
    let startLocation: Location?
    let engLocation: Location?
    let polyline: Point?
    let duration: Time?
    let htmlInstructions: String?
    let distance: Time?
    
    enum CodingKeys: String, CodingKey {
        case polyline, duration, distance
        case travelMode = "travel_mode"
        case startLocation = "start_location"
        case engLocation = "eng_location"
        case htmlInstructions = "html_instructions"
    }
}

struct Point: Codable {
    var points: String?
    
    enum CodingKeys: String, CodingKey {
        case points
    }
}

struct Location: Codable {
    var lat: Double?
    var lng: Double?
    
    enum CodingKeys: String, CodingKey {
        case lat, lng
    }
}

struct Time: Codable {
    var text: String?
    var value: Int?
    
    enum CodingKeys: String, CodingKey {
        case text, value
    }
}

//
//  Connection.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/18/24.
//

import Foundation
import UniformTypeIdentifiers

protocol Connection {
    var baseURL: String { get }
    var apiKey: String { get }
    var requestType: UTType { get }
}

struct WeatherAPIConnection: Connection {
    let baseURL = "https://api.weatherapi.com/v1"
    let apiKey = "da948f827bb54e51a4e152433241712"
    let requestType: UTType = .json
}

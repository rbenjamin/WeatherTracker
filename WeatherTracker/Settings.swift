//
//  Settings.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import Foundation
import Combine

@MainActor
class Settings: NSObject, ObservableObject {
    
    enum DefaultsKeys: String {
        case locationName
        case latitude
        case longitude
        case existingLocations
    }
    static let shared = Settings()

    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    var currentLocationName: String? {
        didSet {
            self.defaults.set(currentLocationName,
                              forKey: DefaultsKeys.locationName.rawValue)
        }
    }
    
    @Published var existingLocations: [String : WeatherCoordinates] {
        didSet {
            let data = try? encoder.encode(existingLocations)
            self.defaults.set(data, forKey: DefaultsKeys.existingLocations.rawValue)
        }
    }
    
    func addLocation(name: String,
                     coordinates: WeatherCoordinates) {
        
        self.existingLocations[name] = WeatherCoordinates(latitude: coordinates.latitude,
                                                      longitude: coordinates.longitude)
    }
    
    func removeLocation(with name: String) {
        self.existingLocations.removeValue(forKey: name)
    }

    var currentLocationCoordinates: WeatherCoordinates? {
        guard let latitude, let longitude else { return nil }
        return WeatherCoordinates(latitude: latitude, longitude: longitude)
    }
    
    var latitude: Double? {
        didSet {
            self.defaults.set(latitude, forKey: DefaultsKeys.latitude.rawValue)
        }
    }
    
    var longitude: Double? {
        didSet {
            self.defaults.set(longitude, forKey: DefaultsKeys.longitude.rawValue)
        }
    }
    
    override init() {
        self.currentLocationName = self.defaults.value(forKey: DefaultsKeys.locationName.rawValue) as? String
        self.latitude = self.defaults.value(forKey: DefaultsKeys.latitude.rawValue) as? Double
        self.longitude = self.defaults.value(forKey: DefaultsKeys.longitude.rawValue) as? Double
        
        if let data = self.defaults.value(forKey: DefaultsKeys.existingLocations.rawValue) as? Data,
            let decoded = try? self.decoder.decode([String: WeatherCoordinates].self,
                                                   from: data) {
            
            self.existingLocations = decoded
        } else {
            self.existingLocations = [:]
        }
    }
    
    
}

//
//  WeatherData.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import Foundation


struct WeatherCoordinates: Sendable, Codable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct WeatherLocation: Sendable, Decodable, Identifiable, Equatable {
    enum CodingKeys: String, CodingKey {
        case name
        case region
        case latitude = "lat"
        case longitude = "lon"
    }
    
    let id = UUID()
    var name: String
    var region: String
    var coordinate: WeatherCoordinates
    
    public static func ==(lhs: WeatherLocation, rhs: WeatherLocation) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: CodingKeys.name)
        self.region = try container.decode(String.self, forKey: CodingKeys.region)
        let latitude = try container.decode(Double.self, forKey: CodingKeys.latitude)
        let longitude = try container.decode(Double.self, forKey: CodingKeys.longitude)
        self.coordinate = WeatherCoordinates(latitude: latitude, longitude: longitude)
    }
    
    init(name: String,
         region: String,
         coordinates: WeatherCoordinates) {
        
        self.name = name
        self.region = region
        self.coordinate = coordinates
    }
    
}

struct WeatherConditions: Sendable, Decodable, Identifiable {
    
    enum CodingKeys: String, CodingKey {
        case label = "text"
        case icon
        case code
    }
    
    let id = UUID()
    var label: String
    var icon: String
    var code: Int
    
    var iconURL: URL? {
        let withHTTP = "https:".appending(icon)
        return URL(string: withHTTP)
    }
    
    init(label: String,
         icon: String,
         code: Int) {
        
        self.label = label
        self.icon = icon
        self.code = code
    }
}

struct WeatherData: Sendable, Decodable, Identifiable, Equatable, Comparable {
    
    enum CodingKeys: String, CodingKey {
        case location
        case current
    }
    
    public static func ==(lhs: WeatherData, rhs: WeatherData) -> Bool {
        return lhs.id == rhs.id
    }

    public static func <(lhs: WeatherData, rhs: WeatherData) -> Bool {
        return lhs.location.name < rhs.location.name
    }
    
    let id = UUID()
    
    /// The current location name and coordinates
    var location: WeatherLocation
    var currentWeather: CurrentWeather
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.location = try container.decode(WeatherLocation.self, forKey: .location)
        self.currentWeather = try container.decode(CurrentWeather.self, forKey: .current)
    }
    
    init(location: WeatherLocation,
         currentWeather: CurrentWeather) {
        
        self.location = location
        self.currentWeather = currentWeather
    }
   
}

struct CurrentWeather: Sendable, Decodable, Identifiable, Equatable {
    enum CodingKeys: String, CodingKey {
        case temperature = "temp_c"
        case conditions = "condition"
        case humidity
        case uvIndex = "uv"
        case feelsLike = "feelslike_c"
    }
    
    
    public static func ==(lhs: CurrentWeather, rhs: CurrentWeather) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()

    /// Temperature (celcius): WeatherAPI returns temperature as a decimal (double), we'll convert to locale specific temperature format.
    var temperature: Measurement<UnitTemperature>
  
    /// Current weather conditions
    var conditions: WeatherConditions
   
    /// Humidity %: WeatherAPI returns humidity as an Int, but we want to use percentFormatter to ensure humidity is formatted correctly.
    var humidity: Double
    
    /// Feels-Like Temperature (celcius): WeatherAPI returns feels-like as a decimal (double), we'll convert to locale specific temperature format.
    var feelsLike: Measurement<UnitTemperature>
   
    /// UV-Index : Weather API returns as a decimal, we want to save as an Int.
    var uvIndex: Int
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let temperature = try container.decode(Double.self, forKey: .temperature)
        self.temperature = Measurement<UnitTemperature>.tempCelciusToLocale(temperature)
        
        self.conditions = try container.decode(WeatherConditions.self, forKey: .conditions)
        
        let humidity = try container.decode(Int.self, forKey: .humidity)
        self.humidity = Double(humidity) / 100.0
        
        let feelsLike = try container.decode(Double.self, forKey: .feelsLike)
        self.feelsLike = Measurement<UnitTemperature>.tempCelciusToLocale(feelsLike)
        
        let uvIndex = try container.decode(Double.self, forKey: .uvIndex)
        self.uvIndex = Int(uvIndex)
    }
    
    init(temperatureCelcius: Double,
         conditions: WeatherConditions,
         humidity: Double,
         feelsLikeCelcius: Double,
         uvIndex: Int) {
        
        self.temperature = Measurement<UnitTemperature>.tempCelciusToLocale(temperatureCelcius)
        self.conditions = conditions
        self.humidity = humidity
        self.feelsLike = Measurement<UnitTemperature>.tempCelciusToLocale(feelsLikeCelcius)
        self.uvIndex = uvIndex
    }
}

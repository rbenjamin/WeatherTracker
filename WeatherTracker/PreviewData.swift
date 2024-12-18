//
//  PreviewData.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/18/24.
//

struct PreviewData {
    let location = WeatherLocation(name: "London",
                                   region: "City of London, Greater London",
                                   coordinates: WeatherCoordinates(latitude: 51.5171, longitude: -0.1062))
    let currentWeather = CurrentWeather(temperatureCelcius: 11.5,
                                        conditions: .init(label: "Patchy rain nearby",
                                                          icon: "//cdn.weatherapi.com/weather/64x64/night/176.png",
                                                          code: 1063),
                                        humidity: 0.82,
                                        feelsLikeCelcius: 9.7,
                                        uvIndex: 0)
    let weatherData: WeatherData
    
    init() {
        self.weatherData = WeatherData(location: location,
                                       currentWeather: currentWeather)
    }
}
    

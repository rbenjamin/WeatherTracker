//
//  Measurement+Extensions.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import Foundation

extension Measurement<UnitTemperature> {
    
    /// Since WeatherAPI returns farenheit or celcius as a Double, we want to convert it to a UnitTemperature measurement specific to device locale, rather than based on returned location.
    ///
    static func tempCelciusToLocale(_ temperature: Double) -> Measurement<UnitTemperature> {
        let tempC = Measurement<UnitTemperature>(value: temperature, unit: .celsius)
        let converted = tempC.converted(to: UnitTemperature(forLocale: .current, usage: .weather))
        return converted
    }
}

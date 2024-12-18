//
//  WeatherTrackerTests.swift
//  WeatherTrackerTests
//
//  Created by Ben Davis on 12/17/24.
//

import Testing
@testable import WeatherTracker

struct WeatherTrackerTests {

    @Test func testDownloadWeather() async throws {
        let connection = ConnectionManager(connection: WeatherAPIConnection())
        let coordinates = PreviewData().location.coordinate
        let weather = try await connection.weather(for: coordinates)
        #expect(weather != nil, "Weather data is nil for London coordinates.")
    }
    
    @Test func testSearchLocation() async throws {
        let connection = ConnectionManager(connection: WeatherAPIConnection())
        let results = try await connection.search(for: "London")
        #expect(results != nil, "Connection location search results is nil!")
        #expect(results?.isEmpty == false, "Connection location search results is empty.")
    }

}

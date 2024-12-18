//
//  WeatherRowView.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import SwiftUI
import Combine

struct WeatherRowView: View {
    let weather: WeatherData
    let connection: ConnectionManager<WeatherAPIConnection>
    @State private var iconImage: Image?
    
    init(weather: WeatherData, connection: ConnectionManager<WeatherAPIConnection>) {
        self.weather = weather
        self.connection = connection
    }
    
    func downloadIcon(url: URL) async {
        if let icon = try? await connection.icon(fromURL: url) {
            Task { @MainActor in
                self.iconImage = Image(uiImage: icon)
            }
        }
    }
    
    
    var body: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading) {
                    Text(weather.location.name)
                        .fontWeight(.bold)
                    
                    Text(weather.currentWeather.temperature, format: .measurement(width: .abbreviated, usage: .asProvided))
                        .font(.system(.title, weight: .bold))
                }
                Spacer()
                if let icon = self.iconImage {
                    icon
                        .transition(.scale)
                }
            }
        }
        .task {
            if let iconURL = weather.currentWeather.conditions.iconURL {
                Task {
                    await self.downloadIcon(url: iconURL)
                }
            }
        }
        .onChange(of: weather) { oldValue, newValue in
            if let iconURL = newValue.currentWeather.conditions.iconURL {
                Task {
                    await self.downloadIcon(url: iconURL)
                }
            }
        }

    }
}

#Preview {
    let previewData = PreviewData()

    WeatherRowView(weather: previewData.weatherData,
                   connection: ConnectionManager(connection: WeatherAPIConnection()))
}

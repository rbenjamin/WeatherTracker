//
//  MainWeatherView.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import SwiftUI

struct MainWeatherView: View {
    @Binding var weather: WeatherData?
    @State private var current: CurrentWeather?
    @State private var iconImage: Image?
    
    let connection: ConnectionManager<WeatherAPIConnection>
    
    init(weather: Binding<WeatherData?>, connection: ConnectionManager<WeatherAPIConnection>) {
        _weather = weather
        self.connection = connection
    }
    
    func downloadIcon(url: URL) async {
        if let icon = try? await connection.icon(fromURL: url) {
            Task { @MainActor in
                withAnimation {
                    self.iconImage = Image(uiImage: icon)
                }
            }
        }
    }
    
    @ViewBuilder
    func currentWeatherView(weather: WeatherData) -> some View {
        let current = weather.currentWeather
        
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            
            if let icon = self.iconImage {
                icon
                    .transition(.scale)
            }
            HStack {
                Text(weather.location.name)
                Image(systemName: "location.fill")
            }
            .font(.system(.headline, weight: .bold))
            Text(current.temperature, format: .measurement(width: .abbreviated,
                                                           usage: .asProvided))
            .font(.system(.largeTitle,
                          weight: .bold))
            
            GroupBox {
                HStack {
                    
                    // Humidity
                    VStack(alignment: .center) {
                        Text("Humidity")
                        Text(current.humidity, format: .percent)
                    }
                    
                    // UV
                    VStack(alignment: .center) {
                        Text("UV")
                        Text(String(current.uvIndex))
                    }
                    
                    // Feels Like
                    VStack(alignment: .center) {
                        Text("Feels Like")
                        Text(current.feelsLike, format: .measurement(width: .abbreviated,
                                                                     usage: .asProvided))
                    }
                    
                }
                .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .center)
        .task {
            if let iconURL = weather.currentWeather.conditions.iconURL {
                Task {
                    await self.downloadIcon(url: iconURL)
                }
            }
        }

    }
    
    var missingWeatherView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                Text("No City Selected")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please Search For A City")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity,
                    maxHeight: .infinity)
            
            
        }
//        .frame(maxWidth: .infinity,
//                maxHeight: .infinity)
    }
    
    var body: some View {
        ScrollView {
            if let weather {
                self.currentWeatherView(weather: weather)
            } else {
                self.missingWeatherView
            }
        }
        .onChange(of: self.weather, { _, newValue in
            if let current = newValue?.currentWeather {
                withAnimation {
                    self.current = current
                }
            }
        })
        .onAppear {
            self.current = weather?.currentWeather
        }
    }
}

#Preview {
    let previewData = PreviewData()
    MainWeatherView(weather: .constant(previewData.weatherData),
                    connection: .init(connection: WeatherAPIConnection()))
}

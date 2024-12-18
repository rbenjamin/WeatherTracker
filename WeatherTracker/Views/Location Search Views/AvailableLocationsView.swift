//
//  AvailableLocationsView.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import SwiftUI

struct AvailableLocationsView: View {
    let connection: ConnectionManager<WeatherAPIConnection>
    @Binding var locations: [WeatherData]
    @Binding var currentWeather: WeatherData?
    @FocusState.Binding var searchFocus:  Bool
    
    init(locations: Binding<[WeatherData]>, currentWeather: Binding<WeatherData?>, searchFocus: FocusState<Bool>.Binding, connection: ConnectionManager<WeatherAPIConnection>) {
        _locations = locations
        _currentWeather = currentWeather
        _searchFocus = searchFocus
        self.connection = connection
    }
    
    var body: some View {
        List {
            ForEach(self.locations, id: \.id, content: { locationWeather in
                Button {
                    withAnimation {
                        self.currentWeather = locationWeather
                        self.searchFocus.toggle()
                    }
                } label: {
                    WeatherRowView(weather: locationWeather,
                                   connection: self.connection)
                }
                .transition(.opacity)
            })
            .onDelete { indexSet in
                for index in indexSet {
                    let location = locations[index].location
                    Settings.shared.removeLocation(with: location.name)
                    withAnimation {
                       _ = locations.remove(at: index)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .background(.white)
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .center)

    }
}

//#Preview {
//    AvailableLocationsView(locations: .constant([]), currentWeather: .constant(nil), connection: ConnectionManager(connection: WeatherAPIConnection()))
//}

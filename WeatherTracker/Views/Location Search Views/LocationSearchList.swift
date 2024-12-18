//
//  LocationsList.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import SwiftUI

struct LocationSearchList: View {
    
    let locations: [WeatherLocation]
    
    @Binding var searchText: String
    @Binding var selectedLocation: WeatherLocation?
    
    init(locations: [WeatherLocation],
         searchText: Binding<String>,
         selectedLocation: Binding<WeatherLocation?>) {
        
        self.locations = locations
        _searchText = searchText
        _selectedLocation = selectedLocation
    }
    
    var body: some View {
        ZStack {
            LazyVStack {
                if locations.isEmpty {
                    ProgressView()
                }
                ForEach(locations, id: \.id) { location in
                    Button {
                        self.searchText = ""
                        self.selectedLocation = location

                    } label: {
                        HStack {
                            Text(location.name)
                            Text(location.region)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 44)
                }
                if !locations.isEmpty {
                    Divider()
                }
            }
        }
    }
}

#Preview {
    LocationSearchList(locations: [],
                       searchText: .constant(""),
                       selectedLocation: .constant(nil))
}

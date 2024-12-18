//
//  ContentView.swift
//  WeatherTracker
//
//  Created by Ben Davis on 12/17/24.
//

import SwiftUI
import Combine
import Network


@MainActor
class WeatherViewModel: ObservableObject {
    @Published var searchText: String = ""
    private var cancellables = [AnyCancellable]()
    
    
    var searchTask: Task<Void, Never>?
    let connection: ConnectionManager<WeatherAPIConnection>
    @Published var selectedLocation: WeatherLocation?
    @Published var networkAvailable: Bool = true
    
    let weatherLocaleData = PassthroughSubject<[WeatherData]?, Never>()
    let matchedLocations = PassthroughSubject<[WeatherLocation]?, Never>()
    let currentWeather = PassthroughSubject<WeatherData?, Never>()
    let monitor = NWPathMonitor()
    
    init(connection: ConnectionManager<WeatherAPIConnection>) {
        self.connection = connection
        
        monitor.start(queue: .global())
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.networkAvailable = (path.status == .satisfied)
            }
        }
        $searchText.debounce(for: .seconds(0.25),
                             scheduler: DispatchQueue.main)
        .removeDuplicates()
        .sink { string in
            self.locationSearch(string)
        }
        .store(in: &cancellables)
        
        $selectedLocation.sink { location in
            guard let location else {
                return
            }
            Task {
                guard let currentWeather = await self.loadCoordinates(location.coordinate) else { return }
                Task { @MainActor in
                    self.currentWeather.send(currentWeather)
                }
            }
            
        }.store(in: &cancellables)
                
        if let coordinate = Settings.shared.currentLocationCoordinates {
            Task {
                let currentWeather = await self.loadCoordinates(coordinate)
                Task { @MainActor in
                    self.currentWeather.send(currentWeather)
                }
            }
        }
        
        Task {
           await self.loadExistingWeatherLocations()
        }

    }
    
    func loadExistingWeatherLocations() async {
        let existing = Settings.shared.existingLocations
        do {
            var downloaded = [WeatherData]()
            for (_, coordinates) in existing {
                let coordinate2d = WeatherCoordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
                if let weather = try await self.connection.weather(for: coordinate2d) {
                    downloaded.append(weather)
                    print(weather.location.name)
                }
            }
            downloaded.sort()
            Task { @MainActor in
                self.weatherLocaleData.send(downloaded)
            }
        } catch let error {
            print("Error: \(error)")
        }

    }
    
    func loadCoordinates(_ coordinates: WeatherCoordinates) async -> WeatherData? {
        do {
            return try await self.connection.weather(for: coordinates)
        } catch let error {
            print(error)
        }
        return nil
    }
    

    func locationSearch(_ searchString: String) {
        guard !searchString.isEmpty else { return }
        self.searchTask?.cancel()
        let searchTask = Task { 
            do {
                if let results = try await self.connection.search(for: searchString) {
                    Task { @MainActor in
                        self.matchedLocations.send(results)
                    }
                }
            } catch let error {
                print(error)
            }
        }
        self.searchTask = searchTask
    }
}

struct ContentView: View {
    
    enum VisibleView {
        case searchResults
        case currentWeather
    }
    
    let connection: ConnectionManager<WeatherAPIConnection>
    @StateObject private var viewModel: WeatherViewModel

    @State private var locations: [WeatherLocation]?
    @State private var currentWeather: WeatherData?
    @State private var weatherLocaleData: [WeatherData] = []
    @State private var beginLocationSearch: Bool = false
    
    @State private var visibleView: VisibleView = .currentWeather
    @FocusState private var searchFocus: Bool

    init() {
        let connection = ConnectionManager(connection: WeatherAPIConnection())
        _viewModel = StateObject(wrappedValue: WeatherViewModel(connection: connection))
        self.connection = connection
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                GroupBox {
                    HStack {
                        TextField("Search Location", text: $viewModel.searchText,
                                  prompt: Text("Search Location"))
                            .focused(self.$searchFocus)
                            .autocorrectionDisabled()
                            
                        Label("Search", systemImage: "magnifyingglass")
                            .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                    }
                    .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                }
                .padding([.leading, .trailing, .top], 24)
                
                if self.viewModel.networkAvailable == false {
                    GroupBox {
                        Text("\(Image(systemName: "exclamationmark.triangle.fill")) Network Unavailable")
                    }
                }
                
                if self.visibleView == .searchResults {
                    VStack {
                        if let results = self.locations {
                            LocationSearchList(locations: results,
                                               searchText: $viewModel.searchText,
                                               selectedLocation: self.$viewModel.selectedLocation)

                        }
                        AvailableLocationsView(locations: self.$weatherLocaleData,
                                               currentWeather: self.$currentWeather,
                                               searchFocus: $searchFocus,
                                               connection: self.connection)
                    }
                    .background {
                        Color.white
                    }
                    .transition(.push(from: .bottom).combined(with: .opacity))
                }
                else {
                    MainWeatherView(weather: self.$currentWeather,
                                    connection: self.connection)
                    .transition(.push(from: .top).combined(with: .opacity))
                }
            }
        }
        .onChange(of: self.viewModel.selectedLocation, { _, _ in
            self.searchFocus = false
        })
        .onChange(of: self.currentWeather, { oldValue, newValue in
            self.searchFocus = false
        })
        .onChange(of: self.searchFocus, { _, newValue in
            withAnimation(.easeIn) {
                if newValue == true {
                    if viewModel.searchText.isEmpty == false {
                        viewModel.locationSearch(viewModel.searchText)
                    }
                    self.visibleView = .searchResults
                    
                } else {
                    self.visibleView = .currentWeather
                    self.locations = nil
                }
            }
        })
        .onReceive(self.viewModel.weatherLocaleData, perform: { output in
            guard let output, !output.isEmpty else { return }
            withAnimation {
                self.weatherLocaleData = output
            }
        })
        .onReceive(self.viewModel.matchedLocations, perform: { output in
            withAnimation {
                self.visibleView = .searchResults
                self.locations = output
            }
        })
        .onReceive(self.viewModel.currentWeather, perform: { output in
            guard let output else { return }
            withAnimation {
                self.visibleView = .currentWeather
                self.currentWeather = output
            }
            Settings.shared.addLocation(name: output.location.name, coordinates: output.location.coordinate)

            Settings.shared.currentLocationName = output.location.name
            Settings.shared.latitude = output.location.coordinate.latitude
            Settings.shared.longitude = output.location.coordinate.longitude
            
            Task {
                await self.viewModel.loadExistingWeatherLocations()
            }
            
        })
    }
}

#Preview {
    ContentView()
}

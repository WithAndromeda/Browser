//
//  Home.swift
//  Andromeda
//
//  Created by WithAndromeda on 11/23/24.
//

#if os(macOS)
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: ViewModel
    @StateObject private var weatherManager = WeatherManager()
    @State private var searchText = ""
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds", "partly cloudy":
            return "cloud.sun.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
    
    private func handleSearch() {
        if !searchText.isEmpty {
            if searchText.contains(".") && !searchText.contains(" ") {
                viewModel.currentURL = searchText
            } else {
                let encodedSearch = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                viewModel.currentURL = "https://www.google.com/search?q=\(encodedSearch)"
            }
            viewModel.navigateToURL()
        }
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top Bar
                HStack {
                    Text("Andromeda")
                        .font(.system(size: 30, weight: .thin))
                        .padding()
                    
                    Spacer()
                    
                    // Weather with dynamic icon
                    HStack(spacing: 8) {
                        Image(systemName: weatherIcon(for: weatherManager.condition))
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 20, weight: .thin))
                        Text("\(weatherManager.temperature)°F")
                            .font(.system(size: 20, weight: .thin))
                        Text(weatherManager.city)
                            .font(.system(size: 20, weight: .thin))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Search Bar
                VStack(spacing: 20) {
                    TextField("Search or enter web address", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 600)
                        .font(.system(size: 16))
                        .padding()
                        .onSubmit {
                            handleSearch()
                        }
                    
                    // Weather Condition
                    Text(weatherManager.condition)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .onAppear {
            weatherManager.fetchWeather()
        }
    }
}
#endif

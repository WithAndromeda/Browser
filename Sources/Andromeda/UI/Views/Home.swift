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
    @State private var searchText = ""
    @State private var temperature = "72"
    @State private var city = "New York"
    @State private var condition = "Partly Cloudy"
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top Bar
                HStack {
                    Text("Andromeda")
                        .font(.system(size: 20, weight: .thin))
                        .padding()
                    
                    Spacer()
                    
                    // Weather
                    HStack(spacing: 8) {
                        Image(systemName: "cloud.sun.fill")
                            .symbolRenderingMode(.multicolor)
                        Text("\(temperature)°F")
                        Text(city)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Search Bar
                VStack(spacing: 20) {
                    TextField("Search or enter web address", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 500)
                        .onSubmit {
                            if !searchText.isEmpty {
                                viewModel.currentURL = searchText
                                viewModel.navigateToURL()
                            }
                        }
                    
                    // Weather Condition
                    Text(condition)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}
#endif

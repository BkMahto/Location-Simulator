//
//  ContentView.swift
//  Location Simulator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapsView()
                .tabItem {
                    Label("Maps", systemImage: "map.circle")
                }
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
            DeveloperDetailsView()
                .tabItem {
                    Label("Developer", systemImage: "wrench.and.screwdriver")
                }
        }
    }
}

#Preview {
    ContentView()
}

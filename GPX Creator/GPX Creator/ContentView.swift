//
//  ContentView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import AppKit
import CoreLocation
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = GPXCreatorViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with toggle and simulation speed
                HStack {
                    AddressSearchView(viewModel: viewModel)
                        .padding()
                        .background(Color(nsColor: .separatorColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack {
                        Toggle("Two Fields", isOn: .init(
                            get: { viewModel.appState.isTwoFieldMode },
                            set: { _ in viewModel.toggleTwoFieldMode() }
                        ))
                            .toggleStyle(SwitchToggleStyle())
                            .help("Switch between single location and start/end location modes")
                            .accessibilityLabel("Two field mode toggle")
                            .accessibilityHint("Toggle between single address field and separate start/end address fields")
                            .keyboardShortcut("t", modifiers: .command)

                        if viewModel.appState.isTwoFieldMode {
                            VStack {
                                Text("Simulation Speed")
                                    .font(.headline)

                                HStack {
                                    TextField("Speed", value: .init(
                                        get: { viewModel.appState.simulationSpeed },
                                        set: { viewModel.updateSimulationSpeed($0) }
                                    ), format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 80)
                                    .help("Simulation speed in km/h (20-100)")
                                    .accessibilityLabel("Simulation speed")
                                    .accessibilityHint("Enter simulation speed between 20 and 100 km/h for GPX file generation")

                                    Text("km/h")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .separatorColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

                ZStack(alignment: .topTrailing) {
                    MapView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    MapControlsView(viewModel: viewModel)
                }
            }

            // Error and warning alerts
            ErrorAlertView(viewModel: viewModel)
        }
        .frame(minWidth: 800, minHeight: 600)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("GPX Creator - Create and export GPX files for location simulation")
    }
}

#Preview {
    ContentView()
}

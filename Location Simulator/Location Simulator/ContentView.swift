//
//  ContentView.swift
//  Location Simulator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location Simulator")
                            .font(.title2).bold()
                        Text("Debug helper for simulating GPS via Xcode")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    Spacer()
                    Text("DEBUG")
                        .font(.caption2).bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                        )
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("How to use")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Label {
                            Text("Run this app from Xcode on a simulator or device.")
                        } icon: { Image(systemName: "1.circle.fill").foregroundStyle(.secondary) }
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Choose a GPX route:")
                                Text("Debug > Simulate Location > [Pick GPX]")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("or set a GPX under the scheme’s Location settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "2.circle.fill").foregroundStyle(.secondary) }
                        Label {
                            Text("Keep this app running (foreground or background). Do not force quit.")
                        } icon: { Image(systemName: "3.circle.fill").foregroundStyle(.secondary) }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle").foregroundStyle(.secondary)
                            Text("This is a workaround: iOS only allows mock locations through Xcode while debugging.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle").foregroundStyle(.secondary)
                            Text("Killing the app stops the simulation. Keep it running during tests.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "gear").foregroundStyle(.secondary)
                            Text("If nothing happens, ensure the scheme has Location Simulation enabled and a GPX is selected.")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Included sample")
                        .font(.headline)
                    Text("The project ships with \"Cupertino.gpx\" you can select from the Xcode Simulate Location menu.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                Spacer(minLength: 8)
                Text("Made for internal testing and development.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

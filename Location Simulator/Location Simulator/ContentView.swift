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
            // MARK: Info Tab
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

                    Spacer(minLength: 8)
                    Text("Made for internal testing and development.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .tabItem {
                Label("Info", systemImage: "info.circle")
            }

            // MARK: Developer Tab
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

// MARK: - Developer Details View
struct DeveloperDetailsView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
        "Location Simulator"
    }
    private var bundleId: String { Bundle.main.bundleIdentifier ?? "—" }
    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "v\(v) (\(b))"
    }
    private var deviceInfo: String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        return UIDevice.current.model + " • iOS " + UIDevice.current.systemVersion
        #endif
    }
    private var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    // Developer-provided metadata (configure in target Info as user-defined keys)
    private var developerName: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperName") as? String ?? "Bandan Kumar Mahto"
    }
    private var developerEmail: String {
        Bundle.main.object(forInfoDictionaryKey: "DeveloperEmail") as? String ?? "bandan.kmahto@gmail.com"
    }
    private var developerWebsite: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "DeveloperWebsite") as? String, !raw.isEmpty {
            return raw
        }
        return "https://bandan-kumar.vercel.app"
    }
    private var developerGitHub: String {
        // Placeholder until set in Info or updated later
        if let raw = Bundle.main.object(forInfoDictionaryKey: "DeveloperGitHub") as? String, !raw.isEmpty {
            return raw
        }
        return "—" // set your GitHub URL once available
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer Details")
                            .font(.title3).bold()
                        Text("Build and environment information")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledRow(label: "App", value: appName)
                        LabeledRow(label: "Bundle ID", value: bundleId)
                        LabeledRow(label: "Version", value: version)
                        LabeledRow(label: "Device", value: deviceInfo)
                        LabeledRow(label: "Configuration", value: isDebug ? "Debug" : "Release")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Developer")
                            .font(.headline)
                        LabeledRow(label: "Name", value: developerName)
                        LabeledRow(label: "Email", value: developerEmail)
                        if developerWebsite != "—", let url = URL(string: developerWebsite) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Website")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Link(developerWebsite, destination: url)
                                    .font(.subheadline)
                                Spacer()
                            }
                        } else {
                            LabeledRow(label: "Website", value: developerWebsite)
                        }
                        if developerGitHub != "—", let gh = URL(string: developerGitHub) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("GitHub")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 110, alignment: .leading)
                                Link(developerGitHub, destination: gh)
                                    .font(.subheadline)
                                Spacer()
                            }
                        } else {
                            LabeledRow(label: "GitHub", value: developerGitHub)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips")
                            .font(.headline)
                        Text("• Ensure the scheme has a GPX selected or use Debug → Simulate Location.")
                        Text("• Keep the app alive; killing it stops the simulated feed.")
                        Text("• Some apps cache location; consider restarting the target app under test.")
                    }
                }
            }
            .padding()
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
    }
}

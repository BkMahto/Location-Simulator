//
//  DeveloperDetailsView.swift
//  Location Simulator
//
//  Created by Bandan.K on 07/11/25.
//

import SwiftUI

struct DeveloperDetailsView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
            as? String ?? "Location Simulator"
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
        return "—"  // set your GitHub URL once available
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
                        Divider()
                        HStack(alignment: .firstTextBaseline) {
                            Text("Credit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 110, alignment: .leading)
                            Text("Developed with AI assistance (Cursor & ChatGPT)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips")
                            .font(.headline)
                        Text("• Ensure the scheme has a GPX selected or use Debug → Simulate Location.")
                        Text("• Keep the app alive; killing it might stops the simulated feed.")
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

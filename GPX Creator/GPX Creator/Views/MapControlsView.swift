//
//  MapControlsView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MapControlsView: View {
    @ObservedObject var viewModel: GPXCreatorViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Path and Route controls
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.fitToRoute()
                }) {
                    HStack {
                        Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                        Text("Fit to Route")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.appState.route == nil)
                .help("Zoom map to show the entire calculated route")
                .accessibilityLabel("Fit to route")
                .accessibilityHint("Zoom and center the map to show the complete calculated route")

                Button(action: {
                    viewModel.pickPoint()
                }) {
                    HStack {
                        Image(systemName: "mappin")
                        Text("Pick Point")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .help("Switch to single point selection mode")
                .accessibilityLabel("Pick single point")
                .accessibilityHint("Switch to mode for selecting a single location point")
                .keyboardShortcut("p", modifiers: .command)

                Button(action: {
                    Task {
                        await viewModel.calculateRoute()
                    }
                }) {
                    HStack {
                        if viewModel.exportState.isCalculatingRoute {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "road.lanes")
                        }
                        Text("Calculate Route")
                    }
                }
                .disabled(!viewModel.canCalculateRoute())
                .buttonStyle(.borderedProminent)
                .tint((viewModel.appState.selectedStartLocation != nil &&
                      viewModel.appState.selectedEndLocation != nil) ? .orange : .gray)
                .help("Calculate driving route between start and end points")
                .accessibilityLabel("Calculate route")
                .accessibilityHint("Calculate driving directions between the selected start and end points")
                .keyboardShortcut("r", modifiers: .command)

                Button(action: {
                    viewModel.clearSelections()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                }
                .buttonStyle(.bordered)
                .help("Clear all selected points and routes")
                .accessibilityLabel("Clear selections")
                .accessibilityHint("Remove all selected locations and calculated routes")
                .keyboardShortcut("n", modifiers: .command)
            }

            // Export controls
            HStack(spacing: 12) {
                Button(action: {
                    exportWaypointGPX()
                }) {
                    HStack {
                        Image(systemName: "smallcircle.filled.circle")
                        Text("Export Point GPX")
                    }
                }
                .disabled(!viewModel.canExportWaypoint() || viewModel.exportState.isExporting)
                .buttonStyle(.borderedProminent)
                .tint((viewModel.appState.selectedStartLocation != nil ||
                      viewModel.appState.selectedEndLocation != nil) ? .green : .gray)
                .help("Export selected location as GPX waypoint file")
                .accessibilityLabel("Export waypoint GPX")
                .accessibilityHint("Save the selected location as a GPX waypoint file")
                .keyboardShortcut("w", modifiers: .command)

                Button(action: {
                    exportRouteGPX()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export GPX")
                    }
                }
                .disabled(!viewModel.canExportRoute() || viewModel.exportState.isExporting)
                .buttonStyle(.borderedProminent)
                .tint(viewModel.appState.route != nil ? .green : .gray)
                .help("Export calculated route as GPX file for simulation")
                .accessibilityLabel("Export route GPX")
                .accessibilityHint("Save the calculated route as a GPX file for location simulation")
                .keyboardShortcut("s", modifiers: .command)

                Button(action: {
                    viewModel.clearMap()
                }) {
                    HStack {
                        Image(systemName: "map")
                        Text("Clear Map")
                    }
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .help("Clear map and reset all selections")
                .accessibilityLabel("Clear map")
                .accessibilityHint("Remove all annotations and reset the map to default state")
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func exportRouteGPX() {
        guard let (content, filename) = viewModel.prepareRouteGPX() else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
        savePanel.nameFieldStringValue = "\(filename).gpx"
        savePanel.title = "Save GPX Route File"

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    print("GPX route file saved to: \(url.path)")
                } catch {
                    // Handle error through view model
                    viewModel.errorState.currentError = .fileSaveFailed(error.localizedDescription)
                    viewModel.errorState.showError = true
                }
            }
        }
    }

    private func exportWaypointGPX() {
        guard let (content, filename) = viewModel.prepareWaypointGPX() else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
        savePanel.nameFieldStringValue = "\(filename).gpx"
        savePanel.title = "Save GPX Waypoint File"

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    print("GPX waypoint file saved to: \(url.path)")
                } catch {
                    // Handle error through view model
                    viewModel.errorState.currentError = .fileSaveFailed(error.localizedDescription)
                    viewModel.errorState.showError = true
                }
            }
        }
    }
}

#Preview {
    MapControlsView(viewModel: GPXCreatorViewModel())
        .frame(width: 600)
}

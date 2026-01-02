//
//  AddressSearchView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI
import MapKit

struct AddressSearchView: View {
    @ObservedObject var viewModel: GPXCreatorViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.appState.isTwoFieldMode {
                twoFieldSearchView
            } else {
                singleFieldSearchView
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var twoFieldSearchView: some View {
        VStack(spacing: 8) {
            // Start Location
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start Location")
                        .font(.headline)
                    Spacer()
                }

                TextField("Enter start address", text: $viewModel.searchState.startAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("Start location search field")
                    .accessibilityHint("Enter an address or location name to search for the starting point")
                    .onChange(of: viewModel.searchState.startAddress) { oldValue, newValue in
                        if viewModel.searchState.suppressStartSearch {
                            viewModel.searchState.suppressStartSearch = false
                            viewModel.searchState.isSearchingStart = false
                        } else {
                            viewModel.searchForLocation(query: newValue, isStart: true)
                        }
                    }

                if viewModel.searchState.isSearchingStart && !viewModel.searchState.startSearchResults.isEmpty {
                    searchResultsView(results: viewModel.searchState.startSearchResults, isStart: true)
                }
            }

            // End Location
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("End Location")
                        .font(.headline)
                    Spacer()
                }

                TextField("Enter end address", text: $viewModel.searchState.endAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel("End location search field")
                    .accessibilityHint("Enter an address or location name to search for the ending point")
                    .onChange(of: viewModel.searchState.endAddress) { oldValue, newValue in
                        if viewModel.searchState.suppressEndSearch {
                            viewModel.searchState.suppressEndSearch = false
                            viewModel.searchState.isSearchingEnd = false
                        } else {
                            viewModel.searchForLocation(query: newValue, isStart: false)
                        }
                    }

                if viewModel.searchState.isSearchingEnd && !viewModel.searchState.endSearchResults.isEmpty {
                    searchResultsView(results: viewModel.searchState.endSearchResults, isStart: false)
                }
            }
        }
    }

    private var singleFieldSearchView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location")
                    .font(.headline)
                Spacer()
            }

            TextField("Enter address", text: $viewModel.searchState.singleAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Location search field")
                .accessibilityHint("Enter an address or location name to search for a single point")
                .onChange(of: viewModel.searchState.singleAddress) { oldValue, newValue in
                    if viewModel.searchState.suppressSingleSearch {
                        viewModel.searchState.suppressSingleSearch = false
                        viewModel.searchState.isSearchingSingle = false
                    } else {
                        viewModel.searchForSingleLocation(query: newValue)
                    }
                }

            if viewModel.searchState.isSearchingSingle && !viewModel.searchState.singleSearchResults.isEmpty {
                searchResultsView(results: viewModel.searchState.singleSearchResults, isStart: nil)
            }
        }
    }

    private func searchResultsView(results: [MKMapItem], isStart: Bool?) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(results, id: \.self) { item in
                                        Button(action: {
                                            if let isStart = isStart {
                                                viewModel.selectLocation(item, isStart: isStart)
                                            } else {
                                                viewModel.selectSingleLocation(item)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "Unknown")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .accessibilityLabel("Select location: \(item.name ?? "Unknown")")
                                        .accessibilityHint("Tap to select this location as \(isStart == true ? "start" : isStart == false ? "end" : "single") point")
                                    }
            }
        }
        .frame(maxHeight: 120)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    AddressSearchView(viewModel: GPXCreatorViewModel())
        .frame(width: 400, height: 300)
}

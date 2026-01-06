//
//  AddressSearchView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import MapKit
import SwiftUI

struct AddressSearchView: View {
    @ObservedObject var viewModel: GPXCreatorViewModel

    var body: some View {
        VStack {
            if viewModel.appState.isTwoFieldMode {
                // Two field mode: Start and End locations
                locationSearchField(
                    title: "Start Location",
                    placeholder: "Enter start address",
                    text: $viewModel.searchState.startAddress,
                    isSearching: viewModel.searchState.isSearchingStart,
                    searchResults: viewModel.searchState.startSearchResults,
                    accessibilityLabel: "Start location search field",
                    accessibilityHint: "Enter an address or location name to search for the starting point",
                    suppressSearch: viewModel.searchState.suppressStartSearch,
                    suppressBinding: $viewModel.searchState.suppressStartSearch,
                    isSearchingBinding: $viewModel.searchState.isSearchingStart,
                    isStart: true
                )

                locationSearchField(
                    title: "End Location",
                    placeholder: "Enter end address",
                    text: $viewModel.searchState.endAddress,
                    isSearching: viewModel.searchState.isSearchingEnd,
                    searchResults: viewModel.searchState.endSearchResults,
                    accessibilityLabel: "End location search field",
                    accessibilityHint: "Enter an address or location name to search for the ending point",
                    suppressSearch: viewModel.searchState.suppressEndSearch,
                    suppressBinding: $viewModel.searchState.suppressEndSearch,
                    isSearchingBinding: $viewModel.searchState.isSearchingEnd,
                    isStart: false
                )
            } else {
                // Single field mode: Single location
                locationSearchField(
                    title: "Location",
                    placeholder: "Enter address",
                    text: $viewModel.searchState.startAddress,
                    isSearching: viewModel.searchState.isSearchingStart,
                    searchResults: viewModel.searchState.startSearchResults,
                    accessibilityLabel: "Location search field",
                    accessibilityHint: "Enter an address or location name to search for a single point",
                    suppressSearch: viewModel.searchState.suppressStartSearch,
                    suppressBinding: $viewModel.searchState.suppressStartSearch,
                    isSearchingBinding: $viewModel.searchState.isSearchingStart,
                    isStart: nil
                )
            }
        }
    }

    /// A customizable search field component with integrated MKLocalSearch triggering.
    /// - Parameters:
    ///   - title: Label for the field.
    ///   - placeholder: Ghost text when empty.
    ///   - text: Binding to the address string.
    ///   - isSearching: Whether a search is currently active.
    ///   - searchResults: List of results to display.
    ///   - isStart: Optional boolean to differentiate start/end fields.
    private func locationSearchField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSearching: Bool,
        searchResults: [MKMapItem],
        accessibilityLabel: String,
        accessibilityHint: String,
        suppressSearch: Bool,
        suppressBinding: Binding<Bool>,
        isSearchingBinding: Binding<Bool>,
        isStart: Bool?
    ) -> some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)

                TextField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityHint(accessibilityHint)
                    .onChange(of: text.wrappedValue) { oldValue, newValue in
                        if suppressSearch {
                            suppressBinding.wrappedValue = false
                            isSearchingBinding.wrappedValue = false
                        } else {
                            if let isStart = isStart {
                                viewModel.searchForLocation(query: newValue, isStart: isStart)
                            } else {
                                viewModel.searchForSingleLocation(query: newValue)
                            }
                        }
                    }
            }

            if isSearching && !searchResults.isEmpty {
                searchResultsView(results: searchResults, isStart: isStart)
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
                            Divider()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Select location: \(item.name ?? "Unknown")")
                    .accessibilityHint("Tap to select this location as \(isStart == true ? "start" : isStart == false ? "end" : "single") point")
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 120)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
    }
}

#Preview {
    AddressSearchView(viewModel: GPXCreatorViewModel())
        .frame(width: 400, height: 300)
}

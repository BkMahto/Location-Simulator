//
//  ErrorAlertView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI

struct ErrorAlertView: View {
    @ObservedObject var viewModel: GPXCreatorViewModel

    var body: some View {
        ZStack {
            // Semi-transparent overlay when error is shown
            if viewModel.errorState.showError || viewModel.errorState.showWarning {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.errorState.showError || viewModel.errorState.showWarning)
                    .onTapGesture {
                        // Dismiss on tap
                        viewModel.errorState.showError = false
                        viewModel.errorState.showWarning = false
                    }
            }

            // Error Alert - toast style at top
            VStack {
                if viewModel.errorState.showError, let error = viewModel.errorState.currentError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Error")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(error.localizedDescription)
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.errorState.showError = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorState.showError)
                    .task {
                        // Auto-dismiss after 4 seconds
                        try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
                        await MainActor.run {
                            withAnimation(.easeOut(duration: 0.3)) {
                                viewModel.errorState.showError = false
                            }
                        }
                    }
                }

                // Warning Alert - positioned below error if both are shown
                if viewModel.errorState.showWarning {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Warning")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(viewModel.errorState.currentWarning)
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        Spacer()
                        Button(action: {
                            viewModel.errorState.showWarning = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.95))
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, viewModel.errorState.showError ? 8 : 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorState.showWarning)
                    .onAppear {
                        // Auto-dismiss after 3 seconds for warnings
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                viewModel.errorState.showWarning = false
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .zIndex(1000) // Very high z-index to appear above everything
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
        VStack {
            Text("Sample Content")
                .font(.largeTitle)
            Text("This content is behind the overlay")
                .foregroundColor(.secondary)
            Spacer()
        }
        ErrorAlertView(viewModel: {
            let vm = GPXCreatorViewModel()
            vm.errorState.showError = true
            vm.errorState.currentError = .routeCalculationFailed("Unable to calculate route")
            return vm
        }())
    }
}

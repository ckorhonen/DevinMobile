import SwiftUI

struct ConsumptionView: View {
    @State private var viewModel = ConsumptionViewModel()

    var body: some View {
        Group {
            switch viewModel.loadingState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let data):
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary card
                        VStack(spacing: 8) {
                            Text(String(format: "%.1f", data.totalAcus))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                            Text("Total ACUs (30 days)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)

                        // Chart
                        if !data.consumptionByDate.isEmpty {
                            ConsumptionChartView(data: data.consumptionByDate)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            case .error(let info):
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: info.systemImage)
                } description: {
                    Text(info.message)
                } actions: {
                    Button(info.actionLabel) {
                        Task { await viewModel.loadConsumption() }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Consumption")
        .task {
            await viewModel.loadConsumption()
        }
    }
}

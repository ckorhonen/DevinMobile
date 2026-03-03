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
                switch data {
                case .enterprise(let response):
                    enterpriseView(response)
                case .sessionBased(let summary):
                    sessionBasedView(summary)
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

    // MARK: - Enterprise view (daily chart)

    @ViewBuilder
    private func enterpriseView(_ data: ConsumptionResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", data.totalAcus))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("Total ACUs (30 days)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)

                if !data.consumptionByDate.isEmpty {
                    ConsumptionChartView(data: data.consumptionByDate)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    // MARK: - Session-based fallback view

    @ViewBuilder
    private func sessionBasedView(_ summary: SessionACUSummary) -> some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Showing estimated usage from your sessions. Detailed daily breakdown requires an enterprise API key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", summary.totalAcus))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("ACUs across \(summary.sessionCount) session\(summary.sessionCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            if !summary.sessions.isEmpty {
                Section("By Session") {
                    ForEach(summary.sessions) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body)
                                    .lineLimit(1)
                                if let date = item.createdAt {
                                    Text(date.asRelativeDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(String(format: "%.1f ACU", item.acus))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

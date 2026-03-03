import Foundation

enum ConsumptionData: Sendable {
    case enterprise(ConsumptionResponse)
    case sessionBased(SessionACUSummary)
}

@Observable
@MainActor
final class ConsumptionViewModel {
    var loadingState: LoadingState<ConsumptionData> = .idle

    func loadConsumption() async {
        loadingState = .loading

        // Attempt enterprise endpoint first
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let end = formatter.string(from: .now)
        let start = formatter.string(from: Calendar.current.date(byAdding: .day, value: -30, to: .now)!)

        do {
            let response: ConsumptionResponse = try await APIClient.shared.perform(
                .consumption(dateStart: start, dateEnd: end)
            )
            loadingState = .loaded(.enterprise(response))
        } catch {
            // Enterprise endpoint unavailable (400 for personal keys, or other API error)
            // Fall back to session-aggregated data
            await loadSessionBasedConsumption()
        }
    }

    private func loadSessionBasedConsumption() async {
        do {
            let response: SessionListResponse = try await APIClient.shared.perform(
                .listSessions(limit: 50, offset: 0, userEmail: nil)
            )

            let items = response.sessions.compactMap { session -> SessionACUItem? in
                guard let acus = session.acusConsumed, acus > 0 else { return nil }
                return SessionACUItem(
                    sessionId: session.sessionId,
                    title: session.title ?? "Untitled Session",
                    acus: acus,
                    createdAt: session.createdAt
                )
            }.sorted { $0.acus > $1.acus }

            let total = items.reduce(0.0) { $0 + $1.acus }

            let summary = SessionACUSummary(
                totalAcus: total,
                sessionCount: items.count,
                sessions: items
            )

            loadingState = .loaded(.sessionBased(summary))
        } catch {
            loadingState = .error(ErrorInfo(
                message: "Unable to load consumption data",
                systemImage: "chart.bar.xaxis",
                actionLabel: "Retry"
            ))
        }
    }
}

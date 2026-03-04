import Foundation

struct ConsumptionResponse: Decodable, Sendable {
    let totalAcus: Double
    let consumptionByDate: [DailyConsumption]
}

struct DailyConsumption: Decodable, Identifiable, Sendable {
    let date: String
    let acus: Double

    var id: String { date }
}

// MARK: - Session-aggregated fallback models

struct SessionACUSummary: Sendable {
    let totalAcus: Double
    let sessionCount: Int
    let sessions: [SessionACUItem]
}

struct SessionACUItem: Identifiable, Sendable {
    let sessionId: String
    let title: String
    let acus: Double
    let createdAt: String?

    var id: String { sessionId }
}

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

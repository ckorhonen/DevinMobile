import SwiftUI
import Charts

struct ConsumptionChartView: View {
    let data: [DailyConsumption]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Date", formattedDate(item.date)),
                y: .value("ACUs", item.acus)
            )
            .foregroundStyle(.tint)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        // Take just the day portion for compact display
        if dateString.count >= 10 {
            let start = dateString.index(dateString.startIndex, offsetBy: 5)
            let end = dateString.index(dateString.startIndex, offsetBy: 10)
            return String(dateString[start..<end])
        }
        return dateString
    }
}

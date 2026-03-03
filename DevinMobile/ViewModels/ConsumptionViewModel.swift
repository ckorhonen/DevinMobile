import Foundation

@Observable
@MainActor
final class ConsumptionViewModel {
    var consumption: ConsumptionResponse?
    var loadingState: LoadingState<ConsumptionResponse> = .idle

    func loadConsumption() async {
        loadingState = .loading

        // Last 30 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let end = formatter.string(from: .now)
        let start = formatter.string(from: Calendar.current.date(byAdding: .day, value: -30, to: .now)!)

        do {
            let response: ConsumptionResponse = try await APIClient.shared.perform(
                .consumption(dateStart: start, dateEnd: end)
            )
            consumption = response
            loadingState = .loaded(response)
        } catch let error as DevinAPIError {
            loadingState = .error(ErrorInfo(error))
        } catch {
            loadingState = .error(ErrorInfo(message: error.localizedDescription))
        }
    }
}

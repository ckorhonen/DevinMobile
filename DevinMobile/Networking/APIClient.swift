import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func perform<T: Decodable & Sendable>(_ endpoint: APIEndpoint, body: (any Encodable & Sendable)? = nil) async throws(DevinAPIError) -> T {
        guard let token = APIConfiguration.token else {
            throw .noAuthToken
        }

        let request = try RequestBuilder.build(endpoint: endpoint, body: body, token: token)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw .unauthorized
        case 429:
            throw .rateLimited
        case 404:
            throw .notFound
        default:
            throw .serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw .decodingError(error)
        }
    }

    func performVoid(_ endpoint: APIEndpoint, body: (any Encodable & Sendable)? = nil) async throws(DevinAPIError) {
        guard let token = APIConfiguration.token else {
            throw .noAuthToken
        }

        let request = try RequestBuilder.build(endpoint: endpoint, body: body, token: token)

        let response: URLResponse
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw .networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw .unauthorized
        case 429:
            throw .rateLimited
        case 404:
            throw .notFound
        default:
            throw .serverError(statusCode: httpResponse.statusCode)
        }
    }
}

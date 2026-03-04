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
        let data = try await execute(request)
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
        _ = try await execute(request)
    }

    func uploadFile(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws(DevinAPIError) -> String {
        guard let token = APIConfiguration.token else {
            throw .noAuthToken
        }
        let request = try RequestBuilder.buildMultipart(
            endpoint: endpoint,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            token: token
        )
        let data = try await execute(request)

        // API returns a URL string
        guard let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw .decodingError(URLError(.cannotParseResponse))
        }

        // Handle both bare string and JSON-wrapped responses
        if urlString.hasPrefix("\""), let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }

        return urlString
    }

    private func execute(_ request: URLRequest) async throws(DevinAPIError) -> Data {
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

        return data
    }
}

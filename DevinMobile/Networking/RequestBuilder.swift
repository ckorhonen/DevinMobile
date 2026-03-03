import Foundation

enum RequestBuilder {
    static func build(endpoint: APIEndpoint, body: (any Encodable & Sendable)? = nil, token: String) throws(DevinAPIError) -> URLRequest {
        var components = URLComponents(string: endpoint.baseURL + endpoint.path)
        let queryItems = endpoint.queryItems
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw .invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw .decodingError(error)
            }
        }

        return request
    }
}

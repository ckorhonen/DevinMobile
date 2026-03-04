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

    static func buildMultipart(
        endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        token: String
    ) throws(DevinAPIError) -> URLRequest {
        let components = URLComponents(string: endpoint.baseURL + endpoint.path)

        guard let url = components?.url else {
            throw .invalidURL
        }

        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body = Data()
        body.append("--\(boundary)\r\n")
        let safeName = fileName
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        return request
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

import Foundation

struct Secret: Codable, Identifiable, Sendable {
    let secretId: String
    let type: SecretType
    let key: String
    let note: String?
    let isSensitive: Bool?
    let accessType: String?
    let createdAt: String?

    var id: String { secretId }
}

enum SecretType: String, Codable, Sendable {
    case cookie
    case keyValue = "key-value"
    case totp
}

struct CreateSecretRequest: Encodable, Sendable {
    let type: SecretType
    let key: String
    let value: String
    let note: String?
    let isSensitive: Bool?
}

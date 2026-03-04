import Foundation

struct SelfResponse: Decodable, Sendable {
    let serviceUserId: String?
    let serviceUserName: String?
    let orgId: String?

    // v2 fallback fields
    let apiKeyId: String?
    let userId: String?
    let userEmail: String?
}

import Foundation

/// XOR obfuscation only: a client-bundled key can be recovered. Never log it.
enum EmbeddedCredential {
    private static let mask: [UInt8] = []
    private static let bytes: [UInt8] = []
    static var value: String {
        guard !mask.isEmpty else { return "" }
        return String(decoding: bytes.enumerated().map { $0.element ^ mask[$0.offset % mask.count] }, as: UTF8.self)
    }
}

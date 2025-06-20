import Foundation
import CryptoKit

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    var sha256: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

final class CacheService {
    static let shared = CacheService()
    private let cacheDir: URL
    private init() {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = dir.appendingPathComponent("openai_cache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func cachedResponse(forKey key: String) -> Data? {
        let url = cacheDir.appendingPathComponent(key)
        return try? Data(contentsOf: url)
    }

    func storeResponse(_ data: Data, forKey key: String) {
        let url = cacheDir.appendingPathComponent(key)
        try? data.write(to: url)
    }
}

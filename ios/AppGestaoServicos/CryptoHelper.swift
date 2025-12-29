import Foundation
import CryptoKit

enum CryptoHelper {
    private static let keyAccount = "encryptionKey"

    static func encrypt(_ data: Data) throws -> Data {
        let key = try loadKey()
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    static func decrypt(_ data: Data) throws -> Data {
        let key = try loadKey()
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }

    static func encryptString(_ value: String) -> String {
        guard !value.isEmpty else { return value }
        guard let data = value.data(using: .utf8) else { return value }
        do {
            let encrypted = try encrypt(data)
            return "enc:" + encrypted.base64EncodedString()
        } catch {
            return value
        }
    }

    static func decryptString(_ value: String) -> String {
        guard value.hasPrefix("enc:") else { return value }
        let payload = String(value.dropFirst(4))
        guard let data = Data(base64Encoded: payload) else { return value }
        do {
            let decrypted = try decrypt(data)
            return String(data: decrypted, encoding: .utf8) ?? value
        } catch {
            return value
        }
    }

    static func encryptData(_ data: Data?) -> Data? {
        guard let data else { return nil }
        do {
            return try encrypt(data)
        } catch {
            return data
        }
    }

    static func decryptData(_ data: Data?) -> Data? {
        guard let data else { return nil }
        do {
            return try decrypt(data)
        } catch {
            return data
        }
    }

    private static func loadKey() throws -> SymmetricKey {
        if let keyData = KeychainHelper.loadKey(account: keyAccount) {
            return SymmetricKey(data: keyData)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        KeychainHelper.saveKey(data, account: keyAccount)
        return key
    }

    enum CryptoError: Error {
        case encryptionFailed
    }
}

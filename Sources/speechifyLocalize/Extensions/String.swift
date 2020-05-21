//
//  String.swift
//  
//
//  Created by Oleh Hudeichuk on 18.05.2020.
//

import Foundation

extension String {

    func clean() -> String {
        var string = self
        string.cleanSelf()
        return string
    }

    mutating func cleanSelf() {
        var string = self.trimmingCharacters(in: .whitespacesAndNewlines)
//        string.replaceSelf("\\s+", " ")
        self = string
    }
}

#if canImport(CommonCrypto)
import CommonCrypto
#endif

extension String {

    func toSHA256() -> String? {
        guard let data = data(using: .utf8) else { return nil }
        var result: String?
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        result = Data(hash).compactMap { String(format: "%02x", $0) }.joined()

        return result
    }
}

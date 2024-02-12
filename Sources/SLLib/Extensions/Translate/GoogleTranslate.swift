//
//  GoogleTranslate.swift
//  
//
//  Created by Oleh Hudeichuk on 20.08.2020.
//

import Foundation
import SwiftExtensionsPack

final class GoogleTranslate {

    var api: String
    var key: String

    init(api: String, key: String) {
        self.api = api
        self.key = key
    }

    func getResponse(_ text: String, from: String = "en", to: String) throws -> String {
        let group: DispatchGroup = .init()
        group.enter()
        let queryParams: [String: Any] = [
            "key": key,
            "source": from,
            "target": to,
            "q": text
        ]
        var result: String = .init()
        try Net.sendRequest(url: api, method: "GET", params: queryParams) { (data, response, error) in
            guard let data = data else { group.leave(); return }
            result = String(data: data, encoding: .utf8) ?? ""
            group.leave()
        }
        group.wait()

        return result
    }

    func translate(_ text: String, from: String = "en", to: String) throws -> String {
        var result: String = .init()
        let rawResponse: String = try getResponse(text, from: from, to: to)
        if let data: Data = rawResponse.data(using: .utf8) {
            let response: ModelResponse = try JSONDecoder().decode(ModelResponse.self, from: data)
            response.data.translations.forEach { (translation) in
                var resultText = translation.translatedText
                resultText = resultText.removeApostrophes()
                result = resultText
            }
        }

        return result
    }
}

private extension String {
    func removeApostrophes() -> String {
        var newString = self
        let apostropheRegex = try! NSRegularExpression(pattern: "&#39;", options: .caseInsensitive)
        let range = NSRange(location: 0, length: newString.count)
        newString = apostropheRegex.stringByReplacingMatches(in: newString, options: [], range: range, withTemplate: "'")
        return newString
    }
}

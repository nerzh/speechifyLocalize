//
//  ModelResponse.swift
//  
//
//  Created by Oleh Hudeichuk on 20.08.2020.
//

import Foundation

struct ModelResponse: Codable {
    var data: TranslationData

    struct TranslationData: Codable {
        var translations: [Translation]

        struct Translation: Codable {
            var translatedText: String
        }
    }
}

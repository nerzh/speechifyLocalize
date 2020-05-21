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

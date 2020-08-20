//
//  SLError.swift
//  
//
//  Created by Oleh Hudeichuk on 20.08.2020.
//

import Foundation

struct SLError: Error, CustomStringConvertible {

    enum Types {
        case standard
    }

    var type:        Types
    var reason:      String?
    var description: String {
        var text = "[SLError] \(type)"
        if let reason = reason {
            text += ", reason: " + reason
        }
        return text
    }

    init (_ type: Types = .standard, reason: String? = nil) {
        self.type = type
        self.reason = reason
    }
}

//
//  Helpers.swift
//  
//
//  Created by Oleh Hudeichuk on 15.05.2020.
//

import Foundation

func realpath(_ path: String) throws -> String {
    let pointer: UnsafeMutablePointer<Int8>? = realpath(path, nil)
    guard
        let cStringPointer = pointer
        else { throw fatalError("unknown error for path: \(path)\nPlease, check your path.\n") }
    defer { free(cStringPointer) }
    return String(cString: cStringPointer)
}

func realpath(_ url: URL) throws -> String {
    try realpath(url.path)
}

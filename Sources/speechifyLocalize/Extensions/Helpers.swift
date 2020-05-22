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

func readFile(_ fileURL: URL, _ handler: (_ line: String) -> Void) {
    let file: FileReader = .init(fileURL: fileURL)
    do {
        try file.open()
        defer { file.close() }
        while let line = try? file.readLine() {
            handler(line)
        }
    } catch let error {
        fatalError(error.localizedDescription)
    }
}

func writeFile(to: String, _ text: String) {
    let fileDescriptor = open(to, O_TRUNC | O_WRONLY | O_CREAT, 0o755)

    if fileDescriptor < 0 {
        perror("could not open \(to)")
    } else {
        write(fileDescriptor, text, text.count)
        close(fileDescriptor)
    }
}

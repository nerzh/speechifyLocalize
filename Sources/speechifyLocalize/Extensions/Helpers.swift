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
        let cStringPointer: UnsafeMutablePointer<Int8> = pointer
        else { throw fatalError("unknown error for path: \(path)\nPlease, check your path.\n") }
    defer { free(cStringPointer) }
    return String(cString: cStringPointer)
}

func realpath(_ url: URL) throws -> String {
    try realpath(url.path)
}

func readDirectory(path: String, _ handler: (URL) -> Void) {
    FileManager.default.urls(for: path).forEach { handler($0) }
}

func readDirectory(path: URL, _ handler: (URL) -> Void) {
    readDirectory(path: path.path, handler)
}

func recursiveReadDirectory(path: String, _ handler: (_ folder: String, _ file: URL) -> Void) {
    readDirectory(path: path) { (url) in
        if FileManager.default.isDirectory(url) {
            recursiveReadDirectory(path: url.path, handler)
        } else {
            handler(path, url)
        }
    }
}

func recursiveReadDirectory(path: URL, _ handler: (_ folder: URL, _ file: URL) -> Void) {
    readDirectory(path: path) { (url) in
        if FileManager.default.isDirectory(url) {
            recursiveReadDirectory(path: url, handler)
        } else {
            handler(path, url)
        }
    }
}

func readFile(_ fileURL: URL, _ handler: (_ line: String) -> Void) {
    let file: FileReader = .init(fileURL: fileURL)
    do {
        try file.open()
        defer { file.close() }
        while let line: String = try? file.readLine() {
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
        guard let size: Int = text.data(using: .utf8)?.count else { return }
        write(fileDescriptor, text, size)
        close(fileDescriptor)
    }
}

func getCurrentLocalizations(path: String, localizedPrefix: String) -> [LocaleFolder] {
    var tempStore: [String: LocaleFolder] = .init()

    recursiveReadDirectory(path: path) { (folderPath, filePath) in
        var localeFolder: LocaleFolder = .init(path: folderPath)
        if tempStore[folderPath] != nil { localeFolder = tempStore[folderPath]! }
        var localeFile: LocaleFile = .init(path: filePath.path, localizedPrefix: localizedPrefix)
        readFile(filePath) { (str) in
            localeFile.parseLocalizableString(str)
        }
        localeFolder.addLocaleFile(localeFile)
        tempStore[localeFolder.path] = localeFolder
    }

    let result: [LocaleFolder] = tempStore.values.map { (localeFolder) -> LocaleFolder in
        localeFolder
    }

    return result
}


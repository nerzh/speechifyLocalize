//
//  Helpers.swift
//  
//
//  Created by Oleh Hudeichuk on 15.05.2020.
//

import Foundation
import SwiftRegularExpression


public func realpath(_ path: String) throws -> String {
    let pointer: UnsafeMutablePointer<Int8>? = realpath(path, nil)
    guard
        let cStringPointer: UnsafeMutablePointer<Int8> = pointer
        else { throw fatalError("unknown error for path: \(path)\nPlease, check your path.\n") }
    defer { free(cStringPointer) }

    return String(cString: cStringPointer)
}

public func realpath(_ url: URL) throws -> String {
    try realpath(url.path)
}

public func readDirectory(path: String, _ handler: (URL) -> Void) {
    FileManager.default.urls(for: urlEncode(path)).forEach { handler($0) }
}

public func readDirectory(path: URL, _ handler: (URL) -> Void) {
    readDirectory(path: path.path, handler)
}

public func recursiveReadDirectory(path: String, _ handler: (_ folder: String, _ file: URL) -> Void) {
    readDirectory(path: path) { (url) in
        if FileManager.default.isDirectory(url) {
            recursiveReadDirectory(path: url.path, handler)
        } else {
            handler(path, url)
        }
    }
}

public func recursiveReadDirectory(path: URL, _ handler: (_ folder: URL, _ file: URL) -> Void) {
    readDirectory(path: path) { (url) in
        if FileManager.default.isDirectory(url) {
            recursiveReadDirectory(path: url, handler)
        } else {
            handler(path, url)
        }
    }
}

public func readFile(_ fileURL: URL, _ handler: (_ line: String) -> Void) {
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

public func writeFile(to: String, _ text: String) {
    let fileDescriptor = open(to, O_TRUNC | O_WRONLY | O_CREAT, 0o755)

    if fileDescriptor < 0 {
        perror("could not open \(to)")
    } else {
        guard let size: Int = text.data(using: .utf8)?.count else { return }
        write(fileDescriptor, text, size)
        close(fileDescriptor)
    }
}

public func getCurrentLocalizations(path: String, localizedPrefix: String) -> [LocaleFolder] {
    var tempStore: [String: LocaleFolder] = .init()

    findStringsFiles(form: path) { (folderPath, fileURL) in
        var localeFolder: LocaleFolder = .init(path: folderPath)
        if tempStore[folderPath] != nil { localeFolder = tempStore[folderPath]! }
        var localeFile: LocaleFile = .init(path: fileURL.path, localizedPrefix: localizedPrefix)
        readFile(fileURL) { (str) in
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

public func findStringsFiles(form directory: String, _ handle: (String, URL) -> Void) {
    recursiveReadDirectory(path: directory) { (folderPath, fileURL) in
        if !fileURL.path[StringFilePattern] { return }
        handle(folderPath, fileURL)
    }
}

public func makeLocalizableString(_ key: String, _ value: String) -> String {
    "\"\(key)\" = \"\(value)\";"
}

public func urlEncode(_ string: String) -> String {
    var allowedCharacters = CharacterSet.alphanumerics
    allowedCharacters.insert(charactersIn: ".-_")

    return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
}

public func makeRelativePath(from projectPath: String, to filePath: String) -> String? {
    guard let realProjectPath: String = try? realpath(projectPath) else { return nil }
    return filePath.replace(realProjectPath, "")
}

public func isValidSwiftFileName(_ path: String) -> Bool {
    path[PathWithSwiftExtensionPattern]
}

public func isValidStringsFileName(_ path: String) -> Bool {
    path[StringFilePattern]
}

public func makeClearKeyFrom(path: String) -> String {
    var path: String = path
    path.replaceSelf(#"^/"#, "")
    path.replaceSelf(#"/"#, ".")
    guard
        let key = path.regexp(PathWithSwiftExtensionPattern)[1]
        else { fatalError("Can not get key from path: \(path). Maybe it is not swift file ?") }

    return key
}

public func makeClearKeyFrom(_ projectPath: String, _ filePath: String) -> String? {
    guard let relativeFilePath: String = makeRelativePath(from: projectPath, to: filePath) else { return nil }

    return makeClearKeyFrom(path: relativeFilePath)
}

public func makeNewKey(_ clearKey: String, _ localizedPrefix: String, _ number: Int) -> String {
    "\(clearKey).\(localizedPrefix)_\(number)"
}

public func getDataFromFileLocalizedString(_ string: String,
                                           _ localizedPrefix: String,
                                           _ methodPrefix: String,
                                           _ handler: (_ clearKey: String, _ number: Int) -> Void
) {
    
    let matches: [Int: String] = string.regexp(fileLocalizedStringPattern(localizedPrefix, methodPrefix))
    guard
        let clearKey: String = matches[1],
        let strNumber: String = matches[2],
        let number: Int = Int(strNumber)
        else { return }
    handler(clearKey, number)
}

public func getDataFromAnyLocalizedKey(_ string: String,
                                       _ localizedPrefix: String,
                                       _ handler: (_ clearKeys: [(clearKey: String, number: Int)]) -> Void
) {
    var clearKeys: [(clearKey: String, number: Int)] = .init()
    var string: String = string
    while true {
        let matches: [Int: String] = string.regexp(localizedKeyItemsPattern(localizedPrefix))
        guard
            let clearKey: String = matches[1],
            let strNumber: String = matches[2],
            let number: Int = Int(strNumber)
            else { break }

        clearKeys.append((clearKey: clearKey, number: number))
        string.replaceFirstSelf(localizedKeyItemsPattern(localizedPrefix), "")
    }

    handler(clearKeys)
}

public func cleanFile(path: String) {
    guard let fileURL: URL = URL(string: path) else { return }
    var newText: String = .init()
    var newLineCount: Int = .init()
    readFile(fileURL) { (line) in
        if line.clean().count == 0 {
            newLineCount += 1
            if newLineCount > 2 { return }
        } else {
            newLineCount = 0
        }
        newText.append(line)
    }

    writeFile(to: path, newText)
}

public func checkLocalizationKeysDiff(_ localizationPath: String) {
    var lastSet: Set<String> = .init()
    var currentSet: Set<String> = .init()
    recursiveReadDirectory(path: localizationPath) { (folderPath, fileURL) in
        if !isValidStringsFileName(fileURL.path) { return }
        readFile(fileURL) { (line) in
            let matches: [Int: String] = line.regexp(LocalizableStringPattern)
            if let key: String = matches[1] {
                currentSet.insert(key)
            }
        }
        if lastSet.count != 0 {
            var diff: Set<String> = .init()
            if currentSet.count > lastSet.count {
                diff = currentSet.subtracting(lastSet)
            } else {
                diff = lastSet.subtracting(currentSet)
            }
            if diff.count > 0 {
                fatalError("ERROR: localization files are difference: \(diff)")
            }
        }
        lastSet = currentSet
    }
}





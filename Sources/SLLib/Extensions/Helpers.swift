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

public func readFile(_ fileURL: URL) -> String {
    var content: String = .init()
    readFile(fileURL) { (line) in
        content.append(line)
    }
    return content
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

public func getCurrentStrings(path: String, localizedPrefix: String) -> LocaleStore {
    let localeStore: LocaleStore = .init()
    var tmpLangFolder: LangFolder = .init(path: "")

    iterateFileStringsLines(localizationPath: path) { (folderPath, filePath, localizedString, other) in
        guard let localizedString = localizedString else { return }
        if tmpLangFolder.path != folderPath {
            if tmpLangFolder.files.count > 0 {
                localeStore.langs.append(tmpLangFolder)
            }
            tmpLangFolder = LangFolder(path: folderPath)
        }
        if tmpLangFolder.files[filePath] == nil {
            tmpLangFolder.files[filePath] = StringsFile(path: filePath, keyPrefix: localizedPrefix)
        }
        tmpLangFolder.files[filePath]?.parseLocalizedString(localizedString: localizedString)
    }
    if tmpLangFolder.files.count > 0 {
        localeStore.langs.append(tmpLangFolder)
    }

    return localeStore
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

//public func checkLocalizationKeysDiff(_ localizationPath: String) {
//    var lastSet: Set<String> = .init()
//    var currentSet: Set<String> = .init()
//    recursiveReadDirectory(path: localizationPath) { (folderPath, fileURL) in
//        if !isValidStringsFileName(fileURL.path) { return }
//        readFile(fileURL) { (line) in
//            let matches: [Int: String] = line.regexp(LocalizableStringPattern)
//            if let key: String = matches[1] {
//                currentSet.insert(key)
//            }
//        }
//        if lastSet.count != 0 {
//            var diff: Set<String> = .init()
//            if currentSet.count > lastSet.count {
//                diff = currentSet.subtracting(lastSet)
//            } else {
//                diff = lastSet.subtracting(currentSet)
//            }
//            if diff.count > 0 {
//                fatalError("ERROR: localization files are difference: \(diff)")
//            }
//        }
//        lastSet = currentSet
//    }
//}


public func checkLocalizationKeysDiff(_ localizationPath: String, _ localizedPrefix: String) {

    var allKeys: Set<String> = .init()
    var eachLangKeys: [String: Set<String>] = .init()
    var diffLangKeys: [String: Set<String>] = .init()

    let localeStore: LocaleStore = getCurrentStrings(path: localizationPath, localizedPrefix: localizedPrefix)

    localeStore.langs.forEach { (langFolder) in
        langFolder.files.values.forEach { (stringsFile) in
            stringsFile.groups.forEach { (clearKey, swiftFileGroup) in
                swiftFileGroup.lines.forEach { (stringsLine) in
                    if eachLangKeys[stringsFile.path] == nil { eachLangKeys[stringsFile.path] = .init() }
                    allKeys.insert(stringsLine.fullKey)
                    eachLangKeys[stringsFile.path]!.insert(stringsLine.fullKey)
                }
            }
        }
    }

    eachLangKeys.forEach { (langPath, langKeys) in
        let diff: Set<String> = allKeys.subtracting(langKeys)
        if diff.count > 0 { diffLangKeys[langPath] = diff }
        if diffLangKeys.count > 0 {
            fatalError("ERROR: localization files are difference: \(diffLangKeys)")
        }
    }
}


func translate(_ text: String, from: String = "en", to: String, api: String, key: String) throws -> String {
    let googleTranslate: GoogleTranslate = .init(api: api, key: key)

    return try googleTranslate.translate(text, from: from, to: to)
}

func getAllLocalizeStringItems(_ localizedString: String?,
                               _ keyPrefix: String
) -> (key: String, clearKey: String, prefix: String, number: Int, value: String)? {
    guard let localizedString = localizedString else { return nil }
    let matches: [Int: String] = localizedString.regexp(localizedStringAllItemsPattern(keyPrefix))
    if  let clearKey: String = matches[1],
        let prefix: String = matches[2],
        let stringNumber: String = matches[3],
        let number: Int = Int(stringNumber),
        let value: String = matches[4]
    {
        let key: String = "\(clearKey).\(prefix)"
        return (key: key, clearKey: clearKey, prefix: prefix, number: number, value: value)
    } else {
        return nil
    }
}

func iterateFileStringsLines(localizationPath: String,
                             _ handler: (_ folderPath: String, _ filePath: String, _ localizedString: String?, _ other: String?) -> Void
) {
    recursiveReadDirectory(path: localizationPath) { (folderPath, fileURL) in
        if !isValidStringsFileName(fileURL.path) { return }
        readFile(fileURL) { (line) in
            if line[LocalizableStringPattern] {
                handler(folderPath, fileURL.path, line, nil)
            } else {
                handler(folderPath, fileURL.path, nil, line)
            }
        }
    }
}

func iterateSwiftFilesKeys(projectPath: String,
                           localizedPrefix: String,
                           stringPrefix: String,
                           methodPrefix: String,
                           _ handler: (_ filePath: String, _ clearKey: String, _ translated: String?, _ target: String?, _ raw: String) -> Void
) {
    recursiveReadDirectory(path: projectPath) { (folderPath, fileURL) in
        if !isValidSwiftFileName(fileURL.path) { return }
        guard let clearKey: String = makeClearKeyFrom(projectPath, fileURL.path) else {
            fatalError("ERROR: make ClearKey for \(fileURL.path)")
        }
        readFile(fileURL) { (line) in
            if line[stringForLocalizePattern(stringPrefix)] {
                handler(fileURL.path, clearKey, nil, line, line)
            } else if line[fileLocalizedStringPattern(localizedPrefix, methodPrefix)] {
                handler(fileURL.path, clearKey, line, nil, line)
            } else {
                handler(fileURL.path, clearKey, nil, nil, line)
            }
        }
    }
}

func escapeRegexpSymbols(_ value: inout String) {
    value.replaceSelf(#"\\"#, "\\\\")
    value.replaceSelf(#"\^"#, "\\\\^")
    value.replaceSelf(#"\$"#, "\\\\$")
    value.replaceSelf(#"\*"#, "\\\\*")
    value.replaceSelf(#"\+"#, "\\\\+")
    value.replaceSelf(#"\."#, "\\\\.")
    value.replaceSelf(#"\|"#, "\\\\|")
    value.replaceSelf(#"\{"#, "\\\\{")
    value.replaceSelf(#"\}"#, "\\\\}")
    value.replaceSelf(#"\["#, "\\\\[")
    value.replaceSelf(#"\]"#, "\\\\]")
    value.replaceSelf(#"\("#, "\\\\(")
    value.replaceSelf(#"\)"#, "\\\\)")
    value.replaceSelf(#"\:"#, "\\\\:")
    value.replaceSelf(#"\?"#, "\\\\?")
}

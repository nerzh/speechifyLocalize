//
//  ParserCore.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation
import ArgumentParser

final class ParserCore {

    let parser: Parser
    private let fileManager: FileManager = .default
    private var localizableStrings: [String: String] = .init()

    init(parser: Parser) {
        self.parser = parser
    }

    func run() throws {

        let currentStrings: [LocaleFolder] = getCurrentLocalizations(path: parser.localizationPath,
                                                                     localizedPrefix: parser.localizedPrefix)

        let newStrings: [FileGroup] = try findNewLocalizeStrings(parser.projectPath,
                                                                 parser.stringPrefix,
                                                                 parser.localizationPath,
                                                                 parser.localizedPrefix)
        writeLocaleFiles(mergeLocalizedStrings(currentStrings, newStrings))
        replaceInsideSwiftFiles(parser.projectPath, parser.localizationPath, parser.localizedPrefix, parser.stringPrefix)
    }

    private func replaceInsideSwiftFiles(_ projectPath: String,
                                         _ localizationPath: String,
                                         _ localizedPrefix: String,
                                         _ stringPrefix: String
    ) {
        recursiveReadDirectory(path: projectPath) { (folderPath, fileURL) in
            if folderPath != localizationPath {
                var resultText: String = .init()

                readFile(fileURL) { (str) in
                    guard
                        let realProjectPath: String = try? realpath(projectPath)
                        else { return }
                    var filePath: String = fileURL.path
                    deleteProjectPath(rooPath: realProjectPath, &filePath)
                    let pattern: String = "^([\\s\\S]*)\"\\S*\(stringPrefix)([\\s\\S]+)\\S*?\"([\\s\\S]*)$"
                    let matches: [Int: String] = str.regexp(pattern)
                    if matches[0] != nil {
                        if  let beforeValue = matches[1],
                            let value = matches[2],
                            let afterValue = matches[3]
                        {
                            if let localizedKey: String = findLocalizedString(projectPath, localizedPrefix, filePath, value) {
                                let newLine = str.replace("^[\\s\\S]+$", "\(beforeValue)\"\(localizedKey)\".localize\(afterValue)")
                                resultText.append(newLine)
                            }
                            return
                        }
                    }
                    resultText.append(str)
                }
                writeFile(to: fileURL.path, resultText)
            }
        }
    }

    private func findLocalizedString(_ path: String,
                                     _ localizedPrefix: String,
                                     _ filePath: String,
                                     _ value: String
    ) -> String? {
        var result: String?
        let currentStrings: [LocaleFolder] = getCurrentLocalizations(path: parser.localizationPath,
                                                                     localizedPrefix: parser.localizedPrefix)
        let key: String = makeKeyFrom(path: filePath)
        if let anyLocaleFile: LocaleFile = currentStrings.first?.files.first {
            anyLocaleFile.groups.forEach { (group) in
                if result != nil { return }
                if (group.name ?? "") == key {
                    group.lines.forEach { (textLine) in
                        if result != nil { return }
                        let matches: [Int: String] = textLine.text.regexp(#"^\"([\s\S]+)\"\s+=\s+\"([\s\S]+)\"\.*;\.*$"#)
                        if  let localizedKey: String = matches[1],
                            let localizedValue: String = matches[2]
                        {
                            if localizedValue == value {
                                result = localizedKey
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    private func writeLocaleFiles(_ folders: [LocaleFolder]) {
        folders.forEach { (localeFolder) in
            localeFolder.files.forEach { (localeFile) in
                var resultString: String = .init()
                if !fileManager.fileExists(atPath: localeFile.path) {
                    fileManager.createFile(atPath: localeFile.path, contents: nil, attributes: nil)
                }
                localeFile.groups.forEach { (group) in
                    resultString.append(group.text)
                    resultString.append("\n")
                }

                writeFile(to: localeFile.path, resultString)
            }
        }
    }

    private func mergeLocalizedStrings(_ current: [LocaleFolder], _ new: [FileGroup]) -> [LocaleFolder] {
        var result: [LocaleFolder] = .init()

        for var localeFolder in current {
            for var localeFile in localeFolder.files {
                for lineGroup in new {
                    localeFile.addGroup(lineGroup)
                }
                localeFolder.addLocaleFile(localeFile)
            }
            result.append(localeFolder)
        }

        return result
    }

    private func getCurrentLocalizations(path: String, localizedPrefix: String) -> [LocaleFolder] {
        var tempStore: [String: LocaleFolder] = .init()

        recursiveReadDirectory(path: path) { (folderPath, filePath) in
            var localeFolder: LocaleFolder = .init(path: folderPath)
            if tempStore[folderPath] != nil { localeFolder = tempStore[folderPath]! }
            var localeFile: LocaleFile = .init(path: filePath.path, localizedPrefix: localizedPrefix)
            readFile(filePath) { (str) in
                localeFile.parseRawLocalizableString(str)
            }
            localeFolder.addLocaleFile(localeFile)
            tempStore[localeFolder.path] = localeFolder
        }

        let result: [LocaleFolder] = tempStore.values.map { (localeFolder) -> LocaleFolder in
            localeFolder
        }

        return result
    }

    private func findNewLocalizeStrings(_ path: String,
                                        _ stringPrefix: String,
                                        _ localizationPath: String,
                                        _ localizedPrefix: String
    ) throws -> [FileGroup] {
        var tempStore: [String: FileGroup] = .init()

        recursiveReadDirectory(path: path) { (folderPath, fileURL) in
            if folderPath != localizationPath {
                readFile(fileURL) { (str) in
                    let line: String = str.trimmingCharacters(in: CharacterSet.init(arrayLiteral: "\n"))
                    guard let realProjectPath: String = try? realpath(path) else { return }
                    var filePath: String = fileURL.path
                    deleteProjectPath(rooPath: realProjectPath, &filePath)
                    if line["\(stringPrefix)"] {
                        let key: String = makeKeyFrom(path: filePath)
                        guard
                            var value: String = line.regexp("\"\\S*(\(stringPrefix)[\\s\\S]+)\\S*?\"")[1]
                            else { return }
                        value.replaceFirstSelf("\(stringPrefix)", "")
                        if tempStore[key] == nil {
                            tempStore[key] = .init(name: key, localizedPrefix: localizedPrefix)
                        }
                        tempStore[key]!.addTextLine(value: value)
                    }
                }
            }
        }

        let result: [FileGroup] = tempStore.values.map { (fileGroup) -> FileGroup in
            fileGroup
        }

        return result
    }

    private func makeKeyFrom(path: String) -> String {
        var key: String = path
        key.replaceSelf(#"^/"#, "")
        key.replaceSelf(#"/"#, ".")
        let matches: [Int: String] = key.regexp(#"^([\s\S]+)\.([\s\S]+)$"#)
        if matches[1] != nil && matches[2] != nil {
            key = matches[1]!
        }

        return key
    }

    private func deleteProjectPath(rooPath: String, _ filePath: inout String) {
        filePath.replaceSelf(rooPath, "")
    }

    private func readDirectory(path: String, _ handler: (URL) -> Void) {
        fileManager.urls(for: path).forEach { handler($0) }
    }

    private func readDirectory(path: URL, _ handler: (URL) -> Void) {
        readDirectory(path: path.path, handler)
    }

    private func recursiveReadDirectory(path: String, _ handler: (_ folder: String, _ file: URL) -> Void) {
        readDirectory(path: path) { (url) in
            if fileManager.isDirectory(url) {
                recursiveReadDirectory(path: url.path, handler)
            } else {
                handler(path, url)
            }
        }
    }

    private func recursiveReadDirectory(path: URL, _ handler: (_ folder: URL, _ file: URL) -> Void) {
        readDirectory(path: path) { (url) in
            if fileManager.isDirectory(url) {
                recursiveReadDirectory(path: url, handler)
            } else {
                handler(path, url)
            }
        }
    }
}

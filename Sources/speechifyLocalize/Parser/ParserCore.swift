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

        var currentStrings: [LocaleFolder] = getCurrentLocalizations(path: parser.localizationPath,
                                                                      localizedPrefix: parser.localizedPrefix)

        let newStrings: [FileGroup] = try findNewLocalizeStrings(parser.projectPath,
                                                                 parser.stringPrefix,
                                                                 parser.localizationPath,
                                                                 parser.localizedPrefix)
        writeLocaleFiles(mergeLocalizedStrings(currentStrings, newStrings))
        currentStrings = getCurrentLocalizations(path: parser.localizationPath, localizedPrefix: parser.localizedPrefix)
        replaceInsideSwiftFiles(currentStrings, parser.projectPath, parser.localizationPath, parser.stringPrefix)
    }

    private func replaceInsideSwiftFiles(_ folders: [LocaleFolder],
                                         _ projectPath: String,
                                         _ localizationPath: String,
                                         _ stringPrefix: String
    ) {
        if let anyLocaleFile: LocaleFile = folders.first?.files.first {
            recursiveReadDirectory(path: projectPath) { (folderPath, fileURL) in
                if folderPath != localizationPath {
                    var resultText: String = .init()

                    readFile(fileURL) { (str) in
                        let line: String = str.clean()
                        guard
                            let realProjectPath: String = try? realpath(projectPath)
                            else { return }
                        var filePath: String = fileURL.path
                        deleteProjectPath(rooPath: realProjectPath, &filePath)
                        let pattern: String = "^([\\s\\S]*)\"\\S*\(stringPrefix)([\\s\\S]+)\\S*?\"([\\s\\S]*)$"
                        if line[pattern] {
                            if  let beforeValue = str.regexp(pattern)[1],
                                let value = str.regexp(pattern)[2],
                                let afterValue = str.regexp(pattern)[3]
                            {
                                var newLine = str.replace("^[\\s\\S]+$", "\(beforeValue)\"\(value)\".localize\(afterValue)")
                                resultText.append(newLine)
                                return
                            }
                            resultText.append(str)
                        }
                        resultText.append(str)
                    }

                    let fileHandl: FileHandle = try! FileHandle(forWritingTo: URL(fileURLWithPath: fileURL.path))
                    fileHandl.write(resultText.data(using: .utf8)!)
                    fileHandl.closeFile()
                }
            }
        }
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

                let fileHandl: FileHandle = try! FileHandle(forWritingTo: URL(fileURLWithPath: localeFile.path))
                fileHandl.write(resultString.data(using: .utf8)!)
                fileHandl.closeFile()
            }
        }
    }

    private func mergeLocalizedStrings(_ current: [LocaleFolder], _ new: [FileGroup]) -> [LocaleFolder] {
        var result: [LocaleFolder] = .init()

        for var localeFolder in current {
            for var (index, localeFile) in localeFolder.files.enumerated() {
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

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
        let currentStrings: Set<LocaleFolder> = getCurrentLocalizations(path: parser.localizationPath,
                                                                        localizedPrefix: parser.localizedPrefix)
        let newStrings: [String: LocalizedFile] = try findNewLocalizeStrings(parser.projectPath,
                                                                             parser.stringPrefix,
                                                                             parser.localizedPrefix)
        write(mergeLocalizedStrings(currentStrings, newStrings))
    }

    private func write(_ folders: [LocaleFolder]) {
        folders.forEach { (localeFolder) in
            localeFolder.items.forEach { (localeFile) in
                var resultString: String = .init()
//                if !fileManager.fileExists(atPath: localeFile.path) {
//                    fileManager.createFile(atPath: localeFile.path, contents: nil, attributes: nil)
//                }
//                print(localeFile.path)

                localeFile.lines.forEach { (localeFileLine) in
                    resultString.append(localeFileLine.text)
                }
                print("file 1\n\n", localeFile)
//                print("RESULT:\n\n", resultString)
//                localeFile.localizedFiles.sorted { $0.key > $1.key }.forEach { (pair) in
//
//                    print(pair.value.text)

//                    pair.value.localizedStrings.sorted { $0.key > $1.key }.forEach { (pair) in
//                        print(pair.value.text)
//                    }
//                }

//                let fileHandl: FileHandle = try! FileHandle(forWritingTo: URL(fileURLWithPath: localeFile.path))
//                fileHandl.write(resultString.data(using: .utf8)!)
//                fileHandl.closeFile()
            }
        }
    }

    private func mergeLocalizedStrings(_ current: Set<LocaleFolder>, _ new: [String: LocalizedFile]) -> [LocaleFolder] {
        var result: [LocaleFolder] = .init()

        for var localeFolder in current {
            for (index, localeFile) in localeFolder.items.enumerated() {
                for clearKey in new.keys {
                    var localizedFile: LocalizedFile = localeFile.getLocalizedFile(by: clearKey)
                    localizedFile.merge(localizedFile: new[clearKey]!)
                    localeFolder.items[index].localizedFiles[clearKey] = localizedFile
                }
            }
            result.append(localeFolder)
        }

        return result
    }

    private func getCurrentLocalizations(path: String, localizedPrefix: String) -> Set<LocaleFolder> {
        var result: Set<LocaleFolder> = .init()

        recursiveReadDirectory(path: path) { (folderPath, filePath) in
            var localeFolder: LocaleFolder = .init(path: folderPath)
            if let existLocaleFolder = result.first(where: { $0 == localeFolder }) {
                localeFolder = existLocaleFolder
            }
            let file: FileReader = .init(fileURL: filePath)
            do {
                try file.open()
                defer { file.close() }
                var localeFile: LocaleFile = .init(path: filePath.path, localizedPrefix: localizedPrefix)
                while let str = try? file.readLine() {
                    localeFile.parseRawLocalizableString(str)
                }
                localeFolder.items.append(localeFile)
            } catch let error {
                fatalError(error.localizedDescription)
            }
            result.insert(localeFolder)
        }

        return result
    }

    private func findNewLocalizeStrings(_ path: String,
                                        _ stringPrefix: String,
                                        _ localizedPrefix: String
    ) throws -> [String: LocalizedFile] {
        var localizedFiles: [String: LocalizedFile] = .init()

        recursiveReadDirectory(path: path) { (_, url) in
            let file: FileReader = .init(fileURL: url)
            do {
                try file.open()
                defer { file.close() }
                while let str = try? file.readLine() {
                    let line: String = str.trimmingCharacters(in: CharacterSet.init(arrayLiteral: "\n"))
                    let realProjectPath: String = try realpath(path)
                    var filePath: String = url.path
                    deleteProjectPath(rooPath: realProjectPath, &filePath)
                    if line["\(stringPrefix)"] {
                        let key: String = makeKeyFrom(path: filePath)
                        guard
                            var value: String = line.regexp("\"\\S*(\(stringPrefix)[\\s\\S]+)\\S*?\"")[1]
                            else { continue }
                        value.replaceSelf("\(stringPrefix)", "")
                        if localizedFiles[key] == nil { localizedFiles[key] = LocalizedFile(name: key) }
                        localizedFiles[key]!.setLocalizedString(value: value, localizedPrefix: localizedPrefix)
                    }
                }
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }

        return localizedFiles
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

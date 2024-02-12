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
    private let fileManager: FileManager
    private var localizableStrings: [String: String] = .init()

    init(parser: Parser, fileManager: FileManager = .default) {
        self.parser = parser
        self.fileManager = fileManager
    }

    func run() throws {
        /// the strings files keys comparison
        checkLocalizationKeysDiff(parser.localizationPath, parser.localizedPrefix)

        /// Current localized strings
        let localeStore: LocaleStore = getCurrentStrings(path: parser.localizationPath, localizedPrefix: parser.localizedPrefix)

        /// Add new localized strings to localized current strings
        iterateSwiftFilesKeys(projectPath: parser.projectPath,
                              localizedPrefix: parser.localizedPrefix,
                              stringPrefix: parser.stringPrefix,
                              methodPrefix: parser.methodPrefix
        ) { (filePath, clearKey, translated, target, raw) in
            if let target = target {
                localeStore.addNewString(clearKey: clearKey,
                                         target: target,
                                         stringPrefix: parser.stringPrefix,
                                         defaultLang: parser.lang,
                                         gApi: parser.googleApi,
                                         gKey: parser.googlekey)
            }
        }

        /// Rewrite the strings files with new localized strings
        writeLocaleFiles(localeStore)

        /// Rewrite the swift files with new localized keys
        replaceValuesInsideSwiftFiles(parser.projectPath,
                                      parser.localizationPath,
                                      parser.localizedPrefix,
                                      parser.stringPrefix,
                                      parser.methodPrefix,
                                      localeStore)
    }
}

// MARK: PRIVATE METHODS
extension ParserCore {

    private func replaceValuesInsideSwiftFiles(_ projectPath: String,
                                               _ localizationPath: String,
                                               _ localizedPrefix: String,
                                               _ stringPrefix: String,
                                               _ methodPrefix: String,
                                               _ localeStore: LocaleStore
    ) {
        localeStore.langs.forEach { (langFolder) in
            let folderLang: String = langFolder.getLocaleName()
            if folderLang == parser.lang {
                var newSwiftFileContent: String = .init()
                var tmpFilePathTrigger: String = .init()
                var backUpFileContent: String = .init()
                iterateSwiftFilesKeys(projectPath: projectPath,
                                      localizedPrefix: localizedPrefix,
                                      stringPrefix: stringPrefix,
                                      methodPrefix: methodPrefix
                ) { (filePath, clearKey, translated, target, raw) in
                    if newSwiftFileContent.count > 0 && tmpFilePathTrigger != filePath {
                        if tmpFilePathTrigger.count > 0 {
                            writeFile(to: tmpFilePathTrigger, newSwiftFileContent)
                            cleanFile(path: tmpFilePathTrigger)
                        }
                        newSwiftFileContent = .init()
                        tmpFilePathTrigger = filePath
                        guard let fileUrl: URL = URL(string: urlEncode(tmpFilePathTrigger)) else {
                            fatalError("CAN NOT GET URL FROM STRING \(tmpFilePathTrigger)")
                        }
                        backUpFileContent = readFile(fileUrl)
                    }
                    if  let target = target,
                        let clearKey: String = makeClearKeyFrom(projectPath, filePath)
                    {
                        var tmpTarget: String = target
                        var matches: [Int: String] = tmpTarget.regexp(stringForLocalizePattern(stringPrefix))
                        var warningCounter: Int = 0
                        while var value: String = matches[2] {
                            warningCounter += 1
                            if warningCounter > 15 {
                                writeFile(to: tmpFilePathTrigger, backUpFileContent)
                                fatalError("WARNING: INFINITY CYCLE. PLEASE CHECK REGEXP.")
                            }
                            langFolder.files.forEach { (filePath, stringsFile) in
                                if  let swiftFileGroup: SwiftFileGroup = stringsFile.groups[clearKey],
                                    let stringLine: StringsLine = swiftFileGroup.getLine(value)
                                {
                                    escapeRegexpSymbols(&value)
                                    tmpTarget.replaceFirstSelf(replaceStringLocalizePattern(stringPrefix, value), "\"\(stringLine.fullKey)\".\(methodPrefix)")
                                } else {
                                    writeFile(to: tmpFilePathTrigger, backUpFileContent)
                                    fatalError("VALUE \(value) NOT FOUND. PLEASE CHECK REGEXP FOR PARSE NEW STRINGS")
                                }
                            }
                            matches = tmpTarget.regexp(stringForLocalizePattern(stringPrefix))
                        }
                        newSwiftFileContent.append(tmpTarget)
                    } else {
                        newSwiftFileContent.append(raw)
                    }
                }
                if newSwiftFileContent.count > 0 && tmpFilePathTrigger.count > 0 {
                    writeFile(to: tmpFilePathTrigger, newSwiftFileContent)
                    cleanFile(path: tmpFilePathTrigger)
                }
            }
        }
    }

    private func writeLocaleFiles(_ localeStore: LocaleStore) {
        localeStore.langs.forEach { (langFolder) in
            langFolder.files.forEach { (filePath, stringsFile) in
                var resultString: String = .init()
                if !fileManager.fileExists(atPath: filePath) {
                    fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
                }
                stringsFile.sortedGroups.forEach { (tuple) in
                    tuple.value.lines.forEach { (line) in
                        resultString.append("\(line.makeLocalizable())\n")
                    }
                }
                writeFile(to: filePath, resultString)
                cleanFile(path: filePath)
            }
        }
    }
}

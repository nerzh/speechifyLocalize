//
//  CSVImporter.swift
//  
//
//  Created by Oleh Hudeichuk on 25.05.2020.
//

import Foundation

class CSVImporter {

    let localizationPath: String
    let tableFilePath: String
    let localizedPrefix: String
    let separator: String

    private let keyName: String = "[key]"
    private let localeFolderExt: String = "lproj"
    private let localeFileName: String = "Localizable.strings"

    init(_ localizationPath: String, _ tableFilePath: String, _ localizedPrefix: String, _ separator: String) {
        self.localizationPath = localizationPath
        self.tableFilePath = tableFilePath
        self.localizedPrefix = localizedPrefix
        self.separator = separator
    }

    func run() throws {
        let csvFile: CSVFile = CSVFile(separator: separator, filePath: tableFilePath)
        importFromCSV(csvFile)
    }

    private func importFromCSV(_ file: CSVFile) {
        let localeFiles: [LocaleFile] = parseCSVFile(file)

        localeFiles.forEach { (lf) in
            lf.groups.forEach { (g) in
                print(g.text)
            }
        }
    }

    private func parseCSVFile(_ file: CSVFile) -> [LocaleFile] {
        var localeFiles: [LocaleFile] = .init()
        file.columns().forEach { (columnName) in
            if columnName == keyName { return }
            let folderPath: String = makeLocaleDir(columnName, localizationPath)
            var localeFile: LocaleFile = .init(path: makeLocaleFilePath(folderPath), localizedPrefix: localizedPrefix)
            if !isPresentLocale(folderPath) {
                createNewLocale(folderPath)
            }
            var isFirstLine: Bool = true
            file.rows.forEach { (row) in
                if isFirstLine { isFirstLine = false; return }
                let key: String = row[keyName]
                let value: String = row[columnName]

                if  let groupName: String = key.regexp(fileNameFromLocalizedKeyPattern(localizedPrefix))[1],
                    let strNumber: String = key.regexp(numberLocalizedStringPattern(localizedPrefix))[1],
                    let textLineNumber: Int = Int(strNumber)
                {
                    var lineGroup: LineGroup = .init(name: groupName, localizedPrefix: localizedPrefix)
                    if var existGroup = localeFile.getGroup(by: lineGroup.id) {
                        existGroup.addTextLine(number: textLineNumber, value: value)
                        localeFile.overrideGroup(existGroup)
                    } else {
                        lineGroup.addTextLine(number: textLineNumber, value: value)
                        localeFile.addGroup(lineGroup)
                    }
                } else {
                    var lineGroup: LineGroup = .init(name: groupName)
                    if var existGroup = localeFile.getGroup(by: lineGroup.id) {
                        existGroup.addTextLine(number: textLineNumber, value: value)
                        localeFile.overrideGroup(existGroup)
                    } else {
                        lineGroup.addTextLine(number: textLineNumber, value: value)
                        localeFile.addGroup(lineGroup)
                    }
                }
            }
            localeFiles.append(localeFile)
        }

        return localeFiles
    }

    private func isPresentLocale(_ folderPath: String) -> Bool {
        FileManager.default.fileExists(atPath: folderPath)
    }

    private func createNewLocale(_ folderPath: String) {
        do {
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            let filePath: String = "\(folderPath)/\(localeFileName)"
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        } catch {
            print(error.localizedDescription)
        }
    }

    private func makeLocaleDir(_ lang: String, _ localizationPath: String) -> String {
        "\(localizationPath)/\(lang).\(localeFolderExt)".replace("//", "/")
    }

    private func makeLocaleFilePath(_ localeDir: String) -> String {
        "\(localeDir)/\(localeFileName)".replace("//", "/")
    }
}








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

    private var newLocales: Set<String> = .init()
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
        addNewLocales(from: file)
        updateStrings(from: file)
        updateNewLocalizationsStrings(from: file)
    }

    private func updateStrings(from file: CSVFile) {
        let stringsFromCSV: [String: LocaleContainer] = parseCSVFile(file)

        findStringsFiles(form: localizationPath) { (folderPath, fileURL) in
            guard let localeName: String = folderPath.regexp(LprojNamePattern)[1] else { return }
            var newText: String = .init()
            readFile(fileURL) { (str) in
                let matches: [Int: String] = str.regexp(LocalizableStringPattern)
                if let key: String = matches[1] {
                    if let localeContainer = stringsFromCSV[localeName], localeContainer.isExistKey(key) {
                        newText.append(makeLocalizableString(key, localeContainer[key]))
                        newText.append("\n")
                        return
                    }
                }
                newText.append(str)
            }

            writeFile(to: fileURL.path, newText)
        }
    }

    private func updateNewLocalizationsStrings(from file: CSVFile) {
        let stringsFromCSV: [String: LocaleContainer] = parseCSVFile(file)

        findStringsFiles(form: localizationPath) { (folderPath, fileURL) in
            guard
                let localeName: String = folderPath.regexp(LprojNamePattern)[1],
                newLocales.contains(localeName)
                else { return }
            var newText: String = .init()
            stringsFromCSV[localeName]?.forEach({ (pair) in
                newText.append(makeLocalizableString(pair.key, pair.value))
                newText.append("\n")
            })

            writeFile(to: fileURL.path, newText)
        }
    }

    private func parseCSVFile(_ file: CSVFile) -> [String: LocaleContainer] {
        var localeStrings: [String: LocaleContainer] = .init()
        file.columns().forEach { (columnName) in
            if columnName == keyName { return }
            var isFirstLine: Bool = true
            file.rows.forEach { (row) in
                if isFirstLine { isFirstLine = false; return }
                let key: String = row[keyName]
                let value: String = row[columnName]
                if localeStrings[columnName] == nil { localeStrings[columnName] = .init() }
                localeStrings[columnName]!.addPair(key, value)
            }
        }

        return localeStrings
    }

    private func isPresentLocale(_ folderPath: String) -> Bool {
        FileManager.default.fileExists(atPath: folderPath)
    }

    private func addNewLocales(from file: CSVFile) {
        checkNewLocales(from: file)
        createNewLocales(from: newLocales)
    }

    private func checkNewLocales(from file: CSVFile) {
        file.columns().forEach { (columnName) in
            if columnName == keyName { return }
            let folderPath: String = makeLocaleDir(columnName, localizationPath)
            if !isPresentLocale(folderPath) {
                newLocales.insert(columnName)
            }
        }
    }

    private func createNewLocales(from newLocales: Set<String>) {
        newLocales.forEach { (columnName) in
            let folderPath: String = makeLocaleDir(columnName, localizationPath)
            if !isPresentLocale(folderPath) {
                createNewLocale(folderPath)
            }
        }
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

struct LocaleContainer: Sequence {

    private var index: [String: Int] = .init()
    private var localizedStrings: [(key: String, value: String)] = .init()

    subscript(key: String) -> String {
        get {
            localizedStrings[index[key]!].value
        }
        set {
            index[key] = localizedStrings.count
            localizedStrings.append((key, newValue))
        }
    }

    func isExistKey(_ key: String) -> Bool {
        index[key] != nil
    }

    mutating func addPair(_ key: String, _ value: String) {
        index[key] = localizedStrings.count
        localizedStrings.append((key, value))
    }

    func makeIterator() -> Array<(key: String, value: String)>.Iterator {
        localizedStrings.makeIterator()
    }
}

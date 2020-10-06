//
//  CSVExporter.swift
//  
//
//  Created by Oleh Hudeichuk on 25.05.2020.
//

import Foundation
import SwiftRegularExpression

final class CSVExporter {

    let localizationPath: String
    let tableFilePath: String
    let localizedPrefix: String
    let separator: String

    private let keyName: String = "[key]"

    init(_ localizationPath: String, _ tableFilePath: String, _ localizedPrefix: String, _ separator: String) {
        self.localizationPath = localizationPath
        self.tableFilePath = tableFilePath
        self.localizedPrefix = localizedPrefix
        self.separator = separator
    }

    func run() throws {
        convert(localizationPath, tableFilePath)
    }
}


// MARK: PRIVATE METHODS
extension CSVExporter {

    private func convert(_ localizationPath: String, _ tableFilePath: String) {
        let localeStore: LocaleStore = getCurrentStrings(path: localizationPath, localizedPrefix: localizedPrefix)
        var csvFile: CSVFile = .init(separator: separator)
        csvFile.addColumnName(keyName)
        
        localeStore.langs.forEach { (langFolder) in
            let langName: String = langFolder.getLocaleName()
            csvFile.addColumnName(langName)
            langFolder.files.values.forEach { (stringsFile) in
                stringsFile.groups.forEach { (clearKey, swiftFileGroup) in
                    swiftFileGroup.lines.forEach { (stringsLine) in
                        csvFile[stringsLine.fullKey][langName] = stringsLine.value
                    }
                }
            }
        }

        csvFile.write(to: tableFilePath)
    }
}

//
//  CSVExporter.swift
//  
//
//  Created by Oleh Hudeichuk on 25.05.2020.
//

import Foundation
import SwiftRegularExpression

class CSVExporter {

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

    private func convert(_ localizationPath: String, _ tableFilePath: String) {
        let currentLocales: [LocaleFolder] = getCurrentLocalizations(path: localizationPath, localizedPrefix: localizedPrefix)
        var csvFile: CSVFile = .init(separator: separator)
        csvFile.addColumnName(keyName)

        currentLocales.forEach { (localeFolder) in
            guard let langName: String = getLocaleName(localeFolder.path) else { return }
            csvFile.addColumnName(langName)
            localeFolder.files.forEach { (localeFile) in
                localeFile.groups.forEach { (group) in
                    group.lines.forEach { (textLine) in
                        switch textLine.type {
                        case .localizedString:
                            csvFile[textLine.getKey()][langName] = textLine.getValue()
                        default:
                            break
                        }
                    }
                }
            }
        }

        csvFile.write(to: tableFilePath)
    }

    private func getLocaleName(_ path: String) -> String? {
        path.regexp(LprojNamePattern)[1]
    }
}

//
//  ConverterCore.swift
//  
//
//  Created by Oleh Hudeichuk on 25.05.2020.
//

import Foundation

final class ConverterCore {

    private var converter: Converter

    init(converter: Converter) {
        self.converter = converter
    }

    func run() throws {
        /// the strings files keys comparison
        checkLocalizationKeysDiff(converter.localizationPath)

        switch converter.type {
        case .exportCSV:
            try CSVExporter(converter.localizationPath,
                            converter.tableFilePath,
                            converter.localizedPrefix,
                            converter.separator
            ).run()
        case .importCSV:
            try CSVImporter(converter.localizationPath,
                            converter.tableFilePath,
                            converter.localizedPrefix,
                            converter.separator
            ).run()
        }
    }
}

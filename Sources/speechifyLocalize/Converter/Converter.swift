//
//  Converter.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation
import ArgumentParser

struct Converter: ParsableCommand {

    @Option(help: "Path to localizations")
    var localizationPath: String

    @Option(help: "Path to file")
    var tableFilePath: String

    @Option(default: "String", help: "Prefix of localized strings")
    var localizedPrefix: String

    @Option(default: ",", help: "Path to localizations")
    var separator: String

    @Flag(help: "Converting type")
    var type: ConvertingType

    func run() throws {
        try ConverterCore(converter: self).run()
    }
}

enum ConvertingType: String, CaseIterable {
    case exportCSV
    case importCSV
}

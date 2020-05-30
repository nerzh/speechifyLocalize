//
//  Parser.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation
import ArgumentParser

struct Parser: ParsableCommand {

    @Option(default: FileManager.default.currentDirectoryPath, help: "Project path.")
    var projectPath: String

    @Option(help: "Path to localizations")
    var localizationPath: String

    @Option(default: "localize", help: "Prefix for raw strings")
    var stringPrefix: String

    @Option(default: "String", help: "Prefix for localized strings")
    var localizedPrefix: String

    @Option(default: "localized", help: "Method for localizable strings")
    var methodPrefix: String

    func run() throws {
        try ParserCore(parser: self).run()
    }
}

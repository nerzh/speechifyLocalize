//
//  Parser.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation
import ArgumentParser

public struct Parser: ParsableCommand {

    @Option(default: FileManager.default.currentDirectoryPath, help: "Project path.")
    var projectPath: String

    @Option(help: "Path to localizations")
    var localizationPath: String

    @Option(default: "localize", help: "Prefix for raw strings")
    var stringPrefix: String

    @Option(name: .customLong("gKey"), help: "Google Key")
    var googlekey: String

    @Option(name: .customLong("gApi"), default: "https://translation.googleapis.com/language/translate/v2", help: "Google API URL")
    var googleApi: String

    @Option(default: "en", help: "Default project language")
    var lang: String

    @Option(default: "String", help: "Prefix for localized strings")
    var localizedPrefix: String

    @Option(default: "localized", help: "Method for localizable strings")
    var methodPrefix: String

    public init() {}

    public func run() throws {
        try ParserCore(parser: self).run()
    }
}

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

    @Option(help: "Path to localizations.")
    var localizationPath: String

    @Option(default: "localize.", help: "Prefix for localize strings")
    var localizePrefix: String

    func run() throws {
        try ParserCore(parser: self).run()
    }
}

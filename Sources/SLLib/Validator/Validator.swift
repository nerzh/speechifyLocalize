//
//  Validator.swift
//  
//
//  Created by Oleh Hudeichuk on 30.05.2020.
//

import Foundation
import ArgumentParser

public struct Validator: ParsableCommand {

    @Option(default: FileManager.default.currentDirectoryPath, help: "Project path.")
    var projectPath: String

    @Option(help: "Path to localizations")
    var localizationPath: String

    @Option(default: "String", help: "Prefix for localized strings")
    var localizedPrefix: String

    @Option(default: "localized", help: "Method name for localizable strings")
    var methodPrefix: String

    @Option(default: "localize", help: "Prefix for raw strings")
    var stringPrefix: String

    @Flag(help: "Validation type")
    var type: ValidationType

    public init() {}

    public func run() throws {
        try ValidatorCore(validator: self).run()
    }
}

public enum ValidationType: String, CaseIterable {
    case sync
    case deleteUnusedKeys
    case fileName
}



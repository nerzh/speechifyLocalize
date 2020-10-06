//
//  Merge.swift
//  
//
//  Created by Oleh Hudeichuk on 06.10.2020.
//

import Foundation
import ArgumentParser

public struct Merge: ParsableCommand {

    @Option(help: "Translated file path.")
    var translatedFilePath: String

    @Option(help: "Project file path.")
    var projectFilePath: String

    public init() {}

    public func run() throws {
        try MergeCore(merge: self).run()
    }
}

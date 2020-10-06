//
//  Utility.swift
//  
//
//  Created by Oleh Hudeichuk on 06.10.2020.
//

import Foundation
import ArgumentParser

public struct Utility: ParsableCommand {

    public init() {}

    public static var configuration = CommandConfiguration(
        abstract: "Utilities",
        version: "1.0.0",
        subcommands: [Merge.self],
        defaultSubcommand: nil
    )
}

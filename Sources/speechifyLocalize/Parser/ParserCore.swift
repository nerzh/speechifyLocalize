//
//  ParserCore.swift
//  
//
//  Created by Oleh Hudeichuk on 12.05.2020.
//

import Foundation
import ArgumentParser
//import Path
import PathKit
//import var libc.errno
//import func libc.free
//import func libc.realpath

final class ParserCore {

    let parser: Parser
    private let fileManager: FileManager = .default
    private var localizableStrings: [String: String] = .init()

    init(parser: Parser) {
        self.parser = parser
    }

    func run() throws {
        let newStrings: [String: [String]] = try findNewLocalizeStrings(parser.projectPath, parser.localizePrefix)
        print(newStrings)
    }

    private func findNewLocalizeStrings(_ path: String,
                                        _ localizePrefix: String
    ) throws -> [String: [String]] {
        var result: [String: [String]] = .init()

        recursiveReadDirectory(path: path) { (url) in
            let file: FileReader = .init(fileURL: url)
            do {
                try file.open()
                defer { file.close() }
                while let str = try? file.readLine() {
                    let line: String = str.trimmingCharacters(in: CharacterSet.init(arrayLiteral: "\n"))
                    let realProjectPath: String = try realpath(path)
                    var filePath: String = url.path
                    deleteProjectPath(rooPath: realProjectPath, &filePath)
                    filePath.replaceSelf(#"^/"#, "")
                    if line["\(parser.localizePrefix)"] {
                        let key: String = filePath.replace(#"/"#, ".")
                        guard
                            var value: String = line.regexp("\"\\S*(\(localizePrefix)[\\s\\S]+)\\S*?\"")[1]
                            else { continue }
                        value.replaceSelf("\(localizePrefix)", "")
                        if result[key] == nil { result[key] = [] }
                        result[key]!.append(value)
                    }
                }
            } catch let error {
                fatalError(error.localizedDescription)
            }
        }

        return result
    }

    private func deleteProjectPath(rooPath: String, _ filePath: inout String) {
        filePath.replaceSelf(rooPath, "")
    }

    private func readDirectory(path: String, _ handler: (URL) -> Void) {
        fileManager.urls(for: path).forEach { handler($0) }
    }

    private func recursiveReadDirectory(path: String, _ handler: (URL) -> Void) {
        readDirectory(path: path) { (url) in
            if fileManager.isDirectory(url) {
                recursiveReadDirectory(path: url.path, handler)
            } else {
                handler(url)
            }
        }
    }
}

//
//  MergeCore.swift
//  
//
//  Created by Oleh Hudeichuk on 06.10.2020.
//

import Foundation

final class MergeCore {

    let merge: Merge

    init(merge: Merge) {
        self.merge = merge
    }

    func run() throws {
        var tarnslatedPairs: [String: String] = .init()
        iterateStringsFile(merge.translatedFilePath) { (localizedLine, other) in
            if let localizedLine = localizedLine {
                let matches: [Int: String] = localizedLine.regexp(LocalizableStringPattern)
                if let key = matches[1], let value = matches[2] {
                    tarnslatedPairs[key] = value
                }
            }
        }

        var newFileText: String = .init()
        iterateStringsFile(merge.projectFilePath) { (localizedLine, other) in
            if let localizedLine = localizedLine {
                let matches: [Int: String] = localizedLine.regexp(LocalizableStringPattern)
                if let key = matches[1], let newValue = tarnslatedPairs[key] {
                    newFileText.append("\"\(key)\" = \"\(newValue)\";\n")
                } else {
                    newFileText.append(localizedLine)
                }
            } else if let other = other {
                newFileText.append(other)
            }
        }

        writeFile(to: merge.projectFilePath, newFileText)
    }
}

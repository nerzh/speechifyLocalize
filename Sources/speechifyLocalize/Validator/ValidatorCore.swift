//
//  ValidatorCore.swift
//  
//
//  Created by Oleh Hudeichuk on 30.05.2020.
//

import Foundation

final class ValidatorCore {

    let validator: Validator

    init(validator: Validator) {
        self.validator = validator
    }

    func run() throws {
        let changedFileKeys: [(from: String, to: String)] = getChangedFilePaths(validator.projectPath,
                                                                                validator.localizedPrefix,
                                                                                validator.methodPrefix)
        updateKeys(diff: changedFileKeys, validator.projectPath, validator.localizedPrefix)
        updateKeys(diff: changedFileKeys, validator.localizationPath, validator.localizedPrefix)
    }
}


// MARK: PRIVATE METHODS
extension ValidatorCore {

    private func getChangedFilePaths(_ projectPath: String,
                                     _ localizedPrefix: String,
                                     _ methodPrefix: String
    ) -> [(from: String, to: String)] {
        var result: [(from: String, to: String)] = .init()
        recursiveReadDirectory(path: projectPath) { (folderPath, fileURL) in
            if !isValidSwiftFileName(fileURL.path) { return }
            guard let currentClearKey: String = makeKeyFrom(projectPath, fileURL.path) else { return }

            readFile(fileURL) { (line) in
                getDataFromFileLocalizedString(line, localizedPrefix, methodPrefix) { (clearKey, number) in
                    if clearKey != currentClearKey {
                        result.append((from: clearKey, to: currentClearKey))
                    }
                }
            }
        }

        return result
    }

    private func updateKeys(diff: [(from: String, to: String)], _ path: String, _ localizedPrefix: String) {
        var tempIndex: [String: (from: String, to: String)] = .init()
        diff.forEach { tempIndex[$0.from] = $0 }
        recursiveReadDirectory(path: path) { (folderPath, fileURL) in
            var newText: String = .init()
            readFile(fileURL) { (line) in
                var line: String = line
                getDataFromAnyLocalizedKey(line, localizedPrefix) { (clearKey, number) in
                    if tempIndex[clearKey] != nil {
                        let from: String = makeNewKey(clearKey, localizedPrefix, number)
                        let to: String = makeNewKey(tempIndex[clearKey]!.to, localizedPrefix, number)
                        line.replaceSelf(from, to)
                    }
                }
                newText.append(line)
            }

            writeFile(to: fileURL.path, newText)
        }
    }

    private func makeNewKey(_ clearKey: String, _ localizedPrefix: String, _ number: Int) -> String {
        "\(clearKey).\(localizedPrefix)_\(number)"
    }
}

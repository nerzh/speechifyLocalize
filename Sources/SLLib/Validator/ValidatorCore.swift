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
        /// the strings files keys comparison
        checkLocalizationKeysDiff(validator.localizationPath)
        
        replaceKeysOfChangedFiles(validator.projectPath,
                                  validator.localizationPath,
                                  validator.localizedPrefix,
                                  validator.methodPrefix)

        deleteUnusedLocalizationStrings(validator.projectPath,
                                        validator.localizationPath,
                                        validator.localizedPrefix)
    }
}


// MARK: DELETE UNUSED LOCALIZATION STRINGS
extension ValidatorCore {

    private func deleteUnusedLocalizationStrings(_ projectPath: String,
                                                 _ localizationPath: String,
                                                 _ localizedPrefix: String
    ) {
        let currentKeys: Set<String> = getCurrentKeys(from: localizationPath, localizedPrefix: localizedPrefix)
        let unusedKeys: [String] = getUnusedKeys(from: projectPath,
                                                 with: Array(currentKeys),
                                                 localizedPrefix: localizedPrefix)
        deleteLocalizationStrings(from: localizationPath, with: unusedKeys, localizedPrefix: localizedPrefix)
    }

    /// Get current keys from Localization Path
    private func getCurrentKeys(from path: String, localizedPrefix: String) -> Set<String> {
        var result: Set<String> = .init()
        findStringsFiles(form: path) { (folderPath, fileURL) in
            if !isValidStringsFileName(fileURL.path) { return }
            readFile(fileURL) { (line) in
                getDataFromAnyLocalizedKey(line, localizedPrefix) { clearKeys in
                    clearKeys.forEach { key in
                        result.insert(makeNewKey(key.clearKey, localizedPrefix, key.number))
                    }
                }
            }
        }

        return result
    }

    /// Compare current localization keys with keys inside swift files and get array of unused keys
    private func getUnusedKeys(from path: String, with: [String], localizedPrefix: String) -> [String] {
        var keysIndex: [String: Int] = .init()
        with.forEach { keysIndex[$0] = 0 }
        recursiveReadDirectory(path: path) { (folderPath, fileURL) in
            if !isValidSwiftFileName(fileURL.path) { return }
            readFile(fileURL) { (line) in
                getDataFromAnyLocalizedKey(line, localizedPrefix) { clearKeys in
                    clearKeys.forEach { clearKey in
                        let key: String = makeNewKey(clearKey.clearKey, localizedPrefix, clearKey.number)
                        if keysIndex[key] != nil {
                            keysIndex[key]! += 1
                        }
                    }
                }
            }
        }

        return Array(keysIndex.filter { $1 == 0 }.keys)
    }

    /// Find unused keys inside .strings files and delete them
    private func deleteLocalizationStrings(from path: String, with: [String], localizedPrefix: String) {
        let unusedKeysSet: Set<String> = .init(with)
        findStringsFiles(form: path) { (folderPath, fileURL) in
            if !isValidStringsFileName(fileURL.path) { return }
            var newText: String = .init()
            readFile(fileURL) { (line) in
                var line: String = line
                getDataFromAnyLocalizedKey(line, localizedPrefix) { clearKeys in
                    clearKeys.forEach { clearKey in
                        let key: String = makeNewKey(clearKey.clearKey, localizedPrefix, clearKey.number)
                        if unusedKeysSet.contains(key) { line = "" }
                    }
                }
                if line.count != 0 { newText.append(line) }
            }

            writeFile(to: fileURL.path, newText)
        }
    }
}


// MARK: REPLACE KEYS IF CHANGED FILE PATH
extension ValidatorCore {

    private func replaceKeysOfChangedFiles(_ projectPath: String,
                                           _ localizationPath: String,
                                           _ localizedPrefix: String,
                                           _ methodPrefix: String
    ) {
        let changedFileKeys: [(from: String, to: String)] = getChangedFilePaths(projectPath,
                                                                                localizedPrefix,
                                                                                methodPrefix)
        updateKeys(diff: changedFileKeys, projectPath, localizedPrefix)
        updateKeys(diff: changedFileKeys, localizationPath, localizedPrefix)
    }

    private func getChangedFilePaths(_ projectPath: String,
                                     _ localizedPrefix: String,
                                     _ methodPrefix: String
    ) -> [(from: String, to: String)] {
        var result: [(from: String, to: String)] = .init()
        recursiveReadDirectory(path: projectPath) { (folderPath, fileURL) in
            if !isValidSwiftFileName(fileURL.path) { return }
            guard let currentClearKey: String = makeClearKeyFrom(projectPath, fileURL.path) else { return }
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
            if !(isValidStringsFileName(fileURL.path) || isValidSwiftFileName(fileURL.path)) { return }
            var newText: String = .init()
            readFile(fileURL) { (line) in
                var line: String = line
                getDataFromAnyLocalizedKey(line, localizedPrefix) { clearKeys in
                    clearKeys.forEach { clearKey in
                        if tempIndex[clearKey.clearKey] != nil {
                            let from: String = makeNewKey(clearKey.clearKey, localizedPrefix, clearKey.number)
                            let to: String = makeNewKey(tempIndex[clearKey.clearKey]!.to, localizedPrefix, clearKey.number)
                            line.replaceSelf(from, to)
                        }
                    }
                }
                newText.append(line)
            }

            writeFile(to: fileURL.path, newText)
        }
    }
}

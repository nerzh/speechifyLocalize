//
//  LocaleFolder.swift
//
//  Created by Oleh Hudeichuk on 21.05.2020.
//

import Foundation

public typealias FilePath = String

public class LocaleStore {

    var langs: [LangFolder] = .init()

    func addNewString(clearKey: String,
                      target: String,
                      stringPrefix: String,
                      defaultLang: String,
                      gApi: String,
                      gKey: String
    ) {
        var tmpTarget: String = target
        var matches: [Int: String] = tmpTarget.regexp(stringForLocalizePattern(stringPrefix))
        var warningCounter: Int = 0
        while var value: String = matches[2] {
            warningCounter += 1
            if warningCounter > 15 { fatalError("WARNING: INFINITY CYCLE. PLEASE CHECK REGEXP.") }
            langs.forEach { (lang) in
                lang.addNewString(clearKey: clearKey, value: value, defaultLang: defaultLang, gApi: gApi, gKey: gKey)
            }
            escapeRegexpSymbols(&value)
            tmpTarget.replaceFirstSelf(replaceStringLocalizePattern(stringPrefix, value), "")
            matches = tmpTarget.regexp(stringForLocalizePattern(stringPrefix))
        }
    }
}

public class LangFolder {

    var path: String
    var files: [FilePath: StringsFile] = .init()

    init(path: String) {
        self.path = path
    }

    func addNewString(clearKey: String,
                      value: String,
                      defaultLang: String,
                      gApi: String,
                      gKey: String
    ) {
        files.forEach { (filePath, stringFile) in
            var newValue: String = value
            let lang = getLocaleName()
            if lang != defaultLang {
                newValue = tryTranslate(value: value, from: defaultLang, to: lang, gApi: gApi, gKey: gKey)
            }
            files[filePath]?.addNewString(clearKey: clearKey, value: newValue)
        }
    }

    func getLocaleName() -> String {
        guard let folderLang: String = path.regexp(LprojNamePattern)[1] else {
            fatalError("Can not parse lang name")
        }
        return folderLang
    }

    private func tryTranslate(value: String, from: String, to: String, gApi: String, gKey: String) -> String {
        if let newValue: String = try? translate(value, from: from, to: to, api: gApi, key: gKey) {
            return newValue
        }
        return value
    }
}

public struct StringsFile {

    typealias ClearKey = String
    var path: String
    var keyPrefix: String
    var groups: [ClearKey: SwiftFileGroup] = .init()
    var sortedGroups: [(key: ClearKey, value: SwiftFileGroup)] {
        groups.sorted(by: { $0.key < $1.key })
    }

    init(path: String, keyPrefix: String) {
        self.path = path
        self.keyPrefix = keyPrefix
    }

    mutating func parseLocalizedString(localizedString: String) {
        if let items = getAllLocalizeStringItems(localizedString, keyPrefix) {
            if groups[items.clearKey] == nil {
                groups[items.clearKey] = SwiftFileGroup(clearKey: items.clearKey, keyPrefix: keyPrefix)
            }
            let line: StringsLine = .init(keyPrefix: keyPrefix,
                                          clearKey: items.clearKey,
                                          fullKey: items.key,
                                          number: items.number,
                                          value: items.value)
            groups[items.clearKey]!.addLine(line)
        }
    }

    mutating func addNewString(clearKey: String, value: String) {
        if groups[clearKey] != nil {
            groups[clearKey]!.addNewString(clearKey: clearKey, value: value)
        } else {
            groups[clearKey] = SwiftFileGroup(clearKey: clearKey, keyPrefix: keyPrefix)
            groups[clearKey]!.addNewString(clearKey: clearKey, value: value)
        }
    }
}

public struct SwiftFileGroup {

    var clearKey: String
    var keyPrefix: String
    var count: Int {
        get { _count }
        set { if _count < newValue { _count = newValue } }
    }
    var lines: [StringsLine] { _lines }

    private var _lines: [StringsLine]
    private var valuesKeys: [String: StringsLine]
    private var _count: Int

    init(clearKey: String, keyPrefix: String) {
        self.clearKey = clearKey
        self.keyPrefix = keyPrefix
        self._count = .init()
        self._lines = .init()
        self.valuesKeys = .init()
    }

    mutating func addNewString(clearKey: String, value: String) {
        if isExistValue(value) { return }
        _count += 1
        let newLine: StringsLine = .init(keyPrefix: keyPrefix,
                                         clearKey: clearKey,
                                         fullKey: makeNewKey(clearKey, keyPrefix, count),
                                         number: count,
                                         value: value)
        _lines.append(newLine)
        valuesKeys[newLine.value] = newLine
    }

    public func getLine(_ value: String) -> StringsLine? {
        valuesKeys[value]
    }

    mutating public func addLine(_ line: StringsLine) {
        self.count = line.number
        _lines.append(line)
        valuesKeys[line.value] = line
    }

    private func isExistValue(_ value: String) -> Bool {
        valuesKeys[value] != nil
    }
}

public struct StringsLine {
    var keyPrefix: String
    var clearKey: String
    var fullKey: String
    var number: Int
    var value: String

    public func makeLocalizable() -> String {
        makeLocalizableString(fullKey, value)
    }
}


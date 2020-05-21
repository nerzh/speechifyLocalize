//
//  LocaleNode.swift
//  
//
//  Created by Oleh Hudeichuk on 15.05.2020.
//

import Foundation

struct LocaleFolder: Hashable {

    var path: String
    var items: [LocaleFile] = .init()

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.path == rhs.path
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}

protocol LocaleFileLine {
    var text: String { get }
}

struct LocaleFile: Equatable {

    var path: String
    var localizedPrefix: String
    var lines: [LocaleFileLine] = .init()
    var localizedFiles: [String: LocalizedFile] = .init()

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.path == rhs.path
    }

    mutating func setLocalizedFile(to name: String, value: LocalizedFile) {
        localizedFiles[name] = value
        lines.append(value)
    }

    mutating func setNewLine(_ line: String) {
        let line = line.clean()
        lines.append(LocaleFileTextLine(text: "\(line)\n"))
    }

    func getLocalizedFile(by name: String) -> LocalizedFile {
        if let localizedFile = localizedFiles[name] {
            return localizedFile
        } else {
            return LocalizedFile(name: name)
        }
    }

    mutating func parseRawLocalizableString(_ string: String) {
        if isLocalizedString(string, localizedPrefix) {
            guard let number: Int = Int(getNumberFromLocalizedString(string, localizedPrefix)) else { return }
            let clearKey: String = getFileNameFromLocalizedString(string, localizedPrefix)
            let value: String = getValueFromLocalizedString(string)
            var localizedFile: LocalizedFile = getLocalizedFile(by: clearKey)
            localizedFile.setLocalizedString(to: number, localizedPrefix: localizedPrefix, value: value)
            setLocalizedFile(to: clearKey, value: localizedFile)
        } else {
            setNewLine(string)
        }
    }

    private func getFileNameFromLocalizedString(_ string: String, _ localizedPrefix: String) -> String {
        let string: String = string.clean()
        guard
            let fileName = string.regexp("^.*\"([\\s\\S]+)\\.\(localizedPrefix)_\\d+.*?\"\\s+=\\s+.+")[1]
            else { fatalError("can not parse file name from string: \(string)") }
        return fileName
    }

    private func getNumberFromLocalizedString(_ string: String, _ localizedPrefix: String) -> String {
        let string: String = string.clean()
        guard
            let number = string.regexp("\(localizedPrefix)_(\\d+)")[1]
            else { fatalError("can not parse number from string: \(string) with prefix: \(localizedPrefix)") }
        return number
    }

    private func getValueFromLocalizedString(_ string: String) -> String {
        let string: String = string.clean()
        guard
            let number = string.regexp(#"^[\s\S]+\s=\s\"([\s\S]+)\".*;$"#)[1]
            else { fatalError("can not parse value from string: \(string)") }
        return number
    }

    private func isLocalizedString(_ string: String, _ localizedPrefix: String) -> Bool {
        let string: String = string.clean()
        return string["^\".+\(localizedPrefix)_\\d+\"\\s+=\\s+\".*\";$"]
    }
}

struct LocalizedFile: Hashable, LocaleFileLine {

    var name: String
    var localizedStrings: [Int: LocalizedString] = .init()
    var text: String { makeTextStrings() }
    private var lastNumber: Int = 0

    init(name: String) {
        self.name = name
    }

    mutating func setLocalizedString(to number: Int, value: LocalizedString) {
        if lastNumber < number { lastNumber = number }
        localizedStrings[number] = value
    }

    mutating func setLocalizedString(to number: Int, localizedPrefix: String, value: String) {
        if lastNumber < number { lastNumber = number }
        localizedStrings[number] = LocalizedString(number: number, clearKey: name, localizedPrefix: localizedPrefix, value: value)
    }

    mutating func setLocalizedString(value: LocalizedString) {
        setLocalizedString(to: nextNumber(), value: value)
    }

    mutating func setLocalizedString(value: String, localizedPrefix: String) {
        setLocalizedString(to: nextNumber(), localizedPrefix: localizedPrefix, value: value)
    }

    func getLocalizedString(by number: Int) -> LocalizedString? {
        localizedStrings[number]
    }

    mutating func merge(localizedFile: LocalizedFile) {
        localizedFile.localizedStrings.values.forEach { (localizedString) in
            setLocalizedString(value: localizedString)
        }
    }

    private func makeTextStrings() -> String {
        var result: String = .init()
        localizedStrings.sorted { $0.key > $1.key }.forEach { (pair) in
            result.append(pair.value.text)
        }

        return result
    }

    private mutating func nextNumber() -> Int {
        lastNumber += 1
        return lastNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: LocalizedFile, rhs: LocalizedFile) -> Bool {
        lhs.name == rhs.name
    }
}

struct LocalizedString {

    private var key: String
    private var value: String
    var text: String

    init(number: Int, clearKey: String, localizedPrefix: String, value: String) {
        self.value = value.clean()
        text = .init()
        key = .init()
        key = makeKey(number: number, key: clearKey, localizedPrefix: localizedPrefix)
        text = makeText(key: key, value: value)
    }

    init(text: String) {
        key = .init()
        value = .init()
        self.text = text
    }

    private func makeKey(number: Int, key: String, localizedPrefix: String) -> String {
        "\(key.clean()).\(localizedPrefix)_\(number)"
    }

    private func makeText(key: String, value: String) -> String {
        "\(key) = \(value);\n"
    }
}

struct LocaleFileTextLine: LocaleFileLine {

    var text: String
}

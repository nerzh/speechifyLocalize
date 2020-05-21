//
//  LocaleFolder.swift
//  
//
//  Created by Oleh Hudeichuk on 21.05.2020.
//

import Foundation

protocol TextLineProtocol {
    var text: String { get }
}

protocol LineGroupProtocol: TextLineProtocol {
    var id: String { get set }
    var name: String? { get set }
    var number: Int { get set }
    var lines: [TextLineProtocol] { get set }

    mutating func merge(_ group: LineGroupProtocol)
}

struct LocaleFolder {
    var path: String
    var files: [LocaleFile] = .init()

    mutating func addLocaleFile(_ value: LocaleFile) {
        for (index, localeFile) in files.enumerated() {
            if localeFile.path == value.path {
                files[index].groups = value.groups
                return
            }
        }
        files.append(value)
    }
}

struct LocaleFile {
    var path: String
    var localizedPrefix: String
    var groups: [LineGroupProtocol] = .init()

    mutating func addGroup(_ group: LineGroupProtocol) {
        var group: LineGroupProtocol = group
        if var lineGroup: LineGroupProtocol = getGroup(by: group.id) {
            lineGroup.merge(group)
            groups[lineGroup.number] = lineGroup
            return
        }
        group.number = groups.count
        groups.append(group)
    }

    func getGroup(by id: String) -> LineGroupProtocol? {
        groups.first { $0.id == id }
    }

    mutating func parseRawLocalizableString(_ string: String) {
        if isLocalizedString(string, localizedPrefix) {
            guard let number: Int = Int(getNumberFromLocalizedString(string, localizedPrefix)) else { return }
            let clearKey: String = getFileNameFromLocalizedString(string, localizedPrefix)
            let value: String = getValueFromLocalizedString(string)
            var fileGroup: FileGroup = .init(name: clearKey, localizedPrefix: localizedPrefix)
            fileGroup.addTextLine(number: number, value: value)
            addGroup(fileGroup)
        } else {
            let lineGroup: TextGroup = .init(text: string)
            addGroup(lineGroup)
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

struct FileGroup: LineGroupProtocol {

    var id: String
    var name: String?
    var number: Int = .init()
    var lines: [TextLineProtocol] = .init()
    var text: String { makeTextStrings() }
    var localizedPrefix: String
    private var lastNumber: Int = 0

    init(name: String, localizedPrefix: String) {
        self.name = name.clean()
        self.localizedPrefix = localizedPrefix
        guard let id = self.name?.toSHA256() else { fatalError("Can not convert to SHA256") }
        self.id = id
    }

    mutating func addTextLine(number: Int, value: String) {
        if lastNumber < number { lastNumber = number }
        guard let name = name else { return }
        let textLine: TextLine = .init(number: number, clearKey: name, localizedPrefix: localizedPrefix, value: value)
        for currentTextLine in lines {
            if currentTextLine.text == textLine.text {
                return
            }
        }
        lines.append(textLine)
    }

    mutating func addTextLine(value: String) {
        guard let name = name else { return }
        let textLine: TextLine = .init(number: nextNumber(), clearKey: name, localizedPrefix: localizedPrefix, value: value)
        for currentTextLine in lines {
            if currentTextLine.text == textLine.text {
                return
            }
        }
        lines.append(textLine)
    }

    mutating func merge(_ group: LineGroupProtocol) {
        let valuePattern: String = #"^\".+\"\s+=\s+\"([\s\S]+)\";$"#
        var newValues: [String] = .init()

        if id == group.id {
            group.lines.forEach { (textLine) in
                if let newValue = textLine.text.clean().regexp(valuePattern)[1] {
                    var trigger: Bool = true
                    for currentTextLine in lines {
                        if let currentValue = currentTextLine.text.clean().regexp(valuePattern)[1] {
                            if currentValue == newValue {
                                trigger = false
                            }
                        }
                    }
                    if trigger { newValues.append(newValue) }
                }
            }

            newValues.forEach { (value) in
                addTextLine(number: nextNumber(), value: value)
            }
        }
    }

    private func addMARK(_ string: String) -> String {
        var result: String = .init()
        let mark: String = "// MARK: \(name ?? "")\n\n"
        if name != nil, !string["// MARK: \(name ?? "")"] {

            result.append(mark)
            result.append(string)
        }

        return result
    }

    private func makeTextStrings() -> String {
        var result: String = .init()

        lines.sorted { $0.text < $1.text }.forEach { (textLine) in
            result.append(textLine.text)
        }
//        result = addMARK(result)

        return result
    }

    private mutating func nextNumber() -> Int {
        lastNumber += 1
        return lastNumber
    }
}

struct TextGroup: LineGroupProtocol {

    var id: String
    var name: String?
    var number: Int = .init()
    var lines: [TextLineProtocol] = .init()
    var text: String

    init(text: String) {
        self.text = text
        guard let id = text.toSHA256() else { fatalError("Can not convert to SHA256") }
        self.id = id
        self.lines.append(TextLine(text: text))
    }

    mutating func addTextLine(value: String) {
        text = value
        guard let id = text.toSHA256() else { fatalError("Can not convert to SHA256") }
        self.id = id
        lines.append(TextLine(text: text))
    }

    mutating func merge(_ group: LineGroupProtocol) {
        group.lines.forEach { (textLineProtocol) in
            if !lines.contains(where: { $0.text == textLineProtocol.text }) {
                lines.append(textLineProtocol)
            }
        }
    }
}

struct TextLine: TextLineProtocol, Equatable {

    private var clearKey: String = .init()
    private var value: String = .init()
    private var localizedPrefix: String = .init()
    var number: Int = .init() {
        didSet {
            makeText(key: clearKey, value: value)
        }
    }
    var text: String = .init()
    var type: TextLineType = .text

    init(number: Int, clearKey: String, localizedPrefix: String, value: String, type: TextLineType = .localizedString) {
        self.value = value.clean()
        self.number = number
        self.clearKey = clearKey
        self.localizedPrefix = localizedPrefix
        self.type = type
        makeText(key: clearKey, value: value)
    }

    init(text: String) {
        self.text = text
    }

    private func makeKey(number: Int, key: String, localizedPrefix: String) -> String {
        "\(key.clean()).\(localizedPrefix)_\(number)"
    }

    private mutating func makeText(key: String, value: String) {
        let key = makeKey(number: number, key: clearKey, localizedPrefix: localizedPrefix)
        text = "\"\(key)\" = \"\(value)\";\n"
    }
}

enum TextLineType {

    case text
    case localizedString
}

extension TextLineType: Equatable {

    public static func ==(lhs: TextLineType, rhs: TextLineType) -> Bool {
        switch (lhs, rhs) {
        case (.text, .text):
            return true
        case (.text, .text):
            return true
        default:
            return false
        }
    }
}

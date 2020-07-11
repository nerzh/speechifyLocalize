//
//  LocaleFolder.swift
//  
//
//  Created by Oleh Hudeichuk on 21.05.2020.
//

import Foundation

public struct LocaleFolder {
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
    var groups: [LineGroup] = .init() {
        didSet {
            for (index, group) in groups.enumerated() {
                groupIndex[group.id] = index
            }
        }
    }
    private var groupIndex: [String: Int] = .init()

    init(path: String, localizedPrefix: String) {
        self.path = path
        self.localizedPrefix = localizedPrefix
    }

    mutating func addGroup(_ group: LineGroup) {
        var group: LineGroup = group
        group.number = groups.count
        groups.append(group)
        groupIndex[group.id] = groups.count - 1
    }

    mutating func overrideGroup(_ group: LineGroup) {
        if let lineGroup: LineGroup = getGroup(by: group.id) {
            groups[lineGroup.number] = group
        }
    }

    func getGroup(by id: String) -> LineGroup? {
        guard let index = groupIndex[id] else { return nil }
        return groups[index]
    }

    mutating func parseLocalizableString(_ string: String) {
        if isLocalizedString(string, localizedPrefix) {
            guard let number: Int = Int(getNumberFromLocalizedString(string, localizedPrefix)) else { return }
            let clearKey: String = getFileNameFromLocalizedString(string, localizedPrefix)
            let value: String = getValueFromLocalizedString(string)
            var newGroup: LineGroup = .init(name: clearKey, localizedPrefix: localizedPrefix)
            newGroup.addTextLine(number: number, value: value)
            if var lineGroup = getGroup(by: newGroup.id) {
                lineGroup.merge(newGroup) { (_, _) -> Int in
                    number
                }
                overrideGroup(lineGroup)
            } else {
                addGroup(newGroup)
            }
        } else {
            let lineGroup: LineGroup = .init(text: string)
            addGroup(lineGroup)
        }
    }

    private func getFileNameFromLocalizedString(_ string: String, _ localizedPrefix: String) -> String {
        let string: String = string.clean()
        guard
            let fileName: String = string.regexp(localizedStringItemsPattern(localizedPrefix))[1]
            else { fatalError("can not parse file name from string: \(string)") }
        return fileName
    }

    private func getNumberFromLocalizedString(_ string: String, _ localizedPrefix: String) -> String {
        let string: String = string.clean()
        guard
            let number: String = string.regexp(numberLocalizedStringPattern(localizedPrefix))[1]
            else { fatalError("can not parse number from string: \(string) with prefix: \(localizedPrefix)") }
        return number
    }

    private func getValueFromLocalizedString(_ string: String) -> String {
        let string: String = string.clean()
        guard
            let value: String = string.regexp(LocalizableStringPattern)[2]
            else { fatalError("can not parse value from string: \(string)") }
        return value
    }

    private func isLocalizedString(_ string: String, _ localizedPrefix: String) -> Bool {
        let string: String = string.clean()
        return string["^\".+\(localizedPrefix)_\\d+\"\\s+=\\s+\".*\";$"]
    }
}

struct LineGroup {

    var id: String = .init()
    var name: String?
    var number: Int = .init()
    var lines: [TextLine] = .init()
    var text: String { makeTextStrings() }
    var localizedPrefix: String = .init()
    var lastNumber: Int = 0

    init(name: String, localizedPrefix: String) {
        self.name = name.clean()
        self.localizedPrefix = localizedPrefix
        self.id = generateId(name)
    }

    init(text: String) {
        self.id = generateId(text)
        self.lines.append(TextLine(text: text))
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

    mutating func addNextTextLine(value: String) {
        guard let name = name else { return }
        let textLine: TextLine = .init(number: nextNumber(), clearKey: name, localizedPrefix: localizedPrefix, value: value)
        for currentTextLine in lines {
            if currentTextLine.text == textLine.text {
                return
            }
        }
        lines.append(textLine)
    }

    mutating func merge(_ group: LineGroup,
                        _ calcNumber: ((LineGroup, LineGroup) -> Int)? = nil
    ) {
        if id == group.id {
            group.lines.forEach { (textLine) in
                if let newValue = textLine.text.clean().regexp(LocalizableStringPattern)[2] {
                    var trigger: Bool = true
                    for currentTextLine in lines {
                        if let currentValue = currentTextLine.text.clean().regexp(LocalizableStringPattern)[2] {
                            if currentValue == newValue {
                                trigger = false
                            }
                        }
                    }
                    if trigger {
                        var newNumber: Int = .init()
                        if let calcNumber = calcNumber {
                            newNumber = calcNumber(self, group)
                        } else {
                            newNumber = nextNumber()
                        }
                        addTextLine(number: newNumber, value: newValue)
                    }
                }
            }
        }
    }

    func generateId(_ name: String) -> String {
        guard let id = name.toSHA256() else { fatalError("Can not convert to SHA256") }
        return id
    }

    private func makeTextStrings() -> String {
        var result: String = .init()

        for (index, textLine) in lines.sorted { $0.text < $1.text }.enumerated() {
            result.append("\(textLine.text.clean())\n")
            if textLine.type == .localizedString && index == lines.count - 1 {
                result.append("\n")
            }
        }

        return result
    }

    private mutating func nextNumber() -> Int {
        lastNumber += 1
        return lastNumber
    }
}

struct TextLine: Equatable {

    private var clearKey: String = .init()
    private var value: String = .init()
    private var localizedPrefix: String = .init()
    var number: Int = .init()
    var text: String { makeText(key: clearKey, value: value) }
    var type: TextLineType = .text

    init(number: Int, clearKey: String, localizedPrefix: String, value: String, type: TextLineType = .localizedString) {
        self.value = value
        self.number = number
        self.clearKey = clearKey
        self.localizedPrefix = localizedPrefix
        self.type = type
    }

    init(text: String) {
        self.value = text
    }

    private func makeKey(number: Int, key: String, localizedPrefix: String) -> String {
        switch type {
        case .localizedString:
            return "\(key.clean()).\(localizedPrefix)_\(number)"
        default:
            return ""
        }
    }

    func getValue() -> String {
        value
    }

    func getKey() -> String {
        switch type {
        case .localizedString:
            return makeKey(number: number, key: clearKey, localizedPrefix: localizedPrefix)
        default:
            return ""
        }
    }

    func getClearKey() -> String {
        switch type {
        case .localizedString:
            return clearKey
        default:
            return ""
        }
    }

    private func makeText(key: String, value: String) -> String {
        switch type {
        case .localizedString:
            let key = makeKey(number: number, key: clearKey, localizedPrefix: localizedPrefix)
            return "\(makeLocalizableString(key, value))\n"
        default:
            return value
        }
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
        case (.localizedString, .localizedString):
            return true
        default:
            return false
        }
    }
}

//
//  CSV.swift
//  
//
//  Created by Oleh Hudeichuk on 25.05.2020.
//

import Foundation

struct CSVFile {

    var separator: String
    var rows: [CSVRow] = .init()
    private var _columns: [String: Int] = .init()
    private var rowKeys: [String: Int] = .init()

    init (separator: String) {
        self.separator = separator
    }

    init (separator: String, filePath: String) {
        self.separator = separator
        read(filePath)
    }

    subscript(index: Int) -> CSVRow {
        get { rows[index] }
        set {
            var newValue = newValue
            addColumns(index, &newValue)
            addRowKey(index, key: newValue.first ?? "")
            rows[index] = newValue
        }
    }

    subscript(rowKey: String) -> CSVRow {
        mutating get {
            if let index = rowKeys[rowKey] {
                return rows[index]
            } else {
                var row: CSVRow = .init()
                row.columns = _columns
                row.add(rowKey)
                addRowKey(rows.count, key: rowKey)
                rows.append(row)
                return row
            }
        }
        set {
            var newValue = newValue
            if let index = rowKeys[rowKey] {
                addColumns(index, &newValue)
                addRowKey(index, key: newValue.first ?? "")
                rows[index] = newValue
            }
        }
    }

//    mutating func add(_ values: String...) {
//        var row: CSVRow = .init()
//        values.forEach { row.add($0) }
//        addColumns(rows.count, &row)
//        addRowKey(rows.count, key: row.first ?? "")
//        rows.append(row)
//    }

    mutating func add(_ values: [String]) {
        var row: CSVRow = .init()
        values.forEach { row.add($0) }
        addColumns(rows.count, &row)
        addRowKey(rows.count, key: row.first ?? "")
        rows.append(row)
    }

//    mutating func add(to column: String, _ value: String) {
//        var row: CSVRow = .init()
//        row.columns = columns
//        row[column] = value
//        addRowKey(rows.count, key: row.first ?? "")
//        rows.append(row)
//    }

//    mutating func add(to index: Int, _ value: String) {
//        var row: CSVRow = .init()
//        row.columns = columns
//        row[index] = value
//        addRowKey(rows.count, key: row.first ?? "")
//        rows.append(row)
//    }

    mutating func addColumnName(_ name: String) {
        var row: CSVRow = rows.first ?? .init()
        row.add(name)
        addColumns(0, &row)
        addRowKey(0, key: row.first ?? "")
        if rows.count == 0 { rows.append(.init()) }
        rows[0] = row
        for (index, _) in rows.enumerated() {
            rows[index].columns = _columns
        }
    }

    func write(to: String) {
        var text: String = .init()
        rows.forEach { (row) in
            text.append("\(row.toString(with: separator))\n")
        }
        writeFile(to: to, text)
    }

    func columns() -> [String] {
        Array<String>(_columns.keys)
    }

    private mutating func read(_ filePath: String) {
        guard let fileURL: URL = URL(string: filePath) else { return }
        var isFirstLine: Bool = true
        readFile(fileURL) { (line) in
            let values: [String] = split(line, separator)
            if isFirstLine {
                values.forEach { addColumnName($0) }
                isFirstLine = false
            } else {
                add(values)
            }
        }
    }

    private func split(_ string: String, _ separator: String) -> [String] {
        var result: [String] = .init()
        var string: String = string.clean()

        while true {
            let matches: [Int: String] = string.regexp(csvElementPattern(separator))
            if var value = matches[1] {
                value.replaceSelf("^\"", "")
                value.replaceSelf("\"$", "")
                result.append(value)
                string.replaceFirstSelf(csvElementPattern(separator), "")
                continue
            }
            break
        }

        return result
    }

    private mutating func addColumns(_ rows: Int, _ row: inout CSVRow) {
        if rows == 0 {
            for (index, value) in row.enumerated() {
                _columns[value] = index
            }
        }
        row.columns = _columns
    }

    private mutating func addRowKey(_ index: Int, key: String) {
        rowKeys[key] = index
    }
}

struct CSVRow: Sequence {

    private var values: [String] = .init()
    var columns: [String: Int] = .init()
    var first: String? { values.first }

    subscript(index: Int) -> String {
        get { values[index] }
        set { values[index] = "\(newValue)" }
    }

    subscript(column: String) -> String {
        get {
            guard let index: Int = columns["\(column)"] else { fatalError("Not found column with name: \(column)") }
            if values.count == index {
                fatalError("Please check value of column: \(column).\n\nRow values: \(values.joined(separator: "\n\n"))")
            }
            return values[index]
        }
        set {
            guard let index: Int = columns["\(column)"] else { fatalError("Not found column with name: \(column)") }
            checkDefaultValues()
            values[index] = "\(newValue)"
        }
    }

    mutating func add(_ value: String) {
        values.append("\(value)")
        checkDefaultValues()
    }

    func toString(with separator: String) -> String {
        values.map { "\"\($0)\"" }.joined(separator: separator)
    }

    func makeIterator() -> Array<String>.Iterator {
        values.makeIterator()
    }

    private mutating func checkDefaultValues() {
        if values.count < columns.keys.count {
            let diff: Int = columns.keys.count - values.count
            for _ in 0..<diff {
                values.append("\"\"")
            }
        }
    }
}

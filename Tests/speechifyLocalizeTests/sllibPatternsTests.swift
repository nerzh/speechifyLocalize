import XCTest
import class Foundation.Bundle
@testable import SLLib

final class sllibPatternsTests: XCTestCase {

    func testLocalizableStringPattern() throws {

        let stringEqual_1: String = "\"Key\" = \"Value\";"
        let stringEqual_2: String = " \"Key\" = \"Value\" ; "
        let stringEqual_3: String = " \" Key \"  =  \" Value \";"
        let stringNotEqual_1: String = "\"Key\" = \"Value\""

        XCTAssertEqual(stringEqual_1.regexp(LocalizableStringPattern)[0], stringEqual_1)
        XCTAssertEqual(stringEqual_1.regexp(LocalizableStringPattern)[1], "Key")
        XCTAssertEqual(stringEqual_1.regexp(LocalizableStringPattern)[2], "Value")

        XCTAssertEqual(stringEqual_2.regexp(LocalizableStringPattern)[0], stringEqual_2)
        XCTAssertEqual(stringEqual_2.regexp(LocalizableStringPattern)[1], "Key")
        XCTAssertEqual(stringEqual_2.regexp(LocalizableStringPattern)[2], "Value")

        XCTAssertEqual(stringEqual_3.regexp(LocalizableStringPattern)[0], stringEqual_3)
        XCTAssertEqual(stringEqual_3.regexp(LocalizableStringPattern)[1], " Key ")
        XCTAssertEqual(stringEqual_3.regexp(LocalizableStringPattern)[2], " Value ")

        XCTAssertNotEqual(stringNotEqual_1.regexp(LocalizableStringPattern)[0], stringNotEqual_1)
    }

    func testPathWithSwiftExtensionPattern() throws {

        let stringEqual_1: String = "aaa.swift"
        let stringEqual_2: String = "/aaa/bbb.swift"
        let stringNotEqual_1: String = ".swift"

        XCTAssertEqual(stringEqual_1.regexp(PathWithSwiftExtensionPattern)[0], stringEqual_1)
        XCTAssertEqual(stringEqual_1.regexp(PathWithSwiftExtensionPattern)[1], "aaa")

        XCTAssertEqual(stringEqual_2.regexp(PathWithSwiftExtensionPattern)[0], stringEqual_2)
        XCTAssertEqual(stringEqual_2.regexp(PathWithSwiftExtensionPattern)[1], "/aaa/bbb")

        XCTAssertNotEqual(stringNotEqual_1.regexp(PathWithSwiftExtensionPattern)[0], stringNotEqual_1)
    }

    func testLprojNamePattern() throws {

        let stringEqual_1: String = "name.lproj"
        let stringEqual_2: String = "/aaa/name.lproj"
        let stringNotEqual_1: String = ".lproj"

        XCTAssertEqual(stringEqual_1.regexp(LprojNamePattern)[0], stringEqual_1)
        XCTAssertEqual(stringEqual_1.regexp(LprojNamePattern)[1], "name")

        XCTAssertEqual(stringEqual_2.regexp(LprojNamePattern)[0], "name.lproj")
        XCTAssertEqual(stringEqual_2.regexp(LprojNamePattern)[1], "name")

        XCTAssertNotEqual(stringNotEqual_1.regexp(LprojNamePattern)[0], stringNotEqual_1)
    }

    func testFileNamePattern() throws {

        let stringEqual_1: String = "name.ext"
        let stringEqual_2: String = "/aaa/name.ext"
        let stringEqual_3: String = ".ext"

        XCTAssertEqual(stringEqual_1.regexp(FileNamePattern)[0], stringEqual_1)
        XCTAssertEqual(stringEqual_1.regexp(FileNamePattern)[1], "name.ext")

        XCTAssertEqual(stringEqual_2.regexp(FileNamePattern)[0], "name.ext")
        XCTAssertEqual(stringEqual_2.regexp(FileNamePattern)[1], "name.ext")

        XCTAssertEqual(stringEqual_3.regexp(FileNamePattern)[0], stringEqual_3)
        XCTAssertEqual(stringEqual_3.regexp(FileNamePattern)[1], ".ext")
    }

    func testStringFilePattern() throws {

        let stringEqual_1: String = "name.strings"
        let stringEqual_2: String = "/aaa/name.strings"
        let stringNotEqual_1: String = ".strings"

        XCTAssertEqual(stringEqual_1.regexp(StringFilePattern)[0], stringEqual_1)

        XCTAssertEqual(stringEqual_2.regexp(StringFilePattern)[0], stringEqual_2)

        XCTAssertNotEqual(stringNotEqual_1.regexp(StringFilePattern)[0], stringNotEqual_1)
    }

    func testCsvElementPattern() throws {

        var separator: String = ","
        var testdString: String = .init()

        /// separator ,
        testdString = "\"[key]\"\(separator)\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"[key]\"")

        testdString = "\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "Base\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "Base\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "\"Base\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "\"Ba\"se\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Ba\"se\"")

        /// separator "
        separator = "\""
        testdString = "\"[key]\"\(separator)\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"[key]\"")

        testdString = "\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "Base\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "Base\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "\"Base\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "\"Ba\"se\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Ba\"se\"")

        /// separator #
        separator = "#"
        testdString = "\"[key]\"\(separator)\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"[key]\"")

        testdString = "\"Base\"\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "Base\(separator)\"Ru\""
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "Base\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "Base")

        testdString = "\"Base\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Base\"")

        testdString = "\"Ba\"se\"\(separator)Ru"
        XCTAssertEqual(testdString.regexp(csvElementPattern(separator))[1], "\"Ba\"se\"")
    }

    func testTranslate() throws {
        let langFrom: String = "ru"
        let langTo: String = "en"
        let text: String = "Привет мир !"
        let expectedResult: String = "Hello World !"
        let api: String = "https://translation.googleapis.com/language/translate/v2"
        let file = FileReader(fileURL: URL(string: "./Tests/speechifyLocalizeTests/Fixtures/GoogleKey.txt")!)
        try file.open()
        defer { file.close() }
        guard var key: String = try file.readLine() else { throw SLError(reason: "Google Key not found") }
        key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: String = (try? translate(text, from: langFrom, to: langTo, api: api, key: key)) ?? ""

        XCTAssertEqual(result, expectedResult)
    }

    static var allTests = [
        ("testRealPath", testLocalizableStringPattern),
        ("testPathWithSwiftExtensionPattern", testPathWithSwiftExtensionPattern),
        ("testLprojNamePattern", testLprojNamePattern),
        ("testFileNamePattern", testFileNamePattern),
        ("testStringFilePattern", testStringFilePattern),
        ("testCsvElementPattern", testCsvElementPattern),
        ("testTranslate", testTranslate),
    ]
}



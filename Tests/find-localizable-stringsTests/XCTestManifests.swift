import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(find_localizable_stringsTests.allTests),
    ]
}
#endif

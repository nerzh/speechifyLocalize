import XCTest

import speechifyLocalizeTests

var tests = [XCTestCaseEntry]()
tests += sllibPatternsTests.allTests()
XCTMain(tests)

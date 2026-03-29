// Copyright 2023–2026 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import XCTest
import OSLog
import Foundation
@testable import SkipRevenue

let logger: Logger = Logger(subsystem: "SkipRevenue", category: "Tests")

@available(macOS 13, *)
final class SkipRevenueTests: XCTestCase {

    func testSkipRevenue() throws {
        logger.log("running testSkipRevenue")
        XCTAssertEqual(1 + 2, 3, "basic test")
    }

    func testDecodeType() throws {
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SkipRevenue", testData.testModuleName)
    }

}

struct TestData : Codable, Hashable {
    var testModuleName: String
}

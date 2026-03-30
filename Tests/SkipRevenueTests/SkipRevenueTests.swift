// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0

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
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SkipRevenue", testData.testModuleName)
    }

    func testStoreErrorCases() throws {
        let errors: [StoreError] = [
            .userCancelled,
            .unknown,
            .noPurchasesFound,
            .noProductsAvailable,
            .packageNotFound,
            .notConfigured,
        ]
        XCTAssertEqual(errors.count, 6)
        for err in errors {
            XCTAssertFalse("\(err)".isEmpty)
        }
    }

    func testPackageType() throws {
        let types: [RCFusePackageType] = [
            .unknown, .custom, .lifetime, .annual,
            .sixMonth, .threeMonth, .twoMonth, .monthly, .weekly
        ]
        XCTAssertEqual(types.count, 9)
        XCTAssertEqual(RCFusePackageType.annual.rawValue, "annual")
        XCTAssertEqual(RCFusePackageType.monthly.rawValue, "monthly")
    }

    func testRevenueCatFuseSingleton() throws {
        let service = RevenueCatFuse.shared
        XCTAssertNotNil(service)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}

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
        XCTAssertEqual(RCFusePackageType.monthly.rawValue, 0)
        XCTAssertEqual(RCFusePackageType.annual.rawValue, 1)
        XCTAssertLessThan(RCFusePackageType.monthly, RCFusePackageType.annual)
    }

    func testRevenueCatFuseSingleton() throws {
        let service = RevenueCatFuse.shared
        XCTAssertNotNil(service)
    }

    func testLogLevel() throws {
        // Round-trips every level through the underlying Purchases.logLevel on both platforms. (#4)
        let service = RevenueCatFuse.shared
        for level: RCFuseLogLevel in [.verbose, .debug, .info, .warn, .error] {
            service.logLevel = level
            XCTAssertEqual(level, service.logLevel)
        }
        XCTAssertEqual(RCFuseLogLevel.verbose.rawValue, "verbose")
    }

    // RCFusePeriodType raw values must equal RevenueCat's native `PeriodType`
    // ordinals (iOS `normal=0…prepaid=3`; the Android branch maps the
    // UPPER_SNAKE enum names onto these). Cross-platform callers that persist
    // or compare the raw value depend on this contract.
    func testPeriodTypeOrdinals() throws {
        XCTAssertEqual(RCFusePeriodType.normal.rawValue, 0)
        XCTAssertEqual(RCFusePeriodType.intro.rawValue, 1)
        XCTAssertEqual(RCFusePeriodType.trial.rawValue, 2)
        XCTAssertEqual(RCFusePeriodType.prepaid.rawValue, 3)
        XCTAssertEqual(RCFusePeriodType(rawValue: 2), .trial)
        XCTAssertNil(RCFusePeriodType(rawValue: 99))
    }

    // RCFuseStore raw values must equal RevenueCat's native iOS `Store`
    // ordinals. Android-only PADDLE/TEST_STORE have no iOS counterpart and are
    // folded into `.unknownStore` by the Android branch.
    func testStoreOrdinals() throws {
        XCTAssertEqual(RCFuseStore.appStore.rawValue, 0)
        XCTAssertEqual(RCFuseStore.macAppStore.rawValue, 1)
        XCTAssertEqual(RCFuseStore.playStore.rawValue, 2)
        XCTAssertEqual(RCFuseStore.stripe.rawValue, 3)
        XCTAssertEqual(RCFuseStore.promotional.rawValue, 4)
        XCTAssertEqual(RCFuseStore.unknownStore.rawValue, 5)
        XCTAssertEqual(RCFuseStore.amazon.rawValue, 6)
        XCTAssertEqual(RCFuseStore.rcBilling.rawValue, 7)
        XCTAssertEqual(RCFuseStore.externalStore.rawValue, 8)
        XCTAssertEqual(RCFuseStore(rawValue: 6), .amazon)
        XCTAssertNil(RCFuseStore(rawValue: 99))
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}

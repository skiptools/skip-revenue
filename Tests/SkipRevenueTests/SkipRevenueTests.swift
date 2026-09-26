// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0

import XCTest
import OSLog
import Foundation
@testable import SkipRevenue
#if SKIP
import com.android.billingclient.api.ProductDetails
import com.revenuecat.purchases.ProductType
import com.revenuecat.purchases.models.GooglePurchasingData
import com.revenuecat.purchases.models.GoogleStoreProduct
import com.revenuecat.purchases.models.GoogleSubscriptionOption
import com.revenuecat.purchases.models.Period
import com.revenuecat.purchases.models.Price
import com.revenuecat.purchases.models.PricingPhase
import com.revenuecat.purchases.models.RecurrenceMode
import com.revenuecat.purchases.models.SubscriptionOptions
#else
import RevenueCat
#endif

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

    #if SKIP
    // Purchasing a package buys its product's `defaultOption`, which RevenueCat
    // picks from the base plan and its offers: the longest free trial, not the first.
    func testDefaultSubscriptionOptionId() throws {
        let yearly = PricingPhase(billingPeriod: Period(value: 1, unit: Period.Unit.YEAR, iso8601: "P1Y"), recurrenceMode: RecurrenceMode.INFINITE_RECURRING, billingCycleCount: nil, price: Price(formatted: "€59.99", amountMicros: Int64(59_990_000), currencyCode: "EUR"))
        let threeDays = PricingPhase(billingPeriod: Period(value: 3, unit: Period.Unit.DAY, iso8601: "P3D"), recurrenceMode: RecurrenceMode.FINITE_RECURRING, billingCycleCount: 1, price: Price(formatted: "Free", amountMicros: Int64(0), currencyCode: "EUR"))
        let oneWeek = PricingPhase(billingPeriod: Period(value: 1, unit: Period.Unit.WEEK, iso8601: "P1W"), recurrenceMode: RecurrenceMode.FINITE_RECURRING, billingCycleCount: 1, price: Price(formatted: "Free", amountMicros: Int64(0), currencyCode: "EUR"))

        let basePlan = subscriptionOption(offerId: nil, phases: listOf(yearly))
        let shortTrial = subscriptionOption(offerId: "short-trial", phases: listOf(threeDays, yearly))
        let freeTrial = subscriptionOption(offerId: "free-trial", phases: listOf(oneWeek, yearly))

        let withTrials = googleStoreProduct(options: listOf(basePlan, shortTrial, freeTrial))
        let purchased = (withTrials.purchasingData as! GooglePurchasingData.Subscription).optionId
        XCTAssertEqual("yearly:free-trial", purchased)
        XCTAssertEqual(purchased, RCFuseStoreProduct(product: withTrials).defaultSubscriptionOptionId)
        XCTAssertEqual("yearly", RCFuseStoreProduct(product: googleStoreProduct(options: listOf(basePlan))).defaultSubscriptionOptionId)
    }

    private func subscriptionOption(offerId: String?, phases: kotlin.collections.List<PricingPhase>) -> GoogleSubscriptionOption {
        return GoogleSubscriptionOption(productId: "com.example.pro", basePlanId: "yearly", offerId: offerId, pricingPhases: phases, tags: listOf(), productDetails: productDetails(), offerToken: "token")
    }

    private func googleStoreProduct(options: kotlin.collections.List<GoogleSubscriptionOption>) -> GoogleStoreProduct {
        let subscriptionOptions = SubscriptionOptions(options)
        return GoogleStoreProduct(productId: "com.example.pro", basePlanId: "yearly", type: ProductType.SUBS, price: Price(formatted: "€59.99", amountMicros: Int64(59_990_000), currencyCode: "EUR"), name: "Pro", title: "Pro", description: "Pro", period: Period(value: 1, unit: Period.Unit.YEAR, iso8601: "P1Y"), subscriptionOptions: subscriptionOptions, defaultOption: subscriptionOptions.defaultOffer, productDetails: productDetails())
    }

    // ProductDetails has no public constructor; RevenueCat only reads it when talking to Play.
    private func productDetails() -> ProductDetails {
        let constructor = java.lang.Class.forName("com.android.billingclient.api.ProductDetails").getDeclaredConstructor(java.lang.Class.forName("java.lang.String"))
        constructor.setAccessible(true)
        return constructor.newInstance("{\"productId\":\"com.example.pro\",\"type\":\"subs\",\"title\":\"Pro\",\"name\":\"Pro\",\"description\":\"Pro\"}") as! ProductDetails
    }
    #else
    func testDefaultSubscriptionOptionId() throws {
        let product = TestStoreProduct(localizedTitle: "Pro", price: 59.99, currencyCode: "EUR", localizedPriceString: "€59.99", productIdentifier: "com.example.pro", productType: .autoRenewableSubscription, localizedDescription: "Pro", locale: Locale(identifier: "de_DE"))
        XCTAssertNil(RCFuseStoreProduct(product: product.toStoreProduct()).defaultSubscriptionOptionId)
    }
    #endif
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}

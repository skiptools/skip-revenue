// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0

// File structure mirrors `skip-firebase` (Firestore, Functions, …): the
// entire implementation lives inside `#if !SKIP_BRIDGE`. The bridge
// generator runs the same sources with `-DSKIP_BRIDGE` and emits its own
// self-contained `BridgedFromKotlin` Swift classes in
// `SkipRevenue_Bridge.swift`; those JNI-forward into the Kotlin
// transpilation. Native-Swift-on-Android callers link against the
// auto-generated bridge class, NOT the impl in this file — which is why
// the previous "hide impl + leave stubs visible" pattern crashed
// (the stubs were the only thing native-Swift saw).
#if !SKIP_BRIDGE
import Foundation

#if !SKIP
import RevenueCat
#else
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Offerings
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.PurchasesTransactionException
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitLogIn
import com.revenuecat.purchases.awaitLogOut
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import com.revenuecat.purchases.awaitSyncPurchases
import com.revenuecat.purchases.models.Period
#endif

// MARK: - Value types

/// The type of a RevenueCat package. Mirrors iOS `RevenueCat.PackageType`.
public enum RCFusePackageType: String {
    case unknown
    case custom
    case lifetime
    case annual
    case sixMonth
    case threeMonth
    case twoMonth
    case monthly
    case weekly
}

/// Subscription period unit. Mirrors iOS `RevenueCat.SubscriptionPeriod.Unit`.
public enum RCFuseSubscriptionPeriodUnit: Int, Sendable {
    case day = 0
    case week = 1
    case month = 2
    case year = 3
    case unknown = 4
}

/// The billing period an entitlement is currently in.
///
/// Raw values match RevenueCat's native `PeriodType` ordinals on both platforms
/// (iOS `RevenueCat.PeriodType`, Android `com.revenuecat.purchases.PeriodType`).
public enum RCFusePeriodType: Int, Sendable {
    case normal = 0
    case intro = 1
    case trial = 2
    case prepaid = 3
}

/// The store through which an entitlement was purchased.
///
/// Raw values match RevenueCat's native iOS `Store` ordinals. Android adds
/// `PADDLE`/`TEST_STORE`, which have no iOS counterpart and map to `.unknownStore`.
public enum RCFuseStore: Int, Sendable {
    case appStore = 0
    case macAppStore = 1
    case playStore = 2
    case stripe = 3
    case promotional = 4
    case unknownStore = 5
    case amazon = 6
    case rcBilling = 7
    // Named `externalStore` (not `external`) because `external` is a reserved
    // Kotlin keyword and Skip does not escape it as an enum entry.
    case externalStore = 8
}

/// Intro-offer eligibility status. Mirrors iOS `RevenueCat.IntroEligibilityStatus`.
public enum RCFuseIntroEligibilityStatus: Int, Sendable {
    /// RevenueCat doesn't have enough information to determine eligibility.
    case unknown = 0
    /// The user is not eligible for the intro offer.
    case ineligible = 1
    /// The user is eligible for the intro offer.
    case eligible = 2
    /// The user has an active subscription, no intro offer.
    case noIntroOfferExists = 3
}

/// Wrapper for an intro-eligibility result. Mirrors iOS `RevenueCat.IntroEligibility`.
public struct RCFuseIntroEligibility: Sendable {
    public let status: RCFuseIntroEligibilityStatus

    public init(status: RCFuseIntroEligibilityStatus) {
        self.status = status
    }
}

/// Wrapper for a subscription period. Mirrors iOS `RevenueCat.SubscriptionPeriod`.
public struct RCFuseSubscriptionPeriod: Sendable {
    public let unit: RCFuseSubscriptionPeriodUnit
    public let value: Int

    public init(unit: RCFuseSubscriptionPeriodUnit, value: Int) {
        self.unit = unit
        self.value = value
    }
}

/// Sendable wrapper for an Android `Activity` reference that needs to cross
/// the Skip bridge into the suspending `purchase(package:activity:)` call.
///
/// `Any` isn't `Sendable`, and the bridge generator emits `Task { ... }`
/// thunks that capture parameters by value — strict-concurrency rejects the
/// capture without an explicit Sendable opt-in. Wrapping the activity in this
/// `@unchecked Sendable` value type is the opt-in; the bridge layer transfers
/// the underlying reference once and never shares it across actors after that.
public struct RCFuseAndroidActivity: @unchecked Sendable {
    public let activity: Any

    public init(_ activity: Any) {
        self.activity = activity
    }
}

// MARK: - Errors

public enum StoreError: Error {
    case userCancelled
    case unknown
    case noPurchasesFound
    case noProductsAvailable
    case packageNotFound
    case notConfigured
}

extension StoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userCancelled: return "User cancelled"
        case .unknown: return "Unknown error"
        case .noPurchasesFound: return "No purchases found"
        case .noProductsAvailable: return "No products available"
        case .packageNotFound: return "Package not found"
        case .notConfigured: return "RevenueCat is not configured"
        }
    }
}

// MARK: - Wrapper classes

/// Wrapper for RevenueCat `Offerings`.
#if !SKIP
public final class RCFuseOfferings: @unchecked Sendable {
    public let offerings: RevenueCat.Offerings

    public init(offerings: RevenueCat.Offerings) {
        self.offerings = offerings
    }

    public var current: RCFuseOffering? {
        guard let current = offerings.current else { return nil }
        return RCFuseOffering(offering: current)
    }

    public var all: [String: RCFuseOffering] {
        return Dictionary(uniqueKeysWithValues: offerings.all.map { (key, value) in
            (key, RCFuseOffering(offering: value))
        })
    }

    public func offering(identifier: String) -> RCFuseOffering? {
        guard let offering = offerings.offering(identifier: identifier) else {
            return nil
        }
        return RCFuseOffering(offering: offering)
    }
}
#else
public final class RCFuseOfferings: KotlinConverting<com.revenuecat.purchases.Offerings>, @unchecked Sendable {
    public let offerings: com.revenuecat.purchases.Offerings

    public init(offerings: com.revenuecat.purchases.Offerings) {
        self.offerings = offerings
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.Offerings {
        offerings
    }

    public var current: RCFuseOffering? {
        guard let current = offerings.current else { return nil }
        return RCFuseOffering(offering: current)
    }

    public var all: [String: RCFuseOffering] {
        var result: [String: RCFuseOffering] = [:]
        for (key, value) in offerings.all {
            result[key] = RCFuseOffering(offering: value)
        }
        return result
    }

    public func offering(identifier: String) -> RCFuseOffering? {
        guard let offering = offerings.all[identifier] else {
            return nil
        }
        return RCFuseOffering(offering: offering)
    }
}
#endif

/// Wrapper for RevenueCat `Offering`.
#if !SKIP
public final class RCFuseOffering: @unchecked Sendable {
    public let offering: RevenueCat.Offering

    public init(offering: RevenueCat.Offering) {
        self.offering = offering
    }

    public var identifier: String {
        return offering.identifier
    }

    public var serverDescription: String {
        return offering.serverDescription
    }

    public var availablePackages: [RCFusePackage] {
        return offering.availablePackages.map { RCFusePackage(package: $0) }
    }

    public var lifetime: RCFusePackage? {
        guard let pkg = offering.lifetime else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var annual: RCFusePackage? {
        guard let pkg = offering.annual else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var sixMonth: RCFusePackage? {
        guard let pkg = offering.sixMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var threeMonth: RCFusePackage? {
        guard let pkg = offering.threeMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var twoMonth: RCFusePackage? {
        guard let pkg = offering.twoMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var monthly: RCFusePackage? {
        guard let pkg = offering.monthly else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var weekly: RCFusePackage? {
        guard let pkg = offering.weekly else { return nil }
        return RCFusePackage(package: pkg)
    }

    public func package(identifier: String) -> RCFusePackage? {
        guard let pkg = offering.package(identifier: identifier) else { return nil }
        return RCFusePackage(package: pkg)
    }
}
#else
public final class RCFuseOffering: KotlinConverting<com.revenuecat.purchases.Offering>, @unchecked Sendable {
    public let offering: com.revenuecat.purchases.Offering

    public init(offering: com.revenuecat.purchases.Offering) {
        self.offering = offering
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.Offering {
        offering
    }

    public var identifier: String {
        return offering.identifier
    }

    public var serverDescription: String {
        return offering.serverDescription
    }

    public var availablePackages: [RCFusePackage] {
        return Array(offering.availablePackages.map { RCFusePackage(package: $0) })
    }

    public var lifetime: RCFusePackage? {
        guard let pkg = offering.lifetime else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var annual: RCFusePackage? {
        guard let pkg = offering.annual else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var sixMonth: RCFusePackage? {
        guard let pkg = offering.sixMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var threeMonth: RCFusePackage? {
        guard let pkg = offering.threeMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var twoMonth: RCFusePackage? {
        guard let pkg = offering.twoMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var monthly: RCFusePackage? {
        guard let pkg = offering.monthly else { return nil }
        return RCFusePackage(package: pkg)
    }

    public var weekly: RCFusePackage? {
        guard let pkg = offering.weekly else { return nil }
        return RCFusePackage(package: pkg)
    }

    public func package(identifier: String) -> RCFusePackage? {
        guard let pkg = offering.getPackage(identifier) else { return nil }
        return RCFusePackage(package: pkg)
    }
}
#endif

/// Wrapper for RevenueCat `Package`.
#if !SKIP
public final class RCFusePackage: @unchecked Sendable {
    public let package: RevenueCat.Package

    public init(package: RevenueCat.Package) {
        self.package = package
    }

    public var identifier: String {
        return package.identifier
    }

    public var packageType: RCFusePackageType {
        switch package.packageType {
        case .lifetime: return .lifetime
        case .annual: return .annual
        case .sixMonth: return .sixMonth
        case .threeMonth: return .threeMonth
        case .twoMonth: return .twoMonth
        case .monthly: return .monthly
        case .weekly: return .weekly
        case .custom: return .custom
        case .unknown: return .unknown
        }
    }

    public var storeProduct: RCFuseStoreProduct {
        return RCFuseStoreProduct(product: package.storeProduct)
    }

    /// A localized string describing the package duration (e.g., "1 month", "1 year").
    public var localizedPeriodString: String? {
        guard let period = package.storeProduct.subscriptionPeriod else { return nil }
        return "\(period.value) \(period.unit)"
    }

    public var localizedPriceString: String {
        return storeProduct.localizedPriceString
    }
}
#else
public final class RCFusePackage: KotlinConverting<com.revenuecat.purchases.Package>, @unchecked Sendable {
    public let package: com.revenuecat.purchases.Package

    public init(package: com.revenuecat.purchases.Package) {
        self.package = package
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.Package {
        package
    }

    public var identifier: String {
        return package.identifier
    }

    public var packageType: RCFusePackageType {
        let name = "\(package.packageType)"
        switch name {
        case "LIFETIME": return .lifetime
        case "ANNUAL": return .annual
        case "SIX_MONTH": return .sixMonth
        case "THREE_MONTH": return .threeMonth
        case "TWO_MONTH": return .twoMonth
        case "MONTHLY": return .monthly
        case "WEEKLY": return .weekly
        case "CUSTOM": return .custom
        default: return .unknown
        }
    }

    public var storeProduct: RCFuseStoreProduct {
        return RCFuseStoreProduct(product: package.product)
    }

    public var localizedPeriodString: String? {
        return package.product.period?.let { "\($0)" }
    }

    public var localizedPriceString: String {
        return storeProduct.localizedPriceString
    }
}
#endif

/// Wrapper for RevenueCat `StoreProduct`.
#if !SKIP
public final class RCFuseStoreProduct: @unchecked Sendable {
    public let product: RevenueCat.StoreProduct

    public init(product: RevenueCat.StoreProduct) {
        self.product = product
    }

    public var productIdentifier: String {
        return product.productIdentifier
    }

    public var localizedTitle: String {
        return product.localizedTitle
    }

    public var localizedDescription: String {
        return product.localizedDescription
    }

    public var localizedPriceString: String {
        return product.localizedPriceString
    }

    public var price: Double {
        return Double(truncating: product.price as NSNumber)
    }

    /// The currency code for this product's price (e.g., "USD", "EUR").
    public var currencyCode: String? {
        return product.currencyCode
    }

    /// The localized introductory price string, if an intro offer is available.
    public var localizedIntroductoryPriceString: String? {
        return product.introductoryDiscount?.localizedPriceString
    }

    public var subscriptionPeriod: RCFuseSubscriptionPeriod? {
        guard let period = product.subscriptionPeriod else { return nil }
        let unit: RCFuseSubscriptionPeriodUnit
        switch period.unit {
        case .day: unit = .day
        case .week: unit = .week
        case .month: unit = .month
        case .year: unit = .year
        @unknown default: unit = .unknown
        }
        return RCFuseSubscriptionPeriod(unit: unit, value: period.value)
    }

    public var pricePerMonth: Double? {
        guard let pricePerMonth = product.pricePerMonth else { return nil }
        return Double(truncating: pricePerMonth as NSNumber)
    }

    /// Returns a NumberFormatter configured for the product's locale (iOS only).
    /// On Android, use `localizedPriceString` or format prices manually.
    public var priceFormatter: NumberFormatter? {
        return product.priceFormatter
    }

    /// Returns the localized price per month string (e.g., "$4.99").
    /// Uses the product's price formatter for proper locale formatting.
    public var localizedPricePerMonthString: String? {
        guard let pricePerMonth = pricePerMonth,
              let formatter = priceFormatter else { return nil }
        return formatter.string(from: NSNumber(value: pricePerMonth))
    }
}
#else
public final class RCFuseStoreProduct: KotlinConverting<com.revenuecat.purchases.models.StoreProduct>, @unchecked Sendable {
    public let product: com.revenuecat.purchases.models.StoreProduct

    public init(product: com.revenuecat.purchases.models.StoreProduct) {
        self.product = product
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.models.StoreProduct {
        product
    }

    public var productIdentifier: String {
        return product.id
    }

    public var localizedTitle: String {
        return product.title
    }

    public var localizedDescription: String {
        return product.description
    }

    public var localizedPriceString: String {
        return product.price.formatted
    }

    public var price: Double {
        return Double(product.price.amountMicros) / 1_000_000.0
    }

    public var currencyCode: String? {
        return product.price.currencyCode
    }

    public var localizedIntroductoryPriceString: String? {
        return nil // Intro price string not directly available on Android StoreProduct
    }

    public var subscriptionPeriod: RCFuseSubscriptionPeriod? {
        guard let period = product.period else { return nil }
        let unit: RCFuseSubscriptionPeriodUnit
        switch period.unit {
        case com.revenuecat.purchases.models.Period.Unit.DAY: unit = .day
        case com.revenuecat.purchases.models.Period.Unit.WEEK: unit = .week
        case com.revenuecat.purchases.models.Period.Unit.MONTH: unit = .month
        case com.revenuecat.purchases.models.Period.Unit.YEAR: unit = .year
        default: unit = .unknown
        }
        return RCFuseSubscriptionPeriod(unit: unit, value: period.value)
    }

    public var pricePerMonth: Double? {
        guard let monthlyPrice = product.pricePerMonth() else { return nil }
        return Double(monthlyPrice.amountMicros) / 1_000_000.0
    }

    /// Returns the localized price per month string (e.g., "$4.99").
    /// On Android, formats using the product's currency code.
    public var localizedPricePerMonthString: String? {
        guard let monthlyPrice = pricePerMonth else { return nil }
        let formatter = java.text.NumberFormat.getCurrencyInstance()
        formatter.currency = java.util.Currency.getInstance(product.price.currencyCode)
        return formatter.format(monthlyPrice)
    }
}
#endif

/// Wrapper for RevenueCat `CustomerInfo`.
#if !SKIP
public final class RCFuseCustomerInfo: @unchecked Sendable {
    public let customerInfo: RevenueCat.CustomerInfo

    public init(customerInfo: RevenueCat.CustomerInfo) {
        self.customerInfo = customerInfo
    }

    public var originalAppUserId: String {
        return customerInfo.originalAppUserId
    }

    public var activeEntitlements: Set<String> {
        return Set(customerInfo.entitlements.all.values
            .filter { $0.isActive }
            .map { $0.identifier })
    }

    public var allPurchasedProductIdentifiers: Set<String> {
        return customerInfo.allPurchasedProductIdentifiers
    }

    /// The product identifiers of all currently-active subscriptions.
    /// Mirrors iOS `CustomerInfo.activeSubscriptions`.
    public var activeSubscriptions: Set<String> {
        return customerInfo.activeSubscriptions
    }

    public var firstSeen: Date {
        return customerInfo.firstSeen
    }

    public var latestExpirationDate: Date? {
        return customerInfo.latestExpirationDate
    }

    public func expirationDate(forEntitlement identifier: String) -> Date? {
        return customerInfo.expirationDate(forEntitlement: identifier)
    }

    public func purchaseDate(forEntitlement identifier: String) -> Date? {
        return customerInfo.purchaseDate(forEntitlement: identifier)
    }

    public var hasActiveEntitlements: Bool {
        return !activeEntitlements.isEmpty
    }

    public func isEntitlementActive(_ identifier: String) -> Bool {
        return customerInfo.entitlements[identifier]?.isActive == true
    }

    /// All entitlement information for the customer, both active and inactive.
    /// Mirrors iOS `CustomerInfo.entitlements: EntitlementInfos`.
    public var entitlements: RCFuseEntitlementInfos {
        return RCFuseEntitlementInfos(entitlementInfos: customerInfo.entitlements)
    }
}
#else
public final class RCFuseCustomerInfo: KotlinConverting<com.revenuecat.purchases.CustomerInfo>, @unchecked Sendable {
    public let customerInfo: com.revenuecat.purchases.CustomerInfo

    public init(customerInfo: com.revenuecat.purchases.CustomerInfo) {
        self.customerInfo = customerInfo
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.CustomerInfo {
        customerInfo
    }

    public var originalAppUserId: String {
        return customerInfo.originalAppUserId
    }

    public var activeEntitlements: Set<String> {
        return Set(customerInfo.entitlements.active.keys)
    }

    public var allPurchasedProductIdentifiers: Set<String> {
        return Set(customerInfo.allPurchasedProductIds)
    }

    /// The product identifiers of all currently-active subscriptions.
    /// Mirrors iOS `CustomerInfo.activeSubscriptions`.
    public var activeSubscriptions: Set<String> {
        return Set(customerInfo.activeSubscriptions)
    }

    public var firstSeen: Date {
        return Date(platformValue: customerInfo.firstSeen)
    }

    public var latestExpirationDate: Date? {
        guard let d = customerInfo.latestExpirationDate else { return nil }
        return Date(platformValue: d)
    }

    public func expirationDate(forEntitlement identifier: String) -> Date? {
        guard let d = customerInfo.getExpirationDateForEntitlement(identifier) else { return nil }
        return Date(platformValue: d)
    }

    public func purchaseDate(forEntitlement identifier: String) -> Date? {
        guard let d = customerInfo.getPurchaseDateForEntitlement(identifier) else { return nil }
        return Date(platformValue: d)
    }

    public var hasActiveEntitlements: Bool {
        return !customerInfo.entitlements.active.isEmpty()
    }

    public func isEntitlementActive(_ identifier: String) -> Bool {
        return customerInfo.entitlements.active.containsKey(identifier)
    }

    /// All entitlement information for the customer, both active and inactive.
    /// Mirrors iOS `CustomerInfo.entitlements: EntitlementInfos`.
    public var entitlements: RCFuseEntitlementInfos {
        return RCFuseEntitlementInfos(entitlementInfos: customerInfo.entitlements)
    }
}
#endif

/// Wrapper for RevenueCat `EntitlementInfos` — the entitlements collection on
/// a `CustomerInfo`. Mirrors iOS `RevenueCat.EntitlementInfos`: exposes `.all`
/// and `.active` as `[String: RCFuseEntitlementInfo]` plus a subscript lookup.
#if !SKIP
public final class RCFuseEntitlementInfos: @unchecked Sendable {
    public let entitlementInfos: RevenueCat.EntitlementInfos

    public init(entitlementInfos: RevenueCat.EntitlementInfos) {
        self.entitlementInfos = entitlementInfos
    }

    /// All entitlements the user has ever had access to, keyed by identifier.
    public var all: [String: RCFuseEntitlementInfo] {
        return entitlementInfos.all.mapValues { RCFuseEntitlementInfo(entitlementInfo: $0) }
    }

    /// Currently-active entitlements, keyed by identifier.
    public var active: [String: RCFuseEntitlementInfo] {
        return entitlementInfos.active.mapValues { RCFuseEntitlementInfo(entitlementInfo: $0) }
    }

    /// Look up an entitlement by identifier (active or inactive).
    /// Mirrors the iOS `EntitlementInfos` subscript via a regular method,
    /// since Skip 1.9 can't bridge custom subscripts. Swift code can still
    /// reach for `.all[id]` / `.active[id]` to stay close to the iOS shape.
    public func entitlement(forIdentifier identifier: String) -> RCFuseEntitlementInfo? {
        guard let info = entitlementInfos[identifier] else { return nil }
        return RCFuseEntitlementInfo(entitlementInfo: info)
    }
}
#else
public final class RCFuseEntitlementInfos: KotlinConverting<com.revenuecat.purchases.EntitlementInfos>, @unchecked Sendable {
    public let entitlementInfos: com.revenuecat.purchases.EntitlementInfos

    public init(entitlementInfos: com.revenuecat.purchases.EntitlementInfos) {
        self.entitlementInfos = entitlementInfos
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.EntitlementInfos {
        entitlementInfos
    }

    public var all: [String: RCFuseEntitlementInfo] {
        var result: [String: RCFuseEntitlementInfo] = [:]
        let map = entitlementInfos.all
        for key in map.keys {
            if let info = map[key] {
                result[key] = RCFuseEntitlementInfo(entitlementInfo: info)
            }
        }
        return result
    }

    public var active: [String: RCFuseEntitlementInfo] {
        var result: [String: RCFuseEntitlementInfo] = [:]
        let map = entitlementInfos.active
        for key in map.keys {
            if let info = map[key] {
                result[key] = RCFuseEntitlementInfo(entitlementInfo: info)
            }
        }
        return result
    }

    public func entitlement(forIdentifier identifier: String) -> RCFuseEntitlementInfo? {
        guard let info = entitlementInfos.all[identifier] else { return nil }
        return RCFuseEntitlementInfo(entitlementInfo: info)
    }
}
#endif

/// Wrapper for a single RevenueCat `EntitlementInfo`. Mirrors iOS
/// `RevenueCat.EntitlementInfo`.
///
/// `RCFuseCustomerInfo.activeEntitlements` flattens entitlements to a bare
/// `Set<String>`, which loses the per-entitlement detail (renewal / period /
/// store / dates) that subscription-state logic needs. This exposes that
/// detail in a cross-platform shape.
#if !SKIP
public final class RCFuseEntitlementInfo: @unchecked Sendable {
    public let entitlementInfo: RevenueCat.EntitlementInfo

    public init(entitlementInfo: RevenueCat.EntitlementInfo) {
        self.entitlementInfo = entitlementInfo
    }

    /// The entitlement identifier (e.g. "premium").
    public var identifier: String {
        return entitlementInfo.identifier
    }

    /// Whether the entitlement is currently active.
    public var isActive: Bool {
        return entitlementInfo.isActive
    }

    /// Whether the subscription backing this entitlement will auto-renew.
    public var willRenew: Bool {
        return entitlementInfo.willRenew
    }

    /// The product identifier that unlocked this entitlement.
    public var productIdentifier: String {
        return entitlementInfo.productIdentifier
    }

    /// The expiration date of the entitlement, or `nil` for lifetime entitlements.
    public var expirationDate: Date? {
        return entitlementInfo.expirationDate
    }

    /// The most recent purchase date for the entitlement, if any.
    public var latestPurchaseDate: Date? {
        return entitlementInfo.latestPurchaseDate
    }

    /// The billing period the entitlement is in (normal/intro/trial/prepaid).
    ///
    /// The pinned iOS RevenueCat (4.44.2) predates `PeriodType.prepaid`, so it is
    /// not matched here; the cross-platform `.prepaid` is only reachable from the
    /// Android branch (whose SDK has `PREPAID`). Any case this SDK adds later falls
    /// through to `.normal` until matched explicitly.
    public var periodType: RCFusePeriodType {
        switch entitlementInfo.periodType {
        case .normal: return .normal
        case .intro: return .intro
        case .trial: return .trial
        @unknown default: return .normal
        }
    }

    /// The store the entitlement was purchased through.
    public var store: RCFuseStore {
        switch entitlementInfo.store {
        case .appStore: return .appStore
        case .macAppStore: return .macAppStore
        case .playStore: return .playStore
        case .stripe: return .stripe
        case .promotional: return .promotional
        case .unknownStore: return .unknownStore
        case .amazon: return .amazon
        case .rcBilling: return .rcBilling
        case .external: return .externalStore
        @unknown default: return .unknownStore
        }
    }
}
#else
public final class RCFuseEntitlementInfo: KotlinConverting<com.revenuecat.purchases.EntitlementInfo>, @unchecked Sendable {
    public let entitlementInfo: com.revenuecat.purchases.EntitlementInfo

    public init(entitlementInfo: com.revenuecat.purchases.EntitlementInfo) {
        self.entitlementInfo = entitlementInfo
    }

    // SKIP @nooverride
    public override func kotlin(nocopy: Bool = false) -> com.revenuecat.purchases.EntitlementInfo {
        entitlementInfo
    }

    public var identifier: String {
        return entitlementInfo.identifier
    }

    public var isActive: Bool {
        return entitlementInfo.isActive
    }

    public var willRenew: Bool {
        return entitlementInfo.willRenew
    }

    public var productIdentifier: String {
        return entitlementInfo.productIdentifier
    }

    public var expirationDate: Date? {
        guard let d = entitlementInfo.expirationDate else { return nil }
        return Date(platformValue: d)
    }

    public var latestPurchaseDate: Date? {
        guard let d = entitlementInfo.latestPurchaseDate else { return nil }
        return Date(platformValue: d)
    }

    // The Kotlin enums stringify to their UPPER_SNAKE_CASE `name`; match the same
    // idiom used by `RCFusePackage.packageType` rather than pattern-matching the
    // Kotlin enum cases directly.
    public var periodType: RCFusePeriodType {
        let name = "\(entitlementInfo.periodType)"
        switch name {
        case "NORMAL": return .normal
        case "INTRO": return .intro
        case "TRIAL": return .trial
        case "PREPAID": return .prepaid
        default: return .normal
        }
    }

    public var store: RCFuseStore {
        let name = "\(entitlementInfo.store)"
        switch name {
        case "APP_STORE": return .appStore
        case "MAC_APP_STORE": return .macAppStore
        case "PLAY_STORE": return .playStore
        case "STRIPE": return .stripe
        case "PROMOTIONAL": return .promotional
        case "AMAZON": return .amazon
        case "RC_BILLING": return .rcBilling
        case "EXTERNAL": return .externalStore
        // UNKNOWN_STORE plus Android-only PADDLE/TEST_STORE have no iOS ordinal.
        default: return .unknownStore
        }
    }
}
#endif

// MARK: - RevenueCat service
//
// Service facade that proxies to `Purchases.shared` (iOS) / `Purchases.sharedInstance`
// (Android). Mirrors iOS `RevenueCat.Purchases` static methods. Stateless — the
// underlying SDK owns its singleton; `RevenueCatFuse.shared` is just a struct
// handle so call-sites read `RevenueCatFuse.shared.X()` for iOS-parity feel.
//
// NOTE: this type intentionally does NOT extend `KotlinConverting<Purchases>`.
// `Purchases.sharedInstance` only exists *after* `configure()` is called, and
// `configure()` itself is reached via `RevenueCatFuse.shared.configure(...)` —
// holding a Kotlin reference at `shared`-construction time would be a chicken-
// and-egg. Wrapping a SDK reference is appropriate for the wrapper *types*
// above (Offerings/Package/CustomerInfo) which are constructed from already-
// returned SDK objects, but not for the service entry point.

/// Service wrapper for RevenueCat. Returns wrapper objects for cross-platform
/// compatibility. Mirrors iOS `RevenueCat.Purchases` static methods.
public struct RevenueCatFuse: @unchecked Sendable {
    public static let shared = RevenueCatFuse()

    private init() {}

    /// Configure the RevenueCat SDK with the given API key.
    ///
    /// Call this early in your app's lifecycle, typically in your `App` init.
    /// Use the platform-specific API key from your RevenueCat dashboard.
    public func configure(apiKey: String) {
        #if !SKIP
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        #else
        Purchases.debugLogsEnabled = true
        let context = ProcessInfo.processInfo.androidContext
        let builder = PurchasesConfiguration.Builder(context, apiKey)
        let config = builder.build()
        Purchases.configure(config)
        #endif
    }

    /// Configure the RevenueCat SDK with an API key and an app user ID.
    public func configure(apiKey: String, appUserID: String) {
        #if !SKIP
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
        #else
        Purchases.debugLogsEnabled = true
        let context = ProcessInfo.processInfo.androidContext
        let builder = PurchasesConfiguration.Builder(context, apiKey).appUserID(appUserID)
        let config = builder.build()
        Purchases.configure(config)
        #endif
    }

    /// Log in a user with the given user ID. Mirrors iOS `Purchases.logIn(_:)`.
    public func loginUser(userId: String) async throws {
        #if !SKIP
        let _ = try await Purchases.shared.logIn(userId)
        #else
        let _ = Purchases.sharedInstance.awaitLogIn(userId)
        #endif
    }

    /// Log out the current user, reverting to an anonymous ID. Mirrors iOS `Purchases.logOut()`.
    public func logoutUser() async throws {
        #if !SKIP
        let _ = try await Purchases.shared.logOut()
        #else
        let _ = Purchases.sharedInstance.awaitLogOut()
        #endif
    }

    /// Whether the SDK is configured and ready to use.
    public var isConfigured: Bool {
        #if !SKIP
        return Purchases.isConfigured
        #else
        return Purchases.isConfigured
        #endif
    }

    /// The current app user ID, whether anonymous or identified.
    public var appUserID: String {
        #if !SKIP
        return Purchases.shared.appUserID
        #else
        return Purchases.sharedInstance.appUserID
        #endif
    }

    /// Whether the current user is anonymous.
    public var isAnonymous: Bool {
        #if !SKIP
        return Purchases.shared.isAnonymous
        #else
        return Purchases.sharedInstance.isAnonymous
        #endif
    }

    /// Load all offerings from RevenueCat. Mirrors iOS `Purchases.offerings()`.
    public func loadOfferings() async throws -> RCFuseOfferings {
        #if !SKIP
        let offerings = try await Purchases.shared.offerings()
        return RCFuseOfferings(offerings: offerings)
        #else
        let offerings = Purchases.sharedInstance.awaitOfferings()
        return RCFuseOfferings(offerings: offerings)
        #endif
    }

    /// Load packages from a specific offering.
    public func loadProducts(offeringIdentifier: String? = nil) async throws -> [RCFusePackage] {
        #if !SKIP
        let offerings = try await Purchases.shared.offerings()
        let offering = offeringIdentifier != nil ? offerings.offering(identifier: offeringIdentifier!) : offerings.current

        guard let packages = offering?.availablePackages else {
            throw StoreError.noProductsAvailable
        }

        guard packages.count > 0 else {
            throw StoreError.noProductsAvailable
        }

        return packages.map { RCFusePackage(package: $0) }
        #else
        let offerings = Purchases.sharedInstance.awaitOfferings()
        let offering = offeringIdentifier != nil ? offerings.all[offeringIdentifier!] : offerings.current

        guard let packages = offering?.availablePackages else {
            throw StoreError.noProductsAvailable
        }

        guard packages.size > 0 else {
            throw StoreError.noProductsAvailable
        }

        return Array(packages.map { RCFusePackage(package: $0) })
        #endif
    }

    // `purchase` has divergent platform signatures (iOS doesn't need an
    // Activity; Android does). Both signatures are emitted by their respective
    // `#if` branch — the bridge generator only sees the Skip-side body (because
    // the entire file is inside `#if !SKIP_BRIDGE`) and emits a JNI-forwarding
    // bridge for `purchase(package:activity:)`; the iOS overload only matters
    // for iOS callers.

    #if !SKIP
    /// Purchase a package (iOS). Mirrors iOS `Purchases.purchase(package:)`.
    public func purchase(package: RCFusePackage) async throws -> RCFuseCustomerInfo {
        let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package.package)

        if userCancelled {
            throw StoreError.userCancelled
        }

        return RCFuseCustomerInfo(customerInfo: customerInfo)
    }
    #else
    /// Purchase a package (Android) — requires the host `Activity`, wrapped in
    /// `RCFuseAndroidActivity` so the bridge thunk can capture it across a
    /// `Task { ... }` boundary under Swift 6 strict concurrency.
    public func purchase(package: RCFusePackage, activity: RCFuseAndroidActivity) async throws -> RCFuseCustomerInfo {
        guard let androidActivity = activity.activity as? android.app.Activity else {
            throw StoreError.unknown
        }

        let kotlinPackage = package.kotlin()
        let params = PurchaseParams.Builder(androidActivity, kotlinPackage).build()

        do {
            let result = Purchases.sharedInstance.awaitPurchase(params)
            return RCFuseCustomerInfo(customerInfo: result.customerInfo)
        } catch let error as PurchasesTransactionException {
            if error.userCancelled {
                throw StoreError.userCancelled
            }
            throw error
        }
    }
    #endif

    /// Restore purchases. Mirrors iOS `Purchases.restorePurchases()`.
    public func restorePurchases() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.restorePurchases()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitRestore()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #endif
    }

    /// A stream of `RCFuseCustomerInfo` updates, emitted whenever RevenueCat
    /// reports a change to the current customer's entitlements (purchase,
    /// restore, renewal, etc.). Mirrors iOS `Purchases.customerInfoStream`.
    ///
    /// On iOS this maps the native `AsyncStream<CustomerInfo>` element-by-
    /// element into wrapper objects. On Android, where RevenueCat exposes only
    /// the imperative `updatedCustomerInfoListener`, we adapt that listener
    /// into a Swift `AsyncStream` whose `continuation.yield()` is driven by
    /// `onReceived`, and tear the listener down in `onTermination`.
    ///
    /// Caveat (Android): `Purchases` holds a *single*
    /// `updatedCustomerInfoListener`, so subscribing to this stream installs
    /// that one listener — creating a second stream replaces the first, and
    /// termination clears whatever listener is currently set. This matches
    /// how the Android app typically consumes customer-info updates (one
    /// observer), but is not the multicast semantics iOS offers.
    ///
    /// `// SKIP @nobridge` because `AsyncStream<T>` isn't supported by the
    /// Skip 1.9 bridge generator. Swift callers use it directly; Kotlin code
    /// can install its own `updatedCustomerInfoListener` against the native
    /// `Purchases` instance if needed.
    // SKIP @nobridge
    public var customerInfoStream: AsyncStream<RCFuseCustomerInfo> {
        #if !SKIP
        let upstream = Purchases.shared.customerInfoStream
        return AsyncStream<RCFuseCustomerInfo> { continuation in
            let task = Task {
                for await info in upstream {
                    continuation.yield(RCFuseCustomerInfo(customerInfo: info))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
        #else
        let (stream, continuation) = AsyncStream.makeStream(of: RCFuseCustomerInfo.self)
        let purchases = Purchases.sharedInstance
        purchases.updatedCustomerInfoListener = CustomerInfoStreamListener { info in
            continuation.yield(RCFuseCustomerInfo(customerInfo: info))
        }
        continuation.onTermination = { _ in
            purchases.removeUpdatedCustomerInfoListener()
        }
        return stream
        #endif
    }

    /// Sync the user's purchases with RevenueCat's servers. Mirrors iOS
    /// `Purchases.shared.syncPurchases()`.
    ///
    /// Forces a refresh of the customer's entitlements from the store and the
    /// RevenueCat backend — useful after a restore on a new device or to
    /// reconcile transactions that completed outside the normal purchase flow.
    public func syncPurchases() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.syncPurchases()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitSyncPurchases()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #endif
    }

    /// Get current customer info. Mirrors iOS `Purchases.customerInfo()`.
    public func getCustomerInfo() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.customerInfo()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitCustomerInfo()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #endif
    }

    /// Set subscriber attributes for the current user.
    public func setAttributes(_ attributes: [String: String]) {
        #if !SKIP
        Purchases.shared.setAttributes(attributes)
        #else
        var nullableMap: MutableMap<String, String?> = mutableMapOf()
        for (key, value) in attributes {
            nullableMap[key] = value
        }
        // SKIP INSERT: com.revenuecat.purchases.Purchases.sharedInstance.setAttributes(nullableMap as Map<String, String?>)
        #endif
    }

    /// Set the user's email address.
    public func setEmail(_ email: String) {
        #if !SKIP
        Purchases.shared.setEmail(email)
        #else
        Purchases.sharedInstance.setEmail(email)
        #endif
    }

    /// Set the user's display name.
    public func setDisplayName(_ displayName: String) {
        #if !SKIP
        Purchases.shared.setDisplayName(displayName)
        #else
        Purchases.sharedInstance.setDisplayName(displayName)
        #endif
    }

    /// Check trial or intro discount eligibility for products. Returns a dictionary
    /// mapping product identifiers to their eligibility status.
    ///
    /// iOS: Uses native RevenueCat API.
    /// Android: Checks if user has ever had any entitlement (if so, not eligible
    /// for intro). Google Play handles eligibility automatically — if an offer
    /// appears in offerings, the user is eligible for it. This mirrors iOS
    /// behavior at the cost of a heuristic on Android.
    public func checkTrialOrIntroEligibility(productIdentifiers: [String]) async throws -> [String: RCFuseIntroEligibility] {
        #if !SKIP
        let eligibility = await Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
        var result: [String: RCFuseIntroEligibility] = [:]
        for (productId, intro) in eligibility {
            let status: RCFuseIntroEligibilityStatus
            switch intro.status {
            case .unknown:
                status = .unknown
            case .ineligible:
                status = .ineligible
            case .eligible:
                status = .eligible
            case .noIntroOfferExists:
                status = .noIntroOfferExists
            @unknown default:
                status = .unknown
            }
            result[productId] = RCFuseIntroEligibility(status: status)
        }
        return result
        #else
        let customerInfo = Purchases.sharedInstance.awaitCustomerInfo()
        let hasAnyEntitlementHistory = customerInfo.entitlements.all.size > 0

        var result: [String: RCFuseIntroEligibility] = [:]
        for productId in productIdentifiers {
            let status: RCFuseIntroEligibilityStatus = hasAnyEntitlementHistory ? .ineligible : .eligible
            result[productId] = RCFuseIntroEligibility(status: status)
        }
        return result
        #endif
    }
}

#if SKIP
/// Adapts a Swift closure to RevenueCat Android's `UpdatedCustomerInfoListener`
/// single-abstract-method interface so `RevenueCatFuse.customerInfoStream` can
/// drive an `AsyncStream` continuation from `onReceived`. Mirrors the
/// `OnNewIntentListener : Consumer<Intent>` adapter pattern used elsewhere for
/// bridging Kotlin/Java listener interfaces to Swift closures.
///
/// `// SKIP @nobridge` because the superclass `UpdatedCustomerInfoListener`
/// is a Kotlin interface visible only under `#if SKIP`; the bridge generator
/// would otherwise emit an `override` referencing an Android type that the
/// bridge pass can't resolve.
// SKIP @nobridge
final class CustomerInfoStreamListener: UpdatedCustomerInfoListener {
    let onInfo: (com.revenuecat.purchases.CustomerInfo) -> Void

    init(onInfo: @escaping (com.revenuecat.purchases.CustomerInfo) -> Void) {
        self.onInfo = onInfo
    }

    override func onReceived(customerInfo: com.revenuecat.purchases.CustomerInfo) {
        onInfo(customerInfo)
    }
}
#endif

#endif // !SKIP_BRIDGE

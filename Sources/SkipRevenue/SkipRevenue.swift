// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0

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
import com.revenuecat.purchases.awaitCustomerInfo
import com.revenuecat.purchases.awaitOfferings
import com.revenuecat.purchases.awaitLogIn
import com.revenuecat.purchases.awaitLogOut
import com.revenuecat.purchases.awaitPurchase
import com.revenuecat.purchases.awaitRestore
import com.revenuecat.purchases.models.Period
#endif

// MARK: - Wrapper Classes

/// Wrapper for RevenueCat Offerings
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

/// Wrapper for RevenueCat Offering
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

    /// The lifetime package in this offering, if available.
    public var lifetime: RCFusePackage? {
        guard let pkg = offering.lifetime else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The annual package in this offering, if available.
    public var annual: RCFusePackage? {
        guard let pkg = offering.annual else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The six-month package in this offering, if available.
    public var sixMonth: RCFusePackage? {
        guard let pkg = offering.sixMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The three-month package in this offering, if available.
    public var threeMonth: RCFusePackage? {
        guard let pkg = offering.threeMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The two-month package in this offering, if available.
    public var twoMonth: RCFusePackage? {
        guard let pkg = offering.twoMonth else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The monthly package in this offering, if available.
    public var monthly: RCFusePackage? {
        guard let pkg = offering.monthly else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// The weekly package in this offering, if available.
    public var weekly: RCFusePackage? {
        guard let pkg = offering.weekly else { return nil }
        return RCFusePackage(package: pkg)
    }

    /// Returns the package with the given identifier, or `nil`.
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

/// The type of a RevenueCat package.
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

/// Subscription period unit enum
public enum RCFuseSubscriptionPeriodUnit: Int, Sendable {
    case day = 0
    case week = 1
    case month = 2
    case year = 3
    case unknown = 4
}

/// Wrapper for RevenueCat SubscriptionPeriod
public struct RCFuseSubscriptionPeriod: Sendable {
    public let unit: RCFuseSubscriptionPeriodUnit
    public let value: Int

    public init(unit: RCFuseSubscriptionPeriodUnit, value: Int) {
        self.unit = unit
        self.value = value
    }
}

/// Wrapper for RevenueCat Package
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

/// Wrapper for RevenueCat StoreProduct
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

    /// Returns a NumberFormatter configured for the product's locale (iOS only)
    /// On Android, use localizedPriceString or format prices manually
    public var priceFormatter: NumberFormatter? {
        return product.priceFormatter
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
        guard let period = product.period else { return nil }
        let totalPrice = price
        switch period.unit {
        case com.revenuecat.purchases.models.Period.Unit.YEAR:
            return totalPrice / Double(period.value * 12)
        case com.revenuecat.purchases.models.Period.Unit.MONTH:
            return totalPrice / Double(period.value)
        case com.revenuecat.purchases.models.Period.Unit.WEEK:
            return totalPrice * (52.0 / 12.0) / Double(period.value)
        case com.revenuecat.purchases.models.Period.Unit.DAY:
            return totalPrice * (365.0 / 12.0) / Double(period.value)
        default:
            return nil
        }
    }
}
#endif

/// Wrapper for RevenueCat CustomerInfo
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

    /// The date this user was first seen by RevenueCat.
    public var firstSeen: Date {
        return customerInfo.firstSeen
    }

    /// The latest expiration date of any active entitlement, if any.
    public var latestExpirationDate: Date? {
        return customerInfo.latestExpirationDate
    }

    /// Returns the expiration date for the given entitlement identifier, or `nil`.
    public func expirationDate(forEntitlement identifier: String) -> Date? {
        return customerInfo.expirationDate(forEntitlement: identifier)
    }

    /// Returns the purchase date for the given entitlement identifier, or `nil`.
    public func purchaseDate(forEntitlement identifier: String) -> Date? {
        return customerInfo.purchaseDate(forEntitlement: identifier)
    }

    /// Whether the user has any active entitlements.
    public var hasActiveEntitlements: Bool {
        return !activeEntitlements.isEmpty
    }

    /// Checks whether the user has an active entitlement with the given identifier.
    public func isEntitlementActive(_ identifier: String) -> Bool {
        return customerInfo.entitlements[identifier]?.isActive == true
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
}
#endif

// MARK: - RevenueCat Service

/// RevenueCat service for purchases and subscriptions.
/// Returns wrapper objects for cross-platform compatibility.
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
    ///
    /// Use this when you want to identify the user at configuration time.
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

    /// Log in a user with the given user ID.
    ///
    /// If the user ID is different from the current one, the SDK will create a new user
    /// or switch to an existing one, transferring purchases as needed.
    public func loginUser(userId: String) async throws {
        #if !SKIP
        let _ = try await Purchases.shared.logIn(userId)
        #else
        let _ = Purchases.sharedInstance.awaitLogIn(userId)
        #endif
    }

    /// Log out the current user, reverting to an anonymous ID.
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

    /// Load all offerings from RevenueCat.
    /// Returns wrapped Offerings object with full data.
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
    /// Returns wrapped Package objects with full data.
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

    #if !SKIP
    /// Purchase a package (iOS).
    public func purchase(package: RCFusePackage) async throws -> RCFuseCustomerInfo {
        let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package.package)

        if userCancelled {
            throw StoreError.userCancelled
        }

        return RCFuseCustomerInfo(customerInfo: customerInfo)
    }
    #else
    /// Purchase a package (Android) — requires Activity.
    public func purchase(package: RCFusePackage, activity: Any) async throws -> RCFuseCustomerInfo {
        guard let androidActivity = activity as? android.app.Activity else {
            throw StoreError.unknown
        }

        // Convert to Kotlin type
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

    /// Restore purchases.
    /// Returns wrapped CustomerInfo object.
    public func restorePurchases() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.restorePurchases()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitRestore()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #endif
    }

    /// Get current customer info.
    /// Returns wrapped CustomerInfo object.
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
    ///
    /// These are key-value pairs that are synced to RevenueCat and can be used for
    /// analytics, integrations, and customer segmentation.
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

#endif // !SKIP_BRIDGE

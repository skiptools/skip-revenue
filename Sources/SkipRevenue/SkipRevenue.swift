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

    public var availablePackages: [RCFusePackage] {
        return offering.availablePackages.map { RCFusePackage(package: $0) }
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

    public var availablePackages: [RCFusePackage] {
        return Array(offering.availablePackages.map { RCFusePackage(package: $0) })
    }
}
#endif

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

    public var storeProduct: RCFuseStoreProduct {
        return RCFuseStoreProduct(product: package.storeProduct)
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

    public var storeProduct: RCFuseStoreProduct {
        return RCFuseStoreProduct(product: package.product)
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

    public var localizedPriceString: String {
        return product.localizedPriceString
    }

    public var price: Double {
        return Double(truncating: product.price as NSNumber)
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

    /// Returns the localized price per month string (e.g., "$4.99")
    /// Uses the product's price formatter for proper locale formatting
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

    public var localizedPriceString: String {
        return product.price.formatted
    }

    public var price: Double {
        return Double(product.price.amountMicros) / 1_000_000.0
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

    /// Returns the localized price per month string (e.g., "$4.99")
    /// On Android, formats using the product's currency code
    public var localizedPricePerMonthString: String? {
        guard let monthlyPrice = pricePerMonth else { return nil }
        // Use Android's NumberFormat with the product's currency
        let formatter = java.text.NumberFormat.getCurrencyInstance()
        formatter.currency = java.util.Currency.getInstance(product.price.currencyCode)
        return formatter.format(monthlyPrice)
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
}
#endif

// MARK: - RevenueCat Service

/// RevenueCat service for purchases and subscriptions
/// Returns wrapper objects for cross-platform compatibility
public struct RevenueCatFuse: @unchecked Sendable {
    public static let shared = RevenueCatFuse()

    private init() {}

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

    public func loginUser(userId: String) async throws {
        #if !SKIP
        let _ = try await Purchases.shared.logIn(userId)
        #else
        let _ = Purchases.sharedInstance.awaitLogIn(userId)
        #endif
    }

    public func logoutUser() async throws {
        #if !SKIP
        let _ = try await Purchases.shared.logOut()
        #else
        let _ = Purchases.sharedInstance.awaitLogOut()
        #endif
    }

    /// Load all offerings from RevenueCat
    /// Returns wrapped Offerings object with full data
    public func loadOfferings() async throws -> RCFuseOfferings {
        #if !SKIP
        let offerings = try await Purchases.shared.offerings()
        return RCFuseOfferings(offerings: offerings)
        #else
        let offerings = Purchases.sharedInstance.awaitOfferings()
        return RCFuseOfferings(offerings: offerings)
        #endif
    }

    /// Load packages from a specific offering
    /// Returns wrapped Package objects with full data
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
    /// Purchase a package (iOS)
    public func purchase(package: RCFusePackage) async throws -> RCFuseCustomerInfo {
        let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package.package)

        if userCancelled {
            throw StoreError.userCancelled
        }

        return RCFuseCustomerInfo(customerInfo: customerInfo)
    }
    #else
    /// Purchase a package (Android) - requires Activity
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

    /// Restore purchases
    /// Returns wrapped CustomerInfo object
    public func restorePurchases() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.restorePurchases()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitRestore()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #endif
    }

    /// Get current customer info
    /// Returns wrapped CustomerInfo object
    public func getCustomerInfo() async throws -> RCFuseCustomerInfo {
        #if !SKIP
        let customerInfo = try await Purchases.shared.customerInfo()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
        #else
        let customerInfo = Purchases.sharedInstance.awaitCustomerInfo()
        return RCFuseCustomerInfo(customerInfo: customerInfo)
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
}

extension StoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .userCancelled: return "User cancelled"
        case .unknown: return "Unknown error"
        case .noPurchasesFound: return "No purchases found"
        case .noProductsAvailable: return "No products available"
        case .packageNotFound: return "Package not found"
        }
    }
}

#endif // !SKIP_BRIDGE

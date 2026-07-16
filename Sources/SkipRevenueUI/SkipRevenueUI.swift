// Copyright 2023–2026 Skip
// SPDX-License-Identifier: MPL-2.0

#if !SKIP_BRIDGE
import Foundation
import SwiftUI
import SkipRevenue
#if !SKIP
import RevenueCat
import RevenueCatUI
#else
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.models.StoreTransaction
import com.revenuecat.purchases.ui.revenuecatui.Paywall
import com.revenuecat.purchases.ui.revenuecatui.PaywallOptions
import com.revenuecat.purchases.ui.revenuecatui.PaywallListener
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.background
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
#endif

// MARK: - Paywall View Wrapper

/// SwiftUI/Compose view wrapper for the RevenueCat Paywall.
///
/// - iOS: Wraps `RevenueCatUI.PaywallView` (presented fullscreen by the caller).
/// - Android: Embeds RevenueCat's `Paywall(options)` composable via Skip's
///   `ComposeView { Composer(...) }` bridge — the Skip-1.9 replacement for
///   the old `@Composable override func ComposeContent(context:)` shape.
///
/// Callbacks fire with the customer's user ID after purchase/restore completion.
///
/// Annotated `// SKIP @nobridge` because optional closure parameters
/// (`((String) -> Void)?`) trip the Skip 1.9 bridge generator's cast logic.
/// Use the SwiftUI surface directly from Swift; if Kotlin needs to embed this
/// view, expose a non-generic, non-optional-closure wrapper alongside it.
// SKIP @nobridge
public struct RCFusePaywallView: View {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: ((String) -> Void)?
    let onRestoreCompleted: ((String) -> Void)?
    let onDismiss: (() -> Void)?

    public init(
        offering: RCFuseOffering? = nil,
        onPurchaseCompleted: ((String) -> Void)? = nil,
        onRestoreCompleted: ((String) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.offering = offering
        self.onPurchaseCompleted = onPurchaseCompleted
        self.onRestoreCompleted = onRestoreCompleted
        self.onDismiss = onDismiss
    }

    public var body: some View {
        #if os(Android)
        ComposeView {
            RCFusePaywallComposer(
                offering: offering,
                onPurchaseCompleted: onPurchaseCompleted,
                onRestoreCompleted: onRestoreCompleted,
                onDismiss: onDismiss
            )
        }
        #elseif os(iOS) || os(macOS)
        PaywallViewWrapper(
            offering: offering,
            onPurchaseCompleted: { customerInfo in
                onPurchaseCompleted?(customerInfo.originalAppUserId)
            },
            onRestoreCompleted: { customerInfo in
                onRestoreCompleted?(customerInfo.originalAppUserId)
            }
        )
        #else
        EmptyView()
        #endif
    }
}

#if !SKIP && (os(iOS) || os(macOS))
/// Apple-platform bridge to RevenueCatUI's `PaywallView`.
///
/// macOS is supported from RevenueCat 5.x onward (`PaywallView` is
/// `@available(macOS 12.0, *)`); in 4.x it was `@available(macOS, unavailable)`.
@available(iOS 15.0, macOS 12.0, *)
private struct PaywallViewWrapper: View {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: ((RevenueCat.CustomerInfo) -> Void)?
    let onRestoreCompleted: ((RevenueCat.CustomerInfo) -> Void)?

    var body: some View {
        Group {
            if let offering {
                PaywallView(offering: offering.offering)
                    .onPurchaseCompleted { customerInfo in
                        onPurchaseCompleted?(customerInfo)
                    }
                    .onRestoreCompleted { customerInfo in
                        onRestoreCompleted?(customerInfo)
                    }
            } else {
                EmptyView()
            }
        }
    }
}
#endif

// MARK: - Android Compose integration

#if SKIP
/// Composer that hosts RevenueCat's `Paywall(options)` composable inside Skip's
/// `ComposeView`. Built per the Skip-1.9 pattern: `ContentComposer` struct with
/// a `@Composable override func Compose(context:)` — `ComposeContext` is no
/// longer surfaced through `View` directly, so the body uses
/// `ComposeView { RCFusePaywallComposer(...) }` to forward into Compose.
struct RCFusePaywallComposer: ContentComposer {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: ((String) -> Void)?
    let onRestoreCompleted: ((String) -> Void)?
    let onDismiss: (() -> Void)?

    @Composable override func Compose(context: ComposeContext) {
        let dismissCallback = onDismiss ?? {}
        var builder = PaywallOptions.Builder(dismissCallback)

        if let offering {
            builder = builder.setOffering(offering.offering)
        }

        if onPurchaseCompleted != nil || onRestoreCompleted != nil {
            // SKIP INSERT: val listener = object : PaywallListener {
            // SKIP INSERT:     override fun onPurchaseCompleted(customerInfo: CustomerInfo, storeTransaction: StoreTransaction) {
            if let onPurchaseCompleted {
                // SKIP INSERT:         onPurchaseCompleted(customerInfo.originalAppUserId)
                onPurchaseCompleted("") // Placeholder for Swift compilation
            }
            // SKIP INSERT:     }
            // SKIP INSERT:     override fun onRestoreCompleted(customerInfo: CustomerInfo) {
            if let onRestoreCompleted {
                // SKIP INSERT:         onRestoreCompleted(customerInfo.originalAppUserId)
                onRestoreCompleted("") // Placeholder for Swift compilation
            }
            // SKIP INSERT:     }
            // SKIP INSERT: }
            // SKIP INSERT: builder = builder.setListener(listener)
        }

        builder = builder.setShouldDisplayDismissButton(true)
        let options = builder.build()

        // SKIP REPLACE: androidx.compose.foundation.layout.Box(
        // SKIP REPLACE:     modifier = androidx.compose.ui.Modifier
        // SKIP REPLACE:         .fillMaxSize()
        // SKIP REPLACE:         .background(androidx.compose.ui.graphics.Color(0xFF20003C))
        // SKIP REPLACE:         .systemBarsPadding()
        // SKIP REPLACE: ) {
        // SKIP REPLACE:     com.revenuecat.purchases.ui.revenuecatui.Paywall(options)
        // SKIP REPLACE: }
        Paywall(options)
    }
}
#endif

#endif // !SKIP_BRIDGE

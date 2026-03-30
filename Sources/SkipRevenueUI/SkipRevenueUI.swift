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

/// SwiftUI/Compose view wrapper for RevenueCat Paywall
///
/// This view presents a fullscreen paywall UI using RevenueCat's native paywall components.
/// - iOS: Uses PaywallView presented in a sheet or fullScreenCover
/// - Android: Uses Paywall composable (fullscreen, not dialog)
/// Callbacks provide the customer's user ID after purchase/restore completion.
public struct RCFusePaywallView: View {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: ((String) -> Void)?  // Returns customer user ID
    let onRestoreCompleted: ((String) -> Void)?   // Returns customer user ID
    let onDismiss: (() -> Void)?  // Called when user dismisses paywall (X button tap)

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

    #if !SKIP
    public var body: some View {
        #if os(iOS)
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
    #else
    // SKIP @nobridge
    @Composable override func ComposeContent(context: ComposeContext) {
        // Build fullscreen paywall options
        // PaywallOptions.Builder requires dismissRequest as constructor parameter
        let dismissCallback = onDismiss ?? {}
        var builder = PaywallOptions.Builder(dismissCallback)

        // Set offering if provided - use the native offering from RCFuseOffering
        if let offering {
            builder = builder.setOffering(offering.offering)
        }

        // Set listener for purchase/restore events
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

        // Enable built-in dismiss button
        builder = builder.setShouldDisplayDismissButton(true)

        let options = builder.build()

        // SKIP REPLACE: Box(
        // SKIP REPLACE:     modifier = Modifier
        // SKIP REPLACE:         .fillMaxSize()
        // SKIP REPLACE:         .background(Color(0xFF20003C)) // Dark purple background to match paywall
        // SKIP REPLACE:         .systemBarsPadding()
        // SKIP REPLACE: ) {
        // SKIP REPLACE:     Paywall(options)
        // SKIP REPLACE: }
        Paywall(options)
    }
    #endif
}

#if !SKIP && os(iOS)
// iOS-specific wrapper to handle offering loading
@available(iOS 15.0, *)
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

#endif // !SKIP_BRIDGE

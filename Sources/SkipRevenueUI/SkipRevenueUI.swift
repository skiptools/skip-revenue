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
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import com.revenuecat.purchases.ui.revenuecatui.Paywall
import com.revenuecat.purchases.ui.revenuecatui.PaywallOptions
import com.revenuecat.purchases.ui.revenuecatui.PaywallListener
import com.revenuecat.purchases.ui.debugview.DebugRevenueCatBottomSheet
#endif

// MARK: - Paywall View Wrapper

/// SwiftUI/Compose view wrapper for the RevenueCat Paywall.
///
/// - iOS: Wraps `RevenueCatUI.PaywallView` (presented fullscreen by the caller).
/// - Android: Embeds RevenueCat's `Paywall(options)` composable via `ComposeView`.
///   Skip Lite calls the composable directly; Skip Fuse forwards through a
///   `ContentComposer` bridge.
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
        PaywallViewWrapper(
            offering: offering,
            onPurchaseCompleted: onPurchaseCompleted,
            onRestoreCompleted: onRestoreCompleted,
            onDismiss: onDismiss
        )
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

/// Bridgeable companion to ``RCFusePaywallView``.
///
/// ``RCFusePaywallView`` is `// SKIP @nobridge` — its optional closure
/// parameters trip the Skip 1.9 bridge generator, so it cannot be referenced
/// across the bridge boundary by a native-mode Skip Fuse app. This wrapper
/// takes **non-optional** closures (which bridge cleanly) and forwards to
/// ``RCFusePaywallView`` internally — same module, so no boundary crossing on
/// that reference. Native app code should present this type.
public struct RCFusePaywall: View {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: (String) -> Void
    let onRestoreCompleted: (String) -> Void
    let onDismiss: () -> Void

    public init(
        offering: RCFuseOffering? = nil,
        onPurchaseCompleted: @escaping (String) -> Void = { _ in },
        onRestoreCompleted: @escaping (String) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.offering = offering
        self.onPurchaseCompleted = onPurchaseCompleted
        self.onRestoreCompleted = onRestoreCompleted
        self.onDismiss = onDismiss
    }

    public var body: some View {
        RCFusePaywallView(
            offering: offering,
            onPurchaseCompleted: onPurchaseCompleted,
            onRestoreCompleted: onRestoreCompleted,
            onDismiss: onDismiss
        )
    }
}

/// Cross-platform debug overlay modifier for RevenueCat's native debug UI.
/// The `skipRevenue` prefix avoids overload ambiguity with RevenueCat's own
/// Apple-platform `debugRevenueCatOverlay` extension.
public extension View {
    func skipRevenueDebugOverlay() -> some View {
        self.skipRevenueDebugOverlay(isPresented: .constant(true))
    }

    func skipRevenueDebugOverlay(isPresented: Binding<Bool>) -> some View {
        self.modifier(RevenueCatDebugOverlayModifier(isPresented: isPresented))
    }
}

private struct RevenueCatDebugOverlayModifier: ViewModifier {
    let isPresented: Binding<Bool>

    func body(content: Content) -> some View {
        #if os(Android)
        content.overlay {
            DebugOverlayView(isPresented: isPresented)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
        #elseif os(iOS) || os(macOS)
        #if !SKIP
        content.revenueCatDebugOverlayIfAvailable(isPresented: isPresented)
        #else
        content
        #endif
        #else
        content
        #endif
    }
}

#if !SKIP
#if os(iOS) || os(macOS)
private extension View {
    @ViewBuilder
    func revenueCatDebugOverlayIfAvailable(isPresented: Binding<Bool>) -> some View {
        #if DEBUG
        self.debugRevenueCatOverlay(isPresented: isPresented)
        #else
        self
        #endif
    }
}

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
#endif

// MARK: - Android Compose integration

#if os(Android)
/// Android paywall host shared by Skip Lite and Skip Fuse builds.
/// Lite can call Compose directly from `ComposeView`; Fuse still needs a
/// `ContentComposer` because native-mode SwiftUI crosses into Kotlin Compose
/// through the generated bridge.
private struct PaywallViewWrapper: View {
    let offering: RCFuseOffering?
    let onPurchaseCompleted: ((String) -> Void)?
    let onRestoreCompleted: ((String) -> Void)?
    let onDismiss: (() -> Void)?

    var body: some View {
        #if SKIP
        ComposeView { _ in
            composeRevenueCatPaywall(
                offering: offering,
                onPurchaseCompleted: onPurchaseCompleted,
                onRestoreCompleted: onRestoreCompleted,
                onDismiss: onDismiss
            )
        }
        #else
        ComposeView {
            RCFusePaywallComposer(
                offering: offering,
                onPurchaseCompleted: onPurchaseCompleted,
                onRestoreCompleted: onRestoreCompleted,
                onDismiss: onDismiss
            )
        }
        #endif
    }
}

private struct DebugOverlayView: View {
    let isPresented: Binding<Bool>

    var body: some View {
        #if SKIP
        ComposeView { _ in
            composeRevenueCatDebugOverlay(
                isPresented: isPresented.wrappedValue,
                onDismissCallback: {
                    isPresented.wrappedValue = false
                }
            )
        }
        #else
        ComposeView {
            RevenueCatDebugOverlayComposer(
                isPresented: isPresented.wrappedValue,
                onDismissCallback: {
                    isPresented.wrappedValue = false
                }
            )
        }
        #endif
    }
}
#endif

#if SKIP
@Composable private func composeRevenueCatDebugOverlay(isPresented: Bool, onDismissCallback: @escaping () -> Void) {
    // SKIP REPLACE: com.revenuecat.purchases.ui.debugview.DebugRevenueCatBottomSheet(
    // SKIP REPLACE:     onPurchaseCompleted = { },
    // SKIP REPLACE:     onPurchaseErrored = { _ -> },
    // SKIP REPLACE:     isVisible = isPresented,
    // SKIP REPLACE:     onDismissCallback = onDismissCallback
    // SKIP REPLACE: )
    DebugRevenueCatBottomSheet(
        isVisible: isPresented,
        onDismissCallback: onDismissCallback
    )
}

@Composable private func composeRevenueCatPaywall(
    offering: RCFuseOffering?,
    onPurchaseCompleted: ((String) -> Void)?,
    onRestoreCompleted: ((String) -> Void)?,
    onDismiss: (() -> Void)?
) {
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
    // SKIP REPLACE:     modifier = androidx.compose.ui.Modifier.fillMaxSize()
    // SKIP REPLACE: ) {
    // SKIP REPLACE:     com.revenuecat.purchases.ui.revenuecatui.Paywall(options)
    // SKIP REPLACE: }
    Box(modifier: Modifier.fillMaxSize()) {
        Paywall(options)
    }
}

/// Composer that hosts RevenueCat's `DebugRevenueCatBottomSheet` composable
/// inside Skip's native-mode `ComposeView` bridge.
struct RevenueCatDebugOverlayComposer: ContentComposer {
    let isPresented: Bool
    let onDismissCallback: () -> Void

    @Composable override func Compose(context: ComposeContext) {
        composeRevenueCatDebugOverlay(
            isPresented: isPresented,
            onDismissCallback: onDismissCallback
        )
    }
}

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
        composeRevenueCatPaywall(
            offering: offering,
            onPurchaseCompleted: onPurchaseCompleted,
            onRestoreCompleted: onRestoreCompleted,
            onDismiss: onDismiss
        )
    }
}
#endif

#endif // !SKIP_BRIDGE

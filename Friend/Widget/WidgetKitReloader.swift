import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Tiny shim so the main app can ask WidgetKit to reload timelines without
/// importing WidgetKit at the call site.
enum WidgetKitReloader {
    static func reload() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

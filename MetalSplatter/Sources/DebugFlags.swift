import Foundation

/// Internal debug flags for controlling various debug features.
/// These flags are only settable internally and control debug output behavior.
public struct DebugFlags {
    
    /// Internal flag to enable/disable statistics logging throughout the codebase.
    /// When enabled, statistics will be logged via print() and Logger calls.
    /// When disabled, statistics collection still occurs but logging is suppressed.
    internal static var enableStatisticsLogging: Bool = false
    
    /// Set the statistics logging flag (internal use only)
    internal static func setStatisticsLogging(_ enabled: Bool) {
        enableStatisticsLogging = enabled
    }
    
    /// Check if statistics logging is enabled
    internal static var isStatisticsLoggingEnabled: Bool {
        return enableStatisticsLogging
    }
}

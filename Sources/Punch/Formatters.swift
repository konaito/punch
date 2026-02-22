import Foundation

enum Formatters {
    /// Format large numbers compactly: $13.7M, $946.8K, $1.2B
    static func formatCompactCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if absValue >= 1_000_000_000 {
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000_000))B"
        } else if absValue >= 1_000_000 {
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000_000))M"
        } else if absValue >= 1_000 {
            return "\(sign)$\(String(format: "%.1f", absValue / 1_000))K"
        } else if absValue >= 1 {
            return "\(sign)$\(String(format: "%.2f", absValue))"
        } else {
            return "\(sign)$\(String(format: "%.4f", absValue))"
        }
    }

    /// Format price with appropriate precision based on magnitude
    static func formatPrice(_ value: Double) -> String {
        if value >= 1000 {
            return "$\(String(format: "%.2f", value))"
        } else if value >= 1 {
            return "$\(String(format: "%.4f", value))"
        } else if value >= 0.01 {
            return "$\(String(format: "%.5f", value))"
        } else if value >= 0.0001 {
            return "$\(String(format: "%.6f", value))"
        } else {
            return "$\(String(format: "%.8f", value))"
        }
    }

    /// Format percentage with sign: +62.4%, -3.2%
    static func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }
}

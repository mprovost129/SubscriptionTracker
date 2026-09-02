import Foundation

enum SubscriptionManagementURL {
    static func normalizedString(
        from input: String
    ) -> String? {
        let trimmed = input.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return ""
        }

        let candidate = trimmed.contains("://")
            ? trimmed
            : "https://\(trimmed)"

        guard
            let url = URL(string: candidate),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host,
            !host.isEmpty
        else {
            return nil
        }

        return url.absoluteString
    }

    static func url(
        from storedValue: String
    ) -> URL? {
        guard
            let normalized = normalizedString(
                from: storedValue
            ),
            !normalized.isEmpty
        else {
            return nil
        }

        return URL(string: normalized)
    }
}

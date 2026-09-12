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

        let candidate: String

        if let existingScheme =
            URLComponents(string: trimmed)?
                .scheme?.lowercased() {
            guard existingScheme == "http" ||
                    existingScheme == "https" else {
                return nil
            }

            candidate = trimmed
        } else {
            candidate = "https://\(trimmed)"
        }

        guard
            let url = URL(string: candidate),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            let host = url.host,
            isAcceptableWebHost(host)
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

    private static func isAcceptableWebHost(
        _ host: String
    ) -> Bool {
        let hostParts = host
            .lowercased()
            .split(
                separator: ".",
                omittingEmptySubsequences: false
            )
            .map(String.init)

        guard !hostParts.contains(where: { $0.isEmpty }) else {
            return false
        }

        let domainParts: ArraySlice<String>

        if hostParts.first == "www" {
            domainParts = hostParts.dropFirst()
        } else {
            domainParts = hostParts[...]
        }

        return domainParts.count >= 2
    }
}

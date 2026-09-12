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
        let normalizedHost = host.lowercased()

        guard normalizedHost.count <= 253 else {
            return false
        }

        let hostParts = normalizedHost
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

        guard
            domainParts.count >= 2,
            domainParts.allSatisfy(isValidHostLabel),
            let topLevelDomain = domainParts.last
        else {
            return false
        }

        return isValidTopLevelDomain(topLevelDomain)
    }

    private static func isValidHostLabel(
        _ label: String
    ) -> Bool {
        guard
            !label.isEmpty,
            label.count <= 63,
            label.first != "-",
            label.last != "-"
        else {
            return false
        }

        return label.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 45, 48...57, 65...90, 97...122:
                return true
            default:
                return false
            }
        }
    }

    private static func isValidTopLevelDomain(
        _ label: String
    ) -> Bool {
        if label.hasPrefix("xn--") {
            return label.count > 4 && isValidHostLabel(label)
        }

        guard label.count >= 2 else {
            return false
        }

        return label.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 65...90, 97...122:
                return true
            default:
                return false
            }
        }
    }
}

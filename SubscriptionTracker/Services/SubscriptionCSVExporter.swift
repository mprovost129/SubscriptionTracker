import Foundation

enum SubscriptionCSVExporter {
    private static let baseColumnTitles = [
        "Name",
        "Price",
        "Currency",
        "Billing Frequency",
        "Next Renewal Date",
        "Status",
        "Category",
        "Reminder Enabled",
        "Notes",
        "Cancellation Date"
    ]

    static func csvString(
        for subscriptions: [Subscription],
        currencyCode: String,
        calendar: Calendar = .current
    ) -> String {
        let sortedSubscriptions = subscriptions.sorted {
            let nameComparison = $0.name.localizedStandardCompare(
                $1.name
            )

            if nameComparison == .orderedSame {
                return $0.id.uuidString < $1.id.uuidString
            }

            return nameComparison == .orderedAscending
        }

        let includesManagementURL = sortedSubscriptions.contains {
            !$0.managementURL.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

        var columnTitles = baseColumnTitles

        if includesManagementURL {
            columnTitles.insert(
                "Manage URL",
                at: 8
            )
        }

        let header = csvRow(columnTitles)

        let rows = sortedSubscriptions.map { subscription in
            var values = [
                subscription.name,
                NSDecimalNumber(
                    decimal: subscription.price
                ).stringValue,
                currencyCode,
                billingText(for: subscription),
                dateText(
                    for: subscription.nextBillingDate,
                    calendar: calendar
                ),
                statusText(for: subscription),
                subscription.category,
                subscription.reminderEnabled ? "Yes" : "No",
                subscription.notes,
                dateText(
                    for: subscription.cancellationDate,
                    calendar: calendar
                )
            ]

            if includesManagementURL {
                values.insert(
                    subscription.managementURL,
                    at: 8
                )
            }

            return csvRow(values)
        }

        return ([header] + rows)
            .joined(separator: "\r\n") + "\r\n"
    }
    
    static func exportFilename(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let dateStamp = dateText(
            for: date,
            calendar: calendar
        )

        return "SubscriptionTracker-Export-\(dateStamp).csv"
    }
    
    static func createTemporaryFile(
        for subscriptions: [Subscription],
        currencyCode: String,
        date: Date = Date(),
        calendar: Calendar = .current
    ) throws -> URL {
        let csv = csvString(
            for: subscriptions,
            currencyCode: currencyCode,
            calendar: calendar
        )

        guard let data = (
            "\u{FEFF}" + csv
        ).data(using: .utf8) else {
            throw CSVExportError.couldNotEncodeFile
        }

        let filename = exportFilename(
            for: date,
            calendar: calendar
        )

        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(filename)

        try data.write(
            to: fileURL,
            options: .atomic
        )

        return fileURL
    }

    private static func csvRow(
        _ values: [String]
    ) -> String {
        values
            .map { csvField($0) }
            .joined(separator: ",")
    }

    private static func csvField(
        _ value: String
    ) -> String {
        let firstVisibleCharacter = value
            .drop(while: { $0.isWhitespace })
            .first

        let formulaPrefixes: Set<Character> = [
            "=",
            "+",
            "-",
            "@"
        ]

        let safeValue: String

        if let firstVisibleCharacter,
           formulaPrefixes.contains(firstVisibleCharacter) {
            safeValue = "'" + value
        } else {
            safeValue = value
        }

        let escapedValue = safeValue.replacingOccurrences(
            of: "\"",
            with: "\"\""
        )

        return "\"\(escapedValue)\""
    }

    private static func billingText(
        for subscription: Subscription
    ) -> String {
        subscription.billingFrequency.displayName
    }

    private static func statusText(
        for subscription: Subscription
    ) -> String {
        switch subscription.status {
        case .active:
            return "Active"
        case .canceled:
            return "Canceled"
        }
    }

    private static func dateText(
        for date: Date?,
        calendar: Calendar
    ) -> String {
        guard let date else {
            return ""
        }

        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return ""
        }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
}

private enum CSVExportError: LocalizedError {
    case couldNotEncodeFile

    var errorDescription: String? {
        switch self {
        case .couldNotEncodeFile:
            return "The subscription export could not be created."
        }
    }
}

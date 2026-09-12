import Foundation

struct SubscriptionCSVImportRecord {
    let id: UUID?
    let name: String
    let price: Decimal
    let currencyCode: String
    let billingFrequency: BillingFrequency
    let nextBillingDate: Date
    let trialEndDate: Date?
    let status: SubscriptionStatus
    let category: String
    let reminderEnabled: Bool
    let reminderDaysBefore: Int
    let managementURL: String
    let notes: String
    let cancellationDate: Date?
}

struct SubscriptionCSVImportResult {
    let records: [SubscriptionCSVImportRecord]
    let currencyCodes: Set<String>
}

enum SubscriptionCSVImportDuplicatePolicy {
    case skip
    case replace
    case importAll
}

enum SubscriptionCSVImporter {
    private static let requiredColumnTitles: Set<String> = [
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

    static func parse(
        csv: String,
        calendar: Calendar = .current
    ) throws -> SubscriptionCSVImportResult {
        let rows = try parsedRows(from: csv)

        guard let headerRow = rows.first else {
            throw SubscriptionCSVImportError.emptyFile
        }

        let headers = headerRow.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard Set(headers).count == headers.count else {
            throw SubscriptionCSVImportError.duplicateColumns
        }

        let missingColumns = requiredColumnTitles
            .subtracting(headers)
            .sorted()

        guard missingColumns.isEmpty else {
            throw SubscriptionCSVImportError.missingColumns(
                missingColumns
            )
        }

        let headerIndexes = Dictionary(
            uniqueKeysWithValues: headers.enumerated().map {
                ($0.element, $0.offset)
            }
        )

        var records: [SubscriptionCSVImportRecord] = []
        var currencyCodes: Set<String> = []

        for (rowOffset, row) in rows.dropFirst().enumerated() {
            let rowNumber = rowOffset + 2

            if row.allSatisfy({
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            }) {
                continue
            }

            guard row.count == headers.count else {
                throw SubscriptionCSVImportError.invalidRow(
                    rowNumber,
                    "The number of fields does not match the header."
                )
            }

            let record = try importRecord(
                from: row,
                headerIndexes: headerIndexes,
                rowNumber: rowNumber,
                calendar: calendar
            )

            records.append(record)
            currencyCodes.insert(record.currencyCode)
        }

        guard !records.isEmpty else {
            throw SubscriptionCSVImportError.noSubscriptions
        }

        return SubscriptionCSVImportResult(
            records: records,
            currencyCodes: currencyCodes
        )
    }

    static func matchingSubscription(
        for record: SubscriptionCSVImportRecord,
        in subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Subscription? {
        if let id = record.id,
           let exactMatch = subscriptions.first(
               where: { $0.id == id }
           ) {
            return exactMatch
        }

        let legacyMatches = subscriptions.filter { subscription in
            normalizedName(subscription.name)
                == normalizedName(record.name)
            && subscription.billingFrequency
                == record.billingFrequency
            && calendar.isDate(
                subscription.nextBillingDate,
                inSameDayAs: record.nextBillingDate
            )
        }

        return legacyMatches.count == 1
            ? legacyMatches[0]
            : nil
    }

    static func duplicateCount(
        in result: SubscriptionCSVImportResult,
        existing subscriptions: [Subscription],
        calendar: Calendar = .current
    ) -> Int {
        result.records.reduce(0) { count, record in
            count + (
                matchingSubscription(
                    for: record,
                    in: subscriptions,
                    calendar: calendar
                ) == nil ? 0 : 1
            )
        }
    }

    private static func importRecord(
        from row: [String],
        headerIndexes: [String: Int],
        rowNumber: Int,
        calendar: Calendar
    ) throws -> SubscriptionCSVImportRecord {
        func value(_ title: String) -> String? {
            guard let index = headerIndexes[title],
                  row.indices.contains(index) else {
                return nil
            }

            return restoredFieldValue(row[index])
        }

        let name = value("Name")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        guard !name.isEmpty else {
            throw invalidRow(rowNumber, "Name is required.")
        }

        guard
            let priceText = value("Price"),
            let price = Decimal(
                string: priceText,
                locale: Locale(identifier: "en_US_POSIX")
            )
        else {
            throw invalidRow(rowNumber, "Price is invalid.")
        }

        let currencyCode = value("Currency")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""

        guard !currencyCode.isEmpty else {
            throw invalidRow(rowNumber, "Currency is required.")
        }

        guard
            let billingText = value("Billing Frequency"),
            let billingFrequency = BillingFrequency.allCases.first(
                where: {
                    $0.displayName.caseInsensitiveCompare(
                        billingText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    ) == .orderedSame
                }
            )
        else {
            throw invalidRow(
                rowNumber,
                "Billing Frequency is invalid."
            )
        }

        guard
            let nextBillingText = value("Next Renewal Date"),
            let nextBillingDate = date(
                from: nextBillingText,
                calendar: calendar
            )
        else {
            throw invalidRow(
                rowNumber,
                "Next Renewal Date is invalid."
            )
        }

        let trialEndDate = try optionalDate(
            from: value("Trial End Date"),
            rowNumber: rowNumber,
            title: "Trial End Date",
            calendar: calendar
        )

        guard
            let statusText = value("Status"),
            let status = status(from: statusText)
        else {
            throw invalidRow(rowNumber, "Status is invalid.")
        }

        let category = value("Category")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        guard !category.isEmpty else {
            throw invalidRow(rowNumber, "Category is required.")
        }

        guard
            let reminderText = value("Reminder Enabled"),
            let reminderEnabled = yesNoValue(from: reminderText)
        else {
            throw invalidRow(
                rowNumber,
                "Reminder Enabled must be Yes or No."
            )
        }

        let reminderDaysBefore: Int

        if let reminderDaysText = value("Reminder Days Before"),
           !reminderDaysText.trimmingCharacters(
               in: .whitespacesAndNewlines
           ).isEmpty {
            guard
                let parsedDays = Int(
                    reminderDaysText.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                ),
                AppSettings.supportedReminderDays.contains(parsedDays)
            else {
                throw invalidRow(
                    rowNumber,
                    "Reminder Days Before is not supported."
                )
            }

            reminderDaysBefore = parsedDays
        } else {
            reminderDaysBefore = AppSettings.defaultReminderDaysBefore
        }

        let managementInput = value("Manage URL") ?? ""

        guard let managementURL =
            SubscriptionManagementURL.normalizedString(
                from: managementInput
            ) else {
            throw invalidRow(rowNumber, "Manage URL is invalid.")
        }

        let notes = value("Notes") ?? ""

        let cancellationDate = try optionalDate(
            from: value("Cancellation Date"),
            rowNumber: rowNumber,
            title: "Cancellation Date",
            calendar: calendar
        )

        let id: UUID?

        if let idText = value("Subscription ID")?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !idText.isEmpty {
            guard let parsedID = UUID(uuidString: idText) else {
                throw invalidRow(
                    rowNumber,
                    "Subscription ID is invalid."
                )
            }

            id = parsedID
        } else {
            id = nil
        }

        return SubscriptionCSVImportRecord(
            id: id,
            name: name,
            price: price,
            currencyCode: currencyCode,
            billingFrequency: billingFrequency,
            nextBillingDate: nextBillingDate,
            trialEndDate: trialEndDate,
            status: status,
            category: category,
            reminderEnabled: reminderEnabled,
            reminderDaysBefore: reminderDaysBefore,
            managementURL: managementURL,
            notes: notes,
            cancellationDate: cancellationDate
        )
    }

    private static func parsedRows(
        from csv: String
    ) throws -> [[String]] {
        var input = csv

        if input.first == "\u{FEFF}" {
            input.removeFirst()
        }

        guard !input.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            throw SubscriptionCSVImportError.emptyFile
        }

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = input.startIndex

        while index < input.endIndex {
            let character = input[index]
            let nextIndex = input.index(after: index)

            if isInsideQuotes {
                if character == "\"" {
                    if nextIndex < input.endIndex,
                       input[nextIndex] == "\"" {
                        field.append("\"")
                        index = input.index(after: nextIndex)
                        continue
                    }

                    isInsideQuotes = false
                } else {
                    field.append(character)
                }

                index = nextIndex
                continue
            }

            switch character {
            case "\"":
                guard field.isEmpty else {
                    throw SubscriptionCSVImportError.malformedCSV
                }
                isInsideQuotes = true

            case ",":
                row.append(field)
                field = ""

            case "\n":
                row.append(field)
                rows.append(row)
                row = []
                field = ""

            case "\r":
                row.append(field)
                rows.append(row)
                row = []
                field = ""

                if nextIndex < input.endIndex,
                   input[nextIndex] == "\n" {
                    index = input.index(after: nextIndex)
                    continue
                }

            default:
                field.append(character)
            }

            index = nextIndex
        }

        guard !isInsideQuotes else {
            throw SubscriptionCSVImportError.malformedCSV
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }

    private static func restoredFieldValue(
        _ value: String
    ) -> String {
        guard value.first == "'" else {
            return value
        }

        let remainder = String(value.dropFirst())
        let firstVisibleCharacter = remainder
            .drop(while: { $0.isWhitespace })
            .first

        let formulaPrefixes: Set<Character> = [
            "=",
            "+",
            "-",
            "@"
        ]

        guard let firstVisibleCharacter,
              formulaPrefixes.contains(firstVisibleCharacter) else {
            return value
        }

        return remainder
    }

    private static func date(
        from text: String,
        calendar: Calendar
    ) -> Date? {
        let parts = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-", omittingEmptySubsequences: false)

        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2]),
            let date = calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day
                )
            )
        else {
            return nil
        }

        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard components.year == year,
              components.month == month,
              components.day == day else {
            return nil
        }

        return date
    }

    private static func optionalDate(
        from text: String?,
        rowNumber: Int,
        title: String,
        calendar: Calendar
    ) throws -> Date? {
        guard let text else {
            return nil
        }

        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return nil
        }

        guard let parsedDate = date(
            from: trimmed,
            calendar: calendar
        ) else {
            throw invalidRow(
                rowNumber,
                "\(title) is invalid."
            )
        }

        return parsedDate
    }

    private static func status(
        from text: String
    ) -> SubscriptionStatus? {
        switch text.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased() {
        case "active":
            return .active
        case "canceled", "cancelled":
            return .canceled
        default:
            return nil
        }
    }

    private static func yesNoValue(
        from text: String
    ) -> Bool? {
        switch text.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased() {
        case "yes", "true":
            return true
        case "no", "false":
            return false
        default:
            return nil
        }
    }

    private static func normalizedName(
        _ name: String
    ) -> String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
    }

    private static func invalidRow(
        _ rowNumber: Int,
        _ message: String
    ) -> SubscriptionCSVImportError {
        .invalidRow(rowNumber, message)
    }
}

enum SubscriptionCSVImportError: LocalizedError {
    case emptyFile
    case malformedCSV
    case duplicateColumns
    case missingColumns([String])
    case noSubscriptions
    case invalidRow(Int, String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The selected CSV file is empty."
        case .malformedCSV:
            return "The selected file is not a valid CSV file."
        case .duplicateColumns:
            return "The CSV contains duplicate column names."
        case .missingColumns(let columns):
            return "The CSV is missing required columns: \(columns.joined(separator: ", "))."
        case .noSubscriptions:
            return "The CSV does not contain any subscriptions to import."
        case .invalidRow(let rowNumber, let message):
            return "Row \(rowNumber): \(message)"
        }
    }
}

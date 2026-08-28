import Foundation

enum AppSettings {
    static let currencyCodeKey = "currencyCode"
    static let remindersEnabledByDefaultKey =
        "remindersEnabledByDefault"
    static let reminderDaysBeforeKey = "reminderDaysBefore"

    static let defaultCurrencyCode = "USD"
    static let defaultRemindersEnabled = true
    static let defaultReminderDaysBefore = 3

    static let supportedReminderDays = [
        0,
        1,
        3,
        7,
        14,
        30
    ]

    static func normalizedReminderDays(
        _ value: Int?
    ) -> Int {
        guard let value,
              supportedReminderDays.contains(value) else {
            return defaultReminderDaysBefore
        }

        return value
    }

    static func reminderTimingText(
        for days: Int
    ) -> String {
        switch normalizedReminderDays(days) {
        case 0:
            return "On renewal day"
        case 1:
            return "1 day before"
        default:
            return "\(days) days before"
        }
    }
}

import Foundation
import SwiftData

enum BillingFrequency: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        case .yearly:
            return "Yearly"
        }
    }

    var lowercaseDisplayName: String {
        displayName.lowercased()
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active
    case canceled
}

enum SubscriptionCategory: String, CaseIterable, Codable {
    case streaming = "Streaming"
    case software = "Software"
    case ai = "AI"
    case cloudStorage = "Cloud Storage"
    case gaming = "Gaming"
    case fitness = "Fitness"
    case productivity = "Productivity"
    case business = "Business"
    case other = "Other"

    static let customSelectionValue = "__custom__"

    static func resolvedValue(
        selection: String,
        customValue: String
    ) -> String? {
        if selection == customSelectionValue {
            let trimmedValue = customValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            return trimmedValue.isEmpty
                ? nil
                : trimmedValue
        }

        guard allCases.contains(
            where: { $0.rawValue == selection }
        ) else {
            return nil
        }

        return selection
    }

    static func selectionValues(
        for storedValue: String
    ) -> (
        selection: String,
        customValue: String
    ) {
        if allCases.contains(
            where: { $0.rawValue == storedValue }
        ) {
            return (
                selection: storedValue,
                customValue: ""
            )
        }

        return (
            selection: customSelectionValue,
            customValue: storedValue
        )
    }
}

@Model
final class Subscription {
    
    var id: UUID = UUID()
    var name: String
    var price: Decimal
    var billingFrequency: BillingFrequency
    var nextBillingDate: Date
    var category: String
    var notes: String
    var reminderEnabled: Bool
    var reminderDaysBefore: Int = 3
    var status: SubscriptionStatus
    var cancellationDate: Date?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(
        deleteRule: .cascade,
        inverse: \SubscriptionPriceChange.subscription
    )
    var priceChanges: [SubscriptionPriceChange] = []
    
    init(
        name: String,
        price: Decimal,
        billingFrequency: BillingFrequency,
        nextBillingDate: Date,
        category: String = SubscriptionCategory.other.rawValue,
        notes: String = "",
        reminderEnabled: Bool = true,
        reminderDaysBefore: Int = AppSettings.defaultReminderDaysBefore,
        status: SubscriptionStatus = .active,
        cancellationDate: Date? = nil
    ) {
        self.name = name
        self.price = price
        self.billingFrequency = billingFrequency
        self.nextBillingDate = nextBillingDate
        self.category = category
        self.notes = notes
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore =
            AppSettings.normalizedReminderDays(
                reminderDaysBefore
            )
        self.status = status
        self.cancellationDate = cancellationDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

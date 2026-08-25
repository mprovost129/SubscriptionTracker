import Foundation
import SwiftData

enum BillingFrequency: String, Codable, CaseIterable {
    case monthly
    case yearly
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
        self.status = status
        self.cancellationDate = cancellationDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

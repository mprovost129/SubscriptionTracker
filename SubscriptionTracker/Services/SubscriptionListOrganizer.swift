import Foundation

enum SubscriptionSortOption:
    String,
    CaseIterable,
    Identifiable {
    case renewalDate = "Renewal Date"
    case name = "Name"
    case priceHighToLow = "Price: High to Low"
    case priceLowToHigh = "Price: Low to High"

    var id: Self {
        self
    }
}

enum SubscriptionStatusFilter:
    String,
    CaseIterable,
    Identifiable {
    case all = "All Statuses"
    case active = "Active"
    case canceled = "Canceled"

    var id: Self {
        self
    }
}

enum SubscriptionBillingFilter:
    String,
    CaseIterable,
    Identifiable {
    case all = "All Billing"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var id: Self {
        self
    }
}

enum SubscriptionListOrganizer {
    static func organize(
        _ subscriptions: [Subscription],
        statusFilter: SubscriptionStatusFilter,
        billingFilter: SubscriptionBillingFilter,
        sortOption: SubscriptionSortOption
    ) -> [Subscription] {
        subscriptions
            .filter {
                matchesStatus(
                    $0,
                    filter: statusFilter
                )
            }
            .filter {
                matchesBilling(
                    $0,
                    filter: billingFilter
                )
            }
            .sorted {
                comesBefore(
                    $0,
                    $1,
                    using: sortOption
                )
            }
    }

    private static func matchesStatus(
        _ subscription: Subscription,
        filter: SubscriptionStatusFilter
    ) -> Bool {
        switch filter {
        case .all:
            return true
        case .active:
            return subscription.status == .active
        case .canceled:
            return subscription.status == .canceled
        }
    }

    private static func matchesBilling(
        _ subscription: Subscription,
        filter: SubscriptionBillingFilter
    ) -> Bool {
        switch filter {
        case .all:
            return true
        case .weekly:
            return subscription.billingFrequency == .weekly
        case .monthly:
            return subscription.billingFrequency == .monthly
        case .quarterly:
            return subscription.billingFrequency == .quarterly
        case .yearly:
            return subscription.billingFrequency == .yearly
        }
    }

    private static func comesBefore(
        _ first: Subscription,
        _ second: Subscription,
        using sortOption: SubscriptionSortOption
    ) -> Bool {
        switch sortOption {
        case .renewalDate:
            if first.nextBillingDate != second.nextBillingDate {
                return first.nextBillingDate <
                    second.nextBillingDate
            }

        case .name:
            let comparison =
                first.name.localizedStandardCompare(
                    second.name
                )

            if comparison != .orderedSame {
                return comparison == .orderedAscending
            }

        case .priceHighToLow:
            if first.price != second.price {
                return first.price > second.price
            }

        case .priceLowToHigh:
            if first.price != second.price {
                return first.price < second.price
            }
        }

        return first.id.uuidString <
            second.id.uuidString
    }
}

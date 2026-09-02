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

enum SubscriptionDateFilter:
    String,
    CaseIterable,
    Identifiable {
    case all = "All Dates"
    case overdue = "Overdue"
    case next7Days = "Next 7 Days"
    case next30Days = "Next 30 Days"

    var id: Self {
        self
    }
}

enum SubscriptionListOrganizer {
    static let allCategoriesFilter = "All Categories"

    static func categoryOptions(
        from subscriptions: [Subscription]
    ) -> [String] {
        let categorySet: Set<String> = Set(
            subscriptions.compactMap { subscription -> String? in
                let category = subscription.category
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                return category.isEmpty ? nil : category
            }
        )

        let categories = categorySet.sorted {
            (first: String, second: String) in
            first.localizedStandardCompare(second)
                == .orderedAscending
        }

        return [allCategoriesFilter] + categories
    }

    static func organize(
        _ subscriptions: [Subscription],
        statusFilter: SubscriptionStatusFilter,
        billingFilter: SubscriptionBillingFilter,
        sortOption: SubscriptionSortOption,
        categoryFilter: String = allCategoriesFilter,
        dateFilter: SubscriptionDateFilter = .all,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
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
            .filter {
                matchesCategory(
                    $0,
                    filter: categoryFilter
                )
            }
            .filter {
                matchesDate(
                    $0,
                    filter: dateFilter,
                    referenceDate: referenceDate,
                    calendar: calendar
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

    private static func matchesCategory(
        _ subscription: Subscription,
        filter: String
    ) -> Bool {
        guard filter != allCategoriesFilter else {
            return true
        }

        return subscription.category.compare(
            filter,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) == .orderedSame
    }

    private static func matchesDate(
        _ subscription: Subscription,
        filter: SubscriptionDateFilter,
        referenceDate: Date,
        calendar: Calendar
    ) -> Bool {
        switch filter {
        case .all:
            return true

        case .overdue:
            return RenewalCalculator.isOverdue(
                subscription,
                from: referenceDate,
                calendar: calendar
            )

        case .next7Days:
            return RenewalCalculator.isDueSoon(
                subscription,
                withinDays: 7,
                from: referenceDate,
                calendar: calendar
            )

        case .next30Days:
            return RenewalCalculator.isDueSoon(
                subscription,
                withinDays: 30,
                from: referenceDate,
                calendar: calendar
            )
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

import Foundation

struct CategorySpendingInsight:
    Identifiable,
    Equatable {
    let category: String
    let monthlyCost: Decimal
    let annualCost: Decimal

    var id: String {
        category
    }
}

enum SubscriptionInsightsCalculator {
    static func spendingByCategory(
        for subscriptions: [Subscription],
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> [CategorySpendingInsight] {
        let paidSubscriptions = subscriptions.filter {
            SubscriptionTrialCalculator
                .isPaidActiveSubscription(
                    $0,
                    on: date,
                    calendar: calendar
                )
        }

        let groupedSubscriptions = Dictionary(
            grouping: paidSubscriptions
        ) { subscription in
            let trimmedCategory =
                subscription.category.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmedCategory.isEmpty
                ? SubscriptionCategory.other.rawValue
                : trimmedCategory
        }

        return groupedSubscriptions
            .map { category, subscriptions in
                CategorySpendingInsight(
                    category: category,
                    monthlyCost:
                        SubscriptionCalculator
                            .totalMonthlyCost(
                                for: subscriptions,
                                on: date,
                                calendar: calendar
                            ),
                    annualCost:
                        SubscriptionCalculator
                            .totalAnnualCost(
                                for: subscriptions,
                                on: date,
                                calendar: calendar
                            )
                )
            }
            .sorted { first, second in
                if first.monthlyCost != second.monthlyCost {
                    return first.monthlyCost >
                        second.monthlyCost
                }

                return first.category
                    .localizedStandardCompare(
                        second.category
                    ) == .orderedAscending
            }
    }

    static func largestSubscriptions(
        from subscriptions: [Subscription],
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> [Subscription] {
        subscriptions
            .filter {
                SubscriptionTrialCalculator
                    .isPaidActiveSubscription(
                        $0,
                        on: date,
                        calendar: calendar
                    )
            }
            .sorted { first, second in
                let firstMonthlyCost =
                    SubscriptionCalculator
                        .monthlyEquivalent(
                            price: first.price,
                            billingFrequency:
                                first.billingFrequency
                        )

                let secondMonthlyCost =
                    SubscriptionCalculator
                        .monthlyEquivalent(
                            price: second.price,
                            billingFrequency:
                                second.billingFrequency
                        )

                if firstMonthlyCost != secondMonthlyCost {
                    return firstMonthlyCost >
                        secondMonthlyCost
                }

                let nameComparison =
                    first.name.localizedStandardCompare(
                        second.name
                    )

                if nameComparison != .orderedSame {
                    return nameComparison ==
                        .orderedAscending
                }

                return first.id.uuidString <
                    second.id.uuidString
            }
    }
}

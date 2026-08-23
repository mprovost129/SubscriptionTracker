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
        for subscriptions: [Subscription]
    ) -> [CategorySpendingInsight] {
        let activeSubscriptions = subscriptions.filter {
            $0.status == .active
        }

        let groupedSubscriptions = Dictionary(
            grouping: activeSubscriptions
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
                                for: subscriptions
                            ),
                    annualCost:
                        SubscriptionCalculator
                            .totalAnnualCost(
                                for: subscriptions
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
        from subscriptions: [Subscription]
    ) -> [Subscription] {
        subscriptions
            .filter {
                $0.status == .active
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

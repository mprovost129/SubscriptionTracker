import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionCategoryFilterTests {
    @Test
    func categoryOptionsIncludeAllAndUniqueSortedValues() {
        let subscriptions = [
            Subscription(
                name: "Streaming One",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category: "Streaming"
            ),
            Subscription(
                name: "Custom One",
                price: Decimal(20),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category: "Professional Memberships"
            ),
            Subscription(
                name: "Streaming Two",
                price: Decimal(15),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category: "Streaming"
            )
        ]

        let result = SubscriptionListOrganizer.categoryOptions(
            from: subscriptions
        )

        #expect(
            result == [
                "All Categories",
                "Professional Memberships",
                "Streaming"
            ]
        )
    }

    @Test
    func categoryFilterReturnsOnlyMatchingSubscriptions() {
        let streaming = Subscription(
            name: "Netflix",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category: "Streaming"
        )

        let software = Subscription(
            name: "Design App",
            price: Decimal(30),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category: "Software"
        )

        let result = SubscriptionListOrganizer.organize(
            [software, streaming],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            categoryFilter: "Streaming"
        )

        #expect(result.map(\.name) == ["Netflix"])
    }

    @Test
    func allCategoriesFilterPreservesSubscriptions() {
        let subscriptions = [
            Subscription(
                name: "One",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category: "Streaming"
            ),
            Subscription(
                name: "Two",
                price: Decimal(20),
                billingFrequency: .yearly,
                nextBillingDate: Date(),
                category: "Software"
            )
        ]

        let result = SubscriptionListOrganizer.organize(
            subscriptions,
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .name,
            categoryFilter:
                SubscriptionListOrganizer.allCategoriesFilter
        )

        #expect(result.count == 2)
    }

    @Test
    func categoryFilterCombinesWithStatusAndBillingFilters() {
        let matching = Subscription(
            name: "Matching",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category: "Software"
        )

        let wrongBilling = Subscription(
            name: "Wrong Billing",
            price: Decimal(10),
            billingFrequency: .yearly,
            nextBillingDate: Date(),
            category: "Software"
        )

        let canceled = Subscription(
            name: "Canceled",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category: "Software",
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [wrongBilling, canceled, matching],
            statusFilter: .active,
            billingFilter: .monthly,
            sortOption: .name,
            categoryFilter: "Software"
        )

        #expect(result.map(\.name) == ["Matching"])
    }
}

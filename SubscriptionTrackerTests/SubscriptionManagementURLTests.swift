import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionManagementURLTests {
    @Test
    func blankManagementURLIsAllowed() {
        let result =
            SubscriptionManagementURL.normalizedString(
                from: "   "
            )

        #expect(result == "")
    }

    @Test
    func managementURLAddsHTTPSWhenSchemeIsMissing() {
        let result =
            SubscriptionManagementURL.normalizedString(
                from: "example.com/account"
            )

        #expect(
            result == "https://example.com/account"
        )
    }

    @Test
    func managementURLPreservesHTTPSAddress() {
        let result =
            SubscriptionManagementURL.normalizedString(
                from: "https://example.com/account"
            )

        #expect(
            result == "https://example.com/account"
        )
    }

    @Test
    func managementURLAllowsCompleteWWWAddress() {
        let result =
            SubscriptionManagementURL.normalizedString(
                from: "www.netflix.com"
            )

        #expect(result == "https://www.netflix.com")
    }

    @Test
    func managementURLRejectsIncompleteHosts() {
        #expect(
            SubscriptionManagementURL.normalizedString(
                from: "netflix"
            ) == nil
        )

        #expect(
            SubscriptionManagementURL.normalizedString(
                from: "www.netflix"
            ) == nil
        )

        #expect(
            SubscriptionManagementURL.normalizedString(
                from: "https://www.netflix"
            ) == nil
        )
    }

    @Test
    func managementURLRejectsNonWebSchemes() {
        #expect(
            SubscriptionManagementURL.normalizedString(
                from: "ftp://example.com"
            ) == nil
        )

        #expect(
            SubscriptionManagementURL.normalizedString(
                from: "mailto:test@example.com"
            ) == nil
        )
    }

    @Test
    func subscriptionStoresManagementURL() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            managementURL: "https://example.com/account"
        )

        #expect(
            subscription.managementURL ==
                "https://example.com/account"
        )
    }

    @Test
    func csvExportIncludesManagementURL() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            managementURL: "https://example.com/account"
        )

        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD"
        )

        #expect(csv.contains("\"Manage URL\""))
        #expect(
            csv.contains(
                "\"https://example.com/account\""
            )
        )
    }
}

import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionCSVImporterTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        year: Int = 2026,
        month: Int,
        day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )!
    }

    @Test
    func importsLegacyCSVWithoutRestoreMetadata() throws {
        let subscription = Subscription(
            name: "Legacy Service",
            price: Decimal(string: "12.99")!,
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 12),
            category: SubscriptionCategory.streaming.rawValue,
            notes: "Family plan",
            reminderEnabled: true
        )

        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD",
            calendar: calendar
        )

        let result = try SubscriptionCSVImporter.parse(
            csv: csv,
            calendar: calendar
        )

        let record = try #require(result.records.first)

        #expect(result.records.count == 1)
        #expect(record.id == nil)
        #expect(record.name == "Legacy Service")
        #expect(record.price == Decimal(string: "12.99")!)
        #expect(record.currencyCode == "USD")
        #expect(record.billingFrequency == .monthly)
        #expect(
            calendar.isDate(
                record.nextBillingDate,
                inSameDayAs: date(month: 10, day: 12)
            )
        )
        #expect(record.trialEndDate == nil)
        #expect(record.reminderDaysBefore == 3)
        #expect(record.managementURL.isEmpty)
        #expect(record.notes == "Family plan")
    }

    @Test
    func restoreMetadataRoundTripPreservesRestorableFields() throws {
        let trialEndDate = date(month: 10, day: 20)
        let subscription = Subscription(
            name: "Trial, Service",
            price: Decimal(24),
            billingFrequency: .quarterly,
            nextBillingDate: trialEndDate,
            trialEndDate: trialEndDate,
            category: "Custom Category",
            notes: "Line one\nLine \"two\"",
            managementURL: "https://example.com/account",
            reminderEnabled: true,
            reminderDaysBefore: 7
        )

        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "CAD",
            calendar: calendar,
            includeRestoreMetadata: true
        )

        let result = try SubscriptionCSVImporter.parse(
            csv: csv,
            calendar: calendar
        )

        let record = try #require(result.records.first)

        #expect(record.id == subscription.id)
        #expect(record.name == "Trial, Service")
        #expect(record.currencyCode == "CAD")
        #expect(record.billingFrequency == .quarterly)
        #expect(record.trialEndDate != nil)
        #expect(
            calendar.isDate(
                try #require(record.trialEndDate),
                inSameDayAs: trialEndDate
            )
        )
        #expect(record.category == "Custom Category")
        #expect(record.notes == "Line one\nLine \"two\"")
        #expect(
            record.managementURL ==
                "https://example.com/account"
        )
        #expect(record.reminderDaysBefore == 7)
    }

    @Test
    func restoreExportContainsRestoreMetadataColumns() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 1),
            trialEndDate: date(month: 10, day: 1),
            reminderDaysBefore: 14
        )

        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD",
            calendar: calendar,
            includeRestoreMetadata: true
        )

        #expect(csv.contains("\"Subscription ID\""))
        #expect(csv.contains("\"Trial End Date\""))
        #expect(csv.contains("\"Reminder Days Before\""))
        #expect(csv.contains("\"Manage URL\""))
        #expect(csv.contains("\"14\""))
    }

    @Test
    func formulaProtectionRoundTripsToOriginalText() throws {
        let subscription = Subscription(
            name: "=Service",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 1),
            notes: "   +Formula-like note"
        )

        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD",
            calendar: calendar,
            includeRestoreMetadata: true
        )

        let result = try SubscriptionCSVImporter.parse(
            csv: csv,
            calendar: calendar
        )

        let record = try #require(result.records.first)

        #expect(record.name == "=Service")
        #expect(record.notes == "   +Formula-like note")
    }

    @Test
    func matchingUsesSubscriptionIDBeforeChangedRenewalDate() {
        let existing = Subscription(
            name: "Service",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: date(month: 11, day: 1)
        )

        let record = SubscriptionCSVImportRecord(
            id: existing.id,
            name: "Service",
            price: Decimal(10),
            currencyCode: "USD",
            billingFrequency: .monthly,
            nextBillingDate: date(month: 10, day: 1),
            trialEndDate: nil,
            status: .active,
            category: SubscriptionCategory.other.rawValue,
            reminderEnabled: true,
            reminderDaysBefore: 3,
            managementURL: "",
            notes: "",
            cancellationDate: nil
        )

        let match = SubscriptionCSVImporter.matchingSubscription(
            for: record,
            in: [existing],
            calendar: calendar
        )

        #expect(match?.id == existing.id)
    }

    @Test
    func legacyMatchingUsesNameFrequencyAndRenewalDay() {
        let existing = Subscription(
            name: "Service",
            price: Decimal(10),
            billingFrequency: .yearly,
            nextBillingDate: date(month: 10, day: 5)
        )

        let record = SubscriptionCSVImportRecord(
            id: nil,
            name: " service ",
            price: Decimal(20),
            currencyCode: "USD",
            billingFrequency: .yearly,
            nextBillingDate: date(month: 10, day: 5),
            trialEndDate: nil,
            status: .active,
            category: SubscriptionCategory.other.rawValue,
            reminderEnabled: true,
            reminderDaysBefore: 3,
            managementURL: "",
            notes: "Updated",
            cancellationDate: nil
        )

        let match = SubscriptionCSVImporter.matchingSubscription(
            for: record,
            in: [existing],
            calendar: calendar
        )

        #expect(match?.id == existing.id)
    }

    @Test
    func malformedManagementURLIsRejected() {
        let csv = """
        \"Name\",\"Price\",\"Currency\",\"Billing Frequency\",\"Next Renewal Date\",\"Status\",\"Category\",\"Reminder Enabled\",\"Manage URL\",\"Notes\",\"Cancellation Date\"
        \"Bad URL\",\"10\",\"USD\",\"Monthly\",\"2026-10-01\",\"Active\",\"Other\",\"Yes\",\"https://-.-\",\"\",\"\"
        """

        var didThrow = false

        do {
            _ = try SubscriptionCSVImporter.parse(
                csv: csv,
                calendar: calendar
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow)
    }
}

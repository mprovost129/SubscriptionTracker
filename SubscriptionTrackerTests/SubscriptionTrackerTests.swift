import Foundation
import Testing
@testable import SubscriptionTracker

struct SubscriptionTrackerTests {
    
    @Test
    func monthlySubscriptionKeepsMonthlyPrice() {
        let result = SubscriptionCalculator.monthlyEquivalent(
            price: Decimal(10),
            billingFrequency: .monthly
        )
        
        #expect(result == Decimal(10))
    }
    
    @Test
    func monthlySubscriptionCalculatesAnnualPrice() {
        let result = SubscriptionCalculator.annualEquivalent(
            price: Decimal(10),
            billingFrequency: .monthly
        )
        
        #expect(result == Decimal(120))
    }
    
    @Test
    func yearlySubscriptionCalculatesMonthlyEquivalent() {
        let result = SubscriptionCalculator.monthlyEquivalent(
            price: Decimal(120),
            billingFrequency: .yearly
        )
        
        #expect(result == Decimal(10))
    }
    
    @Test
    func yearlySubscriptionKeepsAnnualPrice() {
        let result = SubscriptionCalculator.annualEquivalent(
            price: Decimal(120),
            billingFrequency: .yearly
        )
        
        #expect(result == Decimal(120))
    }
    
    @Test
    func cancellationSavingsUsesNormalizedValues() {
        let result = SubscriptionCalculator.cancellationSavings(
            price: Decimal(120),
            billingFrequency: .yearly
        )
        
        #expect(result.monthly == Decimal(10))
        #expect(result.annual == Decimal(120))
    }
    
    @Test
    func totalMonthlyCostCombinesMonthlyAndYearlySubscriptions() {
        let subscriptions = [
            Subscription(
                name: "Monthly",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date()
            ),
            Subscription(
                name: "Yearly",
                price: Decimal(120),
                billingFrequency: .yearly,
                nextBillingDate: Date()
            )
        ]
        
        let result = SubscriptionCalculator.totalMonthlyCost(
            for: subscriptions
        )
        
        #expect(result == Decimal(20))
    }
    
    @Test
    func totalAnnualCostCombinesMonthlyAndYearlySubscriptions() {
        let subscriptions = [
            Subscription(
                name: "Monthly",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date()
            ),
            Subscription(
                name: "Yearly",
                price: Decimal(120),
                billingFrequency: .yearly,
                nextBillingDate: Date()
            )
        ]
        
        let result = SubscriptionCalculator.totalAnnualCost(
            for: subscriptions
        )
        
        #expect(result == Decimal(240))
    }
    
    @Test
    func canceledSubscriptionsAreExcludedFromMonthlyTotal() {
        let subscriptions = [
            Subscription(
                name: "Active",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date()
            ),
            Subscription(
                name: "Canceled",
                price: Decimal(20),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                status: .canceled
            )
        ]
        
        let result = SubscriptionCalculator.totalMonthlyCost(
            for: subscriptions
        )
        
        #expect(result == Decimal(10))
    }
    
    @Test
    func canceledSubscriptionsAreExcludedFromAnnualTotal() {
        let subscriptions = [
            Subscription(
                name: "Active",
                price: Decimal(10),
                billingFrequency: .monthly,
                nextBillingDate: Date()
            ),
            Subscription(
                name: "Canceled",
                price: Decimal(120),
                billingFrequency: .yearly,
                nextBillingDate: Date(),
                status: .canceled
            )
        ]
        
        let result = SubscriptionCalculator.totalAnnualCost(
            for: subscriptions
        )
        
        #expect(result == Decimal(120))
    }
    
    @Test
    func renewalDueSoonWithinSevenDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let subscription = Subscription(
            name: "Netflix",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: calendar.date(
                byAdding: .day,
                value: 5,
                to: today
            )!
        )
        
        #expect(
            RenewalCalculator.isDueSoon(
                subscription,
                withinDays: 7,
                from: today
            )
        )
    }
    
    @Test
    func renewalOutsideSevenDaysIsNotDueSoon() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let subscription = Subscription(
            name: "Netflix",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: calendar.date(
                byAdding: .day,
                value: 10,
                to: today
            )!
        )
        
        #expect(
            !RenewalCalculator.isDueSoon(
                subscription,
                withinDays: 7,
                from: today
            )
        )
    }
    
    @Test
    func pastRenewalIsOverdue() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let subscription = Subscription(
            name: "Netflix",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: calendar.date(
                byAdding: .day,
                value: -2,
                to: today
            )!
        )
        
        #expect(
            RenewalCalculator.isOverdue(
                subscription,
                from: today
            )
        )
    }
    
    @Test
    func canceledSubscriptionIsNotDueSoon() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let subscription = Subscription(
            name: "Canceled",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: today,
            status: .canceled
        )
        
        #expect(
            !RenewalCalculator.isDueSoon(
                subscription,
                from: today
            )
        )
    }
    
    @Test
    func monthlyRenewalAdvancesOneMonth() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 13
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .monthly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 13)
    }
    
    @Test
    func yearlyRenewalAdvancesOneYear() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 13
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .yearly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2027)
        #expect(components.month == 8)
        #expect(components.day == 13)
    }
    
    @Test
    func zeroSubscriptionsProduceZeroMonthlyTotal() {
        let subscriptions: [Subscription] = []
        
        let result = SubscriptionCalculator.totalMonthlyCost(
            for: subscriptions
        )
        
        #expect(result == Decimal.zero)
    }
    
    @Test
    func zeroSubscriptionsProduceZeroAnnualTotal() {
        let subscriptions: [Subscription] = []
        
        let result = SubscriptionCalculator.totalAnnualCost(
            for: subscriptions
        )
        
        #expect(result == Decimal.zero)
    }
    
    @Test
    func january31AdvancesToFebruary28InNonLeapYear() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 1,
                day: 31
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .monthly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2026)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }
    
    @Test
    func january31AdvancesToFebruary29InLeapYear() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2028,
                month: 1,
                day: 31
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .monthly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2028)
        #expect(components.month == 2)
        #expect(components.day == 29)
    }
    
    @Test
    func march31AdvancesToApril30() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 3,
                day: 31
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .monthly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2026)
        #expect(components.month == 4)
        #expect(components.day == 30)
    }
    
    @Test
    func leapDayYearlyRenewalAdvancesToFebruary28() {
        let calendar = Calendar.current
        
        let startingDate = calendar.date(
            from: DateComponents(
                year: 2028,
                month: 2,
                day: 29
            )
        )!
        
        let result = RenewalCalculator.nextRenewalDate(
            after: startingDate,
            billingFrequency: .yearly,
            calendar: calendar
        )!
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: result
        )
        
        #expect(components.year == 2029)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }
    
    @Test
    func changingMonthlyPriceUpdatesMonthlyAndAnnualTotals() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )
        
        let subscriptions = [subscription]
        
        #expect(
            SubscriptionCalculator.totalMonthlyCost(
                for: subscriptions
            ) == Decimal(10)
        )
        
        #expect(
            SubscriptionCalculator.totalAnnualCost(
                for: subscriptions
            ) == Decimal(120)
        )
        
        subscription.price = Decimal(25)
        
        #expect(
            SubscriptionCalculator.totalMonthlyCost(
                for: subscriptions
            ) == Decimal(25)
        )
        
        #expect(
            SubscriptionCalculator.totalAnnualCost(
                for: subscriptions
            ) == Decimal(300)
        )
    }
    
    @Test
    func changingBillingFrequencyUpdatesNormalizedTotals() {
        let subscription = Subscription(
            name: "Test",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: Date()
        )
        
        let subscriptions = [subscription]
        
        #expect(
            SubscriptionCalculator.totalMonthlyCost(
                for: subscriptions
            ) == Decimal(10)
        )
        
        #expect(
            SubscriptionCalculator.totalAnnualCost(
                for: subscriptions
            ) == Decimal(120)
        )
        
        subscription.billingFrequency = .monthly
        
        #expect(
            SubscriptionCalculator.totalMonthlyCost(
                for: subscriptions
            ) == Decimal(120)
        )
        
        #expect(
            SubscriptionCalculator.totalAnnualCost(
                for: subscriptions
            ) == Decimal(1440)
        )
    }
    @Test
    func yearlySubscriptionKeepsActualRenewalAmountWhileNormalizingMonthlyCost() {
        let subscription = Subscription(
            name: "Annual Service",
            price: Decimal(240),
            billingFrequency: .yearly,
            nextBillingDate: Date()
        )
        
        let monthlyEquivalent =
        SubscriptionCalculator.monthlyEquivalent(
            price: subscription.price,
            billingFrequency: subscription.billingFrequency
        )
        
        #expect(subscription.price == Decimal(240))
        #expect(monthlyEquivalent == Decimal(20))
    }
    
    @Test
    func supportedCurrenciesNormalizePriceToTwoDecimalPlaces() {
        let originalAmount = Decimal(string: "10.999")!
        
        for currencyCode in ["USD", "CAD", "EUR", "GBP"] {
            let normalizedAmount = CurrencyAmount.normalized(
                originalAmount,
                currencyCode: currencyCode
            )
            
            #expect(normalizedAmount == Decimal(11))
        }
    }
    
    @Test
    func currencyNormalizationUsesCurrencyMinorUnits() {
        let originalAmount = Decimal(string: "10.6")!
        
        let normalizedAmount = CurrencyAmount.normalized(
            originalAmount,
            currencyCode: "JPY"
        )
        
        #expect(normalizedAmount == Decimal(11))
    }
    
    @Test
    func csvExportIncludesExpectedHeadersAndValues() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let renewalDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 20
            )
        )!
        
        let subscription = Subscription(
            name: "Netflix",
            price: Decimal(string: "19.99")!,
            billingFrequency: .monthly,
            nextBillingDate: renewalDate,
            category: SubscriptionCategory.streaming.rawValue,
            notes: "Family plan",
            reminderEnabled: true
        )
        
        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD",
            calendar: calendar
        )
        
        #expect(
            csv.hasPrefix(
                "\"Name\",\"Price\",\"Currency\",\"Billing Frequency\",\"Next Renewal Date\",\"Status\",\"Category\",\"Reminder Enabled\",\"Notes\",\"Cancellation Date\"\r\n"
            )
        )
        
        #expect(
            csv.contains(
                "\"Netflix\",\"19.99\",\"USD\",\"Monthly\",\"2026-08-20\",\"Active\",\"Streaming\",\"Yes\",\"Family plan\",\"\"\r\n"
            )
        )
    }
    
    @Test
    func csvExportEscapesCommasAndQuotationMarks() {
        let subscription = Subscription(
            name: "Movies, Music",
            price: Decimal(15),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            notes: "Shared \"family\" plan"
        )
        
        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "USD"
        )
        
        #expect(
            csv.contains("\"Movies, Music\"")
        )
        
        #expect(
            csv.contains(
                "\"Shared \"\"family\"\" plan\""
            )
        )
    }
    
    @Test
    func csvExportIncludesCanceledSubscriptionDetails() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let renewalDate = calendar.date(
            from: DateComponents(
                year: 2027,
                month: 8,
                day: 20
            )
        )!
        
        let cancellationDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 15
            )
        )!
        
        let subscription = Subscription(
            name: "Annual Service",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: renewalDate,
            category: SubscriptionCategory.software.rawValue,
            reminderEnabled: false,
            status: .canceled,
            cancellationDate: cancellationDate
        )
        
        let csv = SubscriptionCSVExporter.csvString(
            for: [subscription],
            currencyCode: "GBP",
            calendar: calendar
        )
        
        #expect(
            csv.contains(
                "\"Annual Service\",\"120\",\"GBP\",\"Yearly\",\"2027-08-20\",\"Canceled\",\"Software\",\"No\",\"\",\"2026-08-15\"\r\n"
            )
        )
    }
    
    @Test
    func csvExportCreatesNamedUTF8File() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let exportDate = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 8,
                day: 20
            )
        )!
        
        let subscription = Subscription(
            name: "Test",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: exportDate
        )
        
        let fileURL = try SubscriptionCSVExporter
            .createTemporaryFile(
                for: [subscription],
                currencyCode: "USD",
                date: exportDate,
                calendar: calendar
            )
        
        defer {
            try? FileManager.default.removeItem(
                at: fileURL
            )
        }
        
        #expect(
            fileURL.lastPathComponent ==
            "SubscriptionTracker-Export-2026-08-20.csv"
        )
        
        let fileData = try Data(contentsOf: fileURL)
        let utf8ByteOrderMark = Data([
            0xEF,
            0xBB,
            0xBF
        ])
        
        #expect(
            fileData.starts(
                with: utf8ByteOrderMark
            )
        )
    }
    
    @Test
    func subscriptionOrganizerFiltersByStatus() {
        let activeSubscription = Subscription(
            name: "Active Service",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            status: .active
        )

        let canceledSubscription = Subscription(
            name: "Canceled Service",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            status: .canceled
        )

        let result = SubscriptionListOrganizer.organize(
            [
                activeSubscription,
                canceledSubscription
            ],
            statusFilter: .active,
            billingFilter: .all,
            sortOption: .name
        )

        #expect(
            result.map(\.name) ==
            ["Active Service"]
        )
    }

    @Test
    func subscriptionOrganizerFiltersByBillingFrequency() {
        let monthlySubscription = Subscription(
            name: "Monthly Service",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let yearlySubscription = Subscription(
            name: "Yearly Service",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: Date()
        )

        let result = SubscriptionListOrganizer.organize(
            [
                monthlySubscription,
                yearlySubscription
            ],
            statusFilter: .all,
            billingFilter: .yearly,
            sortOption: .name
        )

        #expect(
            result.map(\.name) ==
            ["Yearly Service"]
        )
    }

    @Test
    func subscriptionOrganizerSortsByPrice() {
        let lowerPrice = Subscription(
            name: "Lower Price",
            price: Decimal(5),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let higherPrice = Subscription(
            name: "Higher Price",
            price: Decimal(25),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let subscriptions = [
            lowerPrice,
            higherPrice
        ]

        let highToLow =
            SubscriptionListOrganizer.organize(
                subscriptions,
                statusFilter: .all,
                billingFilter: .all,
                sortOption: .priceHighToLow
            )

        let lowToHigh =
            SubscriptionListOrganizer.organize(
                subscriptions,
                statusFilter: .all,
                billingFilter: .all,
                sortOption: .priceLowToHigh
            )

        #expect(
            highToLow.map(\.name) ==
            [
                "Higher Price",
                "Lower Price"
            ]
        )

        #expect(
            lowToHigh.map(\.name) ==
            [
                "Lower Price",
                "Higher Price"
            ]
        )
    }

    @Test
    func subscriptionOrganizerSortsByRenewalDate() {
        let earlierDate = Date(
            timeIntervalSince1970: 1_000
        )

        let laterDate = Date(
            timeIntervalSince1970: 2_000
        )

        let laterSubscription = Subscription(
            name: "Later Renewal",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: laterDate
        )

        let earlierSubscription = Subscription(
            name: "Earlier Renewal",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: earlierDate
        )

        let result = SubscriptionListOrganizer.organize(
            [
                laterSubscription,
                earlierSubscription
            ],
            statusFilter: .all,
            billingFilter: .all,
            sortOption: .renewalDate
        )

        #expect(
            result.map(\.name) ==
            [
                "Earlier Renewal",
                "Later Renewal"
            ]
        )
    }

    @Test
    func insightsGroupsAndRanksCategorySpending() {
        let subscriptions = [
            Subscription(
                name: "Streaming Monthly",
                price: Decimal(20),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category:
                    SubscriptionCategory.streaming.rawValue
            ),
            Subscription(
                name: "Streaming Yearly",
                price: Decimal(120),
                billingFrequency: .yearly,
                nextBillingDate: Date(),
                category:
                    SubscriptionCategory.streaming.rawValue
            ),
            Subscription(
                name: "Software",
                price: Decimal(15),
                billingFrequency: .monthly,
                nextBillingDate: Date(),
                category:
                    SubscriptionCategory.software.rawValue
            )
        ]

        let insights =
            SubscriptionInsightsCalculator
                .spendingByCategory(
                    for: subscriptions
                )

        #expect(insights.count == 2)
        #expect(
            insights[0].category ==
                SubscriptionCategory.streaming.rawValue
        )
        #expect(insights[0].monthlyCost == Decimal(30))
        #expect(insights[0].annualCost == Decimal(360))

        #expect(
            insights[1].category ==
                SubscriptionCategory.software.rawValue
        )
        #expect(insights[1].monthlyCost == Decimal(15))
        #expect(insights[1].annualCost == Decimal(180))
    }

    @Test
    func insightsExcludeCanceledSubscriptions() {
        let activeSubscription = Subscription(
            name: "Active",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category:
                SubscriptionCategory.productivity.rawValue
        )

        let canceledSubscription = Subscription(
            name: "Canceled",
            price: Decimal(100),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category:
                SubscriptionCategory.business.rawValue,
            status: .canceled
        )

        let insights =
            SubscriptionInsightsCalculator
                .spendingByCategory(
                    for: [
                        activeSubscription,
                        canceledSubscription
                    ]
                )

        #expect(insights.count == 1)
        #expect(
            insights[0].category ==
                SubscriptionCategory.productivity.rawValue
        )
        #expect(insights[0].monthlyCost == Decimal(10))
    }

    @Test
    func insightsTreatBlankCategoryAsOther() {
        let subscription = Subscription(
            name: "Uncategorized",
            price: Decimal(12),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            category: "   "
        )

        let insights =
            SubscriptionInsightsCalculator
                .spendingByCategory(
                    for: [subscription]
                )

        #expect(insights.count == 1)
        #expect(
            insights[0].category ==
                SubscriptionCategory.other.rawValue
        )
    }

    @Test
    func insightsRankLargestSubscriptionsByMonthlyCost() {
        let monthlySubscription = Subscription(
            name: "Monthly Plus",
            price: Decimal(15),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let yearlySubscription = Subscription(
            name: "Yearly Pro",
            price: Decimal(240),
            billingFrequency: .yearly,
            nextBillingDate: Date()
        )

        let canceledSubscription = Subscription(
            name: "Canceled Premium",
            price: Decimal(100),
            billingFrequency: .monthly,
            nextBillingDate: Date(),
            status: .canceled
        )

        let rankedSubscriptions =
            SubscriptionInsightsCalculator
                .largestSubscriptions(
                    from: [
                        monthlySubscription,
                        yearlySubscription,
                        canceledSubscription
                    ]
                )

        #expect(
            rankedSubscriptions.map(\.name) == [
                "Yearly Pro",
                "Monthly Plus"
            ]
        )
    }

    @Test
    func renewalCalendarReturnsEveryDayInThirtyOneDayMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = calendar.date(
            from: DateComponents(
                year: 2027,
                month: 1,
                day: 15
            )
        )!

        let days = RenewalCalendarCalculator.days(
            inMonthContaining: date,
            calendar: calendar
        )

        #expect(days.count == 31)
        #expect(calendar.component(.day, from: days.first!) == 1)
        #expect(calendar.component(.day, from: days.last!) == 31)
    }

    @Test
    func renewalCalendarHandlesLeapYearFebruary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let date = calendar.date(
            from: DateComponents(
                year: 2028,
                month: 2,
                day: 10
            )
        )!

        let days = RenewalCalendarCalculator.days(
            inMonthContaining: date,
            calendar: calendar
        )

        #expect(days.count == 29)
        #expect(calendar.component(.day, from: days.last!) == 29)
    }

    @Test
    func renewalCalendarReturnsOnlyActiveSubscriptionsForDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let renewalDate = calendar.date(
            from: DateComponents(
                year: 2027,
                month: 3,
                day: 12
            )
        )!

        let activeSubscription = Subscription(
            name: "Active Service",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: renewalDate
        )

        let canceledSubscription = Subscription(
            name: "Canceled Service",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: renewalDate,
            status: .canceled
        )

        let results = RenewalCalendarCalculator
            .activeSubscriptions(
                on: renewalDate,
                from: [
                    canceledSubscription,
                    activeSubscription
                ],
                calendar: calendar
            )

        #expect(results.count == 1)
        #expect(results.first?.name == "Active Service")
    }

    @Test
    func renewalCalendarSortsSameDaySubscriptionsByName() {
        let renewalDate = Date()

        let zebra = Subscription(
            name: "Zebra",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: renewalDate
        )

        let alpha = Subscription(
            name: "Alpha",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: renewalDate
        )

        let results = RenewalCalendarCalculator
            .activeSubscriptions(
                on: renewalDate,
                from: [zebra, alpha]
            )

        #expect(
            results.map(\.name) == [
                "Alpha",
                "Zebra"
            ]
        )
    }

    @Test
    func renewalCalendarCalculatesDailyChargeTotal() {
        let renewalDate = Date()

        let monthlyService = Subscription(
            name: "Monthly Service",
            price: Decimal(string: "19.99")!,
            billingFrequency: .monthly,
            nextBillingDate: renewalDate
        )

        let yearlyService = Subscription(
            name: "Yearly Service",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: renewalDate
        )

        let total = RenewalCalendarCalculator.totalCharges(
            on: renewalDate,
            from: [
                monthlyService,
                yearlyService
            ]
        )

        #expect(total == Decimal(string: "139.99")!)
        #expect(
            RenewalCalendarCalculator.hasRenewals(
                on: renewalDate,
                from: [
                    monthlyService,
                    yearlyService
                ]
            )
        )
    }

    @Test
    func priceChangeRecorderRecordsPriceChange() {
        let subscription = Subscription(
            name: "Streaming",
            price: Decimal(10),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let recorded =
            SubscriptionPriceChangeRecorder.recordChange(
                for: subscription,
                newPrice: Decimal(12),
                newBillingFrequency: .monthly
            )

        #expect(recorded)
        #expect(subscription.priceChanges.count == 1)

        let change = subscription.priceChanges[0]

        #expect(change.previousPrice == Decimal(10))
        #expect(change.newPrice == Decimal(12))
        #expect(
            change.previousBillingFrequency == .monthly
        )
        #expect(
            change.newBillingFrequency == .monthly
        )
    }

    @Test
    func priceChangeRecorderRecordsBillingFrequencyChange() {
        let subscription = Subscription(
            name: "Software",
            price: Decimal(120),
            billingFrequency: .yearly,
            nextBillingDate: Date()
        )

        let recorded =
            SubscriptionPriceChangeRecorder.recordChange(
                for: subscription,
                newPrice: Decimal(120),
                newBillingFrequency: .monthly
            )

        #expect(recorded)
        #expect(subscription.priceChanges.count == 1)

        let change = subscription.priceChanges[0]

        #expect(
            change.previousBillingFrequency == .yearly
        )
        #expect(
            change.newBillingFrequency == .monthly
        )
    }

    @Test
    func priceChangeRecorderDoesNotRecordUnchangedValues() {
        let subscription = Subscription(
            name: "Cloud Storage",
            price: Decimal(15),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        let recorded =
            SubscriptionPriceChangeRecorder.recordChange(
                for: subscription,
                newPrice: Decimal(15),
                newBillingFrequency: .monthly
            )

        #expect(recorded == false)
        #expect(subscription.priceChanges.isEmpty)
    }

    @Test
    func priceChangeRecorderPreservesMultipleChanges() {
        let subscription = Subscription(
            name: "AI Service",
            price: Decimal(20),
            billingFrequency: .monthly,
            nextBillingDate: Date()
        )

        SubscriptionPriceChangeRecorder.recordChange(
            for: subscription,
            newPrice: Decimal(25),
            newBillingFrequency: .monthly
        )

        subscription.price = Decimal(25)

        SubscriptionPriceChangeRecorder.recordChange(
            for: subscription,
            newPrice: Decimal(30),
            newBillingFrequency: .monthly
        )

        #expect(subscription.priceChanges.count == 2)
        #expect(
            subscription.priceChanges[0].previousPrice ==
            Decimal(20)
        )
        #expect(
            subscription.priceChanges[1].previousPrice ==
            Decimal(25)
        )
    }
}

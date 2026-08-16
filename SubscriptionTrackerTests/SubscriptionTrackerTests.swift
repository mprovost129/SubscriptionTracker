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
}

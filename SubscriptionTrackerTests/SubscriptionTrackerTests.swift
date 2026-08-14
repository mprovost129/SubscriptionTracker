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
}

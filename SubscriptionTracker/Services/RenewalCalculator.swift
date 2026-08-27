import Foundation

struct RenewalCalculator {
    
    static func daysUntilRenewal(
        for subscription: Subscription,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: date)
        let renewal = calendar.startOfDay(
            for: subscription.nextBillingDate
        )
        
        return calendar.dateComponents(
            [.day],
            from: start,
            to: renewal
        ).day ?? 0
    }
    
    static func isDueSoon(
        _ subscription: Subscription,
        withinDays days: Int = 7,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.status == .active else {
            return false
        }
        
        let daysRemaining = daysUntilRenewal(
            for: subscription,
            from: date,
            calendar: calendar
        )
        
        return daysRemaining >= 0 && daysRemaining <= days
    }
    
    static func isOverdue(
        _ subscription: Subscription,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard subscription.status == .active else {
            return false
        }
        
        return daysUntilRenewal(
            for: subscription,
            from: date,
            calendar: calendar
        ) < 0
    }
    
    static func nextRenewalDate(
        after date: Date,
        billingFrequency: BillingFrequency,
        calendar: Calendar = .current
    ) -> Date? {
        switch billingFrequency {
        case .weekly:
            return calendar.date(
                byAdding: .day,
                value: 7,
                to: date
            )

        case .monthly:
            return nextDate(
                after: date,
                addingMonths: 1,
                calendar: calendar
            )

        case .quarterly:
            return nextDate(
                after: date,
                addingMonths: 3,
                calendar: calendar
            )

        case .yearly:
            return nextYearlyDate(
                after: date,
                calendar: calendar
            )
        }
    }
    
    private static func nextDate(
        after date: Date,
        addingMonths monthCount: Int,
        calendar: Calendar
    ) -> Date? {
        let originalDay = calendar.component(
            .day,
            from: date
        )

        guard
            let targetMonth = calendar.date(
                byAdding: .month,
                value: monthCount,
                to: date
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: targetMonth
            )
        else {
            return nil
        }

        var components = calendar.dateComponents(
            [.year, .month, .hour, .minute, .second],
            from: targetMonth
        )

        components.day = min(
            originalDay,
            dayRange.count
        )

        return calendar.date(from: components)
    }
    
    private static func nextYearlyDate(
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        let originalComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        
        guard
            let originalYear = originalComponents.year,
            let originalMonth = originalComponents.month,
            let originalDay = originalComponents.day
        else {
            return nil
        }
        
        let targetYear = originalYear + 1
        
        var firstOfTargetMonth = DateComponents()
        firstOfTargetMonth.year = targetYear
        firstOfTargetMonth.month = originalMonth
        firstOfTargetMonth.day = 1
        
        guard
            let targetMonthDate = calendar.date(
                from: firstOfTargetMonth
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: targetMonthDate
            )
        else {
            return nil
        }
        
        let targetDay = min(
            originalDay,
            dayRange.count
        )
        
        var resultComponents = DateComponents()
        resultComponents.year = targetYear
        resultComponents.month = originalMonth
        resultComponents.day = targetDay
        
        return calendar.date(
            from: resultComponents
        )
    }
}

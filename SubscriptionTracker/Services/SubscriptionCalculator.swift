import Foundation

struct SubscriptionCalculator {
    
    static func monthlyEquivalent(
        price: Decimal,
        billingFrequency: BillingFrequency
    ) -> Decimal {
        switch billingFrequency {
        case .weekly:
            return price * 52 / 12

        case .monthly:
            return price

        case .quarterly:
            return price / 3

        case .yearly:
            return price / 12
        }
    }
    
    static func annualEquivalent(
        price: Decimal,
        billingFrequency: BillingFrequency
    ) -> Decimal {
        switch billingFrequency {
        case .weekly:
            return price * 52

        case .monthly:
            return price * 12

        case .quarterly:
            return price * 4

        case .yearly:
            return price
        }
    }
    
    static func cancellationSavings(
        price: Decimal,
        billingFrequency: BillingFrequency
    ) -> (monthly: Decimal, annual: Decimal) {
        let monthly = monthlyEquivalent(
            price: price,
            billingFrequency: billingFrequency
        )
        
        let annual = annualEquivalent(
            price: price,
            billingFrequency: billingFrequency
        )
        
        return (monthly, annual)
    }
    
    static func totalMonthlyCost(
        for subscriptions: [Subscription]
    ) -> Decimal {
        subscriptions
            .filter { $0.status == .active }
            .reduce(Decimal.zero) { total, subscription in
                total + monthlyEquivalent(
                    price: subscription.price,
                    billingFrequency: subscription.billingFrequency
                )
            }
    }
    
    static func totalAnnualCost(
        for subscriptions: [Subscription]
    ) -> Decimal {
        subscriptions
            .filter { $0.status == .active }
            .reduce(Decimal.zero) { total, subscription in
                total + annualEquivalent(
                    price: subscription.price,
                    billingFrequency: subscription.billingFrequency
                )
            }
    }
}

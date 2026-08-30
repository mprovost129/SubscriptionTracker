import Foundation

struct CancellationSavingsSummary: Equatable {
    let selectedCount: Int
    let monthlySavings: Decimal

    var yearlySavings: Decimal {
        monthlySavings * 12
    }
}

enum CancellationSavingsCalculator {
    static func summary(
        forMonthlyCosts monthlyCosts: [Decimal]
    ) -> CancellationSavingsSummary {
        CancellationSavingsSummary(
            selectedCount: monthlyCosts.count,
            monthlySavings: monthlyCosts.reduce(.zero, +)
        )
    }
}

import Foundation

enum CurrencyAmount {
    static func fractionDigits(
        for currencyCode: String
    ) -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        return formatter.maximumFractionDigits
    }

    static func normalized(
        _ amount: Decimal,
        currencyCode: String
    ) -> Decimal {
        var amount = amount
        var normalizedAmount = Decimal()

        NSDecimalRound(
            &normalizedAmount,
            &amount,
            fractionDigits(for: currencyCode),
            .plain
        )

        return normalizedAmount
    }
}

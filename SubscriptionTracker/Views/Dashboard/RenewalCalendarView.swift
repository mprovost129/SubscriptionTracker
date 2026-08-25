import SwiftUI

struct RenewalCalendarView: View {
    let subscriptions: [Subscription]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode

    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()

    private let calendar = Calendar.current

    private var daysInDisplayedMonth: [Date] {
        RenewalCalendarCalculator.days(
            inMonthContaining: displayedMonth,
            calendar: calendar
        )
    }

    private var selectedSubscriptions: [Subscription] {
        RenewalCalendarCalculator.activeSubscriptions(
            on: selectedDate,
            from: subscriptions,
            calendar: calendar
        )
    }

    private var selectedTotal: Decimal {
        RenewalCalendarCalculator.totalCharges(
            on: selectedDate,
            from: subscriptions,
            calendar: calendar
        )
    }

    private var leadingBlankCount: Int {
        guard let firstDay = daysInDisplayedMonth.first else {
            return 0
        }

        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )

        return (
            weekday - calendar.firstWeekday + 7
        ) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols =
            calendar.veryShortStandaloneWeekdaySymbols
        let startingIndex = calendar.firstWeekday - 1

        return Array(symbols[startingIndex...])
            + Array(symbols[..<startingIndex])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    monthNavigation

                    if dynamicTypeSize.isAccessibilitySize {
                        accessibleMonthList
                    } else {
                        calendarGrid
                    }

                    selectedDateDetails
                }
                .padding()
            }
            .navigationTitle("Renewal Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var monthNavigation: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Label(
                    "Previous Month",
                    systemImage: "chevron.left"
                )
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }

            Spacer()

            Text(
                displayedMonth.formatted(
                    .dateTime
                        .month(.wide)
                        .year()
                )
            )
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Label(
                    "Next Month",
                    systemImage: "chevron.right"
                )
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: 4
                ),
                count: 7
            ),
            spacing: 8
        ) {
            ForEach(
                Array(weekdaySymbols.enumerated()),
                id: \.offset
            ) { _, symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            ForEach(0..<leadingBlankCount, id: \.self) {
                _ in
                Color.clear
                    .frame(minHeight: 44)
                    .accessibilityHidden(true)
            }

            ForEach(daysInDisplayedMonth, id: \.self) {
                date in
                calendarDayButton(for: date)
            }
        }
    }

    private func calendarDayButton(
        for date: Date
    ) -> some View {
        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )

        let hasRenewals =
            RenewalCalendarCalculator.hasRenewals(
                on: date,
                from: subscriptions,
                calendar: calendar
            )

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 3) {
                Text(
                    date.formatted(
                        .dateTime.day()
                    )
                )
                .font(.body)
                .fontWeight(
                    isSelected ? .bold : .regular
                )

                Circle()
                    .fill(
                        hasRenewals
                            ? Color.accentColor
                            : Color.clear
                    )
                    .frame(width: 6, height: 6)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 44
            )
            .background {
                if isSelected {
                    Circle()
                        .fill(
                            Color.accentColor.opacity(0.18)
                        )
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            accessibilityLabel(
                for: date,
                hasRenewals: hasRenewals
            )
        )
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private var accessibleMonthList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Renewal Dates")
                .font(.title2)
                .fontWeight(.bold)

            let renewalDates = daysInDisplayedMonth.filter {
                RenewalCalendarCalculator.hasRenewals(
                    on: $0,
                    from: subscriptions,
                    calendar: calendar
                )
            }

            if renewalDates.isEmpty {
                Text("No renewals scheduled this month.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(renewalDates, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        HStack {
                            Text(
                                date.formatted(
                                    date: .complete,
                                    time: .omitted
                                )
                            )

                            Spacer()

                            Image(
                                systemName: "chevron.right"
                            )
                            .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
            }
        }
    }

    private var selectedDateDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                selectedDate.formatted(
                    date: .complete,
                    time: .omitted
                )
            )
            .font(.title2)
            .fontWeight(.bold)

            if selectedSubscriptions.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Renewals",
                        systemImage: "calendar"
                    )
                } description: {
                    Text(
                        "No active subscriptions renew on this date."
                    )
                    .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scheduled Total")
                            .fontWeight(.semibold)

                        Text(
                            selectedTotal.formatted(
                                .currency(code: currencyCode)
                            )
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    HStack {
                        Text("Scheduled Total")
                            .fontWeight(.semibold)

                        Spacer()

                        Text(
                            selectedTotal.formatted(
                                .currency(code: currencyCode)
                            )
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    }
                    .accessibilityElement(children: .combine)
                }

                Divider()

                ForEach(selectedSubscriptions) {
                    subscription in
                    NavigationLink {
                        SubscriptionDetailView(
                            subscription: subscription
                        )
                    } label: {
                        Group {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(subscription.name)
                                        .fontWeight(.semibold)

                                    Text(
                                        subscription
                                            .billingFrequency
                                            .rawValue
                                            .capitalized
                                    )
                                    .foregroundStyle(.primary)

                                    Text(
                                        subscription.price.formatted(
                                            .currency(
                                                code: currencyCode
                                            )
                                        )
                                    )
                                    .foregroundStyle(.primary)
                                }
                            } else {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading) {
                                        Text(subscription.name)
                                            .fontWeight(.semibold)

                                        Text(
                                            subscription
                                                .billingFrequency
                                                .rawValue
                                                .capitalized
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                    }

                                    Spacer()

                                    Text(
                                        subscription.price.formatted(
                                            .currency(
                                                code: currencyCode
                                            )
                                        )
                                    )
                                    .foregroundStyle(.primary)
                                }
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44,
                            alignment: .leading
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)

                    if subscription.id
                        != selectedSubscriptions.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func changeMonth(by value: Int) {
        guard
            let newMonth = calendar.date(
                byAdding: .month,
                value: value,
                to: displayedMonth
            ),
            let firstDay = calendar.dateInterval(
                of: .month,
                for: newMonth
            )?.start
        else {
            return
        }

        displayedMonth = newMonth
        selectedDate = firstDay
    }

    private func accessibilityLabel(
        for date: Date,
        hasRenewals: Bool
    ) -> String {
        let dateText = date.formatted(
            date: .complete,
            time: .omitted
        )

        if hasRenewals {
            return "\(dateText), has scheduled renewals"
        }

        return "\(dateText), no scheduled renewals"
    }
}

import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    let subscription: Subscription
    
    @State private var showingEdit = false
    @State private var showingCancelConfirmation = false
    @State private var showingReactivateConfirmation = false
    @State private var showingRenewedConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPersistenceError = false
    @State private var persistenceErrorMessage = ""
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyCodeKey)
    
    private var currencyCode = AppSettings.defaultCurrencyCode
    
    private var monthlyEquivalent: Decimal {
        SubscriptionCalculator.monthlyEquivalent(
            price: subscription.price,
            billingFrequency: subscription.billingFrequency
        )
    }

    private var annualEquivalent: Decimal {
        SubscriptionCalculator.annualEquivalent(
            price: subscription.price,
            billingFrequency: subscription.billingFrequency
        )
    }

    private var activeTrialEndDate: Date? {
        guard subscription.status == .active,
              let trialEndDate = subscription.trialEndDate,
              SubscriptionTrialCalculator.isActive(
                  trialEndDate: trialEndDate
              ) else {
            return nil
        }

        return trialEndDate
    }

    private var trialDaysRemaining: Int? {
        SubscriptionTrialCalculator.daysRemaining(
            until: activeTrialEndDate
        )
    }

    private var trialStatusText: String {
        guard activeTrialEndDate != nil else {
            return "Ended"
        }

        guard let trialDaysRemaining else {
            return "Active"
        }

        switch trialDaysRemaining {
        case 0:
            return "Ends Today"
        case 1:
            return "1 Day Remaining"
        default:
            return "\(trialDaysRemaining) Days Remaining"
        }
    }

    private var billingLabel: String {
        subscription.billingFrequency.displayName
    }
    
    private var reminderStatusText: String {
        guard subscription.status == .active else {
            return "Off (Canceled)"
        }

        guard subscription.reminderEnabled else {
            return "Off"
        }

        return AppSettings.reminderTimingText(
            for: subscription.reminderDaysBefore
        )
    }
    
    private var renewalDateAfterMarkingRenewed: Date? {
        RenewalCalculator.nextRenewalDate(
            after: subscription.nextBillingDate,
            billingFrequency: subscription.billingFrequency
        )
    }
    
    private func markSubscriptionRenewed() async {
        guard
            subscription.status == .active,
            let nextRenewalDate = renewalDateAfterMarkingRenewed
        else {
            persistenceErrorMessage =
                "The next renewal date could not be calculated."
            showingPersistenceError = true
            return
        }

        let previousNextBillingDate =
            subscription.nextBillingDate
        let previousUpdatedAt = subscription.updatedAt

        subscription.nextBillingDate = nextRenewalDate
        subscription.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            subscription.nextBillingDate =
                previousNextBillingDate
            subscription.updatedAt = previousUpdatedAt

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
            return
        }

        if subscription.reminderEnabled {
            do {
                try await NotificationService
                    .scheduleRenewalReminder(
                        for: subscription
                    )
            } catch {
                print("Notification error: \(error)")
            }
        } else {
            NotificationService.removeRenewalReminder(
                for: subscription
            )
        }
    }
    
    private func cancelSubscription() {
        let previousStatus = subscription.status
        let previousCancellationDate = subscription.cancellationDate
        let previousUpdatedAt = subscription.updatedAt

        subscription.status = .canceled
        subscription.cancellationDate = Date()
        subscription.updatedAt = Date()

        do {
            try modelContext.save()

            NotificationService.removeRenewalReminder(
                for: subscription
            )
        } catch {
            subscription.status = previousStatus
            subscription.cancellationDate = previousCancellationDate
            subscription.updatedAt = previousUpdatedAt

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
        }
    }
    
    private func reactivateSubscription() async {
        let previousStatus = subscription.status
        let previousCancellationDate = subscription.cancellationDate
        let previousUpdatedAt = subscription.updatedAt

        subscription.status = .active
        subscription.cancellationDate = nil
        subscription.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            subscription.status = previousStatus
            subscription.cancellationDate = previousCancellationDate
            subscription.updatedAt = previousUpdatedAt

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
            return
        }

        guard subscription.reminderEnabled else {
            return
        }

        do {
            let granted =
                try await NotificationService.requestAuthorization()

            if granted {
                try await NotificationService.scheduleRenewalReminder(
                    for: subscription
                )
            }
        } catch {
            print("Notification error: \(error)")
        }
    }
    
    private func deleteSubscription() {
        modelContext.delete(subscription)

        do {
            try modelContext.save()

            NotificationService.removeRenewalReminder(
                for: subscription
            )

            dismiss()
        } catch {
            modelContext.rollback()

            persistenceErrorMessage = error.localizedDescription
            showingPersistenceError = true
        }
    }

    private var sortedPriceChanges: [SubscriptionPriceChange] {
        subscription.priceChanges.sorted {
            $0.changedAt > $1.changedAt
        }
    }

    private var changeCountText: String {
        let count = sortedPriceChanges.count

        return count == 1
            ? "1 Change"
            : "\(count) Changes"
    }
    
    var body: some View {
        Form {
            Section("Subscription") {
                LabeledContent("Name", value: subscription.name)
                
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "Price After Trial"
                        : "Price",
                    value: subscription.price.formatted(
                        .currency(code: currencyCode)
                    )
                )
                
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "Billing After Trial"
                        : "Billing",
                    value: billingLabel
                )
                
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "First Paid Renewal"
                        : "Next Renewal Date",
                    value: subscription.nextBillingDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                
                LabeledContent(
                    "Status",
                    value: subscription.status == .active
                    ? "Active"
                    : "Canceled"
                )
                
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "Trial Reminder"
                        : "Renewal Reminder",
                    value: reminderStatusText
                )
                
                LabeledContent(
                    "Category",
                    value: subscription.category
                )
            }
            .headerProminence(.increased)

            if let trialEndDate =
                subscription.trialEndDate {
                Section("Free Trial") {
                    LabeledContent(
                        "Trial Status",
                        value: trialStatusText
                    )

                    LabeledContent(
                        "Trial End Date",
                        value: trialEndDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )

                    if activeTrialEndDate != nil {
                        Text(
                            "The paid subscription begins when the free trial ends."
                        )
                        .font(.caption)
                        .foregroundStyle(.primary)
                    } else {
                        Text(
                            "This subscription previously had a free trial."
                        )
                        .font(.caption)
                        .foregroundStyle(.primary)
                    }
                }
                .headerProminence(.increased)
            }
            
            if !sortedPriceChanges.isEmpty {
                Section {
                    NavigationLink {
                        SubscriptionPriceHistoryView(
                            subscription: subscription
                        )
                    } label: {
                        LabeledContent(
                            "Price History",
                            value: changeCountText
                        )
                    }
                }
            }
            
            if subscription.status == .active &&
                activeTrialEndDate == nil {
                Section("Renewal") {
                    Button {
                        showingRenewedConfirmation = true
                    } label: {
                        Label(
                            "Mark as Renewed",
                            systemImage: "checkmark.circle"
                        )
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)

                    Text(
                        "Use this after the subscription renews. The next renewal date will move forward by one billing period."
                    )
                    .font(.caption)
                    .foregroundStyle(.primary)
                }
                .headerProminence(.increased)
            }
            
            Section("Cost") {
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "Monthly After Trial"
                        : "Monthly Equivalent",
                    value: monthlyEquivalent.formatted(
                        .currency(code: currencyCode)
                    )
                )
                
                LabeledContent(
                    activeTrialEndDate != nil
                        ? "Annual After Trial"
                        : "Annual Equivalent",
                    value: annualEquivalent.formatted(
                        .currency(code: currencyCode)
                    )
                )
            }
            .headerProminence(.increased)
            
            if subscription.status == .active {
                Section {
                    LabeledContent(
                        "Monthly Savings",
                        value: monthlyEquivalent.formatted(
                            .currency(code: currencyCode)
                        )
                    )
                    
                    LabeledContent(
                        "Annual Savings",
                        value: annualEquivalent.formatted(
                            .currency(code: currencyCode)
                        )
                    )
                } header: {
                    Text(
                        activeTrialEndDate != nil
                            ? "If You Cancel Before Conversion"
                            : "If You Cancel"
                    )
                    .foregroundStyle(.primary)
                }
                .headerProminence(.increased)
            }
            
            Section {
                if !subscription.notes.isEmpty {
                    Section("Notes") {
                        Text(subscription.notes)
                    }
                }
            }
            
            Section {
                if subscription.status == .active {
                    Button("Cancel Subscription", role: .destructive) {
                        showingCancelConfirmation = true
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                } else {
                    Button("Reactivate Subscription") {
                        showingReactivateConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
                }

                Button("Delete Subscription", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .font(.title3)
                .fontWeight(.semibold)
            }
            
            if let cancellationDate = subscription.cancellationDate {
                LabeledContent(
                    "Canceled",
                    value: cancellationDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
            }
        }
        
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditSubscriptionView(
                subscription: subscription
            )
        }
        
        .alert(
            "Mark \(subscription.name) as renewed?",
            isPresented: $showingRenewedConfirmation
        ) {
            Button("Mark as Renewed") {
                Task {
                    await markSubscriptionRenewed()
                }
            }

            Button("Keep Current Date", role: .cancel) {
                showingRenewedConfirmation = false
            }
        } message: {
            if let nextRenewalDate =
                renewalDateAfterMarkingRenewed {
                Text(
                    "The next renewal date will move from \(subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted)) to \(nextRenewalDate.formatted(date: .abbreviated, time: .omitted))."
                )
            } else {
                Text(
                    "The next renewal date could not be calculated."
                )
            }
        }
        
        .alert(
            "Cancel \(subscription.name)?",
            isPresented: $showingCancelConfirmation
        ) {
            Button("Cancel Subscription", role: .destructive) {
                cancelSubscription()
            }

            Button("Keep Subscription", role: .cancel) {
                showingCancelConfirmation = false
            }
        } message: {
            Text(
                "This will keep the subscription record but remove it from active spending totals."
            )
        }
        
        .alert(
            "Reactivate \(subscription.name)?",
            isPresented: $showingReactivateConfirmation
        ) {
            Button("Reactivate Subscription") {
                Task {
                    await reactivateSubscription()
                }
            }

            Button("Keep Canceled", role: .cancel) {
                showingReactivateConfirmation = false
            }
        } message: {
            Text(
                "This returns the subscription to active spending totals. Renewal reminders will resume if they are enabled."
            )
        }
        
        .alert(
            "Delete \(subscription.name)?",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete Permanently", role: .destructive) {
                deleteSubscription()
            }

            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = false
            }
        } message: {
            Text(
                "This permanently removes the subscription and cannot be undone."
            )
        }
        
        .alert(
            "Could Not Save Changes",
            isPresented: $showingPersistenceError
        ) {
            Button("OK", role: .cancel) {
            }
        } message: {
            Text(persistenceErrorMessage)
        }
    }
}

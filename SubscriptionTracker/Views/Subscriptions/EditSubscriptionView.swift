import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let subscription: Subscription

    @State private var name: String
    @State private var price: String
    @State private var billingFrequency: BillingFrequency
    @State private var nextBillingDate: Date
    @State private var hasFreeTrial: Bool
    @State private var trialEndDate: Date
    @State private var categorySelection: String
    @State private var customCategory: String
    @State private var notes: String
    @State private var managementURL: String
    @State private var reminderEnabled: Bool
    @State private var reminderDaysBefore: Int
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    
    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode
    
    init(subscription: Subscription) {
        self.subscription = subscription

        _name = State(initialValue: subscription.name)
        _price = State(initialValue: subscription.price.description)
        _billingFrequency = State(initialValue: subscription.billingFrequency)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _hasFreeTrial = State(
            initialValue: subscription.trialEndDate != nil
        )

        _trialEndDate = State(
            initialValue:
                subscription.trialEndDate ??
                subscription.nextBillingDate
        )
        let categoryValues =
            SubscriptionCategory.selectionValues(
                for: subscription.category
            )

        _categorySelection = State(
            initialValue: categoryValues.selection
        )
        _customCategory = State(
            initialValue: categoryValues.customValue
        )
        _notes = State(initialValue: subscription.notes)
        _managementURL = State(
            initialValue: subscription.managementURL
        )
        _reminderEnabled = State(initialValue: subscription.reminderEnabled)
        _reminderDaysBefore = State(
            initialValue:
                AppSettings.normalizedReminderDays(
                    subscription.reminderDaysBefore
                )
        )
    }

    private var normalizedPrice: Decimal? {
        guard let amount = Decimal(string: price) else {
            return nil
        }

        return CurrencyAmount.normalized(
            amount,
            currencyCode: currencyCode
        )
    }

    private var resolvedCategory: String? {
        SubscriptionCategory.resolvedValue(
            selection: categorySelection,
            customValue: customCategory
        )
    }

    private var normalizedManagementURL: String? {
        SubscriptionManagementURL.normalizedString(
            from: managementURL
        )
    }

    private var trialIsActive: Bool {
        guard hasFreeTrial else {
            return false
        }

        return SubscriptionTrialCalculator.isActive(
            trialEndDate: trialEndDate
        )
    }

    private var canSave: Bool {
        guard
            !name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let normalizedPrice,
            normalizedPrice > 0,
            resolvedCategory != nil,
            normalizedManagementURL != nil
        else {
            return false
        }

        return true
    }

    private var billingPicker: some View {
        Picker(
            hasFreeTrial
                ? "Billing After Trial"
                : "Billing",
            selection: $billingFrequency
        ) {
            ForEach(
                BillingFrequency.allCases,
                id: \.self
            ) { frequency in
                Text(frequency.displayName)
                    .tag(frequency)
            }
        }
    }

    private var reminderTimingPicker: some View {
        Picker(
            "Reminder Timing",
            selection: $reminderDaysBefore
        ) {
            ForEach(
                AppSettings.supportedReminderDays,
                id: \.self
            ) { days in
                Text(
                    AppSettings.reminderTimingText(
                        for: days
                    )
                )
                .tag(days)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        TextField("", text: $name)
                            .accessibilityLabel("Name")
                    }

                    Toggle(
                        "Free Trial",
                        isOn: $hasFreeTrial
                    )

                    if hasFreeTrial {
                        Text(
                            trialIsActive
                                ? "Enter what the subscription will cost after the free trial ends."
                                : "This subscription previously had a free trial."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(
                            hasFreeTrial
                                ? "Price After Trial"
                                : "Price"
                        )
                            .font(.caption)
                            .foregroundStyle(.primary)

                        TextField("", text: $price)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel(
                                hasFreeTrial
                                    ? "Price After Trial"
                                    : "Price"
                            )
                    }
                    
                    billingPicker

                    if hasFreeTrial {
                        DatePicker(
                            "Trial End Date",
                            selection: $trialEndDate,
                            displayedComponents: .date
                        )

                        if trialIsActive {
                            Text(
                                "The first paid renewal will be recorded on the trial end date."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else {
                            Text(
                                "The trial has ended. Confirm the next paid renewal date."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            DatePicker(
                                "Next Renewal Date",
                                selection: $nextBillingDate,
                                displayedComponents: .date
                            )
                        }
                    } else {
                        DatePicker(
                            "Next Renewal Date",
                            selection: $nextBillingDate,
                            displayedComponents: .date
                        )
                    }
                    
                    if !price.isEmpty {
                        if let normalizedPrice {
                            if normalizedPrice <= 0 {
                                Text(
                                    hasFreeTrial
                                        ? "Post-trial price must be greater than zero."
                                        : "Price must be greater than zero."
                                )
                                .font(.caption)
                                .foregroundStyle(.red)
                            }
                        } else {
                            Text("Enter a valid price.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Subscription")
                        .foregroundStyle(.primary)
                }
                .headerProminence(.increased)

                Section {
                    Picker(
                        "Category",
                        selection: $categorySelection
                    ) {
                        ForEach(
                            SubscriptionCategory.allCases,
                            id: \.self
                        ) { category in
                            Text(category.rawValue)
                                .tag(category.rawValue)
                        }

                        Text("Custom")
                            .tag(
                                SubscriptionCategory.customSelectionValue
                            )
                    }

                    if categorySelection ==
                        SubscriptionCategory.customSelectionValue {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Category")
                                .font(.caption)
                                .foregroundStyle(.primary)

                            TextField(
                                "",
                                text: $customCategory
                            )
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Custom Category")

                            if customCategory.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty {
                                Text("Enter a category name.")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        TextField(
                            "",
                            text: $notes,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                        .accessibilityLabel("Notes")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Manage URL (Optional)")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        TextField(
                            "example.com/account",
                            text: $managementURL
                        )
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Manage URL")

                        if !managementURL.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty && normalizedManagementURL == nil {
                            Text("Enter a valid website address.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Toggle(
                        "Renewal Reminder",
                        isOn: $reminderEnabled
                    )

                    if reminderEnabled {
                        reminderTimingPicker

                        Text(
                            "Reminder timing: \(AppSettings.reminderTimingText(for: reminderDaysBefore))."
                        )
                        .font(.caption)
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Details")
                        .foregroundStyle(.primary)
                }
                .headerProminence(.increased)
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving || !canSave)
                }
            }
            .alert(
                "Could Not Save Changes",
                isPresented: $showingSaveError
            ) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private func saveChanges() async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        guard let normalizedPrice,
              normalizedPrice > 0,
              let resolvedCategory,
              let normalizedManagementURL else {
            return
        }

        let changedAt = Date()
        let effectiveNextBillingDate =
            hasFreeTrial && trialIsActive
                ? trialEndDate
                : nextBillingDate

        SubscriptionPriceChangeRecorder.recordChange(
            for: subscription,
            newPrice: normalizedPrice,
            newBillingFrequency: billingFrequency,
            changedAt: changedAt
        )

        subscription.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        subscription.price = normalizedPrice
        subscription.billingFrequency = billingFrequency
        subscription.nextBillingDate =
            effectiveNextBillingDate
        subscription.trialEndDate =
            hasFreeTrial
                ? trialEndDate
                : nil
        subscription.category = resolvedCategory
        subscription.notes = notes
        subscription.managementURL = normalizedManagementURL
        subscription.reminderEnabled = reminderEnabled
        subscription.reminderDaysBefore =
            AppSettings.normalizedReminderDays(
                reminderDaysBefore
            )
        subscription.updatedAt = changedAt
        
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
            return
        }
        
        do {
            if reminderEnabled {
                let granted = try await NotificationService.requestAuthorization()

                if granted {
                    try await NotificationService.scheduleRenewalReminder(
                        for: subscription
                    )
                }
            } else {
                NotificationService.removeRenewalReminder(
                    for: subscription
                )
            }
        } catch {
            print("Notification error: \(error)")
        }
        
        dismiss()
    }
}

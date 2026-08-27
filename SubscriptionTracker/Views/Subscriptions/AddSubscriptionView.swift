import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State private var name = ""
    @State private var price = ""
    @State private var billingFrequency: BillingFrequency = .monthly
    @State private var nextBillingDate = Date()
    @State private var categorySelection =
        SubscriptionCategory.other.rawValue
    @State private var customCategory = ""
    @State private var notes = ""
    @State private var reminderEnabled = true
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    
    @AppStorage(AppSettings.remindersEnabledByDefaultKey)
    private var remindersEnabledByDefault =
        AppSettings.defaultRemindersEnabled

    @AppStorage(AppSettings.reminderDaysBeforeKey)
    private var reminderDaysBefore =
        AppSettings.defaultReminderDaysBefore

    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode

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
    
    private var canSave: Bool {
        guard
            !name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let normalizedPrice,
            normalizedPrice > 0,
            resolvedCategory != nil
        else {
            return false
        }

        return true
    }

    private var billingPicker: some View {
        Picker(
            "Billing",
            selection: $billingFrequency
        ) {
            Text("Monthly")
                .tag(BillingFrequency.monthly)

            Text("Yearly")
                .tag(BillingFrequency.yearly)
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

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Price")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        TextField("", text: $price)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Price")
                    }

                    if dynamicTypeSize.isAccessibilitySize {
                        billingPicker
                    } else {
                        billingPicker
                            .pickerStyle(.segmented)
                    }
                    
                    DatePicker(
                        "Next Renewal Date",
                        selection: $nextBillingDate,
                        displayedComponents: .date
                    )
                    
                    if !price.isEmpty {
                        if let normalizedPrice {
                            if normalizedPrice <= 0 {
                                Text("Price must be greater than zero.")
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

                    Toggle(
                        "Renewal Reminder",
                        isOn: $reminderEnabled
                    )
                    
                    if reminderEnabled {
                        Text(
                            "Reminder will be sent \(AppSettings.reminderTimingText(for: reminderDaysBefore)) renewal."
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
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                reminderEnabled = remindersEnabledByDefault
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveSubscription()
                        }
                    }
                    .disabled(isSaving || !canSave)
                }
            }
            .alert(
                "Could Not Save Subscription",
                isPresented: $showingSaveError
            ) {
                Button("OK", role: .cancel) {
                }
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private func saveSubscription() async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        guard let normalizedPrice,
              normalizedPrice > 0,
              let resolvedCategory else {
            return
        }

        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            price: normalizedPrice,
            billingFrequency: billingFrequency,
            nextBillingDate: nextBillingDate,
            category: resolvedCategory,
            notes: notes,
            reminderEnabled: reminderEnabled
        )

        modelContext.insert(subscription)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            modelContext.delete(subscription)

            saveErrorMessage = error.localizedDescription
            showingSaveError = true
            return
        }

        if reminderEnabled {
            do {
                let granted = try await NotificationService.requestAuthorization()

                if granted {
                    try await NotificationService.scheduleRenewalReminder(
                        for: subscription
                    )
                }
            } catch {
                print("Notification error: \(error)")
            }
        }

        dismiss()
        
    }
}

#Preview {
    AddSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}

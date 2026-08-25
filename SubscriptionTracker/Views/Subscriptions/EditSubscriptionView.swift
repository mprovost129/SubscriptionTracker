import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    
    let subscription: Subscription

    @State private var name: String
    @State private var price: String
    @State private var billingFrequency: BillingFrequency
    @State private var nextBillingDate: Date
    @State private var category: SubscriptionCategory
    @State private var notes: String
    @State private var reminderEnabled: Bool
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
    @AppStorage(AppSettings.reminderDaysBeforeKey)
    private var reminderDaysBefore =
        AppSettings.defaultReminderDaysBefore
    
    @AppStorage(AppSettings.currencyCodeKey)
    private var currencyCode =
        AppSettings.defaultCurrencyCode
    
    init(subscription: Subscription) {
        self.subscription = subscription

        _name = State(initialValue: subscription.name)
        _price = State(initialValue: subscription.price.description)
        _billingFrequency = State(initialValue: subscription.billingFrequency)
        _nextBillingDate = State(initialValue: subscription.nextBillingDate)
        _category = State(
            initialValue:
                SubscriptionCategory(rawValue: subscription.category)
                ?? .other
        )
        _notes = State(initialValue: subscription.notes)
        _reminderEnabled = State(initialValue: subscription.reminderEnabled)
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

    private var canSave: Bool {
        guard
            !name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let normalizedPrice,
            normalizedPrice > 0
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
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
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
                            "Reminder will be sent \(reminderDaysBefore) days before renewal."
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
                    .disabled(!canSave)
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
        guard let normalizedPrice,
              normalizedPrice > 0 else {
            return
        }

        let changedAt = Date()

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
        subscription.nextBillingDate = nextBillingDate
        subscription.category = category.rawValue
        subscription.notes = notes
        subscription.reminderEnabled = reminderEnabled
        subscription.updatedAt = changedAt
        
        do {
            try modelContext.save()
        } catch {
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

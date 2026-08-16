import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var billingFrequency: BillingFrequency = .monthly
    @State private var nextBillingDate = Date()
    @State private var category: SubscriptionCategory = .other
    @State private var notes = ""
    @State private var reminderEnabled = true
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Subscription name", text: $name)
                            .accessibilityLabel("Name")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Price")
                    }

                    Picker("Billing", selection: $billingFrequency) {
                        Text("Monthly")
                            .tag(BillingFrequency.monthly)

                        Text("Yearly")
                            .tag(BillingFrequency.yearly)
                    }
                    .pickerStyle(.segmented)
                    
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
                }

                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle(
                        "Renewal Reminder",
                        isOn: $reminderEnabled
                    )
                    
                    if reminderEnabled {
                        Text("Reminder will be sent \(reminderDaysBefore) days before renewal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                reminderEnabled = remindersEnabledByDefault
            }            .toolbar {
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
                    .disabled(!canSave)
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
        guard let normalizedPrice,
              normalizedPrice > 0 else {
            return
        }

        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            price: normalizedPrice,
            billingFrequency: billingFrequency,
            nextBillingDate: nextBillingDate,
            category: category.rawValue,
            notes: notes,
            reminderEnabled: reminderEnabled
        )

        modelContext.insert(subscription)

        do {
            try modelContext.save()
        } catch {
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

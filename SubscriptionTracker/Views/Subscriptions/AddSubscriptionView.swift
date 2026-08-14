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

    private var priceDecimal: Decimal? {
        Decimal(string: price)
    }

    private var canSave: Bool {
        guard
            !name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty,
            let priceDecimal,
            priceDecimal > 0
        else {
            return false
        }

        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Subscription") {
                    TextField("Name", text: $name)

                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)

                    Picker("Billing", selection: $billingFrequency) {
                        Text("Monthly")
                            .tag(BillingFrequency.monthly)

                        Text("Yearly")
                            .tag(BillingFrequency.yearly)
                    }

                    DatePicker(
                        "Next Billing Date",
                        selection: $nextBillingDate,
                        displayedComponents: .date
                    )
                    
                    if !price.isEmpty {
                        if let priceDecimal {
                            if priceDecimal <= 0 {
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
        guard let priceDecimal else {
            return
        }

        let subscription = Subscription(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceDecimal,
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

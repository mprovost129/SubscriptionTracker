import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSubscription = false
    @State private var searchText = ""
    @State private var showingSettings = false
    @AppStorage(AppSettings.currencyCodeKey)
    
    private var currencyCode = AppSettings.defaultCurrencyCode
    
    private var monthlyTotal: Decimal {
        SubscriptionCalculator.totalMonthlyCost(
            for: subscriptions
        )
    }
    
    private var annualTotal: Decimal {
        SubscriptionCalculator.totalAnnualCost(
            for: subscriptions
        )
    }
    
    private var trimmedSearchText: String {
        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var matchingSubscriptions: [Subscription] {
        guard !trimmedSearchText.isEmpty else {
            return subscriptions
        }

        return subscriptions.filter { subscription in
            subscription.name.localizedStandardContains(
                trimmedSearchText
            )
            || subscription.category.localizedStandardContains(
                trimmedSearchText
            )
        }
    }

    private var activeSubscriptions: [Subscription] {
        matchingSubscriptions.filter {
            $0.status == .active
        }
    }

    private var upcomingSubscriptions: [Subscription] {
        activeSubscriptions.sorted {
            $0.nextBillingDate < $1.nextBillingDate
        }
    }

    private var canceledSubscriptions: [Subscription] {
        matchingSubscriptions.filter {
            $0.status == .canceled
        }
    }
    
    private func renewalStatusText(
        for subscription: Subscription
    ) -> String {
        let days = RenewalCalculator.daysUntilRenewal(
            for: subscription
        )
        
        if days < 0 {
            let overdueDays = abs(days)
            
            return overdueDays == 1
            ? "Overdue by 1 day"
            : "Overdue by \(overdueDays) days"
        }
        
        if days == 0 {
            return "Due Today"
        }
        
        if days == 1 {
            return "Due Tomorrow"
        }
        
        return "Due in \(days) days"
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ContentUnavailableView {
                        Label(
                            "No Subscriptions Yet",
                            systemImage: "creditcard"
                        )
                    } description: {
                        Text(
                            "Add your first subscription to start tracking monthly costs, yearly costs, and upcoming renewals."
                        )
                    } actions: {
                        Button("Add Subscription") {
                            showingAddSubscription = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monthly")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text(
                                    monthlyTotal,
                                    format: .currency(code: currencyCode)
                                )
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yearly")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text(
                                    annualTotal,
                                    format: .currency(code: currencyCode)
                                )
                                .font(.title)
                                .fontWeight(.semibold)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Renewals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if upcomingSubscriptions.isEmpty {
                                    if trimmedSearchText.isEmpty {
                                        Text("No upcoming renewals yet.")
                                            .foregroundStyle(.secondary)
                                    } else if canceledSubscriptions.isEmpty {
                                        ContentUnavailableView {
                                            Label(
                                                "No Matches",
                                                systemImage: "magnifyingglass"
                                            )
                                        } description: {
                                            Text(
                                                "No subscriptions match \"\(trimmedSearchText)\"."
                                            )
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                    }
                                } else {
                                    
                                    ForEach(upcomingSubscriptions) { subscription in
                                        NavigationLink {
                                            SubscriptionDetailView(
                                                subscription: subscription
                                            )
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(subscription.name)
                                                        .font(.headline)
                                                    
                                                    Text(
                                                        renewalStatusText(
                                                            for: subscription
                                                        )
                                                    )
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    
                                                    Label(
                                                        subscription.reminderEnabled
                                                            ? "Reminder On"
                                                            : "Reminder Off",
                                                        systemImage: subscription.reminderEnabled
                                                            ? "bell.fill"
                                                            : "bell.slash"
                                                    )
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    
                                                    Text(
                                                        subscription
                                                            .nextBillingDate
                                                            .formatted(
                                                                date: .abbreviated,
                                                                time: .omitted
                                                            )
                                                    )
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(
                                                    subscription.price.formatted(
                                                        .currency(code: currencyCode)
                                                    )
                                                )
                                                .fontWeight(.semibold)
                                            }
                                            .accessibilityElement(children: .combine)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Divider()
                                    }
                                }
                                
                                if !canceledSubscriptions.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Canceled")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        
                                        ForEach(canceledSubscriptions) { subscription in
                                            NavigationLink {
                                                SubscriptionDetailView(
                                                    subscription: subscription
                                                )
                                            } label: {
                                                HStack {
                                                    Text(subscription.name)
                                                    
                                                    Spacer()
                                                    
                                                    Text(
                                                        subscription.price.formatted(
                                                            .currency(code: currencyCode)
                                                        )
                                                    )
                                                    .foregroundStyle(.secondary)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Subscriptions")
            .searchable(
                text: $searchText,
                prompt: "Search by name or category"
            )
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Subscription")
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}

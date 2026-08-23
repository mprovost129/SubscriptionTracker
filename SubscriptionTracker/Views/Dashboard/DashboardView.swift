import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSubscription = false
    @State private var searchText = ""
    @State private var sortOption:
        SubscriptionSortOption = .renewalDate
    
    @State private var statusFilter:
        SubscriptionStatusFilter = .all
    
    @State private var billingFilter:
        SubscriptionBillingFilter = .all
    
    @State private var showingSettings = false
    @State private var showingInsights = false
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    
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

    private var organizedSubscriptions: [Subscription] {
        SubscriptionListOrganizer.organize(
            matchingSubscriptions,
            statusFilter: statusFilter,
            billingFilter: billingFilter,
            sortOption: sortOption
        )
    }

    private var activeSubscriptions: [Subscription] {
        organizedSubscriptions.filter {
            $0.status == .active
        }
    }

    private var upcomingSubscriptions: [Subscription] {
        activeSubscriptions
    }

    private var canceledSubscriptions: [Subscription] {
        organizedSubscriptions.filter {
            $0.status == .canceled
        }
    }
    
    private var filtersAreActive: Bool {
        statusFilter != .all
        || billingFilter != .all
    }
    
    private var listOptionsAreModified: Bool {
        filtersAreActive
        || sortOption != .renewalDate
    }
    
    private func resetListOptions() {
        sortOption = .renewalDate
        statusFilter = .all
        billingFilter = .all
    }
    
    private var subscriptionRowLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(
                VStackLayout(
                    alignment: .leading,
                    spacing: 8
                )
            )
        }

        return AnyLayout(
            HStackLayout(
                alignment: .center,
                spacing: 12
            )
        )
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
                                    .foregroundStyle(.primary)
                                
                                Text(
                                    monthlyTotal,
                                    format: .currency(code: currencyCode)
                                )
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            }
                            
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Monthly subscription total")
                            .accessibilityValue(
                                Text(
                                    monthlyTotal,
                                    format: .currency(code: currencyCode)
                                )
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yearly")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(
                                    annualTotal,
                                    format: .currency(code: currencyCode)
                                )
                                .font(.title)
                                .fontWeight(.semibold)
                            }
                            
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Yearly subscription total")
                            .accessibilityValue(
                                Text(
                                    annualTotal,
                                    format: .currency(code: currencyCode)
                                )
                            )
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Renewals")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if upcomingSubscriptions.isEmpty {
                                    if canceledSubscriptions.isEmpty {
                                        if !trimmedSearchText.isEmpty {
                                            ContentUnavailableView {
                                                Label(
                                                    filtersAreActive
                                                        ? "No Filtered Matches"
                                                        : "No Matches",
                                                    systemImage: "magnifyingglass"
                                                )
                                            } description: {
                                                Text(
                                                    filtersAreActive
                                                        ? "No subscriptions match your search and current filters."
                                                        : "No subscriptions match \"\(trimmedSearchText)\"."
                                                )
                                            } actions: {
                                                Button("Clear Search") {
                                                    searchText = ""
                                                }

                                                if filtersAreActive {
                                                    Button("Reset Filters") {
                                                        resetListOptions()
                                                    }
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 24)
                                        } else if filtersAreActive {
                                            ContentUnavailableView {
                                                Label(
                                                    "No Filtered Subscriptions",
                                                    systemImage:
                                                        "line.3.horizontal.decrease.circle"
                                                )
                                            } description: {
                                                Text(
                                                    "No subscriptions match the selected filters."
                                                )
                                            } actions: {
                                                Button("Reset Filters") {
                                                    resetListOptions()
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 24)
                                        } else {
                                            Text("No upcoming renewals yet.")
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                } else {
                                    
                                    ForEach(upcomingSubscriptions) { subscription in
                                        NavigationLink {
                                            SubscriptionDetailView(
                                                subscription: subscription
                                            )
                                        } label: {
                                            subscriptionRowLayout {
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
                                                    .foregroundStyle(.primary)
                                                    
                                                    Text(
                                                        subscription
                                                            .nextBillingDate
                                                            .formatted(
                                                                date: .abbreviated,
                                                                time: .omitted
                                                            )
                                                    )
                                                    .font(.caption2)
                                                    .foregroundStyle(.primary)
                                                }
                                                .frame(
                                                    maxWidth: .infinity,
                                                    alignment: .leading
                                                )
                                                
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
                                                subscriptionRowLayout {
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(subscription.name)
                                                    }
                                                    .frame(
                                                        maxWidth: .infinity,
                                                        alignment: .leading
                                                    )
                                                    
                                                    Text(
                                                        subscription.price.formatted(
                                                            .currency(code: currencyCode)
                                                        )
                                                    )
                                                    .foregroundStyle(.primary)
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
            .navigationBarTitleDisplayMode(
                dynamicTypeSize.isAccessibilitySize
                    ? .inline
                    : .large
            )
            .searchable(
                text: $searchText,
                prompt: Text(
                    dynamicTypeSize.isAccessibilitySize
                        ? "Search"
                        : "Search by name or category"
                )
            )
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Subscription")
                    
                    Menu {
                        Section("Sort") {
                            Picker(
                                "Sort Subscriptions",
                                selection: $sortOption
                            ) {
                                ForEach(
                                    SubscriptionSortOption.allCases
                                ) { option in
                                    Text(option.rawValue)
                                        .tag(option)
                                }
                            }
                        }

                        Section("Status") {
                            Picker(
                                "Filter by Status",
                                selection: $statusFilter
                            ) {
                                ForEach(
                                    SubscriptionStatusFilter.allCases
                                ) { filter in
                                    Text(filter.rawValue)
                                        .tag(filter)
                                }
                            }
                        }

                        Section("Billing") {
                            Picker(
                                "Filter by Billing",
                                selection: $billingFilter
                            ) {
                                ForEach(
                                    SubscriptionBillingFilter.allCases
                                ) { filter in
                                    Text(filter.rawValue)
                                        .tag(filter)
                                }
                            }
                        }

                        if listOptionsAreModified {
                            Divider()

                            Button {
                                resetListOptions()
                            } label: {
                                Label(
                                    "Reset Sort and Filters",
                                    systemImage: "arrow.counterclockwise"
                                )
                            }
                        }
                    } label: {
                        Image(
                            systemName: listOptionsAreModified
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle"
                        )
                    }
                    .accessibilityLabel("Sort and Filter")
                    .accessibilityValue(
                        listOptionsAreModified
                            ? "Options applied"
                            : "Default options"
                    )

                    Menu {
                        Button {
                            showingInsights = true
                        } label: {
                            Label(
                                "Insights",
                                systemImage: "chart.bar.xaxis"
                            )
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label(
                                "Settings",
                                systemImage: "gearshape"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More Options")
                }
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionView()
        }
        .sheet(isPresented: $showingInsights) {
            NavigationStack {
                InsightsView()
            }
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

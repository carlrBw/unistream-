import Foundation

struct SubscriptionData {
    static let subscriptions: [Subscription] = [
        Subscription(
            service: .hulu,
            status: .active,
            renewalDate: Date().addingTimeInterval(2592000), // 30 days from now
            monthlyCost: 14.99
        ),
        Subscription(
            service: .disney,
            status: .active,
            renewalDate: Date().addingTimeInterval(1296000), // 15 days from now
            monthlyCost: 9.99
        ),
        Subscription(
            service: .paramount,
            status: .active,
            renewalDate: Date().addingTimeInterval(864000), // 10 days from now
            monthlyCost: 11.99
        ),
        Subscription(
            service: .netflix,
            status: .active,
            renewalDate: Date().addingTimeInterval(2592000),
            monthlyCost: 15.99
        ),
        Subscription(
            service: .prime,
            status: .active,
            renewalDate: Date().addingTimeInterval(2592000),
            monthlyCost: 14.99
        ),
        Subscription(
            service: .hboMax,
            status: .pending,
            renewalDate: Date().addingTimeInterval(2592000),
            monthlyCost: 16.99
        ),
        Subscription(
            service: .appleTV,
            status: .expired,
            renewalDate: Date().addingTimeInterval(-864000), // 10 days ago
            monthlyCost: 9.99
        ),
        Subscription(
            service: .peacock,
            status: .pending,
            renewalDate: Date().addingTimeInterval(2592000),
            monthlyCost: 11.99
        )
    ]
} 
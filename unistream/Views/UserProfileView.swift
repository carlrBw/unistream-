import SwiftUI

struct UserProfileView: View {
    @StateObject private var mockData = MockData.shared
    @EnvironmentObject private var userState: UserState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                         startPoint: .top,
                         endPoint: .bottom)
                .ignoresSafeArea()
            
            if mockData.isLoading {
                ProgressView("Loading content...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Banner Image
                            ZStack(alignment: .bottom) {
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                                    .foregroundStyle(.gray.opacity(0.3))
                                    .background(Color.black.opacity(0.3))
                                
                                // Profile Header
                                HStack(alignment: .bottom, spacing: 15) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.blue)
                                        .background(Color.black.opacity(0.3))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                        .offset(y: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(userState.currentUser?.username ?? "")
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                        
                                        if let joinDate = userState.currentUser?.joinDate {
                                            Text("Member since \(joinDate, format: .dateTime.month().year())")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .offset(y: 30)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            
                            // Add some spacing after the profile header
                            Spacer()
                                .frame(height: 40)
                            
                            // Custom Tab Bar
                            HStack(spacing: 0) {
                                ForEach(["Posts", "Following", "Followers", "Watching"], id: \.self) { tab in
                                    Button(action: {
                                        withAnimation {
                                            selectedTab = ["Posts", "Following", "Followers", "Watching"].firstIndex(of: tab) ?? 0
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(tab)
                                                .font(.subheadline)
                                                .fontWeight(selectedTab == ["Posts", "Following", "Followers", "Watching"].firstIndex(of: tab) ? .bold : .regular)
                                            
                                            Rectangle()
                                                .fill(selectedTab == ["Posts", "Following", "Followers", "Watching"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                                .frame(height: 2)
                                        }
                                        .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Tab Content
                            TabView(selection: $selectedTab) {
                                PostsView()
                                    .tag(0)
                                
                                FollowingView(user: userState.currentUser)
                                    .tag(1)
                                
                                FollowersView(user: userState.currentUser)
                                    .tag(2)
                                
                                WatchingView(user: userState.currentUser)
                                    .tag(3)
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            EmptyView()
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .task {
            if mockData.content.isEmpty {
                await mockData.loadContent()
            }
        }
    }
}

// Tab Content Views
struct PostsView: View {
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Recent Activity")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                if let user = userState.currentUser, !user.comments.isEmpty {
                    ForEach(user.comments) { comment in
                        UserCommentCard(comment: comment)
                            .padding(.horizontal)
                    }
                } else {
                    Text("No recent activity")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.vertical)
        }
    }
}

struct UserCommentCard: View {
    let comment: Comment
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail
            AsyncImage(url: URL(string: comment.content.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(comment.content.service.color.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
            .frame(width: 60, height: 90)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(comment.content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct FollowingView: View {
    let user: User?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Following")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Text("Coming soon...")
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding(.vertical)
        }
    }
}

struct FollowersView: View {
    let user: User?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Followers")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Text("Coming soon...")
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding(.vertical)
        }
    }
}

struct WatchingView: View {
    let user: User?
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // My List Section
                if !userState.myList.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My List")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(userState.myList) { content in
                                    ContentCard(content: content)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Currently Watching Section
                if let user = user, !user.watchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Currently Watching")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(user.watchHistory) { content in
                                    ContentCard(content: content)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Looped Series Section
                if !userState.loopedSeries.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Looped Series")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(userState.loopedSeries) { content in
                                    ContentCard(content: content)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct SettingsView: View {
    let user: User?
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Account Settings Section - Only show if logged in
                if user != nil {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Account")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: UserSubscriptionsView()) {
                        SettingsRow(icon: "creditcard", title: "Subscriptions", hasNavigation: true)
                    }
                    
                    SettingsRow(icon: "bell", title: "Notifications", hasNavigation: true)
                    SettingsRow(icon: "lock", title: "Privacy", hasNavigation: true)
                    }
                }
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Preferences")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: AppearanceView()) {
                        SettingsRow(icon: "paintbrush", title: "Appearance", hasNavigation: true)
                    }
                    SettingsRow(icon: "globe", title: "Language", hasNavigation: true)
                    SettingsRow(icon: "play.circle", title: "Playback", hasNavigation: true)
                }
                
                // Help & Support Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Help & Support")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    SettingsRow(icon: "questionmark.circle", title: "Help Center", hasNavigation: true)
                    SettingsRow(icon: "envelope", title: "Contact Us", hasNavigation: true)
                    SettingsRow(icon: "doc.text", title: "Terms of Service", hasNavigation: true)
                }
                
                // Sign Out - Only show if logged in
                if user != nil {
                Button(action: {
                        userState.signOut()
                }) {
                    SettingsRow(icon: "arrow.right.square", title: "Sign Out", hasNavigation: false)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let hasNavigation: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
            Text(title)
            Spacer()
            if hasNavigation {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct UserSubscriptionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Active Subscriptions")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                ForEach(SubscriptionData.subscriptions) { subscription in
                    UserSubscriptionCard(subscription: subscription)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    // Handle add subscription
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Subscription")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Add this new view
struct AppearanceView: View {
    @State private var selectedTheme = Theme.themes[0]
    @State private var isDarkMode = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Theme Selection
                VStack(alignment: .leading, spacing: 15) {
                    Text("Theme")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Theme.themes) { theme in
                                ThemePreviewCard(
                                    theme: theme,
                                    isSelected: theme.id == selectedTheme.id
                                ) {
                                    withAnimation {
                                        selectedTheme = theme
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Display Settings
                VStack(alignment: .leading, spacing: 15) {
                    Text("Display")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .tint(selectedTheme.primary)
                }
                
                // Preview Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Preview")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        HStack {
                            Circle()
                                .fill(selectedTheme.primary)
                                .frame(width: 40, height: 40)
                            Text("Primary Color")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack {
                            Circle()
                                .fill(selectedTheme.secondary)
                                .frame(width: 40, height: 40)
                            Text("Secondary Color")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(selectedTheme.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemePreviewCard: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.background)
                    .frame(width: 120, height: 80)
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }
                    )
                
                Text(theme.name)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? .white : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    UserProfileView()
        .environmentObject(UserState())
} 
import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedCategory: Category = .all
    @State private var isSearching = false
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var mockData = MockData.shared
    
    // Trending searches with emojis for visual interest
    let trendingSearches = [
        ("The Mandalorian", "🌟"),
        ("Succession", "👔"),
        ("Oppenheimer", "💥"),
        ("The Bear", "🐻")
    ]
    
    var filteredContent: [Content] {
        let results = mockData.content.filter { content in
            (searchText.isEmpty || content.title.localizedCaseInsensitiveContains(searchText)) &&
            (selectedCategory == .all || content.category == selectedCategory)
        }
        return results
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !searchText.isEmpty {
                        SearchResultsSection(content: filteredContent)
                    } else {
                        // Default Content
                        VStack(spacing: 32) {
                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Category.allCases, id: \.self) { category in
                                        CategoryPill(
                                            category: category,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Trending Searches
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Trending Searches")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(trendingSearches, id: \.0) { search in
                                    Button(action: {
                                        searchText = search.0
                                    }) {
                                        HStack {
                                            Text(search.1)
                                                .font(.title3)
                                            Text(search.0)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "magnifyingglass")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Content Sections
                            ContentSection(
                                title: "Popular Movies",
                                subtitle: "Top picks this week",
                                content: mockData.content.filter { !$0.isTVShow }
                            )
                            
                            ContentSection(
                                title: "Trending Shows",
                                subtitle: "What everyone's watching",
                                content: mockData.content.filter { $0.isTVShow }
                            )
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search movies, shows, genres...")
            .background(BackgroundGradient())
        }
    }
}

// Modern Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal)
    }
}

// Modern Category Pill
struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.15))
                )
                .foregroundColor(isSelected ? .white : .gray)
        }
        .buttonStyle(.plain)
    }
}

// Enhanced Trending Search Button
struct TrendingSearchButton: View {
    let title: String
    let emoji: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(emoji)
                    .font(.title3)
                Text(title)
                    .lineLimit(1)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// Enhanced Content Section
struct ContentSection: View {
    let title: String
    let subtitle: String
    let content: [Content]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(content) { item in
                        ContentCard(content: item)
                            .shadow(radius: 8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Modern Background Gradient
struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.black,
                Color.black
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// Search Results Section
struct SearchResultsSection: View {
    let content: [Content]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if content.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No results found")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Try searching for something else")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(content) { item in
                        SearchResultCard(content: item)
                    }
                }
                .padding()
            }
        }
    }
}

// Search Result Card Component
struct SearchResultCard: View {
    let content: Content
    
    var body: some View {
        NavigationLink(destination: ContentDetailView(content: content)) {
            VStack(alignment: .leading) {
                // Thumbnail Image
                AsyncImage(url: URL(string: content.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(content.service.color.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                .frame(height: 225)
                .cornerRadius(10)
                
                // Title
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Service and Category
                HStack {
                    AsyncImage(url: URL(string: content.service.logoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Text(content.service.rawValue)
                    }
                    .frame(height: 15)
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(content.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
} 
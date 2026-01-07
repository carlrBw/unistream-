import SwiftUI
import UIKit

struct HomeView: View {
    @StateObject private var mockData = MockData.shared
    @StateObject private var colorExtractor = ImageColorExtractor()
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    @State private var currentBannerIndex = 1  // Start at 1 to show first real item
    @State private var scrollOffset: CGFloat = 0
    @State private var showTitle = true
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var carouselItems: [Content] {
        guard !mockData.featured.isEmpty else { return [] }
        // Add last item at start and first item at end for smooth looping
        return [mockData.featured.last!] + mockData.featured + [mockData.featured.first!]
    }
    
    var currentCarouselContent: Content? {
        guard !carouselItems.isEmpty, currentBannerIndex < carouselItems.count else { return nil }
        return carouselItems[currentBannerIndex]
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if mockData.isLoading {
                    ProgressView("Loading content...")
                        .tint(.white)
                        .foregroundColor(.white)
                } else if let error = mockData.error {
                    VStack(spacing: 16) {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Button("Try Again") {
                            Task {
                                await mockData.loadContent()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } else if mockData.content.isEmpty {
                    VStack(spacing: 16) {
                        Text("No content available")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Button("Load Content") {
                            Task {
                                await mockData.loadContent()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                } else {
                    ScrollView {
                        GeometryReader { geometry in
                            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                        }
                        .frame(height: 0)
                        
                        VStack(alignment: .leading, spacing: 30) {
                            // Featured carousel
                            if !mockData.featured.isEmpty {
                                TabView(selection: $currentBannerIndex) {
                                    ForEach(Array(carouselItems.enumerated()), id: \.offset) { index, content in
                                        FeaturedBanner(content: content)
                                            .environmentObject(colorExtractor)
                                            .environmentObject(userState)
                                            .environmentObject(interactionService)
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 500)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 0)
                                .padding(.vertical, 0)
                                .edgesIgnoringSafeArea(.vertical)
                                .onChange(of: currentBannerIndex) { oldValue, newValue in
                                    handleIndexChange(newValue)
                                    // Update background colors when carousel changes
                                    if let content = currentCarouselContent {
                                        colorExtractor.extractColors(from: content.bannerURL)
                                    }
                                }
                                .onReceive(timer) { _ in
                                    withAnimation {
                                        currentBannerIndex += 1
                                    }
                                }
                                .onAppear {
                                    // Extract colors for initial image
                                    if let content = currentCarouselContent {
                                        colorExtractor.extractColors(from: content.bannerURL)
                                    }
                                }
                            }
                            
                            // Service icons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(StreamingService.allCases, id: \.self) { service in
                                        NavigationLink(destination: ServiceDetailView(service: service)
                                            .environmentObject(userState)
                                            .environmentObject(interactionService)) {
                                        ServiceIcon(service: service)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Movies section
                            if !mockData.movies.isEmpty {
                                ContentRow(title: "Trending Movies", content: mockData.movies)
                            }
                            
                            // TV Shows section
                            if !mockData.tvShows.isEmpty {
                                ContentRow(title: "Trending TV Shows", content: mockData.tvShows)
                            }

                            // In Theaters Now
                            if !mockData.nowPlaying.isEmpty {
                                ContentRow(title: "In Theaters Now", content: mockData.nowPlaying)
                            }
                            
                            // In Theaters
                            if !mockData.nowPlaying.isEmpty {
                                ContentRow(title: "In Theaters", content: mockData.nowPlaying)
                            }
                            
                            // Mixed content
                            if !mockData.content.isEmpty {
                                ContentRow(title: "Continue Watching", content: Array(mockData.content.shuffled().prefix(5)))
                                ContentRow(title: "Your Favorites", content: Array(mockData.content.shuffled().prefix(5)))
                            }
                        }
                        .padding(.vertical)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let offset = value
                        let threshold: CGFloat = 50
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if offset < -threshold && showTitle {
                                showTitle = false
                            } else if offset >= -threshold && !showTitle {
                                showTitle = true
                            }
                        }
                        scrollOffset = offset
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colorExtractor.dominantColors),
                             startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: colorExtractor.dominantColors)
            )
            .navigationTitle(showTitle ? "Unistream" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SearchView()) {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.large)
                }
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .clear
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium)
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium)
                ]
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            .task {
                if mockData.content.isEmpty {
                    await mockData.loadContent()
                }
            }
        }
    }
    
    private func handleIndexChange(_ newIndex: Int) {
        let count = carouselItems.count
        guard count > 0 else { return }
        
        if newIndex == 0 {
            // If we're at the first (duplicate) item, jump to the real last item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.none) {
                    currentBannerIndex = count - 2
                }
            }
        } else if newIndex == count - 1 {
            // If we're at the last (duplicate) item, jump to the real first item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.none) {
                    currentBannerIndex = 1
                }
            }
        }
    }
}

struct ServiceIcon: View {
    let service: StreamingService
    
    var body: some View {
        VStack(spacing: 4) {
            if service == .inTheaters {
                // Use system icon for "In Theaters"
                Image(systemName: "film.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(service.color)
            } else if !service.logoURL.isEmpty {
            AsyncImage(url: URL(string: service.logoURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } placeholder: {
                Circle()
                    .fill(service.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
                }
            } else {
                Circle()
                    .fill(service.color)
                    .frame(width: 40, height: 40)
            }
            Text(service.rawValue)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 60)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60)
    }
}

// PreferenceKey to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeaturedBanner: View {
    let content: Content
    @EnvironmentObject var colorExtractor: ImageColorExtractor
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    
    var body: some View {
        NavigationLink(destination: ContentDetailView(content: content)
            .environmentObject(userState)
            .environmentObject(interactionService)) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: content.bannerURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } placeholder: {
                    Rectangle()
                        .fill(content.service.color.opacity(0.3))
                }
                .clipped()
                
                // Top fade gradient - blends with background
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: colorExtractor.dominantColors.first ?? .black, location: 0.0),
                            .init(color: (colorExtractor.dominantColors.first ?? .black).opacity(0.8), location: 0.3),
                            .init(color: (colorExtractor.dominantColors.first ?? .black).opacity(0.4), location: 0.6),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    
                    Spacer()
                    
                    // Bottom fade gradient - blends with background
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: (colorExtractor.dominantColors.last ?? .black).opacity(0.4), location: 0.4),
                            .init(color: (colorExtractor.dominantColors.last ?? .black).opacity(0.8), location: 0.7),
                            .init(color: colorExtractor.dominantColors.last ?? .black, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }
                
                // Bottom content gradient overlay (for text readability)
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text(content.service.rawValue)
                            .font(.subheadline)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.gray)
                            Text("\(content.viewCount) viewers")
                                .font(.subheadline)
                        }
                    }
                }
                .foregroundColor(.white)
                .padding()
                }
            }
            .edgesIgnoringSafeArea(.vertical)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentRow: View {
    let title: String
    let content: [Content]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(content) { item in
                        ContentCard(content: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HomeView()
} 

import SwiftUI

struct HomeView: View {
    @StateObject private var mockData = MockData.shared
    @State private var currentBannerIndex = 1  // Start at 1 to show first real item
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var carouselItems: [Content] {
        guard !mockData.featured.isEmpty else { return [] }
        // Add last item at start and first item at end for smooth looping
        return [mockData.featured.last!] + mockData.featured + [mockData.featured.first!]
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
                        VStack(alignment: .leading, spacing: 30) {
                            // Featured carousel
                            if !mockData.featured.isEmpty {
                                TabView(selection: $currentBannerIndex) {
                                    ForEach(Array(carouselItems.enumerated()), id: \.offset) { index, content in
                                        FeaturedBanner(content: content)
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                .frame(height: 200)
                                .onChange(of: currentBannerIndex) { oldValue, newValue in
                                    handleIndexChange(newValue)
                                }
                                .onReceive(timer) { _ in
                                    withAnimation {
                                        currentBannerIndex += 1
                                    }
                                }
                            }
                            
                            // Service icons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(StreamingService.allCases, id: \.self) { service in
                                        ServiceIcon(service: service)
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
                            
                            // Mixed content
                            if !mockData.content.isEmpty {
                                ContentRow(title: "Continue Watching", content: Array(mockData.content.shuffled().prefix(5)))
                                ContentRow(title: "Your Favorites", content: Array(mockData.content.shuffled().prefix(5)))
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.8), .black]),
                             startPoint: .top,
                             endPoint: .bottom)
                .ignoresSafeArea()
            )
            .navigationTitle("StreamSphere")
            .navigationBarItems(
                trailing: NavigationLink(destination: SearchView()) {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.large)
                }
            )
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

struct FeaturedBanner: View {
    let content: Content
    
    var body: some View {
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
                
                // Gradient overlay
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
        .cornerRadius(10)
        .padding(.horizontal)
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

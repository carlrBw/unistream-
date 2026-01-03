import Foundation
import SwiftUI

@MainActor
class MockData: ObservableObject {
    @Published var content: [Content] = []
    @Published var featured: [Content] = []
    @Published var movies: [Content] = []
    @Published var tvShows: [Content] = []
    @Published var nowPlaying: [Content] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    static let shared = MockData()
    private init() {
        // Start with empty arrays instead of sample content
        content = []
        featured = []
    }
    
    func loadContent() async {
        guard !isLoading else { return } // Prevent multiple simultaneous loads
        
        isLoading = true
        error = nil
        
        do {
            print("Starting content fetch...")
            let fetchedMovies = try await TMDBService.fetchTrendingMovies()
            print("Fetched \(fetchedMovies.count) movies")
            let fetchedShows = try await TMDBService.fetchTrendingTVShows()
            print("Fetched \(fetchedShows.count) shows")
            let fetchedNowPlaying = try await TMDBService.fetchNowPlayingMovies()
            print("Fetched \(fetchedNowPlaying.count) now playing movies")
            
            // Update UI on main thread
            movies = fetchedMovies
            tvShows = fetchedShows
            nowPlaying = fetchedNowPlaying
            content = movies + tvShows
            featured = Array(content.prefix(3))
            
            print("Updated content: \(content.count) total items")
            print("Featured items: \(featured.count)")
            print("Sample movie title: \(movies.first?.title ?? "none")")
            print("Sample show title: \(tvShows.first?.title ?? "none")")
            
        } catch {
            print("Error loading content: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    // Helper method to get initial sample content
    func getSampleContent() -> Content {
        Content(
            title: "Loading...",
            service: .disney,
            category: .action,
            thumbnailURL: "",
            bannerURL: "",
            description: "Loading content...",
            isTVShow: true,
            likes: 0,
            comments: [],
            episodes: [],
            viewCount: 0
        )
    }
} 

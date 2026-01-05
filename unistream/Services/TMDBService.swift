import Foundation

struct TMDBService {
    static let baseURL = "https://api.themoviedb.org/3"
    static let apiKey = "472a2f9fd2734160ac9ffd5e2fe54635"
    static let accessToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NzJhMmY5ZmQyNzM0MTYwYWM5ZmZkNWUyZmU1NDYzNSIsIm5iZiI6MTc0MDg2NDIyNC4zNjMwMDAyLCJzdWIiOiI2N2MzN2FlMDNkZTdjOWM4NzU0YWVjNWUiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.-zAPUOaqJwsusFxDN4weJeSk0poj0NEE03r_ey2L2C8"
    static let imageBaseURL = "https://image.tmdb.org/t/p/original"
    
    enum TMDBError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
    }
    
    enum Endpoint {
        case trendingMovies
        case trendingTVShows
        case popularMovies
        case popularTVShows
        case topRatedMovies
        case topRatedTVShows
        case nowPlayingMovies
        case tvDetails(Int)
        case tvSeason(Int, Int)
        case movieDetails(Int)
        
        var path: String {
            switch self {
            case .trendingMovies:
                return "/trending/movie/week"
            case .trendingTVShows:
                return "/trending/tv/week"
            case .popularMovies:
                return "/movie/popular"
            case .popularTVShows:
                return "/tv/popular"
            case .topRatedMovies:
                return "/movie/top_rated"
            case .topRatedTVShows:
                return "/tv/top_rated"
            case .nowPlayingMovies:
                return "/movie/now_playing"
            case .tvDetails(let id):
                return "/tv/\(id)"
            case .tvSeason(let tvId, let seasonNumber):
                return "/tv/\(tvId)/season/\(seasonNumber)"
            case .movieDetails(let id):
                return "/movie/\(id)"
            }
        }
    }
    
    static func fetchTrendingMovies() async throws -> [Content] {
        let movies: TMDBResponse<TMDBMovie> = try await fetchData(from: .trendingMovies)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for movie in movies.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: movie.id, isMovie: true, title: movie.title, overview: movie.overview)
                    let posterPath = movie.posterPath ?? ""
                    let backdropPath = movie.backdropPath ?? ""
                    
                    // Map genre from genreIds
                    let category = mapGenreToCategory(genreIds: movie.genreIds ?? [])
                    
                    return Content(
                        title: movie.title,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: movie.overview,
                        isTVShow: false,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: nil,
                        viewCount: movie.voteCount
                    )
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    static func fetchTrendingTVShows() async throws -> [Content] {
        let shows: TMDBResponse<TMDBTVShow> = try await fetchData(from: .trendingTVShows)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for show in shows.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: show.id, isMovie: false, title: show.name, overview: show.overview)
                    let posterPath = show.posterPath ?? ""
                    let backdropPath = show.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: show.genreIds ?? [])
                    
                    let content = Content(
                        title: show.name,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: show.overview,
                        isTVShow: true,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: [],
                        viewCount: show.voteCount
                    )
                    
                    // Fetch real episodes from TMDB
                    var mutableContent = content
                    if let episodes = try? await fetchTVShowEpisodes(tvShowId: show.id, content: content) {
                        mutableContent.episodes = episodes
                    } else {
                        // Fallback to sample episodes if fetch fails
                        mutableContent.episodes = generateSampleEpisodes(for: content)
                    }
                    return mutableContent
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    // Fetch real TV show episodes from TMDB
    static func fetchTVShowEpisodes(tvShowId: Int, content: Content) async throws -> [Episode] {
        // First get TV show details to get seasons
        let tvDetails: TMDBTVDetails = try await fetchData(from: .tvDetails(tvShowId))
        var allEpisodes: [Episode] = []
        
        // Fetch episodes for each season (limit to first 3 seasons to avoid too many API calls)
        for season in tvDetails.seasons.prefix(3) where season.seasonNumber > 0 {
            do {
                let seasonData: TMDBTVSeasonDetails = try await fetchData(from: .tvSeason(tvShowId, season.seasonNumber))
                
                for episodeData in seasonData.episodes {
                    let episode = Episode(
                        title: episodeData.name,
                        description: episodeData.overview ?? "No description available",
                        season: episodeData.seasonNumber,
                        episodeNumber: episodeData.episodeNumber,
                        likes: episodeData.voteCount,
                        comments: [],
                        parentContent: content
                    )
                    allEpisodes.append(episode)
                }
            } catch {
                print("Error fetching season \(season.seasonNumber): \(error)")
                // Continue with other seasons if one fails
            }
        }
        
        return allEpisodes
    }
    
    // Map TMDB genre IDs to app Category enum
    private static func mapGenreToCategory(genreIds: [Int]) -> Category {
        // TMDB genre IDs mapping
        // Action: 28, Adventure: 12, Animation: 16, Comedy: 35, Crime: 80, Documentary: 99
        // Drama: 18, Family: 10751, Fantasy: 14, History: 36, Horror: 27, Music: 10402
        // Mystery: 9648, Romance: 10749, Sci-Fi: 878, Thriller: 53, War: 10752, Western: 37
        
        for genreId in genreIds {
            switch genreId {
            case 28, 12: // Action, Adventure
                return .action
            case 35: // Comedy
                return .comedy
            case 18, 80: // Drama, Crime
                return .drama
            case 878, 14: // Sci-Fi, Fantasy
                return .scifi
            case 27, 53: // Horror, Thriller
                return .horror
            case 99: // Documentary
                return .documentary
            case 16, 10751: // Animation, Family
                return .kids
            default:
                continue
            }
        }
        
        // Default to action if no match
        return .action
    }

    static func fetchPopularMovies() async throws -> [Content] {
        let movies: TMDBResponse<TMDBMovie> = try await fetchData(from: .popularMovies)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for movie in movies.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: movie.id, isMovie: true, title: movie.title, overview: movie.overview)
                    let posterPath = movie.posterPath ?? ""
                    let backdropPath = movie.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: movie.genreIds ?? [])
                    
                    return Content(
                        title: movie.title,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: movie.overview,
                        isTVShow: false,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: nil,
                        viewCount: movie.voteCount
                    )
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    static func fetchTopRatedMovies() async throws -> [Content] {
        let movies: TMDBResponse<TMDBMovie> = try await fetchData(from: .topRatedMovies)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for movie in movies.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: movie.id, isMovie: true, title: movie.title, overview: movie.overview)
                    let posterPath = movie.posterPath ?? ""
                    let backdropPath = movie.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: movie.genreIds ?? [])
                    
                    return Content(
                        title: movie.title,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: movie.overview,
                        isTVShow: false,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: nil,
                        viewCount: movie.voteCount
                    )
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    static func fetchPopularTVShows() async throws -> [Content] {
        let shows: TMDBResponse<TMDBTVShow> = try await fetchData(from: .popularTVShows)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for show in shows.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: show.id, isMovie: false, title: show.name, overview: show.overview)
                    let posterPath = show.posterPath ?? ""
                    let backdropPath = show.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: show.genreIds ?? [])
                    
                    let content = Content(
                        title: show.name,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: show.overview,
                        isTVShow: true,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: [],
                        viewCount: show.voteCount
                    )
                    
                    // Fetch real episodes from TMDB
                    var mutableContent = content
                    if let episodes = try? await fetchTVShowEpisodes(tvShowId: show.id, content: content) {
                        mutableContent.episodes = episodes
                    } else {
                        mutableContent.episodes = generateSampleEpisodes(for: content)
                    }
                    return mutableContent
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    static func fetchTopRatedTVShows() async throws -> [Content] {
        let shows: TMDBResponse<TMDBTVShow> = try await fetchData(from: .topRatedTVShows)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for show in shows.results.prefix(20) {
                group.addTask {
                    let service = try await getStreamingService(for: show.id, isMovie: false, title: show.name, overview: show.overview)
                    let posterPath = show.posterPath ?? ""
                    let backdropPath = show.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: show.genreIds ?? [])
                    
                    let content = Content(
                        title: show.name,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: show.overview,
                        isTVShow: true,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: [],
                        viewCount: show.voteCount
                    )
                    
                    // Fetch real episodes from TMDB
                    var mutableContent = content
                    if let episodes = try? await fetchTVShowEpisodes(tvShowId: show.id, content: content) {
                        mutableContent.episodes = episodes
                    } else {
                        mutableContent.episodes = generateSampleEpisodes(for: content)
                    }
                    return mutableContent
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    static func fetchNowPlayingMovies() async throws -> [Content] {
        let movies: TMDBResponse<TMDBMovie> = try await fetchData(from: .nowPlayingMovies)
        return try await withThrowingTaskGroup(of: Content.self) { group in
            var contents: [Content] = []
            
            for movie in movies.results.prefix(20) {
                group.addTask {
                    // Movies in "now playing" should be "In Theaters" unless they have streaming providers
                    let service: StreamingService
                    do {
                        let providers = try await fetchWatchProviders(for: movie.id, isMovie: true)
                        // If no streaming providers found, it's theater-only
                        if providers.isEmpty {
                            service = .inTheaters
                        } else if let streamingService = mapProviderToService(providers: providers) {
                            // If streaming providers exist, use the first one
                            service = streamingService
                        } else {
                            // No recognized streaming provider, default to theaters
                            service = .inTheaters
                        }
                    } catch {
                        // If API call fails, default to theaters for now playing movies
                        service = .inTheaters
                    }
                    
                    let posterPath = movie.posterPath ?? ""
                    let backdropPath = movie.backdropPath ?? ""
                    let category = mapGenreToCategory(genreIds: movie.genreIds ?? [])
                    
                    return Content(
                        title: movie.title,
                        service: service,
                        category: category,
                        thumbnailURL: "\(imageBaseURL)\(posterPath)",
                        bannerURL: "\(imageBaseURL)\(backdropPath)",
                        description: movie.overview,
                        isTVShow: false,
                        likes: Int.random(in: 100...1000),
                        comments: [],
                        episodes: nil,
                        viewCount: movie.voteCount
                    )
                }
            }
            
            for try await content in group {
                contents.append(content)
            }
            
            return contents
        }
    }
    
    private static func fetchData<T: Codable>(from endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            print("Invalid URL: \(baseURL + endpoint.path)")
            throw TMDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Fetching data from: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                throw TMDBError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("Error response: \(responseString)")
                throw TMDBError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                print("Successfully decoded response")
                return result
            } catch {
                print("Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                throw TMDBError.decodingError
            }
        } catch {
            print("Network error: \(error)")
            throw error
        }
    }
    
    // Get streaming service using watch providers API, fallback only if absolutely necessary
    private static func getStreamingService(for id: Int, isMovie: Bool, title: String, overview: String) async throws -> StreamingService {
        // Always try to fetch watch providers first - this is the most accurate source
        do {
            let providers = try await fetchWatchProviders(for: id, isMovie: isMovie)
            if !providers.isEmpty {
                if let service = mapProviderToService(providers: providers) {
                    print("✅ Assigned \(title) to \(service.rawValue) via watch providers")
                    return service
                } else {
                    print("⚠️ Watch providers found for \(title) but no matching service: \(providers.map { $0.name }.joined(separator: ", "))")
                }
            } else {
                print("⚠️ No watch providers found for \(title) - may be theater-only or not yet available")
            }
        } catch {
            print("❌ Failed to fetch watch providers for \(title): \(error.localizedDescription)")
        }
        
        // Only use pattern matching as last resort for known originals
        // Don't use random assignment - it's inaccurate
        if let service = assignStreamingService(for: title, overview: overview) {
            print("📝 Assigned \(title) to \(service.rawValue) via pattern matching")
            return service
        }
        
        // If we can't determine from watch providers or patterns, 
        // check if it might be theater-only (for movies)
        if isMovie {
            print("❓ Could not determine streaming service for movie \(title), may be theater-only")
            // For movies without streaming providers, it's likely theater-only
            return .inTheaters
        }
        
        // For TV shows, default to a neutral service if we can't determine
        print("❓ Could not determine service for \(title), defaulting to Prime Video")
        return .prime // Default fallback for TV shows
    }
    
    // Fetch watch providers for a movie or TV show
    // Reference: https://developer.themoviedb.org/reference/movie-watch-providers
    private static func fetchWatchProviders(for id: Int, isMovie: Bool) async throws -> [TMDBProvider] {
        let endpoint = isMovie ? "/movie/\(id)/watch/providers" : "/tv/\(id)/watch/providers"
        let providers: TMDBWatchProviders = try await fetchDataFromPath(endpoint)
        
        // Priority order: US > CA > GB > first available country
        let preferredCountries = ["US", "CA", "GB"]
        
        // Try preferred countries first
        for countryCode in preferredCountries {
            if let countryProviders = providers.results[countryCode] {
                var allProviders: [TMDBProvider] = []
                // Prioritize flatrate (subscription) providers
                if let flatrate = countryProviders.flatrate {
                    allProviders.append(contentsOf: flatrate)
                }
                // Then add buy options as fallback
                if let buy = countryProviders.buy {
                    allProviders.append(contentsOf: buy)
                }
                // Finally add rent options
                if let rent = countryProviders.rent {
                    allProviders.append(contentsOf: rent)
                }
                if !allProviders.isEmpty {
                    return allProviders
                }
            }
        }
        
        // If no preferred country providers, try any available country
        for countryProviders in providers.results.values {
            var allProviders: [TMDBProvider] = []
            if let flatrate = countryProviders.flatrate {
                allProviders.append(contentsOf: flatrate)
            }
            if let buy = countryProviders.buy {
                allProviders.append(contentsOf: buy)
            }
            if let rent = countryProviders.rent {
                allProviders.append(contentsOf: rent)
            }
            if !allProviders.isEmpty {
                return allProviders
            }
        }
        
        return []
    }
    
    // Helper function to fetch data from a custom endpoint path
    private static func fetchDataFromPath<T: Codable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw TMDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TMDBError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    // Map TMDB provider IDs to our StreamingService enum
    // Reference: https://developer.themoviedb.org/reference/movie-watch-providers
    private static func mapProviderToService(providers: [TMDBProvider]) -> StreamingService? {
        // TMDB provider ID mapping - official IDs from TMDB API
        // These IDs are from the watch/providers endpoint
        let providerMapping: [Int: StreamingService] = [
            // Netflix
            8: .netflix,
            // Disney+
            337: .disney,
            // Hulu
            15: .hulu,
            // Paramount+
            531: .paramount,
            // Apple TV+
            350: .appleTV,
            // Prime Video
            9: .prime,
            // Max (formerly HBO Max)
            384: .hboMax,
            // Peacock
            386: .peacock
        ]
        
        // Check providers in order - first match wins
        // Providers are already ordered by priority (flatrate first, then buy, then rent)
        for provider in providers {
            if let service = providerMapping[provider.id] {
                print("✅ Mapped provider \(provider.name) (ID: \(provider.id)) to \(service.rawValue)")
                return service
            }
        }
        
        // Log all providers for debugging
        let providerList = providers.map { "\($0.name) (ID: \($0.id))" }.joined(separator: ", ")
        print("⚠️ No matching provider found. Available providers: \(providerList.isEmpty ? "none" : providerList)")
        return nil
    }
    
    private static func assignStreamingService(for title: String, overview: String) -> StreamingService? {
        // Only use pattern matching for known originals/exclusives
        // This should be a last resort - watch providers API is preferred
        
        // Apple TV+ originals - be specific
        let applePatterns = ["Ted Lasso", "The Morning Show", "Foundation", "See", "For All Mankind", "Pluribus"]
        for pattern in applePatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .appleTV
            }
        }
        
        // Disney+ content patterns
        let disneyPatterns = ["Marvel", "Star Wars", "Disney", "Pixar", "National Geographic"]
        for pattern in disneyPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .disney
            }
        }
        
        // Netflix Originals patterns - be specific
        let netflixPatterns = ["Stranger Things", "Bridgerton", "The Witcher", "The Crown", "Squid Game"]
        for pattern in netflixPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .netflix
            }
        }
        
        // HBO Max patterns
        let hboPatterns = ["House of the Dragon", "The Last of Us", "Succession", "Game of Thrones"]
        for pattern in hboPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .hboMax
            }
        }
        
        // Paramount+ patterns
        let paramountPatterns = ["Star Trek", "Yellowstone", "1883", "1923"]
        for pattern in paramountPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .paramount
            }
        }
        
        // Hulu patterns
        let huluPatterns = ["The Handmaid's Tale", "Only Murders in the Building", "The Bear"]
        for pattern in huluPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .hulu
            }
        }
        
        // Prime Video patterns
        let primePatterns = ["The Boys", "The Wheel of Time", "The Rings of Power"]
        for pattern in primePatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .prime
            }
        }
        
        // Peacock patterns
        let peacockPatterns = ["The Office", "Brooklyn Nine-Nine", "Yellowjackets"]
        for pattern in peacockPatterns {
            if title.localizedCaseInsensitiveContains(pattern) || overview.localizedCaseInsensitiveContains(pattern) {
                return .peacock
            }
        }
        
        // Return nil if no match - don't guess
        return nil
    }
    
    private static func generateSampleEpisodes(for content: Content) -> [Episode] {
        (1...5).map { episodeNum in
            Episode(
                title: "Episode \(episodeNum)",
                description: "A new exciting episode of \(content.title)",
                season: 1,
                episodeNumber: episodeNum,
                likes: Int.random(in: 50...500),
                comments: [],
                parentContent: content
            )
        }
    }
} 

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
    
    // Get streaming service using watch providers API, fallback to pattern matching
    private static func getStreamingService(for id: Int, isMovie: Bool, title: String, overview: String) async throws -> StreamingService {
        // Try to fetch watch providers first
        do {
            let providers = try await fetchWatchProviders(for: id, isMovie: isMovie)
            if let service = mapProviderToService(providers: providers) {
                return service
            }
        } catch {
            // If watch providers fail, fall back to pattern matching
            print("Failed to fetch watch providers for \(title), using pattern matching")
        }
        
        // Fallback to improved pattern matching
        return assignStreamingService(for: title, overview: overview)
    }
    
    // Fetch watch providers for a movie or TV show
    private static func fetchWatchProviders(for id: Int, isMovie: Bool) async throws -> [TMDBProvider] {
        let endpoint = isMovie ? "/movie/\(id)/watch/providers" : "/tv/\(id)/watch/providers"
        let providers: TMDBWatchProviders = try await fetchDataFromPath(endpoint)
        
        // Get US providers (most common)
        if let usProviders = providers.results["US"] {
            var allProviders: [TMDBProvider] = []
            if let flatrate = usProviders.flatrate {
                allProviders.append(contentsOf: flatrate)
            }
            if let buy = usProviders.buy {
                allProviders.append(contentsOf: buy)
            }
            return allProviders
        }
        
        // If no US providers, try to get from first available country
        if let firstCountry = providers.results.values.first {
            var allProviders: [TMDBProvider] = []
            if let flatrate = firstCountry.flatrate {
                allProviders.append(contentsOf: flatrate)
            }
            if let buy = firstCountry.buy {
                allProviders.append(contentsOf: buy)
            }
            return allProviders
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
    private static func mapProviderToService(providers: [TMDBProvider]) -> StreamingService? {
        // TMDB provider ID mapping
        let providerMapping: [Int: StreamingService] = [
            8: .netflix,        // Netflix
            337: .disney,       // Disney+
            15: .hulu,          // Hulu
            531: .paramount,   // Paramount+
            350: .appleTV,      // Apple TV+
            9: .prime,          // Prime Video
            384: .hboMax,       // Max (HBO Max)
            386: .peacock       // Peacock
        ]
        
        // Check providers in order of preference (flatrate first, then buy)
        for provider in providers {
            if let service = providerMapping[provider.id] {
                return service
            }
        }
        
        return nil
    }
    
    private static func assignStreamingService(for title: String, overview: String) -> StreamingService {
        // Disney+ content patterns
        let disneyPatterns = ["Marvel", "Star Wars", "Disney", "Pixar", "National Geographic"]
        for pattern in disneyPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .disney
            }
        }
        
        // Netflix Originals patterns
        let netflixPatterns = ["Netflix Original", "Stranger Things", "Bridgerton", "The Witcher", "The Crown"]
        for pattern in netflixPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .netflix
            }
        }
        
        // HBO Max patterns
        let hboPatterns = ["HBO", "House of the Dragon", "The Last of Us", "Succession", "Warner"]
        for pattern in hboPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .hboMax
            }
        }
        
        // Apple TV+ patterns
        let applePatterns = ["Apple Original", "Ted Lasso", "The Morning Show", "Foundation"]
        for pattern in applePatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .appleTV
            }
        }
        
        // Paramount+ patterns
        let paramountPatterns = ["Paramount", "Star Trek", "Yellowstone", "SpongeBob"]
        for pattern in paramountPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .paramount
            }
        }
        
        // Hulu patterns
        let huluPatterns = ["FX", "The Handmaid's Tale", "Only Murders in the Building"]
        for pattern in huluPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .hulu
            }
        }
        
        // Prime Video patterns
        let primePatterns = ["Amazon Original", "The Boys", "Lord of the Rings", "The Wheel of Time"]
        for pattern in primePatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .prime
            }
        }
        
        // Peacock patterns
        let peacockPatterns = ["NBC", "Universal", "The Office", "Brooklyn Nine-Nine"]
        for pattern in peacockPatterns {
            if title.contains(pattern) || overview.contains(pattern) {
                return .peacock
            }
        }
        
        // If no specific match, use weighted random assignment
        return assignRandomService()
    }
    
    private static func assignRandomService() -> StreamingService {
        // Weighted distribution to make some services more common
        let services: [(StreamingService, Double)] = [
            (.netflix, 0.2),
            (.disney, 0.15),
            (.hulu, 0.15),
            (.prime, 0.15),
            (.appleTV, 0.1),
            (.hboMax, 0.1),
            (.paramount, 0.1),
            (.peacock, 0.05)
        ]
        
        let total = services.reduce(0) { $0 + $1.1 }
        var random = Double.random(in: 0..<total)
        
        for (service, weight) in services {
            random -= weight
            if random <= 0 {
                return service
            }
        }
        
        return .netflix // Fallback
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

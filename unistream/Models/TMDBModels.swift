import Foundation

struct TMDBResponse<T: Codable>: Codable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBMovie: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteCount: Int
    let releaseDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
    }
}

struct TMDBTVShow: Codable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteCount: Int
    let firstAirDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
    }
}

// Watch Providers Models
struct TMDBWatchProviders: Codable {
    let results: [String: TMDBWatchProviderCountry]
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

struct TMDBWatchProviderCountry: Codable {
    let link: String?
    let flatrate: [TMDBProvider]?
    let buy: [TMDBProvider]?
    let rent: [TMDBProvider]?
}

struct TMDBProvider: Codable {
    let id: Int
    let name: String
    let logoPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case logoPath = "logo_path"
    }
} 
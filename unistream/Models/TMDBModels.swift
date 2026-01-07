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
    let genreIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case genreIds = "genre_ids"
    }
}

struct TMDBMovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteCount: Int
    let releaseDate: String?
    let genres: [TMDBGenre]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case genres
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
    let genreIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
        case genreIds = "genre_ids"
    }
}

struct TMDBTVSeason: Codable {
    let id: Int
    let name: String
    let overview: String?
    let seasonNumber: Int
    let episodeCount: Int
    let airDate: String?
    let posterPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case airDate = "air_date"
        case posterPath = "poster_path"
    }
}

struct TMDBTVEpisode: Codable {
    let id: Int
    let name: String
    let overview: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let airDate: String?
    let stillPath: String?
    let voteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteCount = "vote_count"
    }
}

struct TMDBTVDetails: Codable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteCount: Int
    let firstAirDate: String?
    let seasons: [TMDBTVSeason]
    let genres: [TMDBGenre]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
        case seasons
        case genres
    }
}

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBTVSeasonDetails: Codable {
    let id: Int
    let name: String
    let overview: String?
    let seasonNumber: Int
    let episodes: [TMDBTVEpisode]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case seasonNumber = "season_number"
        case episodes
    }
}

// Video Models
struct TMDBVideoResponse: Codable {
    let id: Int
    let results: [TMDBVideo]
}

struct TMDBVideo: Codable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case name
        case site
        case type
        case official
    }
}

// Watch Providers Models
struct TMDBWatchProviders: Codable {
    let id: Int?
    let results: [String: TMDBWatchProviderCountry]
    
    enum CodingKeys: String, CodingKey {
        case id
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
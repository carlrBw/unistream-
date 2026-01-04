import SwiftUI

enum StreamingService: String, CaseIterable {
    case netflix = "Netflix"
    case disney = "Disney+"
    case hulu = "Hulu"
    case paramount = "Paramount+"
    case appleTV = "Apple TV+"
    case prime = "Prime Video"
    case hboMax = "Max"
    case peacock = "Peacock"
    case inTheaters = "In Theaters"
    
    var color: Color {
        switch self {
        case .netflix:
            return .red
        case .disney:
            return .blue
        case .hulu:
            return .green
        case .paramount:
            return .blue.opacity(0.7)
        case .appleTV:
            return .gray
        case .prime:
            return .blue.opacity(0.8)
        case .hboMax:
            return .purple
        case .peacock:
            return .yellow
        case .inTheaters:
            return .orange
        }
    }
    
    var logoURL: String {
        switch self {
        case .netflix:
            return "https://assets.nflxext.com/us/ffe/siteui/common/icons/nficon2016.ico"
        case .disney:
            return "https://static-assets.bamgrid.com/product/disneyplus/favicons/favicon.ico"
        case .hulu:
            return "https://www.hulu.com/static/hitch/static/icons/favicon.ico"
        case .paramount:
            return "https://www.paramountplus.com/favicon.ico"
        case .appleTV:
            return "https://tv.apple.com/favicon.ico"
        case .prime:
            return "https://m.media-amazon.com/images/G/01/digital/video/DVUI/favicons/favicon-196x196.png"
        case .hboMax:
            return "https://www.max.com/favicon.ico"
        case .peacock:
            return "https://www.peacocktv.com/static/favicon.ico"
        case .inTheaters:
            return "" // Will use system icon
        }
    }
} 
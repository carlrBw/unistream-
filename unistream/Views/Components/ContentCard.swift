import SwiftUI

struct ContentCard: View {
    let content: Content
    
    var body: some View {
        NavigationLink(destination: ContentDetailView(content: content)) {
            VStack(alignment: .leading) {
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
                .frame(width: 120, height: 180)
                .cornerRadius(10)
                
                Text(content.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Service logo
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
                    
                    // View count
                    HStack(spacing: 2) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("\(content.viewCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.gray)
                }
            }
            .frame(width: 120)
        }
    }
} 
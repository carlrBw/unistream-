import SwiftUI

struct ContentDetailView: View {
    @StateObject private var mockData = MockData.shared
    let content: Content
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var viewsCount: Int
    @State private var newComment = ""
    @State private var comments: [Comment]
    @State private var selectedEpisode: Episode?
    @State private var isAddedToProfile: Bool
    @State private var isLooped = false
    @State private var isWatched = false
    @State private var selectedSeason: Int = 1
    
    init(content: Content) {
        self.content = content
        _likesCount = State(initialValue: content.likes)
        _viewsCount = State(initialValue: content.viewCount)
        _comments = State(initialValue: content.comments)
        _isAddedToProfile = State(initialValue: false)
        if let firstEpisode = content.episodes?.first {
            _selectedEpisode = State(initialValue: firstEpisode)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Banner Image Section with Overlay Content
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Banner Image
                        AsyncImage(url: URL(string: content.bannerURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 400)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(content.service.color.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        
                        // Gradient Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .black.opacity(0.3),
                                .black.opacity(0.7),
                                .black.opacity(0.9)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Content Info Overlay
                        VStack(alignment: .leading, spacing: 16) {
                            // Add spacer to push content down
                            Spacer()
                                .frame(height: 270) // Increased to show more of the banner image
                            
                            // Title and Action Buttons
                            HStack {
                                Text(content.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                HStack(spacing: 15) {
                                    Button(action: toggleAddToProfile) {
                                        Image(systemName: isAddedToProfile ? "checkmark.circle.fill" : "plus.circle.fill")
                                            .foregroundColor(isAddedToProfile ? .green : .blue)
                                            .imageScale(.large)
                                    }
                                    
                                    if !content.isTVShow {
                                        Button(action: toggleLoop) {
                                            Image(systemName: isLooped ? "infinity.circle.fill" : "infinity.circle")
                                                .foregroundColor(isLooped ? .blue : .gray)
                                                .imageScale(.large)
                                        }
                                    }
                                }
                            }
                            
                            // Service and Type Info
                            HStack {
                                AsyncImage(url: URL(string: content.service.logoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 20)
                                } placeholder: {
                                    Text(content.service.rawValue)
                                        .foregroundColor(content.service.color)
                                }
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text(content.category.rawValue)
                                    .foregroundColor(.gray)
                                
                                if content.isTVShow {
                                    Text("•")
                                        .foregroundColor(.gray)
                                    
                                    // Calculate unique seasons
                                    let seasonCount = Set(content.episodes?.map { $0.season } ?? []).count
                                    Text("TV Series • \(seasonCount) Season\(seasonCount == 1 ? "" : "s")")
                                        .foregroundColor(.gray)
                                }
                            }
                            .font(.subheadline)
                            
                            // Description
                            Text(content.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(3)
                            
                            // View count and Play button
                            HStack {
                                // View count and likes
                                HStack(spacing: 16) {
                                    // View count
                                    HStack(spacing: 4) {
                                        Image(systemName: "eye.fill")
                                            .foregroundColor(.gray)
                                        Text("\(viewsCount) user\(viewsCount == 1 ? " has" : "s have") watched")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Likes count
                                    HStack(spacing: 4) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(isLiked ? .red : .gray)
                                        Text("\(likesCount) user\(likesCount == 1 ? " has" : "s have") liked")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                // Watched button (only for movies)
                                if !content.isTVShow {
                                    Button(action: toggleWatched) {
                                        Image(systemName: isWatched ? "checkmark.circle.fill" : "checkmark.circle")
                                            .foregroundColor(isWatched ? .green : .gray)
                                            .imageScale(.large)
                                    }
                                }
                                
                                // Play button
                                Button(action: {
                                    // Add play action here
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .frame(height: 400)
                
                // Description and remaining content
                VStack(alignment: .leading, spacing: 20) {
                    if content.isTVShow {
                        // Season Counter - Moved below content info with spacing
                        if let episodes = content.episodes {
                            let seasons = Array(Set(episodes.map { $0.season })).sorted()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Season Picker
                                Menu {
                                    ForEach(seasons, id: \.self) { season in
                                        Button(action: {
                                            withAnimation {
                                                selectedSeason = season
                                            }
                                        }) {
                                            HStack {
                                                Text("Season \(season)")
                                                if season == selectedSeason {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Season \(selectedSeason)")
                                            .fontWeight(.semibold)
                                        Image(systemName: "chevron.down")
                                            .imageScale(.small)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Episode count for selected season
                                let seasonEpisodes = episodes.filter { $0.season == selectedSeason }
                                Text("\(seasonEpisodes.count) Episodes")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.top, 40)
                            .padding(.bottom, 10)
                        }
                        
                        // Episodes Section
                        VStack(alignment: .leading, spacing: 15) {
                            if let episodes = content.episodes {
                                // Episodes List
                                ForEach(episodes.filter { $0.season == selectedSeason }) { episode in
                                    EpisodeCard(
                                        episode: episode,
                                        isSelected: episode.id == selectedEpisode?.id
                                    ) {
                                        withAnimation {
                                            selectedEpisode = episode
                                        }
                                    }
                                    .padding(.horizontal)
                                    .transition(.opacity)
                                }
                            }
                        }
                    } else {
                        // Movie Social Section
                        MovieSocialSection(
                            content: content,
                            isLiked: $isLiked,
                            likesCount: $likesCount,
                            comments: $comments,
                            newComment: $newComment
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isAddedToProfile = userState.isInMyList(content)
            isLooped = userState.loopedSeries.contains(where: { $0.id == content.id })
            
            // Load real data from interaction service
            if let userId = userState.currentUser?.id {
                isLiked = interactionService.hasUserLikedContent(content.id, userId: userId)
                likesCount = interactionService.getContentLikesCount(content.id)
                
                if !content.isTVShow {
                    isWatched = interactionService.hasUserWatchedContent(content.id, userId: userId)
                    viewsCount = interactionService.getContentViewsCount(content.id)
                } else {
                    viewsCount = content.viewCount // Keep original view count for TV shows
                }
            } else {
                // For non-authenticated users, show counts but not personal status
                likesCount = interactionService.getContentLikesCount(content.id)
                if !content.isTVShow {
                    viewsCount = interactionService.getContentViewsCount(content.id)
                } else {
                    viewsCount = content.viewCount
                }
            }
        }
        .task {
            if mockData.content.isEmpty {
                await mockData.loadContent()
            }
        }
    }
    
    private func toggleAddToProfile() {
        withAnimation {
            isAddedToProfile.toggle()
            if isAddedToProfile {
                userState.addToMyList(content)
            } else {
                userState.removeFromMyList(content)
            }
        }
    }
    
    private func toggleLoop() {
        withAnimation {
            isLooped.toggle()
            if isLooped {
                userState.addToLoopedEpisodes(content: content, episode: selectedEpisode!)
            }
            // You might want to add a remove function as well
        }
    }
    
    private func toggleWatched() {
        guard let userId = userState.currentUser?.id else { return }
        
        withAnimation {
            isWatched.toggle()
            if isWatched {
                userState.markMovieAsWatched(content)
                interactionService.markContentAsWatched(content.id, userId: userId)
                viewsCount = interactionService.getContentViewsCount(content.id)
            } else {
                userState.markMovieAsUnwatched(content)
                interactionService.unmarkContentAsWatched(content.id, userId: userId)
                viewsCount = interactionService.getContentViewsCount(content.id)
            }
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        
        let comment = Comment(
            username: userState.currentUser?.username ?? "Anonymous",
            text: newComment,
            timestamp: Date(),
            content: content
        )
        
        // Add comment to the content
        comments.append(comment)
        
        // Add comment to user's profile
        userState.addComment(comment)
        
        // Clear the comment field
        newComment = ""
    }
}

struct EpisodeCard: View {
    let episode: Episode
    let isSelected: Bool
    let action: () -> Void
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var viewsCount: Int = 0
    @State private var showComments = false
    @State private var newComment = ""
    @State private var comments: [Comment]
    @State private var isLooped = false
    @State private var isWatched = false
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    
    init(episode: Episode, isSelected: Bool, action: @escaping () -> Void) {
        self.episode = episode
        self.isSelected = isSelected
        self.action = action
        _likesCount = State(initialValue: episode.likes)
        _comments = State(initialValue: episode.comments)
    }
    
    private func checkWatchedStatus() {
        if let userId = userState.currentUser?.id {
            isWatched = interactionService.hasUserWatchedEpisode(episode.id, userId: userId)
            viewsCount = interactionService.getEpisodeViewsCount(episode.id)
        } else {
            isWatched = false
            viewsCount = 0
        }
        
        // Also check likes
        if let userId = userState.currentUser?.id {
            isLiked = interactionService.hasUserLikedEpisode(episode.id, userId: userId)
            likesCount = interactionService.getEpisodeLikesCount(episode.id)
        } else {
            likesCount = interactionService.getEpisodeLikesCount(episode.id)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Episode \(episode.episodeNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(episode.title)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: toggleLoop) {
                            Image(systemName: isLooped ? "infinity.circle.fill" : "infinity.circle")
                                .foregroundColor(isLooped ? .blue : .gray)
                                .imageScale(.large)
                        }
                    }
                    
                    Text(episode.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            HStack(spacing: 20) {
                // Like and Comment buttons
                HStack(spacing: 20) {
                    Button(action: toggleLike) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .gray)
                            Text("\(likesCount)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: { 
                        withAnimation {
                            showComments.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .foregroundColor(.gray)
                            Text("\(comments.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Watched button
                Button(action: toggleWatched) {
                    Image(systemName: isWatched ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(isWatched ? .green : .gray)
                        .imageScale(.large)
                }
                
                // Play button
                Button(action: {
                    // Add play action here
                }) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }
            .padding(.top, 4)
            .onAppear {
                checkWatchedStatus()
            }
            
            if showComments {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        
                        Button("Post") {
                            addComment()
                        }
                        .disabled(newComment.isEmpty)
                        .foregroundColor(newComment.isEmpty ? .gray : .blue)
                    }
                    .padding(.vertical, 8)
                    
                    ForEach(comments) { comment in
                        CommentCardView(comment: comment)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private func toggleLike() {
        guard let userId = userState.currentUser?.id else { return }
        
        withAnimation {
            isLiked.toggle()
            if isLiked {
                interactionService.likeEpisode(episode.id, userId: userId)
            } else {
                interactionService.unlikeEpisode(episode.id, userId: userId)
            }
            likesCount = interactionService.getEpisodeLikesCount(episode.id)
        }
    }
    
    private func toggleLoop() {
        withAnimation {
            isLooped.toggle()
            if isLooped {
                userState.addToLoopedEpisodes(content: episode.parentContent, episode: episode)
            }
            // You might want to add a remove function as well
        }
    }
    
    private func toggleWatched() {
        guard let userId = userState.currentUser?.id else { return }
        
        withAnimation {
            isWatched.toggle()
            if isWatched {
                userState.markEpisodeAsWatched(episode)
                interactionService.markEpisodeAsWatched(episode.id, userId: userId)
                viewsCount = interactionService.getEpisodeViewsCount(episode.id)
            } else {
                userState.markEpisodeAsUnwatched(episode)
                interactionService.unmarkEpisodeAsWatched(episode.id, userId: userId)
                viewsCount = interactionService.getEpisodeViewsCount(episode.id)
            }
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        
        let comment = Comment(
            username: userState.currentUser?.username ?? "Anonymous",
            text: newComment,
            timestamp: Date(),
            content: episode.parentContent
        )
        
        // Add comment to the content
        comments.append(comment)
        
        // Add comment to user's profile
        userState.addComment(comment)
        
        // Clear the comment field
        newComment = ""
    }
}

struct CommentCardView: View {
    let comment: Comment
    @State private var isLiked = false
    @State private var likesCount = 0
    @State private var showReplyField = false
    @State private var replyText = ""
    @State private var replies: [Comment] = []
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(comment.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(comment.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text(comment.text)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 16) {
                Button(action: toggleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(likesCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showReplyField.toggle() }) {
                    Text("Reply")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 4)
            
            if showReplyField {
                HStack {
                    TextField("Write a reply...", text: $replyText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.white)
                    
                    Button("Reply") {
                        postReply()
                    }
                    .disabled(replyText.isEmpty)
                    .foregroundColor(replyText.isEmpty ? .gray : .blue)
                }
                .padding(.leading, 16)
            }
            
            ForEach(replies) { reply in
                CommentCardView(comment: reply)
                    .padding(.leading, 16)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
    
    private func toggleLike() {
        withAnimation {
            isLiked.toggle()
            likesCount += isLiked ? 1 : -1
        }
    }
    
    private func postReply() {
        guard !replyText.isEmpty else { return }
        let reply = Comment(
            username: userState.currentUser?.username ?? "Anonymous",
            text: replyText,
            timestamp: Date(),
            content: comment.content
        )
        withAnimation {
            replies.insert(reply, at: 0)
        }
        // Add reply to user's profile activity
        userState.addComment(reply)
        replyText = ""
        showReplyField = false
    }
}

struct MovieSocialSection: View {
    let content: Content
    @Binding var isLiked: Bool
    @Binding var likesCount: Int
    @Binding var comments: [Comment]
    @Binding var newComment: String
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var interactionService: UserInteractionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Likes
            HStack {
                Button(action: toggleLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                Text("\(likesCount) user\(likesCount == 1 ? " has" : "s have") liked")
                    .foregroundColor(.gray)
            }
            
            // Comment Input
            CommentInput(newComment: $newComment) {
                addComment()
            }
            
            // Comments List
            ForEach(comments) { comment in
                CommentView(comment: comment)
            }
        }
    }
    
    private func toggleLike() {
        guard let userId = userState.currentUser?.id else { return }
        
        isLiked.toggle()
        if isLiked {
            interactionService.likeContent(content.id, userId: userId)
        } else {
            interactionService.unlikeContent(content.id, userId: userId)
        }
        likesCount = interactionService.getContentLikesCount(content.id)
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        
        let comment = Comment(
            username: userState.currentUser?.username ?? "Anonymous",
            text: newComment,
            timestamp: Date(),
            content: content
        )
        
        // Add comment to the content
        comments.append(comment)
        
        // Add comment to user's profile
        userState.addComment(comment)
        
        // Clear the comment field
        newComment = ""
    }
}

struct CommentInput: View {
    @Binding var newComment: String
    let action: () -> Void
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        HStack {
            TextField("Add a comment...", text: $newComment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.white)
            
            Button("Post", action: action)
                .disabled(newComment.isEmpty)
                .foregroundColor(newComment.isEmpty ? .gray : .blue)
        }
    }
}

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(comment.username)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(comment.text)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct EpisodeSocialSection: View {
    let episode: Episode
    @State private var isLiked: Bool = false
    @State private var likesCount: Int
    @State private var comments: [Comment]
    @State private var newComment = ""
    
    init(episode: Episode) {
        self.episode = episode
        _likesCount = State(initialValue: episode.likes)
        _comments = State(initialValue: episode.comments)
    }
    
    var body: some View {
        MovieSocialSection(
            content: episode.parentContent,
            isLiked: $isLiked,
            likesCount: $likesCount,
            comments: $comments,
            newComment: $newComment
        )
    }
}

#Preview {
    NavigationView {
        ContentDetailView(content: MockData.shared.getSampleContent())
            .environmentObject(UserState())
            .environmentObject(UserInteractionService.shared)
    }
} 

import SwiftUI

struct ContentDetailView: View {
    @StateObject private var mockData = MockData.shared
    let content: Content
    @EnvironmentObject var userState: UserState
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var newComment = ""
    @State private var comments: [Comment]
    @State private var selectedEpisode: Episode?
    @State private var isAddedToProfile: Bool
    @State private var isLooped = false
    @State private var selectedSeason: Int = 1
    
    init(content: Content) {
        self.content = content
        _likesCount = State(initialValue: content.likes)
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
                                .frame(width: geometry.size.width, height: 300)
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
                                .frame(height: 160) // Adjust this value to control how far down the content starts
                            
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
                                        Text("\(content.viewCount) viewers")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Likes count
                                    HStack(spacing: 4) {
                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(isLiked ? .red : .gray)
                                        Text("\(likesCount) likes")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
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
                .frame(height: 300)
                
                // Description and remaining content
                VStack(alignment: .leading, spacing: 20) {
                    if content.isTVShow {
                        // Seasons and Episodes Section
                        VStack(alignment: .leading, spacing: 15) {
                            if let episodes = content.episodes {
                                // Get unique seasons sorted
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
                        .padding(.top, 20)
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
    @State private var showComments = false
    @State private var newComment = ""
    @State private var comments: [Comment]
    @State private var isLooped = false
    @EnvironmentObject var userState: UserState
    
    init(episode: Episode, isSelected: Bool, action: @escaping () -> Void) {
        self.episode = episode
        self.isSelected = isSelected
        self.action = action
        _likesCount = State(initialValue: episode.likes)
        _comments = State(initialValue: episode.comments)
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
        withAnimation {
            isLiked.toggle()
            likesCount += isLiked ? 1 : -1
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Likes
            HStack {
                Button(action: toggleLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                Text("\(likesCount) Likes")
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
        isLiked.toggle()
        likesCount += isLiked ? 1 : -1
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
    }
} 
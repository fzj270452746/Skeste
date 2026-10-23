import Foundation
import CryptoKit

extension Notification.Name {
    static let skesteAuthChanged = Notification.Name("skeste.auth.changed")
    static let skesteContentChanged = Notification.Name("skeste.content.changed")
    static let skesteCoachingChanged = Notification.Name("skeste.coaching.changed")
}

enum AuthOutcome {
    case success(User)
    case failure(String)
}

final class SKDataStore {
    static let shared = SKDataStore()

    private(set) var state: AppState
    private let storageKey = "skeste.state.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            state = decoded
        } else {
            state = Self.seedState()
        }
        if state.socialGraphs.isEmpty {
            for user in state.users {
                state.socialGraphs[user.id] = .empty
            }
        }
        if state.gifts.isEmpty {
            state.gifts = Self.seededGifts(for: state.posts, users: state.users)
        }
        if !UserDefaults.standard.bool(forKey: Self.coachingSeedKey) {
            if state.coachProfiles.isEmpty {
                state.coachProfiles = Self.seededCoachProfiles()
            }
            if state.bookings.isEmpty {
                state.bookings = Self.seededBookings()
            }
            UserDefaults.standard.set(true, forKey: Self.coachingSeedKey)
            save()
        }
        if !UserDefaults.standard.bool(forKey: Self.demoCountsMigrationKey) {
            Self.applyDemoCounts(to: &state)
            UserDefaults.standard.set(true, forKey: Self.demoCountsMigrationKey)
            save()
        }
    }

    var users: [User] { state.users }

    var currentUser: User? {
        guard let id = state.currentUserID else { return nil }
        return state.users.first(where: { $0.id == id })
    }

    var isLoggedIn: Bool { currentUser != nil }

    var sortedPosts: [Post] {
        postsVisibleToCurrent.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var reels: [Post] {
        sortedPosts.filter { $0.kind == .reel }
    }

    var postsVisibleToCurrent: [Post] {
        let blocked = currentGraph().blockedUserIDs
        return state.posts.filter { !blocked.contains($0.authorID) }
    }

    var currentFollowing: [User] {
        let ids = currentGraph().followingIDs
        return state.users.filter { ids.contains($0.id) }
    }

    var currentFollowers: [User] {
        let ids = currentGraph().followerIDs
        return state.users.filter { ids.contains($0.id) }
    }

    var currentPostCount: Int {
        guard let id = state.currentUserID else { return 0 }
        return state.posts.filter { $0.authorID == id }.count
    }

    /// Coaches the current viewer can book. Blocked riders stay out of the line.
    var coaches: [CoachProfile] {
        let blocked = currentGraph().blockedUserIDs
        return state.coachProfiles
            .filter { !blocked.contains($0.userID) }
            .sorted(by: { $0.rating == $1.rating ? $0.sessionCount > $1.sessionCount : $0.rating > $1.rating })
    }

    /// Bookings made by the signed-in learner, newest first.
    var myBookings: [CoachBooking] {
        guard let id = state.currentUserID else { return [] }
        return state.bookings
            .filter { $0.learnerID == id }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    func user(withID id: String?) -> User? {
        guard let id else { return nil }
        return state.users.first(where: { $0.id == id })
    }

    func user(withUsername username: String) -> User? {
        state.users.first(where: { $0.username.lowercased() == username.lowercased() })
    }

    func post(withID id: String) -> Post? {
        state.posts.first(where: { $0.id == id })
    }

    func comment(withID id: String) -> Comment? {
        state.comments.first(where: { $0.id == id })
    }

    func posts(by userID: String) -> [Post] {
        state.posts.filter { $0.authorID == userID }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func comments(for postID: String) -> [Comment] {
        state.comments.filter { $0.postID == postID }.sorted(by: { $0.createdAt < $1.createdAt })
    }

    func gifts(for postID: String) -> [GiftRecord] {
        state.gifts.filter { $0.postID == postID }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    func giftSenders(for postID: String) -> [User] {
        var seen = Set<String>()
        return gifts(for: postID).compactMap { record in
            guard seen.insert(record.senderID).inserted else { return nil }
            return user(withID: record.senderID)
        }
    }

    func commentCount(for postID: String) -> Int {
        state.comments.filter { $0.postID == postID }.count
    }

    func isLiked(postID: String) -> Bool {
        currentGraph().likedPostIDs.contains(postID)
    }

    func isFollowing(userID: String) -> Bool {
        currentGraph().followingIDs.contains(userID)
    }

    func isBlocked(userID: String) -> Bool {
        currentGraph().blockedUserIDs.contains(userID)
    }

    func followerCount(for user: User) -> Int {
        if user.id == state.currentUserID {
            return currentFollowers.count
        }
        return user.baseFollowers + (isFollowing(userID: user.id) ? 1 : 0)
    }

    func followingCount(for user: User) -> Int {
        if user.id == state.currentUserID {
            return currentFollowing.count
        }
        return user.baseFollowing
    }

    func coachProfile(for userID: String) -> CoachProfile? {
        state.coachProfiles.first(where: { $0.userID == userID })
    }

    func isCoach(userID: String) -> Bool {
        coachProfile(for: userID) != nil
    }

    func booking(withID id: String) -> CoachBooking? {
        state.bookings.first(where: { $0.id == id })
    }

    /// The learner's still-open session with a particular coach, if there is one.
    func openBooking(with coachUserID: String) -> CoachBooking? {
        guard let learner = state.currentUserID else { return nil }
        return state.bookings
            .filter { $0.learnerID == learner && $0.coachUserID == coachUserID && $0.isOpen }
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
    }

    @discardableResult
    func toggleLike(postID: String) -> Bool? {
        guard state.currentUserID != nil, var post = post(withID: postID) else { return nil }
        var graph = currentGraph()
        let wasLiked = graph.likedPostIDs.contains(postID)
        if wasLiked {
            graph.likedPostIDs.removeAll(where: { $0 == postID })
            post.likeCount = max(0, post.likeCount - 1)
        } else {
            graph.likedPostIDs.append(postID)
            post.likeCount += 1
        }
        updatePost(post)
        updateGraph(graph)
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        return !wasLiked
    }

    func toggleFollow(userID: String) -> Bool? {
        guard let current = state.currentUserID, current != userID else { return nil }
        guard user(withID: userID) != nil else { return nil }
        var graph = currentGraph()
        let isFollowing = graph.followingIDs.contains(userID)
        if isFollowing {
            graph.followingIDs.removeAll(where: { $0 == userID })
        } else {
            graph.followingIDs.append(userID)
        }
        updateGraph(graph)
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        return !isFollowing
    }

    // MARK: - Coaching bookings

    /// Records the learner's request as pending. The coach's decision is not
    /// simulated in this build: a booking only becomes callable after the status
    /// is moved to `.accepted` by the coach side or a backend.
    @discardableResult
    func requestBooking(coachUserID: String, topic: CoachingTopic, details: String, scheduledAt: Date, durationMinutes: Int) -> CoachBooking? {
        guard let learner = state.currentUserID,
              learner != coachUserID,
              user(withID: learner) != nil,
              user(withID: coachUserID) != nil,
              coachProfile(for: coachUserID) != nil,
              !currentGraph().blockedUserIDs.contains(coachUserID) else { return nil }
        if let open = openBooking(with: coachUserID) { return open }
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { return nil }
        let booking = CoachBooking(
            id: "booking_\(UUID().uuidString)",
            learnerID: learner,
            coachUserID: coachUserID,
            topic: topic,
            details: trimmed,
            scheduledAt: scheduledAt,
            durationMinutes: durationMinutes,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil,
            lastCallAt: nil,
            lastCallDuration: nil,
            lastCallBy: nil
        )
        state.bookings.insert(booking, at: 0)
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
        return booking
    }

    /// Manual status transitions, kept for future coach-side or backend integration.
    @discardableResult
    func acceptBooking(id: String) -> Bool {
        guard let index = state.bookings.firstIndex(where: { $0.id == id && $0.status == .pending }) else { return false }
        state.bookings[index].status = .accepted
        state.bookings[index].respondedAt = Date()
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
        return true
    }

    func declineBooking(id: String) {
        guard let index = state.bookings.firstIndex(where: { $0.id == id && $0.status == .pending }) else { return }
        state.bookings[index].status = .declined
        state.bookings[index].respondedAt = Date()
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func cancelBooking(id: String) {
        guard let index = state.bookings.firstIndex(where: { $0.id == id && $0.isOpen }) else { return }
        state.bookings[index].status = .cancelled
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func recordCallStart(bookingID: String, by userID: String) {
        guard let index = state.bookings.firstIndex(where: { $0.id == bookingID && $0.status == .accepted }) else { return }
        state.bookings[index].lastCallAt = Date()
        state.bookings[index].lastCallBy = userID
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func recordCallEnd(bookingID: String, duration: TimeInterval) {
        guard let index = state.bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        state.bookings[index].lastCallAt = Date()
        state.bookings[index].lastCallDuration = duration
        save()
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func addComment(postID: String, text: String) -> Comment? {
        guard let current = state.currentUserID, post(withID: postID) != nil else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let comment = Comment(id: "cmt_\(UUID().uuidString)", postID: postID, authorID: current, text: trimmed, createdAt: Date())
        state.comments.append(comment)
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        return comment
    }

    func deleteComment(id: String) {
        state.comments.removeAll(where: { $0.id == id })
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
    }

    @discardableResult
    func addPost(kind: PostKind, caption: String, tags: [String], media: [MediaItem]) -> Post? {
        guard let currentID = state.currentUserID, let current = user(withID: currentID) else { return nil }
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !media.isEmpty else { return nil }
        let cleanedTags = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "") }.filter { !$0.isEmpty }
        let post = Post(
            id: "post_\(UUID().uuidString)",
            authorID: currentID,
            kind: kind,
            caption: trimmed,
            tags: cleanedTags,
            media: media,
            createdAt: Date(),
            location: current.homeResort,
            likeCount: 0,
            giftCount: 0,
            viewCount: 0
        )
        state.posts.insert(post, at: 0)
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        return post
    }

    func deletePost(id: String) {
        state.posts.removeAll(where: { $0.id == id })
        state.comments.removeAll(where: { $0.postID == id })
        state.gifts.removeAll(where: { $0.postID == id })
        for key in state.socialGraphs.keys {
            state.socialGraphs[key]?.likedPostIDs.removeAll(where: { $0 == id })
        }
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
    }

    func addGift(postID: String, giftID: String) {
        guard let index = state.posts.firstIndex(where: { $0.id == postID }) else { return }
        state.posts[index].giftCount += 1
        if let sender = state.currentUserID {
            state.gifts.append(GiftRecord(postID: postID, senderID: sender, giftID: giftID))
        }
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
    }

    func updateProfile(displayName: String, bio: String, avatarFileName: String?, avatarAsset: String?) {
        guard let current = state.currentUserID,
              let index = state.users.firstIndex(where: { $0.id == current }) else { return }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            state.users[index].displayName = name
        }
        state.users[index].bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if let avatarFileName {
            state.users[index].avatarFileName = avatarFileName
            state.users[index].avatarAsset = ""
        } else if let avatarAsset {
            state.users[index].avatarAsset = avatarAsset
            state.users[index].avatarFileName = nil
        }
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
    }

    func updateHomeResort(_ resort: String) {
        guard let current = state.currentUserID,
              let index = state.users.firstIndex(where: { $0.id == current }) else { return }
        state.users[index].homeResort = resort
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
    }

    func removeUserAndData(userID: String) {
        let removedPostIDs = Set(state.posts.filter { $0.authorID == userID }.map(\.id))
        state.posts.removeAll(where: { $0.authorID == userID })
        state.comments.removeAll(where: { $0.authorID == userID || removedPostIDs.contains($0.postID) })
        state.gifts.removeAll(where: { $0.senderID == userID || removedPostIDs.contains($0.postID) })
        state.bookings.removeAll(where: { $0.learnerID == userID || $0.coachUserID == userID })
        for key in state.socialGraphs.keys {
            state.socialGraphs[key]?.followingIDs.removeAll(where: { $0 == userID })
            state.socialGraphs[key]?.followerIDs.removeAll(where: { $0 == userID })
        }
        if state.currentUserID != nil {
            var graph = currentGraph()
            if !graph.blockedUserIDs.contains(userID) {
                graph.blockedUserIDs.append(userID)
            }
            updateGraph(graph)
        }
        save()
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func saveRun(_ run: RunRecord) {
        state.runs.insert(run, at: 0)
        save()
        if let encoded = try? JSONEncoder().encode(state.runs) {
            UserDefaults.standard.set(encoded, forKey: "skeste.runs.v1")
        }
    }

    var runs: [RunRecord] {
        state.runs
    }

    var totalVertical: Double {
        state.runs.reduce(0) { $0 + $1.verticalMeters }
    }

    func login(username: String, password: String) -> AuthOutcome {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, !password.isEmpty else {
            return .failure("Enter your username and password.")
        }
        guard let account = state.accounts.first(where: { $0.username.lowercased() == normalized && $0.provider == .local }),
              account.passwordHash == Self.hash(password),
              let user = user(withID: account.userID) else {
            return .failure("That username or password does not match.")
        }
        state.currentUserID = user.id
        ensureGraph(for: user.id)
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
        return .success(user)
    }

    func register(username: String, password: String) -> AuthOutcome {
        let normalized = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))
        guard normalized.count >= 3, normalized.count <= 20,
              normalized.rangeOfCharacter(from: allowed.inverted) == nil else {
            return .failure("Use 3–20 letters, numbers, dots or underscores.")
        }
        guard password.count >= 6 else {
            return .failure("Your password needs at least 6 characters.")
        }
        guard !state.accounts.contains(where: { $0.username.lowercased() == normalized }) else {
            return .failure("That username is already on the mountain.")
        }
        let userID = "u_\(UUID().uuidString.prefix(8))"
        let display = normalized.prefix(1).uppercased() + normalized.dropFirst()
        let user = User(
            id: userID,
            username: normalized,
            displayName: display,
            avatarAsset: "avatar_me",
            avatarFileName: nil,
            bio: "Finding my line.",
            traits: ["Alpine", "Fresh Tracks"],
            homeResort: "Chamonix, FR",
            baseFollowers: 0,
            baseFollowing: 0,
            isVerified: false
        )
        state.users.append(user)
        state.accounts.append(LocalAccount(id: "acct_\(UUID().uuidString)", username: normalized, passwordHash: Self.hash(password), userID: userID, provider: .local, appleID: nil))
        state.socialGraphs[userID] = .empty
        state.currentUserID = userID
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
        return .success(user)
    }

    func loginWithApple(appleID: String, name: String?) -> AuthOutcome {
        if let account = state.accounts.first(where: { $0.provider == .apple && $0.appleID == appleID }),
           let user = user(withID: account.userID) {
            state.currentUserID = user.id
            ensureGraph(for: user.id)
            save()
            NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
            return .success(user)
        }

        let suffix = appleID.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        var username = "rider_\(suffix)"
        var counter = 2
        while state.accounts.contains(where: { $0.username.lowercased() == username.lowercased() }) {
            username = "rider_\(suffix)\(counter)"
            counter += 1
        }
        let display = (name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : "Mountain Rider")
        let userID = "u_apple_\(suffix)"
        let user = User(
            id: userID,
            username: username,
            displayName: display,
            avatarAsset: "avatar_me",
            avatarFileName: nil,
            bio: "Riding on Apple sign-in.",
            traits: ["Alpine", "New Line"],
            homeResort: "Chamonix, FR",
            baseFollowers: 0,
            baseFollowing: 0,
            isVerified: false
        )
        state.users.append(user)
        state.accounts.append(LocalAccount(id: "acct_\(UUID().uuidString)", username: username.lowercased(), passwordHash: "", userID: userID, provider: .apple, appleID: appleID))
        state.socialGraphs[userID] = .empty
        state.currentUserID = userID
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
        return .success(user)
    }

    func logout() {
        state.currentUserID = nil
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    func deleteAccount() {
        guard let current = state.currentUserID else { return }
        state.accounts.removeAll(where: { $0.userID == current })
        removeUserAndData(userID: current)
        state.users.removeAll(where: { $0.id == current })
        state.socialGraphs.removeValue(forKey: current)
        state.currentUserID = nil
        save()
        NotificationCenter.default.post(name: .skesteAuthChanged, object: nil)
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
        NotificationCenter.default.post(name: .skesteCoachingChanged, object: nil)
    }

    private func currentGraph() -> SocialGraph {
        guard let id = state.currentUserID, let graph = state.socialGraphs[id] else { return .empty }
        return graph
    }

    private func updateGraph(_ graph: SocialGraph) {
        guard let id = state.currentUserID else { return }
        state.socialGraphs[id] = graph
    }

    private func ensureGraph(for userID: String) {
        if state.socialGraphs[userID] == nil {
            state.socialGraphs[userID] = .empty
        }
    }

    private func updatePost(_ post: Post) {
        if let index = state.posts.firstIndex(where: { $0.id == post.id }) {
            state.posts[index] = post
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Gift history behind each seeded post, so the gift log has real senders to show.
    /// Ids are deterministic so the demo store stays stable between launches.
    private static func seededGifts(for posts: [Post], users: [User]) -> [GiftRecord] {
        // The demo history is "from other riders", so the signed-in demo account
        // shouldn't show up as a sender.
        let senders = users.filter { $0.id != "u_me" }
        let pool = senders.isEmpty ? users : senders
        guard !pool.isEmpty else { return [] }
        let giftIDs = Gift.catalog.map(\.id)
        var records: [GiftRecord] = []
        for (postIndex, post) in posts.enumerated() where post.giftCount > 0 {
            for offset in 0..<post.giftCount {
                var senderIndex = (postIndex + offset * 3 + 1) % pool.count
                if pool[senderIndex].id == post.authorID {
                    senderIndex = (senderIndex + 1) % pool.count
                }
                records.append(GiftRecord(
                    id: "gift_\(post.id)_\(offset)",
                    postID: post.id,
                    senderID: pool[senderIndex].id,
                    giftID: giftIDs[(postIndex + offset) % giftIDs.count],
                    createdAt: post.createdAt.addingTimeInterval(Double(offset + 1) * 900)
                ))
            }
        }
        return records
    }

    private static let demoCountsMigrationKey = "skeste.demoCounts.v2"
    private static let coachingSeedKey = "skeste.coaching.seeded.v1"

    /// Keeps persisted demo accounts and posts aligned with the current seed,
    /// so existing installs pick up the rebalanced audience and view counts.
    private static func applyDemoCounts(to state: inout AppState) {
        let seed = seedState()
        for seedUser in seed.users where seedUser.id != "u_me" {
            guard let index = state.users.firstIndex(where: { $0.id == seedUser.id }) else { continue }
            state.users[index].baseFollowers = seedUser.baseFollowers
            state.users[index].baseFollowing = seedUser.baseFollowing
        }
        for seedPost in seed.posts {
            guard let index = state.posts.firstIndex(where: { $0.id == seedPost.id }) else { continue }
            state.posts[index].viewCount = seedPost.viewCount
        }
    }

    private static func seedState() -> AppState {
        let now = Date()
        let users: [User] = [
            User(id: "u_me", username: "test", displayName: "Alex Storm", avatarAsset: "avatar_me", avatarFileName: nil, bio: "First chairs, last light. Filming the quiet parts.", traits: ["Freeride", "Film", "Alpine"], homeResort: "Chamonix, FR", baseFollowers: 0, baseFollowing: 0, isVerified: false),
            User(id: "u_luna", username: "lunafox", displayName: "Luna Fox", avatarAsset: "avatar_luna", avatarFileName: nil, bio: "Freeride chaser. Chasing light on the north face.", traits: ["Freeride", "Alpine", "Film"], homeResort: "Chamonix, FR", baseFollowers: 2_480, baseFollowing: 186, isVerified: true),
            User(id: "u_kai", username: "kaimercer", displayName: "Kai Mercer", avatarAsset: "avatar_kai", avatarFileName: nil, bio: "Snowboarder. Storm chaser. Bad at parking.", traits: ["Snowboard", "Park", "Storm Days"], homeResort: "Whistler, CA", baseFollowers: 1_930, baseFollowing: 142, isVerified: true),
            User(id: "u_sofia", username: "sofiaberg", displayName: "Sofia Berg", avatarAsset: "avatar_sofia", avatarFileName: nil, bio: "Ski mountaineer. Coffee first, rope second.", traits: ["Ski Tour", "Summits", "Coffee"], homeResort: "Åre, SE", baseFollowers: 1_480, baseFollowing: 231, isVerified: true),
            User(id: "u_noah", username: "noahhale", displayName: "Noah Hale", avatarAsset: "avatar_noah", avatarFileName: nil, bio: "Lines over likes. Splitboard in the backcountry.", traits: ["Big Mountain", "Splitboard", "Tetons"], homeResort: "Jackson Hole, US", baseFollowers: 3_260, baseFollowing: 274, isVerified: true),
            User(id: "u_ava", username: "avalind", displayName: "Ava Lindqvist", avatarAsset: "avatar_ava", avatarFileName: nil, bio: "Sunrise laps and aprés all day.", traits: ["Alpine", "Aprés", "Sunrise"], homeResort: "St. Anton, AT", baseFollowers: 940, baseFollowing: 318, isVerified: false),
            User(id: "u_theo", username: "theorossi", displayName: "Theo Rossi", avatarAsset: "avatar_theo", avatarFileName: nil, bio: "Two planks, one love. Slightly obsessed with ridgelines.", traits: ["All Mountain", "Film", "Ridge Life"], homeResort: "Cortina, IT", baseFollowers: 1_120, baseFollowing: 97, isVerified: false),
            User(id: "u_ivy", username: "ivynovak", displayName: "Ivy Novak", avatarAsset: "avatar_ivy", avatarFileName: nil, bio: "Backcountry nurse. Powder hoarder. Safety first, always.", traits: ["Tour", "Safety", "Powder"], homeResort: "Revelstoke, CA", baseFollowers: 1_760, baseFollowing: 158, isVerified: true),
            User(id: "u_emma", username: "emmalaurent", displayName: "Emma Laurent", avatarAsset: "avatar_emma", avatarFileName: nil, bio: "Learning to fly, one cliff at a time.", traits: ["Freestyle", "Park", "La Clusaz"], homeResort: "La Clusaz, FR", baseFollowers: 680, baseFollowing: 204, isVerified: false)
        ]

        let posts: [Post] = [
            Post(id: "p1", authorID: "u_luna", kind: .reel, caption: "When the storm clears, the whole mountain holds its breath. Three winters of staring at this face, forty seconds of actually skiing it.", tags: ["Freeride", "FirstLight", "Chamonix"], media: [MediaItem(id: "m1", kind: .video, assetName: "video_luna_line")], createdAt: now.addingTimeInterval(-4 * 3600), location: "Aiguille du Midi", likeCount: 2_841, giftCount: 12, viewCount: 9_800),
            Post(id: "p2", authorID: "u_kai", kind: .reel, caption: "No filter. Just 40 cm of cold smoke and a landing I refuse to describe.", tags: ["Snowboard", "PowderDay", "Whistler"], media: [MediaItem(id: "m2", kind: .video, assetName: "video_kai_storm")], createdAt: now.addingTimeInterval(-7 * 3600), location: "Whistler Blackcomb", likeCount: 3_910, giftCount: 8, viewCount: 12_600),
            Post(id: "p3", authorID: "u_sofia", kind: .reel, caption: "Sunrise on the Haute Route. Ten minutes of gold before the wind came back.", tags: ["SkiTour", "Alps", "Sunrise"], media: [MediaItem(id: "m3", kind: .video, assetName: "video_sofia_sunrise")], createdAt: now.addingTimeInterval(-10 * 3600), location: "Haute Route", likeCount: 1_720, giftCount: 6, viewCount: 5_400),
            Post(id: "p4", authorID: "u_ava", kind: .reel, caption: "Last run, first stars. The mountain always gets the final word.", tags: ["NightSki", "StAnton", "AfterDark"], media: [MediaItem(id: "m4", kind: .video, assetName: "video_ava_night")], createdAt: now.addingTimeInterval(-13 * 3600), location: "St. Anton", likeCount: 1_094, giftCount: 3, viewCount: 4_100),
            Post(id: "p5", authorID: "u_noah", kind: .note, caption: "Three days, one tent, zero regrets. The Tetons never make it easy. That is the point.", tags: ["SkiTour", "Tetons", "Backcountry"], media: [MediaItem(id: "m5a", kind: .image, assetName: "img_noah_01"), MediaItem(id: "m5b", kind: .image, assetName: "img_noah_02"), MediaItem(id: "m5c", kind: .image, assetName: "img_noah_03")], createdAt: now.addingTimeInterval(-16 * 3600), location: "Grand Teton", likeCount: 932, giftCount: 2, viewCount: 3_400),
            Post(id: "p6", authorID: "u_ivy", kind: .note, caption: "Snowpack class of the day: test your slope, not your ego. Dig a pit. Talk to your partners. Come home.", tags: ["Backcountry", "Safety", "KnowBeforeYouGo"], media: [MediaItem(id: "m6", kind: .image, assetName: "img_ivy_01")], createdAt: now.addingTimeInterval(-19 * 3600), location: "Revelstoke", likeCount: 1_402, giftCount: 9, viewCount: 4_800),
            Post(id: "p7", authorID: "u_theo", kind: .note, caption: "Hot take: the best run of the day is the one you almost skipped. Meet you at the ridge at 7. Bring coffee.", tags: ["MountainLife", "Ridge", "FirstLight"], media: [], createdAt: now.addingTimeInterval(-22 * 3600), location: "Cortina", likeCount: 684, giftCount: 1, viewCount: 2_300),
            Post(id: "p8", authorID: "u_emma", kind: .note, caption: "Landed it fourth try. Elbow is fine. Ego is recovering.", tags: ["Park", "Freestyle", "Progress"], media: [MediaItem(id: "m8a", kind: .image, assetName: "img_emma_01"), MediaItem(id: "m8b", kind: .image, assetName: "img_emma_02")], createdAt: now.addingTimeInterval(-26 * 3600), location: "La Clusaz", likeCount: 1_210, giftCount: 4, viewCount: 4_500),
            Post(id: "p9", authorID: "u_luna", kind: .note, caption: "Morning ritual: skins on before the lifts wake up. The quiet part is the best part.", tags: ["SkiTour", "Morning", "Silence"], media: [MediaItem(id: "m9a", kind: .image, assetName: "img_luna_01"), MediaItem(id: "m9b", kind: .image, assetName: "img_luna_02")], createdAt: now.addingTimeInterval(-30 * 3600), location: "Chamonix", likeCount: 777, giftCount: 2, viewCount: 2_700),
            Post(id: "p10", authorID: "u_kai", kind: .note, caption: "Board waxed. Forecast refreshed. Alarm set for 5:40. See you up there.", tags: ["StormDay", "Whistler", "Ritual"], media: [], createdAt: now.addingTimeInterval(-34 * 3600), location: "Whistler", likeCount: 401, giftCount: 0, viewCount: 1_400),
            Post(id: "p11", authorID: "u_ava", kind: .reel, caption: "Aperol, altitude, and a very questionable dance floor. The perfect storm.", tags: ["Apres", "StAnton", "AfterHours"], media: [MediaItem(id: "m11", kind: .video, assetName: "video_ava_apres")], createdAt: now.addingTimeInterval(-38 * 3600), location: "St. Anton", likeCount: 2_103, giftCount: 15, viewCount: 7_200),
            Post(id: "p12", authorID: "u_sofia", kind: .note, caption: "A rope, a friend, and a very good line. That is the whole story.", tags: ["SkiTour", "Partnership", "Alps"], media: [MediaItem(id: "m12", kind: .image, assetName: "img_sofia_01")], createdAt: now.addingTimeInterval(-42 * 3600), location: "Chamonix", likeCount: 856, giftCount: 3, viewCount: 2_900)
        ]

        let commentPool = [
            "That line is unreal. The light alone is worth the skin.",
            "The control at that speed. Respect.",
            "Adding this to the list and pretending I have the legs for it.",
            "This is the kind of edit that makes me check flights.",
            "The sound of edges on that snow. Pure therapy.",
            "Not me watching this on repeat at work.",
            "That entrance had no business being that clean.",
            "The mountain said yes today.",
            "Please tell me there is a longer cut.",
            "This is why we wake up before the sun.",
            "The camera work is as wild as the line.",
            "Saving this for the next storm day.",
            "Total commitment. Nothing but respect.",
            "The Tetons always humble you. Beautiful capture.",
            "That last turn belongs in a film.",
            "My legs are tired just watching.",
            "The kind of day that makes the whole season.",
            "More of this energy, please.",
            "Absolute cinema.",
            "The forecast looked good. You made it look better."
        ]
        var comments: [Comment] = []
        let commenterIDs = ["u_luna", "u_kai", "u_sofia", "u_noah", "u_ava", "u_theo", "u_ivy", "u_emma"]
        for (postIndex, post) in posts.enumerated() {
            let count = 3 + (postIndex % 3)
            for offset in 0..<count {
                var authorID = commenterIDs[(postIndex + offset) % commenterIDs.count]
                if authorID == post.authorID {
                    authorID = commenterIDs[(postIndex + offset + 1) % commenterIDs.count]
                }
                let text = commentPool[(postIndex * 3 + offset) % commentPool.count]
                comments.append(Comment(id: "cmt_\(post.id)_\(offset)", postID: post.id, authorID: authorID, text: text, createdAt: post.createdAt.addingTimeInterval(Double(offset + 1) * 780)))
            }
        }

        let graphs: [String: SocialGraph] = [
            "u_me": SocialGraph(
                followingIDs: ["u_luna", "u_kai", "u_sofia", "u_noah", "u_theo"],
                followerIDs: ["u_luna", "u_kai", "u_sofia", "u_noah", "u_ava"],
                likedPostIDs: ["p3", "p5"],
                blockedUserIDs: []
            )
        ]

        return AppState(
            users: users,
            posts: posts,
            comments: comments,
            bookings: seededBookings(),
            coachProfiles: seededCoachProfiles(),
            accounts: [LocalAccount(id: "acct_test", username: "test", passwordHash: hash("123456"), userID: "u_me", provider: .local, appleID: nil)],
            socialGraphs: graphs,
            currentUserID: nil,
            runs: [],
            gifts: seededGifts(for: posts, users: users)
        )
    }

    /// The riders who teach. Each profile points at a seeded rider so the coaching
    /// screen can reuse the same avatars, profiles and follow graph as the feed.
    static func seededCoachProfiles() -> [CoachProfile] {
        [
            CoachProfile(
                id: "u_luna",
                headline: "Freeride technique for steep, committing lines.",
                specialties: ["Steep skiing", "Edge control", "Line choice"],
                certifications: ["CSIA Level 3", "AIARE 2"],
                languages: ["English", "French"],
                yearsExperience: 9,
                rating: 4.9,
                sessionCount: 214,
                responseTime: "Usually replies in minutes",
                availability: "Mornings · Chamonix & remote"
            ),
            CoachProfile(
                id: "u_kai",
                headline: "Park progression and storm-day confidence.",
                specialties: ["Park", "Freestyle", "Air awareness"],
                certifications: ["CASI Level 3", "Park Coach"],
                languages: ["English"],
                yearsExperience: 7,
                rating: 4.8,
                sessionCount: 168,
                responseTime: "Usually replies in under an hour",
                availability: "Afternoons · Whistler & remote"
            ),
            CoachProfile(
                id: "u_sofia",
                headline: "Ski touring, rope work and alpine decision making.",
                specialties: ["Ski touring", "Mountaineering", "Avalanche safety"],
                certifications: ["IFMGA Guide", "AIARE Pro"],
                languages: ["English", "Swedish"],
                yearsExperience: 12,
                rating: 5.0,
                sessionCount: 132,
                responseTime: "Usually replies same day",
                availability: "Weekends · Åre & remote"
            ),
            CoachProfile(
                id: "u_noah",
                headline: "Big-mountain reads and backcountry line planning.",
                specialties: ["Big mountain", "Splitboard", "Backcountry"],
                certifications: ["AMGA Apprentice", "AIARE 2"],
                languages: ["English"],
                yearsExperience: 11,
                rating: 4.9,
                sessionCount: 96,
                responseTime: "Usually replies same day",
                availability: "Storm windows · Jackson Hole & remote"
            ),
            CoachProfile(
                id: "u_ivy",
                headline: "Avalanche rescue, snowpack literacy and safe travel.",
                specialties: ["Avalanche safety", "Rescue", "Snowpack"],
                certifications: ["Avalanche Canada", "Wilderness RN"],
                languages: ["English"],
                yearsExperience: 8,
                rating: 4.9,
                sessionCount: 148,
                responseTime: "Usually replies in minutes",
                availability: "Daily · Revelstoke & remote"
            ),
            CoachProfile(
                id: "u_theo",
                headline: "Carving, grip and the small drills that change everything.",
                specialties: ["Carving", "Moguls", "Drills"],
                certifications: ["CSIA Level 2", "Race Coach"],
                languages: ["English", "Italian"],
                yearsExperience: 6,
                rating: 4.7,
                sessionCount: 203,
                responseTime: "Usually replies in under an hour",
                availability: "Mornings · Cortina & remote"
            )
        ]
    }

    /// One already-confirmed session for the demo account so the call entry is visible
    /// right after signing in; every new request starts from the booking form.
    static func seededBookings() -> [CoachBooking] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduled = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        return [
            CoachBooking(
                id: "booking_luna_seed",
                learnerID: "u_me",
                coachUserID: "u_luna",
                topic: .technique,
                details: "I keep losing grip on steep, icy entries. I'd like a few drills I can repeat solo, and a plan for the next storm cycle.",
                scheduledAt: scheduled,
                durationMinutes: 45,
                status: .accepted,
                createdAt: Date().addingTimeInterval(-2 * 3600),
                respondedAt: Date().addingTimeInterval(-90 * 60),
                lastCallAt: nil,
                lastCallDuration: nil,
                lastCallBy: nil
            )
        ]
    }
}

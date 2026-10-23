import Foundation

enum PostKind: String, Codable, CaseIterable {
    case reel
    case note

    var label: String {
        switch self {
        case .reel: return "Line Drop"
        case .note: return "Field Note"
        }
    }
}

enum MediaKind: String, Codable {
    case image
    case video
}

struct MediaItem: Codable, Identifiable, Hashable {
    var id: String
    var kind: MediaKind
    var assetName: String
    var fileName: String?

    init(id: String = UUID().uuidString, kind: MediaKind, assetName: String, fileName: String? = nil) {
        self.id = id
        self.kind = kind
        self.assetName = assetName
        self.fileName = fileName
    }
}

struct User: Codable, Identifiable, Hashable {
    var id: String
    var username: String
    var displayName: String
    var avatarAsset: String
    var avatarFileName: String?
    var bio: String
    var traits: [String]
    var homeResort: String
    var baseFollowers: Int
    var baseFollowing: Int
    var isVerified: Bool

    var handle: String { "@\(username)" }
    var traitLine: String { traits.joined(separator: "  ·  ") }
}

struct Post: Codable, Identifiable, Hashable {
    var id: String
    var authorID: String
    var kind: PostKind
    var caption: String
    var tags: [String]
    var media: [MediaItem]
    var createdAt: Date
    var location: String
    var likeCount: Int
    var giftCount: Int
    var viewCount: Int
}

struct Comment: Codable, Identifiable, Hashable {
    var id: String
    var postID: String
    var authorID: String
    var text: String
    var createdAt: Date
}

struct GiftRecord: Codable, Identifiable, Hashable {
    var id: String
    var postID: String
    var senderID: String
    var giftID: String
    var createdAt: Date

    init(id: String = "gift_\(UUID().uuidString)", postID: String, senderID: String, giftID: String, createdAt: Date = Date()) {
        self.id = id
        self.postID = postID
        self.senderID = senderID
        self.giftID = giftID
        self.createdAt = createdAt
    }
}

enum CoachingTopic: String, Codable, CaseIterable, Hashable {
    case technique
    case gear
    case terrain
    case confidence
    case other

    var title: String {
        switch self {
        case .technique: return "Technique"
        case .gear: return "Gear"
        case .terrain: return "Terrain & safety"
        case .confidence: return "Confidence"
        case .other: return "Something else"
        }
    }

    var symbol: String {
        switch self {
        case .technique: return "figure.skiing.downhill"
        case .gear: return "wrench.and.screwdriver.fill"
        case .terrain: return "mountain.2.fill"
        case .confidence: return "brain.head.profile"
        case .other: return "ellipsis.bubble.fill"
        }
    }
}

enum BookingStatus: String, Codable, Hashable {
    case pending
    case accepted
    case declined
    case cancelled
    case completed

    var title: String {
        switch self {
        case .pending: return "WAITING FOR COACH"
        case .accepted: return "SESSION CONFIRMED"
        case .declined: return "DECLINED"
        case .cancelled: return "CANCELLED"
        case .completed: return "COMPLETED"
        }
    }

    var isOpen: Bool {
        self == .pending || self == .accepted
    }
}

struct CoachProfile: Codable, Identifiable, Hashable {
    /// The coach's rider id. The profile is keyed by the same id as `User`.
    var id: String
    var headline: String
    var specialties: [String]
    var certifications: [String]
    var languages: [String]
    var yearsExperience: Int
    var rating: Double
    var sessionCount: Int
    var responseTime: String
    var availability: String

    var userID: String { id }
}

struct CoachBooking: Codable, Identifiable, Hashable {
    var id: String
    var learnerID: String
    var coachUserID: String
    var topic: CoachingTopic
    var details: String
    var scheduledAt: Date
    var durationMinutes: Int
    var status: BookingStatus
    var createdAt: Date
    var respondedAt: Date?
    var lastCallAt: Date?
    var lastCallDuration: TimeInterval?
    var lastCallBy: String?

    var isOpen: Bool { status.isOpen }
}

struct SocialGraph: Codable {
    var followingIDs: [String]
    var followerIDs: [String]
    var likedPostIDs: [String]
    var blockedUserIDs: [String]

    static let empty = SocialGraph(followingIDs: [], followerIDs: [], likedPostIDs: [], blockedUserIDs: [])
}

enum AccountProvider: String, Codable {
    case local
    case apple
}

struct LocalAccount: Codable, Identifiable {
    var id: String
    var username: String
    var passwordHash: String
    var userID: String
    var provider: AccountProvider
    var appleID: String?
}

struct RunRecord: Codable, Identifiable {
    var id: String
    var startedAt: Date
    var duration: TimeInterval
    var distanceMeters: Double
    var verticalMeters: Double
    var topSpeedKPH: Double
    var resort: String
}

struct AppState: Codable {
    var users: [User]
    var posts: [Post]
    var comments: [Comment]
    var bookings: [CoachBooking]
    var coachProfiles: [CoachProfile]
    var accounts: [LocalAccount]
    var socialGraphs: [String: SocialGraph]
    var currentUserID: String?
    var runs: [RunRecord]
    var gifts: [GiftRecord]

    enum CodingKeys: String, CodingKey {
        case users, posts, comments, bookings, coachProfiles, accounts, socialGraphs, currentUserID, runs, gifts
    }
}

extension AppState {
    /// Saved states written before gifts, bookings or coaching profiles existed have no keys
    /// for them, so decode those leniently instead of throwing away the whole store.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        users = try container.decode([User].self, forKey: .users)
        posts = try container.decode([Post].self, forKey: .posts)
        comments = try container.decode([Comment].self, forKey: .comments)
        bookings = try container.decodeIfPresent([CoachBooking].self, forKey: .bookings) ?? []
        coachProfiles = try container.decodeIfPresent([CoachProfile].self, forKey: .coachProfiles) ?? []
        accounts = try container.decode([LocalAccount].self, forKey: .accounts)
        socialGraphs = try container.decode([String: SocialGraph].self, forKey: .socialGraphs)
        currentUserID = try container.decodeIfPresent(String.self, forKey: .currentUserID)
        runs = try container.decodeIfPresent([RunRecord].self, forKey: .runs) ?? []
        gifts = try container.decodeIfPresent([GiftRecord].self, forKey: .gifts) ?? []
    }
}

struct Gift: Identifiable, Hashable {
    let id: String
    let name: String
    let priceCents: Int
    let imageName: String
    let symbol: String
    let blurb: String
    let colors: [String]
    let productID: String
    let tagline: String

    var priceLabel: String { String(format: "$%.2f", Double(priceCents) / 100) }

    static let catalog: [Gift] = [
        Gift(id: "g1", name: "First Tracks", priceCents: 99, imageName: "gift_01_first_tracks", symbol: "sunrise.fill", blurb: "A fresh line at first light.", colors: ["FF6A3D", "E3A45C"], productID: "gyhanqbvrlzuybir", tagline: "For the early riser"),
        Gift(id: "g2", name: "Cocoa Stop", priceCents: 199, imageName: "gift_02_cocoa", symbol: "cup.and.saucer.fill", blurb: "A warm cup at the mid-mountain hut.", colors: ["D0A07A", "E3A45C"], productID: "odeutdnmnqisqndw", tagline: "Warm hands, cold snow"),
        Gift(id: "g3", name: "Gondola Ride", priceCents: 299, imageName: "gift_03_gondola", symbol: "tram.fill", blurb: "Skip the line and ride to the top.", colors: ["A7C1CA", "6E8A94"], productID: "com.skte.Skeste.gift.03", tagline: "One ride higher"),
        Gift(id: "g4", name: "Powder Cloud", priceCents: 499, imageName: "gift_04_powder", symbol: "cloud.snow.fill", blurb: "A full face-shot of cold smoke.", colors: ["D8E4E7", "A7C1CA"], productID: "ksukbigoclfuqnit", tagline: "Send the storm"),
        Gift(id: "g5", name: "Aurora Glow", priceCents: 999, imageName: "gift_05_aurora", symbol: "sparkles", blurb: "Light up the night ride.", colors: ["D6DE6A", "93B39E"], productID: "rsdzrirsexedwehw", tagline: "Make the sky move"),
        Gift(id: "g6", name: "Peak Crown", priceCents: 1999, imageName: "gift_06_crown", symbol: "crown.fill", blurb: "Crown the high point of the edit.", colors: ["E3A45C", "C08A4A"], productID: "awltfrzboukvvkut", tagline: "Royalty at altitude"),
        Gift(id: "g7", name: "Alpine Summit", priceCents: 4999, imageName: "gift_07_summit", symbol: "mountain.2.fill", blurb: "The summit, delivered.", colors: ["FF4D1C", "E3A45C"], productID: "ylobmffhfttiusfz", tagline: "A line worth the climb"),
        Gift(id: "g8", name: "Ski Legend", priceCents: 9999, imageName: "gift_08_legend", symbol: "star.circle.fill", blurb: "Leave a mark on the mountain.", colors: ["F2EFE8", "FF4D1C"], productID: "pnlcjpgkypyexaqk", tagline: "The ultimate nod")
    ]

    static func gift(withID id: String) -> Gift? {
        catalog.first(where: { $0.id == id })
    }
}

extension Date {
    var skesteRelative: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        if interval < 3600 {
            let minutes = max(1, Int(interval / 60))
            return "\(minutes)m"
        }
        if interval < 86_400 {
            let hours = max(1, Int(interval / 3600))
            return "\(hours)h"
        }
        if interval < 604_800 {
            let days = max(1, Int(interval / 86_400))
            return "\(days)d"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// "Today · 9:00 AM", "Tomorrow · 9:00 AM", "Fri, Oct 30 · 9:00 AM".
    var bookingStamp: String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(self) {
            day = "Today"
        } else if calendar.isDateInTomorrow(self) {
            day = "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEE, MMM d"
            day = formatter.string(from: self)
        }
        let time = DateFormatter()
        time.locale = Locale(identifier: "en_US")
        time.dateFormat = "h:mm a"
        return "\(day) · \(time.string(from: self))"
    }
}

extension Int {
    var compactCount: String {
        if self >= 1_000_000 {
            let value = Double(self) / 1_000_000
            return String(format: value >= 10 ? "%.0fM" : "%.1fM", value)
        }
        if self >= 1_000 {
            let value = Double(self) / 1_000
            return String(format: value >= 10 ? "%.0fK" : "%.1fK", value)
        }
        return "\(self)"
    }
}

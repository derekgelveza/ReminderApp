import Foundation

struct RecommendedVideo: Identifiable, Hashable {
    let id = UUID()
    let platform: VideoPlatform
    let title: String
    let url: URL
}

enum VideoPlatform: String, Hashable {
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"
}

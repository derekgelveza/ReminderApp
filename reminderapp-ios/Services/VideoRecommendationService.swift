import Foundation

protocol VideoRecommendationService {
    func recommendations(for task: TaskItem) async throws -> [RecommendedVideo]
}

struct MockVideoRecommendationService: VideoRecommendationService {
    func recommendations(for task: TaskItem) async throws -> [RecommendedVideo] {
        let query = task.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? task.title
        return [
            RecommendedVideo(platform: .youtube, title: "YouTube tutorials for \(task.title)", url: URL(string: "https://www.youtube.com/results?search_query=\(query)")!),
            RecommendedVideo(platform: .tiktok, title: "TikTok search for \(task.title)", url: URL(string: "https://www.tiktok.com/search?q=\(query)")!),
            RecommendedVideo(platform: .instagram, title: "Instagram search for \(task.title)", url: URL(string: "https://www.instagram.com/explore/search/keyword/?q=\(query)")!)
        ]
    }
}

import Foundation
import Observation

@Observable
final class TaskDetailViewModel {
    var guide: HowToGuide?
    var videos: [RecommendedVideo] = []
    var isLoading = false
    var errorMessage: String?

    private let aiService: AIStepsService
    private let videoService: VideoRecommendationService

    init(aiService: AIStepsService = MockAIStepsService(), videoService: VideoRecommendationService = MockVideoRecommendationService()) {
        self.aiService = aiService
        self.videoService = videoService
    }

    func load(for task: TaskItem) async {
        isLoading = true
        errorMessage = nil
        do {
            async let guideTask = aiService.generateGuide(for: task)
            async let videoTask = videoService.recommendations(for: task)
            guide = try await guideTask
            videos = try await videoTask
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

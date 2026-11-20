import Foundation
import Observation

@Observable
final class TaskDetailViewModel {
    var guide: HowToGuide?
    var videos: [RecommendedVideo] = []
    var smartPlan: SmartReminderPlan?
    var isLoading = false
    var errorMessage: String?
    private let aiService: AIStepsService
    private let videoService: VideoRecommendationService
    private let smartReminderService: SmartReminderService

    init(aiService: AIStepsService = MockAIStepsService(), videoService: VideoRecommendationService = MockVideoRecommendationService(), smartReminderService: SmartReminderService = MockSmartReminderService()) { self.aiService = aiService; self.videoService = videoService; self.smartReminderService = smartReminderService }

    func load(for task: TaskItem) async {
        isLoading = true; errorMessage = nil
        do {
            let snapshot = TaskSnapshot(task: task)
            async let guideTask = aiService.generateGuide(for: snapshot)
            async let videoTask = videoService.recommendations(for: snapshot)
            async let planTask = smartReminderService.makePlan(for: snapshot)
            guide = try await guideTask
            videos = try await videoTask
            smartPlan = try await planTask
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}

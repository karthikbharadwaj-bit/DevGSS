global without sharing class CommunityTrendingsUpdateScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        TopicRatingController.updateCommunityTrendingTopics();
    }
}
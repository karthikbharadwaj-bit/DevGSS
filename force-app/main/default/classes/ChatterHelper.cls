public class ChatterHelper {
    private static final String CHATTER_MESSAGE = ' Could you please take a look?\n {0}\n Details: {1}';
    @TestVisible
    private static ConnectApi.FeedItemInput lastFeedItemInput;
    public class FeedItemInputBuilder {
        private ConnectApi.FeedItemInput feedItemInput;

        public FeedItemInputBuilder() {
            feedItemInput = new ConnectApi.FeedItemInput();
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.body = new ConnectApi.MessageBodyInput();
            feedItemInput.body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        }

        public FeedItemInputBuilder withMessage(String message) {
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = message;
            feedItemInput.body.messageSegments.add(textSegmentInput);
            return this;
        }

        public FeedItemInputBuilder withUserMention(Id userId) {
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = userId;
            if (feedItemInput.body.messageSegments.isEmpty()) {
                feedItemInput.body.messageSegments.add(mentionSegmentInput);
            } else {
                feedItemInput.body.messageSegments.add(0, mentionSegmentInput);
            }
            return this;
        }

        public FeedItemInputBuilder withSObjectMention(Id sObjectId) {
            ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputCase = new ConnectApi.EntityLinkSegmentInput();
            entityLinkSegmentInputCase.entityId = sObjectId;
            feedItemInput.body.messageSegments.add(entityLinkSegmentInputCase);
            return this;
        }

        public FeedItemInputBuilder withFeedSObjectId(Id sObjectId) {
            feedItemInput.subjectId = sObjectId;
            return this;
        }

        public void build() {
            if (!Test.isRunningTest()) {
                ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            } else {
                lastFeedItemInput = feedItemInput;
            }
        }
    }

    public static void createChatterPost(
        Id userIdToMention,
        Id sObjectIdWithFeed,
        String text,
        String details
    ) {
        createChatterPost(userIdToMention, sObjectIdWithFeed, createChatterMessage(text, details));
    }

    public static void createChatterPost(Id userIdToMention, Id sObjectIdWithFeed, String text) {
        new FeedItemInputBuilder()
            .withMessage(text)
            .withUserMention(userIdToMention)
            .withFeedSObjectId(sObjectIdWithFeed)
            .build();
    }

    public static void createChatterPost(
        Id userIdToMention,
        Id sObjectIdWithFeed,
        Id sObjectIdToMention,
        String text,
        String details
    ) {
        createChatterPost(userIdToMention, sObjectIdWithFeed, sObjectIdToMention, createChatterMessage(text, details));
    }

    public static void createChatterPost(
        Id userIdToMention,
        Id sObjectIdWithFeed,
        Id sObjectIdToMention,
        String text
    ) {
        new FeedItemInputBuilder()
            .withMessage(text)
            .withUserMention(userIdToMention)
            .withSObjectMention(sObjectIdToMention)
            .withFeedSObjectId(sObjectIdWithFeed)
            .build();
    }

    @TestVisible
    private static String createChatterMessage(String message, String messageDetails) {
        return String.format(CHATTER_MESSAGE, new List<String>{message, messageDetails});
    }
}
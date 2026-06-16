@isTest
private class Test_ChatterHelper {
    static final String MESSAGE = 'Test message';
    static final String DETAILS = 'Test details';

    @isTest
    static void testWithMessage() {
        Test.startTest();
            new ChatterHelper.FeedItemInputBuilder()
                .withMessage(MESSAGE)
                .build();
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(1, ChatterHelper.lastFeedItemInput.body.messageSegments.size(), 'MessageSegments should contain 1 segment');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0] instanceof ConnectApi.TextSegmentInput, 'Segment should be a TextSegmentInput');
        Assert.areEqual(MESSAGE, ((ConnectApi.TextSegmentInput) ChatterHelper.lastFeedItemInput.body.messageSegments[0]).text, 'Text should match the provided message');
    }

    @isTest
    static void testWithUserMention() {
        Id userId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();

        Test.startTest();
            new ChatterHelper.FeedItemInputBuilder()
                .withUserMention(userId)
                .build();
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(1, ChatterHelper.lastFeedItemInput.body.messageSegments.size(), 'MessageSegments should contain 1 segment');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0] instanceof ConnectApi.MentionSegmentInput, 'Segment should be a MentionSegmentInput');
        Assert.areEqual(userId, ((ConnectApi.MentionSegmentInput) ChatterHelper.lastFeedItemInput.body.messageSegments[0]).id, 'Id should match the provided userId');
    }

    @isTest
    static void testWithSObjectMention() {
        Id sObjectId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            new ChatterHelper.FeedItemInputBuilder()
                .withSObjectMention(sObjectId)
                .build();
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(1, ChatterHelper.lastFeedItemInput.body.messageSegments.size(), 'MessageSegments should contain 1 segment');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0] instanceof ConnectApi.EntityLinkSegmentInput, 'Segment should be an EntityLinkSegmentInput');
        Assert.areEqual(sObjectId, ((ConnectApi.EntityLinkSegmentInput)ChatterHelper.lastFeedItemInput.body.messageSegments[0]).entityId, 'EntityId should match the provided sObjectId');
    }

    @isTest
    static void testWithFeedSObjectId() {
        Id sObjectId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue(); 

        Test.startTest();
            new ChatterHelper.FeedItemInputBuilder()
                .withFeedSObjectId(sObjectId)
                .build();
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(sObjectId, ChatterHelper.lastFeedItemInput.subjectId, 'SubjectId should match the provided sObjectId');
    }

    @isTest
    static void testCreateChatterPostWithUserMention() {
        Id userId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();
        Id sObjectId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();

        Test.startTest();
            ChatterHelper.createChatterPost(userId, sObjectId, MESSAGE, DETAILS);
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(ConnectApi.FeedElementType.FeedItem, ChatterHelper.lastFeedItemInput.feedElementType, 'FeedElementType should be FeedItem');
        Assert.areEqual(sObjectId, ChatterHelper.lastFeedItemInput.subjectId, 'SubjectId should match the provided sObjectId');
        Assert.areEqual(2, ChatterHelper.lastFeedItemInput.body.messageSegments.size(), 'MessageSegments should contain 2 segments');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0] instanceof ConnectApi.MentionSegmentInput, 'First segment should be a MentionSegmentInput');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[1] instanceof ConnectApi.TextSegmentInput, 'Second segment should be a TextSegmentInput');
    }

    @isTest
    static void testCreateChatterPostWithSObjectMention() {
        Id userId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();
        Id sObjectId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        Id sObjectIdToMention = (Id) new ValueProvider.DummyIdProvider(Opportunity.sObjectType).getValue();

        Test.startTest();
            ChatterHelper.createChatterPost(userId, sObjectId, sObjectIdToMention, MESSAGE, DETAILS);
        Test.stopTest();

        Assert.isNotNull(ChatterHelper.lastFeedItemInput, 'FeedItemInput should not be null');
        Assert.areEqual(ConnectApi.FeedElementType.FeedItem, ChatterHelper.lastFeedItemInput.feedElementType, 'FeedElementType should be FeedItem');
        Assert.areEqual(sObjectId, ChatterHelper.lastFeedItemInput.subjectId, 'SubjectId should match the provided sObjectId');
        Assert.areEqual(3, ChatterHelper.lastFeedItemInput.body.messageSegments.size(), 'MessageSegments should contain 3 segments');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[0] instanceof ConnectApi.MentionSegmentInput, 'First segment should be a MentionSegmentInput');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[1] instanceof ConnectApi.TextSegmentInput, 'Second segment should be an EntityLinkSegmentInput');
        Assert.isTrue(ChatterHelper.lastFeedItemInput.body.messageSegments[2] instanceof ConnectApi.EntityLinkSegmentInput, 'Third segment should be a TextSegmentInput');
    }

    @isTest
    static void testCreateChatterMessage() {
        Test.startTest();
            String result = ChatterHelper.createChatterMessage(MESSAGE, DETAILS);
        Test.stopTest();

        Assert.areEqual(' Could you please take a look?\n Test message\n Details: Test details', result, 'Chatter message should be formatted correctly');
    }
}
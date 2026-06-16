@isTest
public with sharing class Test_DeserializeCaseCommentBody {
    @isTest
    public static void deserializeATypicalCaseCommentBody(){
        String json = '{' +
            '\"uid\":\"525698017\",' +
            '\"email\":\"test@aquivalabstest.com\",' +
            '\"createdByUser\":\"test\",' +
            '\"createdByContact\":\"test\",' +
            '\"comment\":\"Comentario test\",' +
            '\"authorName\":\"test\"' +
        '}';

        Test.startTest();
            List<DeserializeCaseCommentBody.Response> responses = DeserializeCaseCommentBody.execute(new String[]{json});
        Test.stopTest();

        System.assertEquals(1, responses.size(), '1 JSON was sended to deserialize.');
        System.assertEquals('525698017', responses[0].uid, 'Incorrect deserialize.');
        System.assertEquals('test@aquivalabstest.com', responses[0].email, 'Incorrect deserialize.');
        System.assertEquals('test', responses[0].createdByUser, 'Incorrect deserialize.');
        System.assertEquals('test', responses[0].createdByContact, 'Incorrect deserialize.');
        System.assertEquals('Comentario test', responses[0].comment, 'Incorrect deserialize.');
        System.assertEquals('test', responses[0].authorName, 'Incorrect deserialize.');
    }
    @isTest
    public static void deserializeABadParsedCaseCommentBody(){
        String json = '{' +
            '\"uid\":\"525698017\",' +
            '\"email\":\"test@aquivalabstest.com\",' +
            '\"createdByUser\":\"test\",' +
            '\"createdByContact\":\"test\",' +
            '\"comment\":\"Comentario test\",' +
            '\"authorName\":\"test\"';

        Test.startTest();
            List<DeserializeCaseCommentBody.Response> responses = DeserializeCaseCommentBody.execute(new String[]{json});
        Test.stopTest();

        System.assertEquals(1, responses.size(), '1 JSON was sended to deserialize.');
        System.assertEquals(null, responses[0].uid, 'Incorrect deserialize.');
        System.assertEquals(null, responses[0].email, 'Incorrect deserialize.');
        System.assertEquals(null, responses[0].createdByUser, 'Incorrect deserialize.');
        System.assertEquals(null, responses[0].createdByContact, 'Incorrect deserialize.');
        System.assertEquals(json, responses[0].comment, 'Incorrect deserialize.');
        System.assertEquals(null, responses[0].authorName, 'Incorrect deserialize.');
    }

    @isTest
    public static void deserializeAPICaseCommentBody(){
        String apiComment = SCApiService.AUTHOR_NAME_KEY + 'Test name' + '\n' +
            SCApiService.COMMENT_KEY + 'Comment test' + '\n' +
            SCApiService.UID_KEY + 'Uid test' + '\n' +
            SCApiService.EMAIL_KEY + 'Email test' + '\n' +
            SCApiService.CREATED_BY_USER_KEY + 'created by user test' + '\n' +
            SCApiService.CREATED_BY_CONTACT_KEY + 'created by contact test';

        Test.startTest();
            List<DeserializeCaseCommentBody.Response> responses = DeserializeCaseCommentBody.execute(new String[]{apiComment});
        Test.stopTest();

        System.assertEquals(1, responses.size(), '1 JSON was sended to deserialize.');
        System.assertEquals('Test name', responses[0].authorName, 'Incorrect deserialize.');
        System.assertEquals('Comment test', responses[0].comment, 'Incorrect deserialize.');
        System.assertEquals('Uid test', responses[0].uid, 'Incorrect deserialize.');
        System.assertEquals('Email test', responses[0].email, 'Incorrect deserialize.');
        System.assertEquals('created by user test', responses[0].createdByUser, 'Incorrect deserialize.');
        System.assertEquals('created by contact test', responses[0].createdByContact, 'Incorrect deserialize.');
    }
}
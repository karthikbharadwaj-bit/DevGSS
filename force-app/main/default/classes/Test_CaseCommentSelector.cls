@isTest
private class Test_CaseCommentSelector {
//Case fields defined
private static final String CASE_ACCOUNT_BRAND = 'Test Brand';

//Case comment fields defined
private static final String CASE_COMMENT_BODY = 'Body';

//Assert messages defined
private static final String ASSERT_MESSAGE = 'Case comments should be selected';
private static final String ASSERT_EQUALS_MESSAGE = 'Wrong case comment selected';

    @testSetup
    private static void testData(){
        Case testCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.RecordTypeId => CaseHelper.RT_ID_PORTING_OUT,
                    Case.Status => CaseHelper.CASE_STATUS_NEW,
                    Case.Account_Brand__c => CASE_ACCOUNT_BRAND
                	}
            )
            .create()
            .getRecord();
        
        CaseComment testCaseComment = (CaseComment) new SObjectBuilder(CaseComment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
					CaseComment.ParentId => testCase.Id,
                    CaseComment.CommentBody => CASE_COMMENT_BODY,
                    CaseComment.isPublished => TRUE
                	}
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectCommentsDefault(){
		List<CaseComment> commentsDefault = (List<CaseComment>) new CaseCommentSelector(true, true)
            .selectCommentsDefault()
			.executeQuery();
        
        System.assert(commentsDefault.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectCaseCommentsByCreatedDate(){
        List<CaseComment> commentsDefault = (List<CaseComment>) new CaseCommentSelector()
            .selectCommentsDefault()
			.executeQuery();

		DateTime dateStart = DateTime.newInstance(2000, 6, 1);
        
		List<CaseComment> caseCommentsByCreatedDate = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCreatedDate(new List<Object>{new List<String>{CaseHelper.RT_NAME_PORTING_OUT},
                											  new List<Datetime>{dateStart}})
			.executeQuery();
        
        System.assert(caseCommentsByCreatedDate.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(commentsDefault[0].Id, caseCommentsByCreatedDate[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCaseCommentsByIdForAPI(){
        List<CaseComment> commentsDefault = (List<CaseComment>) new CaseCommentSelector()
            .selectCommentsDefault()
			.executeQuery();
            
		List<CaseComment> caseCommentsByIdForAPI = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByIdForAPI(new List<Object>{new List<Id>{commentsDefault[0].Id}})
			.executeQuery();

        System.assert(caseCommentsByIdForAPI.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(commentsDefault[0].Id, caseCommentsByIdForAPI[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectCaseCommentsByCaseId(){
        List<Case> cases = (List<Case>) new CaseSelector()
            .selectCases()
			.executeQuery();

        List<CaseComment> commentsDefault = (List<CaseComment>) new CaseCommentSelector()
            .selectCommentsDefault()
			.executeQuery();
        
		List<CaseComment> caseCommentsByCaseId = (List<CaseComment>) new CaseCommentSelector()
            .selectCaseCommentsByCaseId(new List<Object>{new List<Id>{cases[0].Id}})
			.executeQuery();

        System.assert(caseCommentsByCaseId.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(commentsDefault[0].Id, caseCommentsByCaseId[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
}
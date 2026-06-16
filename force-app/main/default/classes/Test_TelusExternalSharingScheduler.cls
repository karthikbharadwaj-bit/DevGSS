/**
 * @author Dmitry Malenko
 * @date 7/18/2019
 * @description Unit tests for TelusExternalSharingScheduler.cls
 */
@isTest 
private class Test_TelusExternalSharingScheduler {

	private static Case createCase () {
		Account newAcc = (Account) new SObjectBuilder(Account.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Account.Name => 'Test account'
				}
			)
			.create()
			.getRecord();

		Case newCase = (Case) new SObjectBuilder(Case.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Case.Status => 'New',
					Case.RecordTypeId => CaseHelper.RT_INFO_BY_NAME.get('Porting - In (TELUS)').getRecordTypeId(),
					Case.Type => 'Other',
					Case.AccountId => newAcc.Id
                }
            )
            .create()
            .getRecord();	
		return newCase;
	}

	private static List<CaseComment> createCaseComments (Integer numOfComments) {
		Case newCase = createCase();
		List<CaseComment> newCaseCommentsList = new List<CaseComment>();
		for (Integer i = 0; i < numOfComments; i ++) {
			CaseComment newCaseComment = new CaseComment (
				ParentId = newCase.Id,
				CommentBody = ('Test Comment Body #' + i)
			);
			newCaseCommentsList.add(newCaseComment);
		}
		insert newCaseCommentsList;
		return newCaseCommentsList;
	}

	@isTest(SeeAllData=false)
	private static void negative_processCaseWithoutComments () {
		createCase();
		TelusExternalSharingScheduler telus = new TelusExternalSharingScheduler();
		telus.execute(null);
		List<Partner_Communication__c> pcs = [SELECT Id, Case_Comment_ID__c FROM Partner_Communication__c];
		System.assertEquals(pcs.size(), 0);
	}

	@isTest(SeeAllData=false)
	private static void positive_processCaseWithSingleComment () {
		createCaseComments(1);
		TelusExternalSharingScheduler telus = new TelusExternalSharingScheduler();
		telus.execute(null);
		List<Partner_Communication__c> pcs = [SELECT Id, Case_Comment_ID__c FROM Partner_Communication__c];
		System.assertEquals(pcs.size(), 1);
	}

	@isTest(SeeAllData=false)
	private static void positive_processCaseWithMultipleComments () {
		createCaseComments(10);
		TelusExternalSharingScheduler telus = new TelusExternalSharingScheduler();
		telus.execute(null);
		List<Partner_Communication__c> pcs = [SELECT Id, Case_Comment_ID__c FROM Partner_Communication__c];
		System.assertEquals(pcs.size(), 10);
	}
}
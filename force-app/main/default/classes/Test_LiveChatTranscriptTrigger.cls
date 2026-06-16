@isTest
private class Test_LiveChatTranscriptTrigger {
    @isTest
	public static void testTrigger() {
        String testChatKey = '8d5f3194-cbe8-666e-a9c1-6f5f8f74e5d1';
        Set<String> chatKeys = new Set<String>();
        chatKeys.add(testChatKey);

        LiveChatVisitor lcVisitor = new LiveChatVisitor();
        insert lcVisitor;

        Test.startTest();
            LiveChatTranscript lct = new LiveChatTranscript(
                LiveChatVisitorId = lcVisitor.Id,
                Status = 'Missed',
                PreChat_Number_of_Employees__c = 'Just Me',
                PreChat_Firstname__c = 'testFname',
                PreChat_Lastname__c = 'testLname',
                PreChat_Company__c = 'testCompany',
                PreChat_Email__c = 'Test@Test.ltd',
                PreChat_Phone__c = '12345',
                AID__c = 'test_AID',
                BMID__c = 'test_BMID',
                PID__c = 'test_PID',
                RCKW__c = 'test_RCKW',
                RCMT__c = 'test_RCMT',
                SID__c = 'test_SID',
                chatKey = testChatKey
            );
            insert lct;
        Test.stopTest();

        List<Lead> leadList = [select Id, FirstName, LastName, Company, Email, Phone,
            LeadSource, NumberOfEmployees__c, Industry, AID__c, BMID__c,
            PID__c, RCKW__c, RCMT__c, SID__c, Chat_Key__c from Lead];
        System.assert( (leadList != null && leadList.size() > 0), 'new Lead is not created');

        Lead createdLead = leadList[0];
        System.assert( createdLead.LeadSource == 'Lead Initial Chat', createdLead.LeadSource + ' != "Lead Initial Chat"');
        System.assert( createdLead.Industry == 'Other', createdLead.Industry + ' != "Other"');
        System.assert( createdLead.Company == lct.PreChat_Company__c, createdLead.Company + ' != ' + lct.PreChat_Company__c);
        System.assert( createdLead.FirstName == lct.PreChat_Firstname__c, createdLead.FirstName + ' != ' + lct.PreChat_Firstname__c);
        System.assert( createdLead.LastName == lct.PreChat_Lastname__c, createdLead.LastName + ' != ' + lct.PreChat_Lastname__c);
        System.assert( createdLead.Email == lct.PreChat_Email__c, createdLead.Email + ' != ' + lct.PreChat_Email__c);
        System.assert( createdLead.Phone == lct.PreChat_Phone__c, createdLead.Phone + ' != ' + lct.PreChat_Phone__c);
        System.assert( createdLead.NumberOfEmployees__c == '1-19', createdLead.NumberOfEmployees__c + ' != ' + lct.PreChat_Number_of_Employees__c);
        System.assert( createdLead.AID__c == lct.AID__c, createdLead.AID__c + ' != ' + lct.AID__c);
        System.assert( createdLead.BMID__c == lct.BMID__c, createdLead.BMID__c + ' != ' + lct.BMID__c);
        System.assert( createdLead.PID__c == lct.PID__c, createdLead.PID__c + ' != ' + lct.PID__c);
        System.assert( createdLead.RCKW__c == lct.RCKW__c, createdLead.RCKW__c + ' != ' + lct.RCKW__c);
        System.assert( createdLead.RCMT__c == lct.RCMT__c, createdLead.RCMT__c + ' != ' + lct.RCMT__c);
        System.assert( createdLead.SID__c == lct.SID__c, createdLead.SID__c + ' != ' + lct.SID__c);
        System.assert( createdLead.Chat_Key__c == lct.chatKey, createdLead.Chat_Key__c + ' != ' + lct.chatKey);

        LiveChatTranscript reselectedLCT = [select Id, Disposition__c, LeadId from LiveChatTranscript where Id = :lct.Id];
        System.assert( createdLead.Id == reselectedLCT.LeadId, createdLead.Id + ' != ' + reselectedLCT.LeadId);
    }
}
@isTest
private class Test_LeadData {

    @isTest
    private static void testRetrieveLeadShouldRetrieveLeadsSuccessfully(){
        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'testFirstName',
                    Lead.Phone => '9910106866',
                    Lead.Notes__c => 'Test Notes',
                    Lead.Website => 'http://test.com',
                    Lead.NumberOfEmployees => 123,
                    Lead.Industry => 'Test',
                    Lead.NumberOfEmployees__c => '2-19',
                    Lead.Number_of_Locations__c => '2-4',
                    Lead.Company => 'fakeCompany'
                }
            )
            .create()
            .getRecord();

        Set<Id> leadsToRetrieve = new Set<Id>{testLead.Id};
        LeadData.ILeadData leadDataInstance = new LeadData();
        Test.startTest();
            List<Lead> leadsRetrieved = leadDataInstance.retrieveLeads(leadsToRetrieve);
        Test.stopTest();

        System.assertEquals(1, leadsRetrieved.size(),
            'Only one Lead should be retrieved');
    }

    @isTest
    private static void testRetrieveLeanDataFutureMethodLeadsPositive(){
        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT  = true;
        Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.FirstName => 'testFirstName',
                    Lead.Phone => '9910106866',
                    Lead.Notes__c => 'Test Notes',
                    Lead.Website => 'http://test.com',
                    Lead.NumberOfEmployees => 123,
                    Lead.Industry => 'Test',
                    Lead.NumberOfEmployees__c => '2-19',
                    Lead.Number_of_Locations__c => '2-4',
                    Lead.Company => 'fakeCompany',
                    Lead.OwnerId => UserHelper.LEANDATAUSERID,
                    Lead.Routing_Reason__c => 'Existing Lead'
                }
            )
            .create()
            .getRecord();


        LeadData.ILeadData leadDataInstance = new LeadData();

        Test.startTest();
        List<Lead> assertLead = leadDataInstance.retrieveLeads(new Set<Id>{testLead.Id});
        List<Lead> assertLeads = leadDataInstance.retrieveLeadsByOwnerRoutingReason(UserHelper.LEANDATAUSERID,
                                                                                    new Set<String>{'Existing Lead'});
        Test.stopTest();

        System.assertEquals(1, assertLeads.size(),
            'Only 1 Lead should be found in the query');
        System.assertEquals(UserHelper.LEANDATAUSERID, assertLeads[0].OwnerId,
            'Owner Should be LeanData Queue User');
        System.assertEquals('Existing Lead', assertLeads[0].Routing_Reason__c,
            'Routing Reason should be the same as insert');
    }

}
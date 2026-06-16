@isTest
public class Test_NGBS_Partner_Hierarchy_Generator {
    public class MockNGBSPartnerResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"id": 123005,"companyName": "Avaya Inc.","firstName": "Default","lastName": "Default","hierarchyType": "Master","externalPartnerAccountId": "68495","businessIdentityId": 20,"partnerType": "BillOnBehalf","invoiceSettings": null,"status": "Active","parentId": null,"settlementSettings": null,"taxExemption": null,"requiresBillingFeed": null,"billingFeedType": null,"csn": 8}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testHierarchyGenerator() {
        Account acc = new Account(Name = 'Test', NGBS_Partner_Id__c = 123005);
        insert acc;
        
        Set<Id> accIds = new Set<Id>();
        accIds.add(acc.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockNGBSPartnerResponseGenerator());
        Test.startTest();
        NGBS_Partner_Hierarchy_Generator.getNGBSPartnerHierarchyFuture(accIds, true, true);
        NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyListFuture(acc.Id, true, false);
        NGBS_Partner_Hierarchy_Generator.getNGBSHierarchyListAura(acc.Id, true, true);
        Test.stopTest();
    }
}
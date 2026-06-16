/*       
* Created By    : Ishwarya.
* Created Date  : 24-03-2020
* Description   : Test class for Lead_LS_Enrich_Controller class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_LeadLSEnrichController {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testWebserviceEnrichLeadShouldEnrichLeadSuccessfully() { 
        
        new SObjectBuilder(RingCentralVariousSettings__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    RingCentralVariousSettings__c.LeadspaceAPIKey__c => 'AnyFakeKey',
                    RingCentralVariousSettings__c.LSBatchRequestMaxNumberRecords__c => 10
                }
            )
            .create();
        
        Lead newLead = new Lead(
            FirstName = 'Prashant', 
            Lastname = 'Mathur', 
            Company = 'Simplion', 
            Email = 'prashant.mathur@simplion.com', 
            website = 'http://www.simplion.com',
            SiteDunsNumber__c = '12345'
        );
        insert newLead;
        
        Test.startTest();
        Lead_LS_Enrich_Controller.Lead_LS_Enrich_Wrapper lenrich=Lead_LS_Enrich_Controller.enrichLead(newLead.Id);
        Test.stopTest();
        
    }
}
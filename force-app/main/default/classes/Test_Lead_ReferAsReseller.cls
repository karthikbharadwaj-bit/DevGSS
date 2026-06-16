/*       
* Created By    : Rajalakshmi
* Created Date  :  25-08-2020
* Description   : Test class forLead_ReferAsReseller on Leads

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@isTest

public class Test_Lead_ReferAsReseller{

@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    static void createLead() {
		Lead testLead = new Lead(Email = 'fake@email.com',
								LastName = 'test_Doe',
								Company = 'test_Com',
								LeadSource = 'SIA',
								PartnerDeal_Status__c = 'BT Approved',
								Domain_Type__c = 'test domain');
		insert testLead;
    
    Lead_ReferAsReseller.getLeadDetails(testLead.id);
	
	}
}
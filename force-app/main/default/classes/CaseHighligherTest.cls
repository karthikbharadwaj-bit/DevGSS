/**
 * This class contains unit tests for validating the behavior of Apex class CaseHighligher 
 */
@isTest
private class CaseHighligherTest {

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void myUnitTest() {
			Triggers.switchOff();
    		Test_Utils tutilss = new Test_Utils();
    		tutilss.initialiseTriggerBypass();
      		Account objAccount1= (Account)SmartFactory.createSObject('Account', true);
            objAccount1.RC_User_ID__c='RC'+Math.random();
      		upsert objAccount1;
     		Red_Account__c objRedAcc= (Red_Account__c)SmartFactory.createSObject('Red_Account__c', true);
            objRedAcc.EscalatedAccount__c=objAccount1.id;
            objRedAcc.Status__c='Inprogress';
			objRedAcc.Issue_Category__c='Product';
			objRedAcc.Issue_Status__c='New';
			objRedAcc.Primary_Competitor__c = 'Comcast';
        	objRedAcc.Primary_Reason_for_Red__c = 'Support Issues';
        	objRedAcc.Sub_Reason_for_Red__c = 'Adoption Issues';
      		upsert objRedAcc;
			Case cas1 = new Case( Type = 'VoIP Device Back Order', AccountId = objAccount1.id, inContact_BU_ID__c = 123);
			upsert cas1;
			ApexPages.StandardController controller=new ApexPages.Standardcontroller(cas1);
  			CaseHighlighter objCaseHighlighter=new CaseHighlighter(controller);
  			tutilss.deInitialiseTriggerBypass();
    }
}
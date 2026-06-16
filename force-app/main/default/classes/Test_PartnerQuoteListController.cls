/*       
* Created By    : 
* Created Date  : 25-02-2020
* Description   : Test class for PartnerQuoteListController class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerQuoteListController {

    @isTest
    static void testMethod2(){
        String AVAYA_PARTNER_ACCOUNT_ID =System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Opportunity oppObj = new Opportunity();
            oppObj.Name = 'Test a Opportunity';
            oppObj.StageName = '1. Qualify';
            
            oppObj.CloseDate = System.today()+1;
            Partner_OpportunitiesMain.OppResponseWrapper orw = Partner_OpportunitiesMain.createOpportunity(oppObj,PartnerRecordsUtil.partnerAccount.id,contact.Lastname);
            System.assertNotEquals(null, orw.opp);
            
            orw.opp.Partner_Account__c = AVAYA_PARTNER_ACCOUNT_ID;
            String msg = Partner_OpportunitiesMain.updateOpportunity(orw.opp);
            //System.assertEquals('Success',msg);
            
            PartnerRecordsUtil.createPartnerQuote(orw.opp);
        }
        
        Test.stopTest();        

        PartnerQuoteListController.getQuoteData(null,1,1,'a','Name','all');
        PartnerQuoteListController.getQuoteData(null,1,1,'a','Name','');
        PartnerQuoteListController.getQuoteData(AVAYA_PARTNER_ACCOUNT_ID,1,1,'a','Name','');

    }
    @isTest
    static void testMethod3(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Opportunity oppObj = new Opportunity();
            oppObj.Name = 'Test a Opportunity';
            oppObj.StageName = '1. Qualify';
            //error catch code
            String msg = Partner_OpportunitiesMain.updateOpportunity(oppObj);
            System.assertNotEquals('Success', msg);
            
            Partner_OpportunitiesMain.OppResponseWrapper orw = Partner_OpportunitiesMain.createOpportunity(oppObj,PartnerRecordsUtil.partnerAccount.id,contact.Lastname);
            System.assertNotEquals(null, orw.opp);
        }
        Test.stopTest();        
    }

}
/*       
        * Created By    : 
        * Created Date  : 26-02-2020
        * Description   : Test class for PartnerDealRegistrationUtil class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************
*/
@isTest
public class Test_PartnerDealRegistrationUtil {   
    /*@testSetup static void insertProcessBypass() {
        ByPassTrigger__c bpt = new ByPassTrigger__c();
        bpt.Bypass_Segmentation_Logic__c = true;
        insert bpt;
    }*/
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod1(){
        String AVAYA_PARTNER_ACCOUNT_ID =System.Label.Avaya_Partner_Account_Id;
        PartnerDealRegistrationUtil utilp = new PartnerDealRegistrationUtil();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();
        List<Deal_Registration__c> lstDeal = new List<Deal_Registration__c>();
        lstDeal.add(dealObj);
        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Lead> leadLst = PartnerDealRegistrationUtil.AddDealAsLead(lstDeal);
            if(leadLst.size() > 0){
                Test.startTest();
                PartnerDealRegistrationUtil.PartnerDetailWrapper pdw = PartnerDealRegistrationUtil.fetchPartnerContact(leadLst.get(0));
                pdw = PartnerDealRegistrationUtil.fetchPartnerOwner(leadLst.get(0));
                                               
                PartnerDealRegistrationUtil.isAvayaUser();
                PartnerDealRegistrationUtil.getCurrentUserPartnerAccount();

                PartnerDealRegistrationUtil.getContactAccount(PartnerRecordsUtil.partnerContact.id);
                PartnerDealRegistrationUtil.userAccountIdIsNotNull(PartnerRecordsUtil.runAsAvayaAdmin.id);
                Test.stopTest();
                
            }
        }                
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testMethod2(){
        String AVAYA_PARTNER_ACCOUNT_ID =System.Label.Avaya_Partner_Account_Id;
        PartnerDealRegistrationUtil utilp = new PartnerDealRegistrationUtil();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Deal_Registration__c dealObj = PartnerRecordsUtil.createAvayaDeal();
        List<Deal_Registration__c> lstDeal = new List<Deal_Registration__c>();
        lstDeal.add(dealObj);       
             
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            List<Lead> leadLst = PartnerDealRegistrationUtil.AddDealAsLead(lstDeal);
            if(leadLst.size() > 0){
                Test.startTest(); 
                PartnerDealRegistrationUtil.PartnerLeadConvertResult plcr = PartnerDealRegistrationUtil.convertPartnerLead(leadLst.get(0),false);
                Test.stopTest();
            }
        }
        
    }
}
/*       
        * Created By    : 
        * Created Date  : 23-02-2020
        * Description   : Test class for Partner_LookupSearchController class
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerLookupSearch {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void getPartnerDetails(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        Test.startTest();
        Partner_LookupSearchController.getPartnerData('avaya',true,'contact',true,true,true);
        Partner_LookupSearchController.getPartnerData('',false,'',true,true,true);
        Partner_LookupSearchController.getPartnerAccountData('avaya');
        Partner_LookupSearchController.getPartnerAccountData('');
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void getPartnerDetails1(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
        Partner_LookupSearchController.getPartnerData('avaya',false,'name',true,true,true);
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void getPartnerDetails2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Account acc=PartnerRecordsUtil.partnerAccount;
        Contact con=PartnerRecordsUtil.partnerContact;
        Test.startTest();
        Partner_LookupSearchController.getPartnerDataforSFDC('avaya','contact',true,'Avaya Cloud Office');
        Partner_LookupSearchController.getPartnerDataforSFDC('avaya','contact',true,'RingCentral');
        Partner_LookupSearchController.getPartnerDataforSFDC('avaya','',true,'RingCentral');
        Partner_LookupSearchController.getPartnerDataforSFDC('','',false,'');
        Partner_LookupSearchController.getPartnerAccountData('avaya');
        Partner_LookupSearchController.getPartnerAccountData('');
        Test.stopTest();
    }
    
}
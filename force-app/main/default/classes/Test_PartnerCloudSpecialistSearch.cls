@isTest
public class Test_PartnerCloudSpecialistSearch {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod1(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Partner_CloudSpecialistSearchController.getUsersForCloudSpecialist(contact.Lastname, '');
            Partner_CloudSpecialistSearchController.PartnerAccountMasterAgtChlMgr(contact.Id);
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethod2(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Contact contact=PartnerRecordsUtil.partnerContact;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Partner_CloudSpecialistSearchController.PartnerAccountMasterAgtChlMgr(contact.Lastname);
        }
    }
}
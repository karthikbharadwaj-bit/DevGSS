@isTest
public class Test_CommunityInfo {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetCommunityName(){
        String test = CommunityInfo.getCommunityName();
    }
    /*@isTest 
    public static void testgetCommunityName1(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin)
        {            
            Id userid = PartnerRecordsUtil.runAsAvayaAdmin.Id;
            system.debug('User Id - '+userid);
            //Profile portalProfile = [SELECT Id FROM Profile where name='Partner Community - Partner Admin' Limit 1];            
            List<NetworkMember> networkmember = [SELECT network.name,NetworkID, MemberID FROM NetworkMember WHERE memberID  =:userid];
            system.debug('networkmember '+ networkmember.size());
            system.debug('networkmember id '+ networkmember[0].NetworkID);
            system.debug('networkmember name '+ networkmember[0].network.name);
            Network network = [Select id,Name from Network where Id =: networkmember[0].NetworkID];
            system.debug('network id '+ network.Id);
            system.debug('network name '+ network.Name);
            String test = CommunityInfo.getCommunityName();
        }
    }*/
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetBrandName(){
        String test = CommunityInfo.getBrandName();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetCommunityDetails(){
        Community_Details__mdt comm_metadata = CommunityInfo.getCommunityDetails();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetAllCommunityDetails(){
        Map<String,Community_Details__mdt> commDetailsMap = CommunityInfo.getAllCommunityDetails();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetAllCommunityTopMastersIds(){
        List<Id> commTopMastersIds = CommunityInfo.getAllCommunityTopMastersIds();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetTranslations(){
        CommunityInfo.getTranslations('Lead');
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest 
    public static void testgetTranslations1(){
        CommunityInfo.getTranslations1('Lead','German');
    }
}
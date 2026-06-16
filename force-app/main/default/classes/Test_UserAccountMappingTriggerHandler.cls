@isTest
public class Test_UserAccountMappingTriggerHandler {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test01(){
        setupData(); 
        List<Account> accList = [SELECT Id, Name, Avaya_Partnership_Account__c FROM Account limit 1];
        Contact con = [SELECT Id,AccountId, Avaya_Partnership_Contact__c FROM Contact where Avaya_Partnership_Contact__c = true limit 1]; 
        User_Account_Mapping__c userObj=new User_Account_Mapping__c();
        userObj.Name='Test User';
        userObj.Partner_Account__c=con.AccountId;
        userObj.Partner_Contact__c=con.Id;
        userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            insert userObj;
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test02(){
        setupData(); 
        List<Account> accList = [SELECT Id, Name, Avaya_Partnership_Account__c FROM Account limit 1];
        Contact con = [SELECT Id,AccountId, Avaya_Partnership_Contact__c FROM Contact where Avaya_Partnership_Contact__c = true limit 1]; 
        User_Account_Mapping__c userObj=new User_Account_Mapping__c();
        userObj.Name='Test User';
        userObj.Partner_Account__c=con.AccountId;
        userObj.Partner_Contact__c=con.Id;
        userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            insert userObj;
        }
        userObj.Name = 'Test Users';
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            update userObj;
        }
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void test03(){
        setupData(); 
        List<Account> accList = [SELECT Id, Name, Avaya_Partnership_Account__c FROM Account limit 1];
        Contact con = [SELECT Id,AccountId, Avaya_Partnership_Contact__c FROM Contact where Avaya_Partnership_Contact__c = true limit 1]; 
        User_Account_Mapping__c userObj=new User_Account_Mapping__c();
        userObj.Name='Test User';
        userObj.Partner_Account__c=con.AccountId;
        userObj.Partner_Contact__c=con.Id;
        userObj.Partner_User__c=PartnerRecordsUtil.runAsAvayaMasterRole.Id;
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            insert userObj;
        }
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            delete userObj;
        }
    }
    private static void setupData() {
        String AVAYA_PARTNER_ACCOUNT_ID = System.Label.Avaya_Partner_Account_Id;
        PartnerRecordsUtil util = new PartnerRecordsUtil();
    }
}
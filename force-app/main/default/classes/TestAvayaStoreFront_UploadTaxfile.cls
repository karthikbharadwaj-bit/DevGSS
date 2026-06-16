@isTest
public class TestAvayaStoreFront_UploadTaxfile {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod1(){        
        
		Account testacct=new Account();
        testacct.Name='Test Account';
        insert testacct;         
        Account_Checklist__c acctChecklist = new Account_Checklist__c();
        acctChecklist.Account__c=testacct.id;
        acctChecklist.Type__c='	Invoice/Credit card';
        insert acctChecklist;
        AvayaStorefront_UploadTaxfile.getUserRecordAccess(acctChecklist.id);
        AvayaStorefront_UploadTaxfile.getFiles(acctChecklist.id);
    
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod2(){
        Account testacct=new Account();
        testacct.Name='Test Account';
        insert testacct;
        AvayaStorefront_UploadTaxfile.getContractDetails(testacct.id);
        AvayaStorefront_UploadTaxfile.getContractFiles(testacct.id);
        AvayaStorefront_UploadTaxfile.getAttachments(testacct.id);
    }
}
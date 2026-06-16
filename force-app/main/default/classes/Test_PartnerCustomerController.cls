/*       
* Created By    : 
* Created Date  : 24-02-2020
* Description   : Test class for Partner_Customer_Controller class

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
@isTest
public class Test_PartnerCustomerController {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testmethodDealReg() {
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        
        Partner_Customer_Controller custController = new Partner_Customer_Controller();
        
        system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Contract cont = new Contract();
            cont.AccountId = PartnerRecordsUtil.partnerAccount.Id;
            cont.Status = 'Draft';
            insert cont;
            Partner_Customer_Controller.getContractFiles(cont.id);
            
            
        }
        
        Contact contact1 = new Contact(
            FirstName = 'Test',
            Lastname = 'BmTesty',
            AccountId = PartnerRecordsUtil.partnerAccount.Id,
            Email = System.now().millisecond() + 'test@bmtest.com'
        );
        
        Account_Change_Request__c acr = new Account_Change_Request__c();
        acr.Payment_Method__c = 'Credit Card';
        acr.Account__c = PartnerRecordsUtil.partnerAccount.Id;
        Test.startTest();
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            insert contact1;
            insert acr; 
            Partner_Customer_Controller.ContactWrapper contwrap = new Partner_Customer_Controller.ContactWrapper();
            contwrap.contact = PartnerRecordsUtil.partnerContact;
            contwrap.isPrimary = true;
            contwrap.role = '';
            
            Partner_Customer_Controller.AccountCheckListWrapper accheckwrap = new Partner_Customer_Controller.AccountCheckListWrapper();
            
            accheckwrap.submittedDate = system.today();
            accheckwrap.id = '';
            accheckwrap.paymentMethod = '';
            accheckwrap.costCenter = '';
            accheckwrap.converttoPaidAccount = true;
            accheckwrap.refundRequest = '';
            accheckwrap.accountCancellation = '';
            accheckwrap.billingAddress = '';
            accheckwrap.locationChange = '';
            accheckwrap.isAvailable = true;
            accheckwrap.isApprovalTagged = false;
            accheckwrap.typeName = '';
            accheckwrap.approvalStatus = '';
            accheckwrap.comments = '';
            accheckwrap.fileUpload = false;
            
            Partner_Customer_Controller.SelectedAccountWrapper selAccWrap = new Partner_Customer_Controller.SelectedAccountWrapper();
            selAccWrap.serviceName = '';
            selAccWrap.isPrimaryAlreadyExists = true ;
            selAccWrap.isAvayaOnly = true;
            
            Partner_Customer_Controller.CustomerDataTableWrapper custDataTableWrap = new Partner_Customer_Controller.CustomerDataTableWrapper();
            custDataTableWrap.isAvaya = true;
            custDataTableWrap.isMaster = false;
            
            
            Contact newCon = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = PartnerRecordsUtil.partnerAccount.Id,
                Email = System.now().millisecond() + 'test@1test.com'
            );//String searchKeyWord, String searchBy,Decimal pageNumber, Decimal pageSize
            Partner_Customer_Controller.createContactRecord(newCon);
            Partner_Customer_Controller.createContactRecord(PartnerRecordsUtil.partnerContact);
            Partner_Customer_Controller.deleteChecklistRecords(PartnerRecordsUtil.partnerAccount.Id);
            Partner_Customer_Controller.insertAccountCheckList('Credit Check','Test Comments',PartnerRecordsUtil.partnerAccount.Id);
            Partner_Customer_Controller.getOpportunity(PartnerRecordsUtil.partnerAccount.Id);
            Partner_Customer_Controller.getSelectedAccountDetails(PartnerRecordsUtil.partnerAccount.Id);
            Partner_Customer_Controller.getCustomerDataController('test','Name',1,10);
            Partner_Customer_Controller.getAttachments(PartnerRecordsUtil.partnerAccount.Id);
            Account portalAccount1 = new Account(
                Name = 'TestAccount'
            );
            insert portalAccount1;            
            Contact conROle = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = PartnerRecordsUtil.partnerAccount.Id,
                Email = System.now().millisecond() + 'test@1test.com'
            );
            insert conROle;
            
            AccountContactRole acctContactRole = new AccountContactRole();
            
            acctContactRole.AccountId = portalAccount1.Id;
            acctContactRole.ContactId = conROle.Id;
            acctContactRole.Role = 'Signatory';
            acctContactRole.IsPrimary = true;
            insert acctContactRole;
            Partner_Customer_Controller.updateAccountContactRole(PartnerRecordsUtil.partnerAccount.Id,'fname','LastName',
                                                                 'String@Email.com','764653654','test',false,
                                                                 acctContactRole.Id,contact1.Id);
            Partner_Customer_ContactController.getAttachmentOppo(PartnerRecordsUtil.partnerAccount.Id);
        }
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod1(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Partner_Customer_Controller.SelectedAccountWrapper selAccWrap = new Partner_Customer_Controller.SelectedAccountWrapper();
        selAccWrap.serviceName = '';
        selAccWrap.isPrimaryAlreadyExists = true ;
        selAccWrap.isAvayaOnly = true;
        Test.startTest();
       	Partner_Customer_Controller.getSelectedAccountDetails(PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod2(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Contact newCon = new Contact(
            FirstName = 'Test',
            Lastname = 'McTesty',
            AccountId = PartnerRecordsUtil.partnerAccount.Id,
            Email = System.now().millisecond() + 'test@1test.com'
        );
        Test.startTest();
        Map<String, String> mapContact =   Partner_Customer_Controller.createContactRecord(newCon);
        Test.stopTest();
        //System.assertEquals('success', mapContact.get('status'));
    }
    
    @isTest static void testMethod3(){
        Partner_Customer_Controller.selectedUserAccountId = (Id) new ValueProvider.DummyIdProvider(Account.sObjectType).getValue();
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
        Partner_Customer_Controller.CustomerDataTableWrapper pw = Partner_Customer_Controller.getCustomerDataController('test','Name',1,10);
        System.assertEquals(10, pw.pageSize);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod4(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
		Partner_Customer_Controller.deleteChecklistRecords(PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod5(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
		Partner_Customer_Controller.insertAccountCheckList('Credit Check','Test Comments',PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod6(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
		Partner_Customer_Controller.getOpportunity(PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod7(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
		Partner_Customer_Controller.getAttachments(PartnerRecordsUtil.partnerAccount.Id);
        Test.stopTest();
    }
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod8(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Contact contact1 = new Contact(
            FirstName = 'Test',
            Lastname = 'BmTesty',
            AccountId = PartnerRecordsUtil.partnerAccount.Id,
            Email = System.now().millisecond() + 'test@bmtest.com'
        );
        //insert contact1;
        Account_Change_Request__c acr = new Account_Change_Request__c();
        acr.Payment_Method__c = 'Credit Card';
        acr.Account__c = PartnerRecordsUtil.partnerAccount.Id;
        system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){
            insert contact1;
            insert acr; 
         }
        Partner_Customer_Controller.AccountCheckListWrapper accheckwrap = new Partner_Customer_Controller.AccountCheckListWrapper();
        accheckwrap.submittedDate = system.today();
        accheckwrap.id = '';
        accheckwrap.paymentMethod = '';
        accheckwrap.costCenter = '';
        accheckwrap.converttoPaidAccount = true;
        accheckwrap.refundRequest = '';
        accheckwrap.accountCancellation = '';
        accheckwrap.billingAddress = '';
        accheckwrap.locationChange = '';
        accheckwrap.isAvailable = true;
        accheckwrap.isApprovalTagged = false;
        accheckwrap.typeName = '';
        accheckwrap.approvalStatus = '';
        accheckwrap.comments = '';
        accheckwrap.fileUpload = false;
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod9(){
        Account portalAccount1 = new Account(
            Name = 'TestAccount'
        );
        insert portalAccount1;            
        Contact conROle = new Contact(
            FirstName = 'Test',
            Lastname = 'McTesty',
            AccountId = portalAccount1.Id,
            Email = System.now().millisecond() + 'test@1test.com'
        );
        insert conROle;
        
        AccountContactRole acctContactRole = new AccountContactRole();
        
        acctContactRole.AccountId = portalAccount1.Id;
        acctContactRole.ContactId = conROle.Id;
        acctContactRole.Role = 'Signatory';
        acctContactRole.IsPrimary = true;
        insert acctContactRole;
        Test.startTest();
        Partner_Customer_Controller.updateAccountContactRole(portalAccount1.Id,'fname','LastName',
                                                             'String@Email.com','764653654','test',false,
                                                             acctContactRole.Id,conROle.Id);
        Partner_Customer_ContactController.getAttachmentOppo(portalAccount1.Id);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest static void testMethod11(){
        Account portalAccount1 = new Account(
            Name = 'TestAccount'
        );
        insert portalAccount1;            
        Contact conROle = new Contact(
            FirstName = 'Test',
            Lastname = 'McTesty',
            AccountId = portalAccount1.Id,
            Email = System.now().millisecond() + 'test@1test.com'
        );
        insert conROle;

        User user3 = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    User.ProfileId => [SELECT Id FROM Profile WHERE Name = 'Partner Community - Partner Admin'].Id,
                    User.Email => new ValueProvider.UniqueStringProvider('test123@noemail.com'),
                    User.EmailEncodingKey => 'UTF-8',
                    User.FirstName => new ValueProvider.UniqueStringProvider('Bruce'),
                    User.LastName => new ValueProvider.UniqueStringProvider('Testing'),
                    User.LanguageLocaleKey => 'en_US',
                    User.LocaleSidKey => 'en_US',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.Country => 'United States',
                    User.Username => new ValueProvider.UniqueStringProvider('testerrandomw1@noemail.com'),
                    User.Alias => 'test123',
                    User.PortalRole => 'Manager',
                    User.ContactId => conROle.Id,
                    User.IsActive => true
                }
            )
            .build()
            .getRecord();

        AccountContactRole acctContactRole = new AccountContactRole();
        
        acctContactRole.AccountId = portalAccount1.Id;
        acctContactRole.ContactId = conROle.Id;
        acctContactRole.Role = 'Signatory';
        acctContactRole.IsPrimary = true;
        insert acctContactRole;
        Test.startTest();
        Partner_Customer_Controller.updateAccountContactRole(portalAccount1.Id,'fname','LastName',
                                                             'String@Email.com','764653654','test',true,
                                                             '',conROle.Id);
        Partner_Customer_Controller.updateAccountContactRole(portalAccount1.Id,'fname','LastName',
                                                             'String@Email.com','764653654','test',true,
                                                             acctContactRole.Id,conROle.Id);
        Partner_Customer_ContactController.getAttachmentOppo(portalAccount1.Id);
        Partner_Customer_ContactController.createUserFromContact(user3);
        Test.stopTest();
    }
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest static void testMethod10(){
        PartnerRecordsUtil util = new PartnerRecordsUtil();
        Test.startTest();
		system.runAs(PartnerRecordsUtil.runAsSysAdmin){
            Contract cont = new Contract();
            cont.AccountId = PartnerRecordsUtil.partnerAccount.Id;
            cont.Status = 'Draft';
            insert cont;
            Partner_Customer_Controller.getContractFiles(cont.id);
        }
        Test.stopTest();
    }

}
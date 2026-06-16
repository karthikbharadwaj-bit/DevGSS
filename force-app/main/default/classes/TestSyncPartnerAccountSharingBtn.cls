@isTest
private class TestSyncPartnerAccountSharingBtn {
    
    enum PortalType { CSPLiteUser, PowerPartner, PowerCustomerSuccess, CustomerSuccess }
    
    @isTest
    static void usertest() {
        User pu = getPortalUser(PortalType.PowerPartner, null, true);
        System.assert([select isPortalEnabled 
                         from user 
                        where id = :pu.id].isPortalEnabled,
                      'User was not flagged as portal enabled.');       
        
        System.RunAs(pu) {
            System.assert([select isPortalEnabled 
                             from user 
                            where id = :UserInfo.getUserId()].isPortalEnabled, 
                          'User wasnt portal enabled within the runas block. ');
        }
       
        User portaluser = [select Contact.AccountId from User where Id = :pu.id];
        Account accObjCustomer = [select id from Account where RecordType.Name = 'Customer Account' and Partner_ID__c = '12344' limit 1];
        Test.startTest();
        SyncPartnerAccountSharingBtn syncShareBtnObj = new SyncPartnerAccountSharingBtn();
        SyncPartnerAccountSharingBtn.sharePartnerAccount('', portaluser.Contact.AccountId);
        SyncPartnerAccountSharingBtn.sharePartnerAccount('12344', portaluser.Contact.AccountId);
        SyncPartnerAccountSharingBtn.sharePartnerAccount('12344', accObjCustomer.id);
        Test.stopTest();
    }
    
    public static User getPortalUser(PortalType portalType, User userWithRole, Boolean doInsert) {
        /* Make sure the running user has a role otherwise an exception 
           will be thrown. */
        if(userWithRole == null) {   
            if(UserInfo.getUserRoleId() == null) {
                UserRole r = new UserRole(name = 'TEST ROLE');
                Database.insert(r);
                
                userWithRole = new User(alias = 'hasrole', email='userwithrole@roletest1.com', userroleid = r.id,
                                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', 
                                    localesidkey='en_US', profileid = UserInfo.getProfileId(), 
                                    timezonesidkey='America/Los_Angeles', username='userwithrole@testorg.com');
            } else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }
            
            System.assert(userWithRole.userRoleId != null, 
                          'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.');
        }

        Account a;
        Contact c;
        
        Account testAcc = new Account();
        testAcc.Name = 'TestAcc';
        insert testAcc;

        Contact testCont = new Contact();
        testCont.LastName = 'TestLastName';
        testCont.AccountId =  testAcc.id;
        testCont.Email = 'test@example.com';
        testCont.Phone='1234567';
        insert testCont;
        
        System.runAs(userWithRole) {
            Schema.DescribeSObjectResult result = Account.SObjectType.getDescribe();
            Map<string,Schema.RecordTypeInfo> rtMapById = result.getRecordTypeInfosByName();
            
            Account accObj2 = new Account();
            accObj2.Name = 'Test Account Parent ';
            accObj2.Partner_ID__c = '12345';
            accObj2.Partner_Contact__c = testCont.Id;
            accObj2.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID(); 
            insert accObj2; 
            
            a = new Account();
            a.Name = 'Test Account';
            a.Partner_ID__c = '12344';
            a.Partner_Contact__c = testCont.Id;
            a.ParentId = accObj2.id;
            a.RecordTypeId = rtMapById.get('Partner Account').getRecordTypeID(); 
            Database.insert(a);
        
            Account accObj1 = new Account();
            accObj1.Name = 'Test Account Customer';
            accObj1.Partner_ID__c = '12344';
            accObj1.Partner_Contact__c = testCont.Id;
            accObj1.RecordTypeId = rtMapById.get('Customer Account').getRecordTypeID(); 
            insert accObj1;
            
            c = new Contact(AccountId = a.id, lastname = 'lastname');
            Database.insert(c);
        }
        
        /* Get any profile for the given type.*/
        Profile p = [select id 
                      from profile 
                     where usertype = :portalType.name() 
                     limit 1];   
        
        String testemail = 'puser000321@amamama.com';
        User pu = new User(profileId = p.id, username = testemail, email = testemail, 
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US', 
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles', 
                           alias='cspu', lastname='lastname', contactId = c.id);
        
        if(doInsert) {
            Triggers.switchOff();
            Database.insert(pu);
            Triggers.switchOn();
        }
        return pu;
    }
    
    /****************************************************************************************************************************************/    
    
}
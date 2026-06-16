@isTest()
private class TestPartnerRequest {
    private static final Id RCPARTNER_USER_ID = HardcodedIdsMapper.getMatchedObjectId('005800000038AHjAAM');

    @testSetup
    static void prepareTestData() {
        PartnerRequestEmailSettings__c emailSettings = new PartnerRequestEmailSettings__c();
        emailSettings.CC_Addresses__c = 'test@fake-mail.tld';

        RCSF_Sync__c syncSettings = new RCSF_Sync__c(Name = 'RCSF Sync');
        syncSettings.Email__c = 'test@fake-mail.tld';

        insert new List<sObject>{ emailSettings, syncSettings };
    }

    @isTest
    static void phoneIsValidated() {
        String phone = '5555555';
        String country = 'USA';
        Partner_Request__c pr = new Partner_Request__c();
        fillPartnerRequestWithSampleData(pr);
        pr.Partner_Phone__c = phone;
        pr.Partner_Country__c = country;

        insert pr;

        pr = [SELECT Partner_Phone__c, Original_Partner_Phone__c FROM Partner_Request__c];

        System.assertEquals(phone, pr.Original_Partner_Phone__c, 'Original_Partner_Phone__c must be equals ' +
            'to value of the Partner_Phone__c, before it was validated');

        System.assertEquals(ValidationUtility.validatePhoneNumber(phone, country), pr.Partner_Phone__c,
            'Partner_Phone__c values not equals to validated value');
    }

    @isTest
    static void testCreateContact2() {
        Triggers.switchOff();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'TestAccount')
            .create()
            .getRecord();

        Partner_Request__c pr = (Partner_Request__c) new SObjectBuilder(Partner_Request__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Partner_Request__c.Avaya_Partnership_Reg__c => true,
                Partner_Request__c.Partner_Country__c => 'USA',
                Partner_Request__c.Partner_Phone__c => '5555555',
                Partner_Request__c.Partner_Last_Name__c => 'Doe',
                Partner_Request__c.Partner_First_Name_Billing_Support__c => 'John',
                Partner_Request__c.Partner_Last_Name_Billing_Support__c => 'Doe',
                Partner_Request__c.Partner_Phone_Billing_Support__c => '5555555',
                Partner_Request__c.Partner_Email_Address_Billing_Support__c => 'jdoe@gmail.com'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        List<Contact> contacts = new PRMHelper().createContact2(testAccount.Id, pr);

        System.assertEquals(2, contacts.size(), '2 contacts should be created by partner request');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testSendEmailAboutFailure() {
        Triggers.switchOff();
        Partner_Request__c pr = (Partner_Request__c) new SObjectBuilder(Partner_Request__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Partner_Request__c.Partner_Country__c => 'USA',
                Partner_Request__c.Partner_Phone__c => '5555555',
                Partner_Request__c.Partner_Last_Name__c => 'Doe',
                Partner_Request__c.Partner_Company_Name__c => 'RingCentral'
            })
            .create()
            .getRecord();
        Triggers.switchOn();

        try {
            throw new AquivaHelper.AquivaException('Check Send Email about failure');
        } catch(Exception e) {
            new PRMHelper().sendEmailAboutFailure(pr, e);
        }
    }

    @isTest
    static void partnerTypeIsUpdated() {
        Partner_Request__c pr_regular = new Partner_Request__c();
        fillPartnerRequestWithSampleData(pr_regular);
        pr_regular.Partner_Company_Name__c = 'Test Partner Request #1';
        pr_regular.Reseller_Partner_Type__c = 'Regular Partner';

        Partner_Request__c pr_isv = new Partner_Request__c();
        fillPartnerRequestWithSampleData(pr_isv);
        pr_isv.Partner_Company_Name__c = 'Test Partner Request #2';
        pr_isv.Reseller_Partner_Type__c = 'ISV Partner';

        insert new List<Partner_Request__c>{ pr_regular, pr_isv };

        List<Partner_Request__c> requests = [
            SELECT Reseller_Partner_Type__c, Partner_Type__c
            FROM Partner_Request__c
        ];

        for (Partner_Request__c request : requests) {
            if (request.Reseller_Partner_Type__c == 'Regular Partner') {
                System.assertEquals('Master Agent', request.Partner_Type__c,
                    'Partner_Type__c must be equals to Master Agent value, if Reseller_Partner_Type__c ' +
                    'equals to the Regular Partner value');
            } else if (request.Reseller_Partner_Type__c == 'ISV Partner') {
                System.assertEquals('ISV Partner', request.Partner_Type__c,
                    'Partner_Type__c must be equals to ISV Partner value, if Reseller_Partner_Type__c ' +
                    'equals to the ISV Partner value');
            }
        }
    }

    @isTest
    static void franchisorRequestProcessed() {
        Partner_Request__c franchisorRequest = new Partner_Request__c();
        fillPartnerRequestWithSampleData(franchisorRequest);
        franchisorRequest.Partner_Type__c = 'Franchisor';
        franchisorRequest.Partner_Request_Source__c = 'National Accounts';

        insert franchisorRequest;

        Partner_Request__c[] requests = getInsertedRequests();
        System.assert(requests.size() > 0, 'No partner requests found');

        Account[] accounts = getInsertedAccounts(new String[]{ requests[0].Partner_ID__c });
        System.assert(accounts.size() > 0, 'No accounts found');

        System.assertEquals('National Accounts', accounts[0].Partner_Source__c,
            'Partner_Source__c of an Account field must equals to National Accounts value');
        System.assertEquals('Franchisor', accounts[0].Partner_Type__c,
            'Partner_Type__c of an Account must equals to Franchisor value');

        validateAccountFieldsEquality(requests[0], accounts[0], true);

        Contact[] contacts = getInsertedContacts(accounts[0].Id);
        System.assert(contacts.size() > 0, 'No contacts, related to account, were found');

        validateContactFieldsEquality(requests[0], contacts[0]);
    }

    @isTest
    static void createAccountOnPartnerRequestInsert() {
        Partner_Request__c request1 = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request1);
        request1.DSR_USER__c = UserInfo.getUserId();
        request1.Reseller_Partner_Type__c = 'Regular Partner';

        Partner_Request__c request2 = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request2);
        request2.Partner_Type__c = 'Master Agent';

        Partner_Request__c request3 = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request3);
        request3.Reseller_Partner_Type__c = 'ISV Partner';

        Partner_Request__c request4 = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request4);
        request4.Partner_Type__c = 'ISV Partner';

        insert new Partner_Request__c[] { request1, request2, request3, request4 };

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(4, requests.size(), '4 Reseller requests were expected');

        List<String> ids = new List<String>();
        for (Partner_Request__c entry : requests) {
            ids.add(entry.Partner_ID__c);
        }

        Account[] accounts = getInsertedAccounts(ids);
        System.assertEquals(4, accounts.size(), '4 Accounts were expected');

        Boolean accountFound = false;
        for (Partner_Request__c request : requests) {
            accountFound = false;
            for (Account acc : accounts) {
                if (request.Partner_ID__c == acc.Partner_ID__c) {
                    if (request.Reseller_Partner_Type__c == 'Regular Partner'
                        || request.Partner_Type__c == 'Master Agent')
                    {
                        System.assertEquals('Master Agent', acc.Partner_Type__c,
                            'Account Partner type expect to be Master Agent');
                    }
                    else if (request.Reseller_Partner_Type__c == 'ISV Partner'
                        || request.Partner_Type__c == 'ISV Partner')
                    {
                        System.assertEquals('ISV Partner', acc.Partner_Type__c,
                            'Account Partner type expect to be ISV Partner');
                    }
                    else {
                        System.assertEquals(request.Partner_Type__c, acc.Partner_Type__c, 'Values must be equal');
                    }
                    validateAccountFieldsEquality(request, acc, true);
                    accountFound = true;
                }
            }
            System.assert(true == accountFound, 'No corresponding Account was found. ' +
                'Reseller Request Partner Id equals to ' + request.Partner_ID__c);
        }

        Contact[] contacts = getInsertedContacts(accounts[0].Id);
        System.assertEquals(requests.size(), contacts.size(),
            'Count of inserted contacts must be equal to count created Reseller requests');

        //It's not an error to pass always first created request to method
        //See code at PRMHelper, method onInsertPRM
        for (Contact cntc : contacts) {
            validateContactFieldsEquality(requests[0], cntc);
        }
    }

    @isTest
    static void updateDeclinedAccountOnPartnerRequestInsert() {
        String partnerName = 'This is partner name';

        Account accWithSameName = new Account();
        accWithSameName.Name = partnerName;
        accWithSameName.Type = 'Partner';
        accWithSameName.PartnerStatus__c = 'Declined';
        accWithSameName.Partner_ID__c = '123456';
        accWithSameName.Other_TextField__c = 'SOME OTHER VALUE';
        accWithSameName.OwnerId = UserInfo.getUserId();
        accWithSameName.BillingStreet = 'SOME OTHER VALUE #1';
        accWithSameName.BillingCity = 'SOME OTHER VALUE #2';
        accWithSameName.BillingState = 'SOME OTHER VALUE #3';
        accWithSameName.BillingPostalCode = 'SOME OTHER VALUE #4';
        accWithSameName.BillingCountry = 'SOME OTHER VALUE #5';
        accWithSameName.Partner_Sign_Up_Date__c = Date.newInstance(1980, 01, 01);
        insert accWithSameName;

        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = partnerName;

        insert request;

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Partner_Request__c record not found');

        Account[] accounts = getInsertedAccounts(new String[]{ accWithSameName.Partner_ID__c });
        System.assertEquals(1, accounts.size(), 'Account record not found by specified Partner_ID__c');

        validateAccountFieldsEquality(requests[0], accounts[0], false);

        System.assertEquals(accWithSameName.Partner_ID__c, accounts[0].Partner_ID__c,
            'Values must be equal');
        System.assertEquals(accWithSameName.Other_TextField__c, accounts[0].Other_TextField__c,
            'Values must be equal');
        System.assertEquals(accWithSameName.OwnerId, accounts[0].OwnerId,
            'Values must be equal');
        System.assertEquals(accWithSameName.BillingStreet, accounts[0].BillingStreet,
            'Values must be equal');
        System.assertEquals(accWithSameName.BillingCity, accounts[0].BillingCity,
            'Values must be equal');
        System.assertEquals(accWithSameName.BillingState, accounts[0].BillingState,
            'Values must be equal');
        System.assertEquals(accWithSameName.BillingPostalCode, accounts[0].BillingPostalCode,
            'Values must be equal');
        System.assertEquals(accWithSameName.BillingCountry, accounts[0].BillingCountry,
            'Values must be equal');
        System.assertEquals(accWithSameName.Partner_Sign_Up_Date__c, accounts[0].Partner_Sign_Up_Date__c,
            'Values must be equal');
    }

    @isTest
    static void updateRelatedByIdPartnerAccountOnRequestUpdate() {
        String partnerName = 'This is partner name';

        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = partnerName;
        insert request;

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Partner_Request__c record not found');

        Account[] accountsBefore = getInsertedAccounts(new String[]{ requests[0].Partner_ID__c });
        System.assertEquals(1, accountsBefore.size(), 'Account record not found by specified Partner_ID__c');

        accountsBefore[0].Partner_Source__c = 'SOME OTHER VALUE';
        accountsBefore[0].Partner_Type__c = 'SOME OTHER VALUE';
        accountsBefore[0].Partner_ID__c = '0101011';
        accountsBefore[0].Partner_Sign_Up_Date__c = Date.newInstance(1980, 01, 01);
        accountsBefore[0].Other_TextField__c = 'SOME OTHER VALUE';
        accountsBefore[0].OwnerId = UserInfo.getUserId();
        accountsBefore[0].BillingStreet = 'SOME OTHER VALUE #1';
        accountsBefore[0].BillingCity = 'SOME OTHER VALUE #2';
        accountsBefore[0].BillingState = 'SOME OTHER VALUE #3';
        accountsBefore[0].BillingPostalCode = 'SOME OTHER VALUE #4';
        accountsBefore[0].BillingCountry = 'SOME OTHER VALUE #5';

        update accountsBefore;

        requests[0].Partner_Request_Source__c = 'SHOULD BE UPDATED';
        requests[0].Partner_Type__c = 'SHOULD BE UPDATED';
        update requests;

        requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Partner_Request__c record not found');

        Account[] accountsAfter = getInsertedAccounts(new String[]{ accountsBefore[0].Partner_ID__c });
        System.assertEquals(1, accountsAfter.size(), 'Unexpected count of accounts records');

        System.assertEquals(requests[0].Partner_Request_Source__c, accountsAfter[0].Partner_Source__c);
        System.assertEquals(accountsBefore[0].Partner_ID__c, accountsAfter[0].Partner_ID__c,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].Partner_Sign_Up_Date__c, accountsAfter[0].Partner_Sign_Up_Date__c,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].Other_TextField__c, accountsAfter[0].Other_TextField__c,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].OwnerId, accountsAfter[0].OwnerId,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].BillingStreet, accountsAfter[0].BillingStreet,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].BillingCity, accountsAfter[0].BillingCity,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].BillingState, accountsAfter[0].BillingState,
            'This value must persists and not be affected by request update');
        System.assertEquals(accountsBefore[0].BillingPostalCode, accountsAfter[0].BillingPostalCode,
            'This value must persists and not be affected by request update');
    }

    @isTest
    static void updateRelatedByNamePartnerAccountOnRequestUpdate() {
        string partnerName = 'Partner with same name';
        test.startTest();
        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = partnerName;
        insert request;
        test.stopTest();
        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Partner_Request__c record not found');
        Account[] createdAccounts = getInsertedAccounts(new String[]{ requests[0].Partner_ID__c });
        delete createdAccounts;

        Account accountWithSameName = new Account();
        accountWithSameName.Name = partnerName;
        accountWithSameName.Type = 'Partner';
        accountWithSameName.Partner_ID__c = '0101010101';
        accountWithSameName.Partner_Source__c = 'National Accounts';
        accountWithSameName.Partner_Type__c = 'Franchisor';

        insert accountWithSameName;

        request.DSR_USER__c = UserInfo.getUserId();
        update request;

        Account[] accountsAfter = getInsertedAccounts(new String[] { accountWithSameName.Partner_ID__c });
        System.assertEquals(1, accountsAfter.size(), 'Unexpected count of accounts records');

        System.assertEquals('Direct Sales Referral', accountsAfter[0].Partner_Source__c,
            'Values must be equal due request has DSR_USER__c setted');

        /*System.assertEquals(accountWithSameName.Partner_Type__c, accountsAfter[0].Partner_Type__c,
            'Values must be equal due Partner_Type__c equals to Franchisor');*/

        System.assertEquals(accountWithSameName.Partner_ID__c, accountsAfter[0].Partner_ID__c,
            'Values must be equal');
    }

    @isTest
    static void createAccountOnRequestUpdate() {
        Partner_Request__c request = new Partner_Request__c();
        test.startTest();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = 'Some partner name';
        insert request;

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Partner_Request__c record not found');
        Account[] createdAccounts = getInsertedAccounts(new String[]{ requests[0].Partner_ID__c });
        test.stopTest();
        delete createdAccounts;
        request.DSR_USER__c = UserInfo.getUserId();
        update request;

        Account[] accountsAfter = getInsertedAccounts(new String[] { requests[0].Partner_ID__c });
        System.assertEquals(1, accountsAfter.size(), 'Account be created must, but found not');

        validateAccountFieldsEquality(requests[0], accountsAfter[0], true);

        System.assertEquals(request.DSR_USER__c, accountsAfter[0].Referring_DSR__c,
            'Values must be equal');

        System.assertEquals(requests[0].Partner_Type__c, accountsAfter[0].Partner_Type__c,
            'Values must be equal');

        Contact[] contacts = getInsertedContacts(accountsAfter[0].Id);
        System.assertEquals(1, contacts.size(), 'Contact record was not found');
        validateContactFieldsEquality(requests[0], contacts[0]);
    }

    @isTest
    static void duplicateAccountsWillBeDiscovered() {
        String partnerName = 'Partner With Same Name';
        String country = 'United States';
        String postalCode = '123456';
        String state = 'Alaska';
        String city = 'Juneau';
        String street = 'Lenina street, bld. 1';
        String emailDomain = 'fake.tld';

        Account accWithSameName = new Account();
        accWithSameName.Name = partnerName;
        accWithSameName.Type = 'Partner';
        accWithSameName.Partner_ID__c = '1';
        accWithSameName.Contact_Email__c = 'test@test.tld';

        Account accWithSameBillingAddr = new Account();
        accWithSameBillingAddr.Name = 'Some other name #1';
        accWithSameBillingAddr.BillingCountry = country;
        accWithSameBillingAddr.BillingPostalCode = postalCode;
        accWithSameBillingAddr.BillingState = state;
        accWithSameBillingAddr.BillingCity = city;
        accWithSameBillingAddr.BillingStreet = street + '1234';
        accWithSameBillingAddr.Type = 'Partner';
        accWithSameBillingAddr.Partner_ID__c = '2';
        accWithSameBillingAddr.Contact_Email__c = 'test@test.tld';

        Account accWithContactWithSameEmail = new Account();
        accWithContactWithSameEmail.Name = 'Some other name #2';
        accWithContactWithSameEmail.Type = 'Partner';
        accWithContactWithSameEmail.Partner_ID__c = '3';
        accWithContactWithSameEmail.Contact_Email__c = 'test@fake.tld';

        Account accWithContactWithSameMailingAddress = new Account();
        accWithContactWithSameMailingAddress.Name = 'Some other name #3';
        accWithContactWithSameMailingAddress.Type = 'Partner';
        accWithContactWithSameMailingAddress.Partner_ID__c = '4';
        accWithContactWithSameMailingAddress.Contact_Email__c = 'test@test.tld';

        Account[] accToInsert = new Account[]
        {
            accWithSameName, accWithSameBillingAddr, accWithContactWithSameEmail, accWithContactWithSameMailingAddress
        };

        insert accToInsert;

        Contact contactWithSameEmail = new Contact();
        contactWithSameEmail.AccountId = accWithContactWithSameEmail.Id;
        contactWithSameEmail.Email = 'employee1@' + emailDomain;
        contactWithSameEmail.LastName = 'Doe';

        Contact contactWithSameAddress = new Contact();
        contactWithSameAddress.AccountId = accWithContactWithSameMailingAddress.Id;
        contactWithSameAddress.MailingCountry = country;
        contactWithSameAddress.MailingPostalCode = postalCode;
        contactWithSameAddress.MailingState = state;
        contactWithSameAddress.MailingCity = city;
        contactWithSameAddress.MailingStreet = street + '5678';
        contactWithSameAddress.LastName = 'Doe';

        insert new Contact[] { contactWithSameEmail, contactWithSameAddress };

        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = partnerName;
        request.Partner_Country__c = country;
        request.Partner_Zip__c = postalCode;
        request.Partner_State__c = state;
        request.Partner_City__c = city;
        request.Partner_Address1__c = street;
        request.Partner_Address2__c = '--';
        request.Partner_Email_Address__c = 'employee2@' + emailDomain;

        insert request;

        Account[] accounts = getInsertedAccounts(new String[] { '1', '2', '3', '4' });
        System.assertEquals(accToInsert.size(), accounts.size(), 'Unexpected count of Account records found');

        system.debug(accounts);

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Unexpected count of Partner_Request__c found');
        System.assert(String.IsNotBlank(requests[0].FoundDuplicateAccountIds__c), 'Field should not be null');

        Map<Id, String> idToAccDescription = new Map<Id, String>
        {
            accWithSameName.Id => 'Account with same name',
            accWithSameBillingAddr.Id => 'Account with same billing address',
            accWithContactWithSameEmail.Id => 'Account with related contact with same email domain',
            accWithContactWithSameMailingAddress.Id => 'Account with related contact with same mailing address'
        };

        for (Id accToProbeId : idToAccDescription.keySet()) {
            //for (Account accEntry : accounts) {
                //System.assert(String.IsNotBlank(accEntry.FoundDuplicateAccountIds__c), 'Field should not be null');
                //System.assert(accEntry.FoundDuplicateAccountIds__c.contains(accToProbeId),
                    //'Account after update does not contains id for ' + idToAccDescription.get(accToProbeId));
            //}
            System.assert(requests[0].FoundDuplicateAccountIds__c.contains(accToProbeId),
                'Partner_Request__c doesnt contains link to an ' + idToAccDescription.get(accToProbeId));
        }
    }

    @isTest
    static void accountWillCreatedAndRecognizedAsDuplicated() {
        String country = 'United States';
        String postalCode = '123456';
        String state = 'Alaska';
        String city = 'Juneau';
        String street = 'Lenina street, bld. 1';

        Account accWithSameAddress = new Account();
        accWithSameAddress.Name = 'Partner Name #1';
        accWithSameAddress.Type = 'Partner';
        accWithSameAddress.Partner_ID__c = '1';
        accWithSameAddress.BillingCountry = country;
        accWithSameAddress.BillingPostalCode = postalCode;
        accWithSameAddress.BillingState = state;
        accWithSameAddress.BillingCity = city;
        accWithSameAddress.BillingStreet = street;
        accWithSameAddress.Contact_Email__c = 'johnny@fake-org.tld';

        insert accWithSameAddress;

        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = 'Partner Name #2';
        request.Partner_Country__c = country;
        request.Partner_Zip__c = postalCode;
        request.Partner_State__c = state;
        request.Partner_City__c = city;
        request.Partner_Address1__c = street;
        request.Partner_Address2__c = null;

        insert request;

        Partner_Request__c[] requests = getInsertedRequests();
        System.assertEquals(1, requests.size(), 'Unexpected count of Partner_Request__c records');

        Account[] accounts = getInsertedAccounts(new String[] { requests[0].Partner_ID__c, accWithSameAddress.Partner_ID__c });
        System.assertEquals(2, accounts.size(), 'Unexpected count of Account records');

        System.assert(String.IsNotBlank(requests[0].FoundDuplicateAccountIds__c),
            'Partner_Request__c.FoundDuplicateAccountIds__c must not be empty');

        System.assert(requests[0].FoundDuplicateAccountIds__c.contains(accWithSameAddress.Id),
            'Required account Id not found in the Partner_Request__c.FoundDuplicateAccountIds__c');

        //for (Account entry : accounts) {
            //System.assert(String.IsNotBlank(entry.FoundDuplicateAccountIds__c), 'Required field on the Account is empty');
            //System.assert(entry.FoundDuplicateAccountIds__c.contains(entry.Id), 'Field doesnt contain required value');
        //}
    }

    @isTest
    static void rcPartnerSyncUserShouldNotUpdateAccount() {
        String partnerName = 'Partner With Same Name';
        String partnerStatus = 'Active';

        Account accWithSameName = new Account();
        accWithSameName.Name = partnerName;
        accWithSameName.Type = 'Partner';
        accWithSameName.Partner_ID__c = '1';
        accWithSameName.PartnerStatus__c = partnerStatus;
        insert accWithSameName;

        Partner_Request__c request = new Partner_Request__c();
        fillPartnerRequestWithSampleData(request);
        request.Partner_Company_Name__c = partnerName;
        insert request;

        User[] rcPartnerUser = [SELECT Id FROM User WHERE Id = :RCPARTNER_USER_ID];
        System.assert(rcPartnerUser.size() == 1, 'RCPARTNER Sync User was not found');

        System.runAs(rcPartnerUser[0]) {
            request.No_of_Employees__c = '250-999';
            update request;
        }

        Account[] accToVerify = [
            SELECT PartnerStatus__c
            FROM Account
            WHERE Id = :accWithSameName.Id];

        System.assertEquals(partnerStatus, accToVerify[0].PartnerStatus__c, 'Field should not be updated');
    }

    static void fillPartnerRequestWithSampleData(Partner_Request__c request) {
        request.Current_Telephone_System_Solution_s__c = 'Premise-Based VOIP Systems';
        request.Partner_Currently_resell__c = 'Polycom';
        request.Partner_Cisco_Reseller__c = 'No';
        request.How_did_you_hear_about_the_RC_Part_Prog__c = 'GOOGLE';
        request.Partner_Average_Customer_Size__c = '9-20';
        request.Partner_Additional_Information__c = 'Additional Information';
        request.Partner_Country__c = 'United States';
        request.Partner_State__c = 'FLORIDA';
        request.Partner_Address1__c = '307 Robin Rd';
        request.Partner_Address2__c = 'round';
        request.Partner_City__c = 'Lakeland';
        request.Partner_Zip__c = '33803';
        request.Partner_Company_Name__c = 'Integral Technologies';
        request.Partner_Phone__c = '5555556';
        request.Partner_Mobile__c = '5555555';
        request.Partner_Email_Address__c = 'charles@fake-org.tld';
        request.Partner_Description_of_Your_Business__c = 'IT Consulting;Telecommunications Consulting;';

        request.Sales_Model__c = 'Simple';
        request.External_SID__c = 'NONE';
        request.Which_verticals_do_you_sell_to_most__c = 'NONE';
        request.Partner_Currently_Resell_Other__c = 'NONE';
        request.Customer_ready_to_place_an_order_now__c = 'NONE';
        request.How_d_you_like_us_to_follow_up_with_you__c = 'NONE';
        request.Partner_Best_Contact_Time__c = 'At lunch';
        request.Closest_Metro_Area__c = 'NONE';
        request.Certifications__c = 'NONE';
        request.Certifications_Other__c = 'NONE';
        request.Partner_First_Name__c = 'Charles';
        request.Partner_Last_Name__c = 'Johnson';
        request.Partner_Title__c = 'Mr';
        request.No_of_Employees__c = '10';
        request.AFN__c = 'NONE';
        request.AD__c = 'Yes';
        request.Company_size_typically_sell_to__c = 'NONE';
        request.Annual_Gross_Revenue__c = 'NONE';
    }

    static Partner_Request__c[] getInsertedRequests() {
        return [
            SELECT Current_Telephone_System_Solution_s__c, Partner_Currently_resell__c, Partner_Cisco_Reseller__c,
                How_did_you_hear_about_the_RC_Part_Prog__c, Partner_Average_Customer_Size__c,
                Partner_Additional_Information__c, Partner_Country__c, Partner_State__c,
                Partner_Address1__c, Partner_Address2__c, Partner_City__c, Partner_Zip__c,
                Partner_Company_Name__c, Partner_Phone__c, Partner_Email_Address__c,
                Partner_Description_of_Your_Business__c, Sales_Model__c, External_SID__c,
                Which_verticals_do_you_sell_to_most__c, Partner_Currently_Resell_Other__c,
                Customer_ready_to_place_an_order_now__c, How_d_you_like_us_to_follow_up_with_you__c,
                Partner_Best_Contact_Time__c, Closest_Metro_Area__c, Certifications__c,
                Certifications_Other__c, Partner_First_Name__c, Partner_Last_Name__c,
                No_of_Employees__c, AFN__c, AD__c, Company_size_typically_sell_to__c,
                Annual_Gross_Revenue__c, Partner_Mobile__c, Partner_ID__c, Partner_Title__c,
                Reseller_Partner_Type__c, Partner_Type__c, DSR_USER__c, Partner_Request_Source__c,
                FoundDuplicateAccountIds__c
            FROM Partner_Request__c
        ];
    }

    static Account[] getInsertedAccounts(String[] partnerIds) {
        return [
            SELECT Partner_Currently_resell__c, Partner_Cisco_Reseller__c,
                How_did_you_hear_about_the_RC_Part_Prog__c, Partner_Average_Customer_Size__c,
                Partner_Additional_Information__c, PartnerStatus__c, Name, Partner_Country__c,
                Partner_State__c, Partner_Address1__c, Partner_Address2__c, Partner_City__c,
                Partner_Zip__c, Partner_Company_Name__c, Partner_ID__c, Phone, Other_TextField__c,
                Partner_Description_of_Your_Business__c, OwnerID, Type, Partner_Sign_Up_Date__c,
                Signup_Link__c, Co_Branded_Funnel_Link__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                Sales_Model__c, External_SID__c, Which_verticals_do_you_sell_to_most__c,
                Partner_Currently_Resell_Other__c, Customer_ready_to_place_an_order_now__c,
                How_d_you_like_us_to_follow_up_with_you__c, Partner_Best_Contact_Time__c,
                Closest_Metro_Area__c, Certifications__c, Certifications_Other__c, Contact_FName__c,
                Contact_LName__c, Contact_Email__c, Contact_Phone__c,
                Dist_Dealer__c, Master_Distributor_Agent__c, Company_size_typically_sell_to__c,
                Annual_Gross_Revenue__c, Partner_Source__c, Partner_Type__c, Referring_DSR__c,
                FoundDuplicateAccountIds__c
            FROM Account
            WHERE Partner_ID__c IN :partnerIds
        ];
    }

    static Contact[] getInsertedContacts(Id accountId) {
        return [
            SELECT Firstname, Lastname, Phone, MobilePhone, Email, MailingpostalCode,
                MailingCity, MailingState, MailingCountry, MailingStreet, Title, Company__c
            FROM Contact
            WHERE AccountId = :accountId
        ];
    }

    static void validateAccountFieldsEquality(Partner_Request__c request, Account acc, Boolean onlyForNewAccounts) {
        //System.assertEquals(request.Current_Telephone_System_Solution_s__c,
            //acc.Current_Telephone_System_Solution_s__c,'Values must be equal');
        System.assertEquals(request.Partner_Currently_resell__c,
            acc.Partner_Currently_resell__c, 'Values must be equal');
        System.assertEquals(request.Partner_Cisco_Reseller__c ,
            acc.Partner_Cisco_Reseller__c, 'Values must be equal');
        System.assertEquals(request.How_did_you_hear_about_the_RC_Part_Prog__c,
            acc.How_did_you_hear_about_the_RC_Part_Prog__c, 'Values must be equal');
        System.assertEquals(request.Partner_Average_Customer_Size__c,
            acc.Partner_Average_Customer_Size__c, 'Values must be equal');
        System.assertEquals(request.Partner_Additional_Information__c,
            acc.Partner_Additional_Information__c, 'Values must be equal');

        System.assertEquals('New', acc.PartnerStatus__c, 'PartnerStatus__c must be equal to New');

        System.assertEquals(request.Partner_Company_Name__c, acc.Name, 'Values must be equal');
        System.assertEquals(request.Partner_Country__c, acc.Partner_Country__c, 'Values must be equal');
        System.assertEquals(request.Partner_State__c, acc.Partner_State__c, 'Values must be equal');
        System.assertEquals(request.Partner_Address1__c, acc.Partner_Address1__c, 'Values must be equal');
        System.assertEquals(request.Partner_Address2__c, acc.Partner_Address2__c, 'Values must be equal');
        System.assertEquals(request.Partner_City__c, acc.Partner_City__c, 'Values must be equal');
        System.assertEquals(request.Partner_Zip__c, acc.Partner_Zip__c, 'Values must be equal');
        System.assertEquals(request.Partner_Company_Name__c , acc.Partner_Company_Name__c, 'Values must be equal');
        System.assertEquals(request.Partner_Phone__c, acc.Phone, 'Values must be equal');

        System.assertEquals(request.Partner_Description_of_Your_Business__c,
            acc.Partner_Description_of_Your_Business__c, 'Values must be equal');

        System.assertEquals(acc.Master_Distributor_Agent__c,
            'Yes'.equalsIgnoreCase(request.AD__c),
            'Master_Distributor_Agent__c depends on value of an AD__c field. True -> Yes, false - > No');

        System.assertEquals('Partner', acc.Type, 'Type of the newly created Account must be Partner');

        System.assertEquals(request.Which_verticals_do_you_sell_to_most__c,
            acc.Which_verticals_do_you_sell_to_most__c, 'Values must be equal');
        System.assertEquals(request.Partner_Currently_Resell_Other__c,
            acc.Partner_Currently_Resell_Other__c, 'Values must be equal');
        System.assertEquals(request.Customer_ready_to_place_an_order_now__c,
            acc.Customer_ready_to_place_an_order_now__c, 'Values must be equal');
        System.assertEquals(request.How_d_you_like_us_to_follow_up_with_you__c,
            acc.How_d_you_like_us_to_follow_up_with_you__c, 'Values must be equal');
        System.assertEquals(request.Partner_Best_Contact_Time__c,
            acc.Partner_Best_Contact_Time__c, 'Values must be equal');
        System.assertEquals(request.Company_size_typically_sell_to__c,
            acc.Company_size_typically_sell_to__c, 'Values must be equal');

        System.assertEquals(request.Closest_Metro_Area__c, acc.Closest_Metro_Area__c, 'Values must be equal');
        System.assertEquals(request.Certifications__c, acc.Certifications__c, 'Values must be equal');
        System.assertEquals(request.Certifications_Other__c, acc.Certifications_Other__c, 'Values must be equal');
        System.assertEquals(request.Partner_First_Name__c, acc.Contact_FName__c, 'Values must be equal');
        System.assertEquals(request.Partner_Last_Name__c, acc.Contact_LName__c, 'Values must be equal');
        System.assertEquals(request.Partner_Email_Address__c, acc.Contact_Email__c, 'Values must be equal');
        System.assertEquals(request.Partner_Phone__c, acc.Contact_Phone__c, 'Values must be equal');
        System.assertEquals(request.AFN__c, acc.Dist_Dealer__c, 'Values must be equal');
        System.assertEquals(request.Annual_Gross_Revenue__c , acc.Annual_Gross_Revenue__c, 'Values must be equal');

        if (onlyForNewAccounts) {
            System.assertEquals(request.Partner_ID__c, acc.Partner_ID__c, 'Values must be equal');

            System.assertEquals(RCPARTNER_USER_ID, acc.OwnerID,
                'OwnerID of newly created Account must be equal to specified value');

            System.assertEquals(Date.today(), acc.Partner_Sign_Up_Date__c,
                'Partner_Sign_Up_Date__c must be equal to current date');

            System.assertEquals(request.Partner_Address1__c, acc.BillingStreet, 'Values must be equal');
            System.assertEquals(request.Partner_City__c, acc.BillingCity, 'Values must be equal');
            System.assertEquals(request.Partner_State__c, acc.BillingState, 'Values must be equal');
            System.assertEquals(request.Partner_Zip__c, acc.BillingPostalCode, 'Values must be equal');
            System.assertEquals(request.Partner_Country__c, acc.BillingCountry, 'Values must be equal');
            System.assertEquals(request.Sales_Model__c, acc.Sales_Model__c, 'Values must be equal');
            System.assertEquals(request.External_SID__c, acc.External_SID__c, 'Values must be equal');

            System.assertEquals(request.Partner_Email_Address__c, acc.Other_TextField__c, 'Values must be equal');
        }
    }

    static void validateContactFieldsEquality(Partner_Request__c request, Contact cont) {
        System.assertEquals(request.Partner_First_Name__c, cont.Firstname, 'Values must be equals');
        System.assertEquals(request.Partner_Last_Name__c, cont.Lastname, 'Values must be equals');
        System.assertEquals(request.Partner_Phone__c, cont.Phone);
        System.assertEquals(request.Partner_Mobile__c, cont.MobilePhone);
        System.assertEquals(request.Partner_Email_Address__c, cont.Email);
        System.assertEquals(request.Partner_Zip__c, cont.MailingpostalCode);
        System.assertEquals(request.Partner_City__c, cont.MailingCity);
        System.assertEquals(request.Partner_State__c, cont.MailingState);
        System.assertEquals(request.Partner_Country__c, cont.MailingCountry);
        System.assertEquals(request.Partner_Address1__c, cont.MailingStreet);
        System.assertEquals(request.Partner_Title__c, cont.Title);
        System.assertEquals(request.Partner_Company_Name__c, cont.Company__c);
    }
}
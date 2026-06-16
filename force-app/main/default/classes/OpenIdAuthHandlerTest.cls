@isTest
public with sharing class OpenIdAuthHandlerTest {
    private static String Setting;
    @testSetup
    private static void AddTestData() {
        Account acc = new Account (
            Name = 'For_test',
            RC_User_ID__c = '1212'
        );
        insert acc;

        String email = 'setupTestUser@maul.com';
        String fname = 'setup';
        String lname = 'for test';
        String encoding = 'UTF-8';
        String locale = 'en_US';

        List<Contact> conts = new  List<Contact>();

        Contact contactForExistingUser = new Contact(
            FirstName = 'SETUP',
            LastName = 'FOR TESTS',
            AccountId = acc.Id,
            Email = email
        );
        conts.Add(contactForExistingUser);

        Contact existsContact_RC_DEFAULT = new Contact(
            FirstName = 'EXISTING',
            LastName = 'CONTACT',
            AccountId = acc.Id,
            Email = 'contact_exists@mail.com'
        );
        conts.Add(existsContact_RC_DEFAULT);

        Contact existsContact_RC_Admin = new Contact(
            FirstName = 'RC',
            LastName = 'ADMIN',
            AccountId = acc.Id,
            Email = 'RC_ADMIN_USER@mail.com'
        );
        conts.Add(existsContact_RC_Admin);

        Contact existsContact_RC_USER = new Contact(
            FirstName = 'RC',
            LastName = 'USER',
            AccountId = acc.Id,
            Email = 'RC_USER@lol.com'
        );
        conts.Add(existsContact_RC_USER);

        Contact existsContact_RC_Moderator = new Contact(
            FirstName = 'RC',
            LastName = 'MOBERATOR',
            AccountId = acc.Id,
            Email = 'RC_MOBERATOR@lol.com'
        );
        conts.Add(existsContact_RC_Moderator);

        insert conts;

        Schema.DescribeFieldResult roleValuesDes = AccountContactRole.Role.getDescribe();

        List<Schema.PicklistEntry> roleValues = roleValuesDes.getPicklistValues();

        List<AccountContactRole> roles = new List<AccountContactRole>();

        AccountContactRole roleAdmin = new AccountContactRole (
            AccountId = acc.id,
            ContactId = existsContact_RC_Admin.Id,
            Role = roleValues[0].getValue()
        );
        roles.Add(roleAdmin);

        AccountContactRole roleUser = new AccountContactRole (
            AccountId = acc.id,
            ContactId = existsContact_RC_USER.Id,
            Role = roleValues[1].getValue()
        );
        roles.Add(roleUser);

        AccountContactRole roleModer = new AccountContactRole (
            AccountId = acc.id,
            ContactId = existsContact_RC_Moderator.Id,
            Role = roleValues[2].getValue()
        );
        roles.Add(roleModer);

        insert roles;

        List<Profile> profiles = [
            SELECT Id, Name
            FROM Profile
        ];

        for (Integer i = 0; i < 3; i++) {
            Setting += profiles[i].Name + '#=#' + roleValues[i].getValue();
        }

        Profile communityProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'RC Guest User'
        ];

        User u = new User (
            FirstName = fname,
            LastName = lname,
            Email = email,
            CommunityNickname = email,
            ContactId = contactForExistingUser.Id,
            EmailEncodingKey = encoding,
            LocaleSidKey  = locale,
            TimeZoneSidKey = 'GMT',
            Alias = 'steupped',
            Username = email,
            ProfileId = communityProfile.Id,
            LanguageLocaleKey = locale
        );
        insert u;
    }

    @isTest
    private static void createUserWithNormalDataAndNewAccountTest() {
        OpenIdAuthHandler handler = new OpenIdAuthHandler();

        String identifier = '1111111111111';
        String fname ='';
        String lname ='';
        String flname =  lname + fname;
        String email = 'insert_testuser@example.org';
        String providerName = 'Open ID Connect';
        String link = null;
        String userName = null;
        String locale = 'en_US';
        String provider = null;
        String siteLoginUrl = null;
        String accId = '4324290348';

        String uniqueUserName = identifier + '.' + email;
        String futureUserAlias = email.subString(0,8);

        Map<String, String> infoMap = new Map<String, String> {
            'LanguageLocalKey' => 'de-DE',
            'useAdditionalInfo' => 'true',
            'accountId' => accId
        };

        Auth.UserData sampleData = new Auth.UserData(
            identifier,
            fname,
            lname,
            flname,
            email,
            link,
            userName,
            locale,
            provider,
            siteLoginUrl,
            infoMap
        );

        User u = handler.createUser(null, sampleData);

        System.assertEquals(uniqueUserName, u.userName);
        System.assertEquals(email, u.email);
        System.assertEquals(email, u.lastName);
        System.assertEquals('', u.firstName);
        System.assertEquals(futureUserAlias, u.alias);
        System.assertEquals('en_US', u.LocaleSidKey);
        List<Account> acc= [
            SELECT Name
            FROM Account
            WHERE RC_User_ID__c = :accId
        ];

        System.assertEquals(1, acc.size(), 'No account was created');
    }

    @isTest
    private static void updateUserWithNormalDataAndNewPermissionSetAssignTest() {
        OpenIdAuthHandler handler = new OpenIdAuthHandler();

        String identifier = '1111111111111';
        String fname ='';
        String lname ='';
        String flname =  lname + fname;
        String email = 'insert_testuser@example.org';
        String providerName = 'Open ID Connect';
        String link = null;
        String userName = null;
        String locale = null;
        String provider = null;
        String siteLoginUrl = null;

        String uniqueUserName = identifier + email;
        String futureUserAlias = email.subString(0,8);
        String accId = '1212';

        Map<String, String> infoMap = new Map<String, String> {
            'language' => 'en-En',
            'accountId' => accId,
            'useAdditionalInfo' => 'true'
        };

        Auth.UserData sampleData = new Auth.UserData(
            identifier,
            fname,
            lname,
            flname,
            email,
            link,
            userName,
            locale,
            provider,
            siteLoginUrl,
            infoMap
        );

        User u = [
            SELECT Id, firstName, LastName, Alias, Email, ContactId, UserName
            FROM User
            WHERE Profile.Name = 'RC Guest User'
            AND Alias = 'steupped'
            LIMIT 1
        ];
        String uid = u.id;

        sampleData.firstName = 'testNewFirst';
        sampleData.lastName = 'testNewLast';
        sampleData.email = 'updated_testuser@example.org';

        String errorText;
        try {
            handler.updateUser(uid, null, sampleData);
        } catch (Exception e){
            errorText = generateErrorMessage('UPDATE USER: ', e);
        }
        System.assertEquals(errorText, null, 'UPDATE USER ERROR: ' + errorText);

        User updatedUser = [
            SELECT UserName, Email, FirstName, LastName, Alias
            FROM User
            WHERE Id = :uid];

        System.assertEquals(u.userName, updatedUser.userName);
        System.assertEquals(sampleData.email, updatedUser.email);
        System.assertEquals(sampleData.lastName, updatedUser.lastName);
        System.assertEquals(sampleData.firstName, updatedUser.firstName);
        System.assertEquals(u.Alias, updatedUser.Alias);

        List<Account> acc= [
            SELECT Name
            FROM Account
            WHERE RC_User_ID__c = :accId
        ];

        System.assertEquals(1, acc.size(), 'Incorrect account number');
    }

    @isTest
    private static void errorWhenAddionalInfoNotReceivedTest() {
        OpenIdAuthHandler handler = new OpenIdAuthHandler();
        String identifier = '1111111111111';
        String fname ='';
        String lname ='';
        String flname =  lname + fname;
        String email = 'insert_testuser@example.org';
        String providerName = 'Open ID Connect';
        String link = null;
        String userName = null;
        String locale = null;
        String provider = null;
        String siteLoginUrl = null;

        String uniqueUserName = identifier + email;
        String futureUserAlias = email.subString(0,8);

        Map<String, String> infoMap = new Map<String, String> {};

        Auth.UserData sampleData = new Auth.UserData(
            identifier,
            fname,
            lname,
            flname,
            email,
            link,
            userName,
            locale,
            provider,
            siteLoginUrl,
            infoMap
        );

        String errorText = null;
        try {
            User u = handler.createUser(null, sampleData);
        } catch (Exception e){
            errorText = generateErrorMessage('Create User', e);
        }
        System.assertNotEquals(errorText, null, errorText);
    }

    @isTest
    private static void createUserForExistingContact() {
        OpenIdAuthHandler handler = new OpenIdAuthHandler();
        String identifier = '333333333333';
        String fname ='';
        String lname ='';
        String flname =  lname + fname;
        String email = 'contact_exists@mail.com';
        String providerName = 'Open ID Connect';
        String link = null;
        String userName = null;
        String locale = null;
        String provider = null;
        String siteLoginUrl = null;

        String uniqueUserName = identifier + email;
        String futureUserAlias = email.subString(0,8);
        String accId = '1212';

        Map<String, String> infoMap = new Map<String, String> {
            'language' => 'en-En',
            'accountId' => accId,
            'useAdditionalInfo' => 'true'
        };

        Auth.UserData sampleData = new Auth.UserData(
            identifier,
            fname,
            lname,
            flname,
            email,
            link,
            userName,
            locale,
            provider,
            siteLoginUrl,
            infoMap
        );

        String errorText = '';
        try {
            User u = handler.createUser(null, sampleData);
        } catch (Exception e){
            errorText += generateErrorMessage('Create User', e);
        }

        System.assertEquals('', errorText, errorText);
    }

    @isTest
    private static void verifyRoleMatchingMapParsingWithCorrectSettings() {
        String settings = ' Customer Community Login Custom #=# RC Admin, RC general User;'
                        + '    Customer Community Login Plus Custom #=# RC moderator;';

        OpenIdAuthHandler handler = new OpenIdAuthHandler();
        Map<String, String> rolesRouting = handler.getMatchingInfoFromSettingString(settings);

        System.assertEquals('Customer Community Login Custom', rolesRouting.get('RC Admin'));
        System.assertEquals('Customer Community Login Custom', rolesRouting.get('RC general User'));
        System.assertEquals('Customer Community Login Plus Custom', rolesRouting.get('RC moderator'));
    }

    @isTest
    private static void verifyRoleMatchingMapParsingWithErrorInSettings() {
        String settings = ' Customer Community Login Custom #= RC Admin, RC general User;'
            + '    Customer Community Login Plus Custom #=# RC moderator;';

        OpenIdAuthHandler handler = new OpenIdAuthHandler();
        Map<String, String> rolesRouting = handler.getMatchingInfoFromSettingString(settings);

        System.assertEquals(null, rolesRouting.get('RC Admin'));
        System.assertEquals(null, rolesRouting.get('RC general User'));
        System.assertEquals('Customer Community Login Plus Custom', rolesRouting.get('RC moderator'));
    }

    private static String generateErrorMessage(String prefix, Exception e) {
        return prefix + ' ' + e.getMessage() + ' ###### ' + e.getStackTraceString();
    }
}
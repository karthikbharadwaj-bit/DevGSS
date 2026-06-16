@isTest
class Test_NdaPdfPreviewControllerExtension {

    @isTest
    static void testNoSigantoryContactRoleValidation() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();

        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

        String error = extension.getError();

        System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_NO_SIGNATORY_ROLE,
            error,
            'Wrong error message for not existing sigantory contact role validation');
    }

    @isTest
    static void testEmptyBrandValidation() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .create()
            .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'Signatory'
                })
            .create()
            .getRecord();

        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

        String error = extension.getError();

        System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_EMPTY_BRAND,
            error,
            'Wrong error message for empty brand validation');
    }

    @isTest
    static void testBillingCountryNotPopulatedForRcEuValidation() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_Brand__c => 'RingCentral EU'
            })
            .create()
            .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'Signatory'
                })
            .create()
            .getRecord();

        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

        String error = extension.getError();

        System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_BLANK_BILLING_COUNTRY,
            error,
            'Wrong error message for empty billing country validation');
    }

    @isTest
    static void testBillingCountryNotInPdfList() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.RC_Brand__c => 'RingCentral EU',
            Account.BillingCountry => 'France'
        })
        .create()
        .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'Signatory'
                })
            .create()
            .getRecord();

        new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'Germany'
            })
            .create()
            .getRecord();

    ApexPages.StandardController controller = new ApexPages.standardController(acc);
    NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

    String error = extension.getError();

    System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_BILLING_COUNTRY_NOT_IN_LIST,
        error,
        'Wrong error message for quote templates billing country validation');
    }

    @isTest
    static void testWrongBillingCountryNotInPdfList() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.RC_Brand__c => 'RingCentral EU',
            Account.BillingCountry => 'Australia'
        })
        .create()
        .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'Signatory'
                })
            .create()
            .getRecord();

        new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'Germany'
            })
            .create()
            .getRecord();

    ApexPages.StandardController controller = new ApexPages.standardController(acc);
    NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

    String error = extension.getError();

    System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_BILLING_COUNTRY_NOT_IN_LIST,
        error,
        'Wrong error message for quote templates billing country validation');
    }

    @isTest
    static void testBrandNotInRCBrandList() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.RC_Brand__c => 'BT Business'
            })
            .create()
            .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
            new Map<SObjectField, Object>{
                AccountContactRole.AccountId => acc.Id,
                AccountContactRole.ContactId => con.Id,
                AccountContactRole.IsPrimary => true,
                AccountContactRole.Role => 'Signatory'
            })
            .create()
            .getRecord();

        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

        String error = extension.getError();

        System.assertEquals(NdaPdfPreviewControllerExtension.ERROR_RC_BRAND_NOT_IN_LIST,
            error,
            'Wrong error message for RC Brand Not in List validation');
    }

    @isTest
    static void testNoValidations() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.RC_Brand__c => 'RingCentral EU',
            Account.BillingCountry => 'France'
        })
        .create()
        .getRecord();


        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.AccountId => acc.Id,
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail('testemail'),
                    Contact.Phone => '1234567897'
                }
            )
            .create()
            .getRecord();

        new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountContactRole.AccountId => acc.Id,
                    AccountContactRole.ContactId => con.Id,
                    AccountContactRole.IsPrimary => true,
                    AccountContactRole.Role => 'Signatory'
                })
            .create()
            .getRecord();

        new SObjectBuilder(RC_Quote_Template__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                RC_Quote_Template__c.ObjectName__c => 'Account',
                RC_Quote_Template__c.Available_For_Billing_Countries__c => 'France',
                RC_Quote_Template__c.Brand__c => RingCentralHelper.BRAND_RINGCENTRAL_EU
            })
            .create()
            .getRecord();

        ApexPages.StandardController controller = new ApexPages.standardController(acc);
        NdaPdfPreviewControllerExtension extension = new NdaPdfPreviewControllerExtension(controller);

        String error = extension.getError();

        System.assert(String.isBlank(error), 'There should be no errors');
    }
}
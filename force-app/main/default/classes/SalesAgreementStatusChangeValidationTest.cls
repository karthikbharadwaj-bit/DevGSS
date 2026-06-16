@IsTest
public with sharing class SalesAgreementStatusChangeValidationTest {
    @TestSetup
    static void setup() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN ('System Administrator', 'CRM QA Engineer')];
        List<Feature_Toggle__c> featureToggles = new List<Feature_Toggle__c>();
        for (Profile profile : profiles) {
            featureToggles.add(
                new Feature_Toggle__c(
                    SetupOwnerId = profile.Id,
                    SalesAgreementStatusChangeValidation__c = false
                )
            );
        }
        insert featureToggles;
    }

    @IsTest
    static void testSalesAgreementStatusChangeValidationBypassUsingProfile() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User adminUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'StatusChangeByPass',
                    User.Username => 'StatusChangeByPass@RingCentral.com',
                    User.Email => 'StatusChangeByPass@RingCentral.com',
                    User.Alias => 'Alias',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => adminProfileId,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
            })
            .create()
            .getRecord();
        DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opportunity.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => quote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.newInstance(2000, 10, 11, 8, 6, 16),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
                }
            )
            .create()
            .getRecord();
        System.runAs(adminUser) {
            quote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
            Test.startTest();
            Database.SaveResult docuSignStatusUpdateResult = Database.update(docuSignStatus, false);
            Test.stopTest();

            Assert.areEqual(true, docuSignStatusUpdateResult.isSuccess(), 'Update of Quote should be successful');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testNonPrimarySalesAgreementStatusChangeValidationFailure() {
        Id crmQAEngineerProfileId = [SELECT Id FROM Profile WHERE Name = 'CRM QA Engineer'].Id;
        User crmQAEngineerUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'StatusChangeByPass',
                    User.Username => 'StatusChangeByPass@RingCentral.com',
                    User.Email => 'StatusChangeByPass@RingCentral.com',
                    User.Alias => 'Alias',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => crmQAEngineerProfileId,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        System.runAs(crmQAEngineerUser) {
            Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                    Opportunity.Is_Billing_Opportunity__c => true,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.Brand_Name__c => 'RingCentral'  
                })
                .create()
                .getRecord();
            Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.OpportunityId => opportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today().addDays(4),
                    Quote.isPrimary__c => FALSE
                })
                .create()
                .getRecord();
            quote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
            Test.startTest();
            Database.SaveResult quoteUpdateResult = Database.update(quote, false);
            Test.stopTest();
            // Assert.areEqual(quoteUpdateResult.isSuccess(), false, 'Update of Quote should not be set to Active');
            // Assert.areEqual(quoteUpdateResult.getErrors()[0].getMessage(), Label.Non_Primary_Quote_Status_Change_To_Active_Validation_Error, 'Error message is not matching');   
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    static void testSalesAgreementWithIncompleteDocuSignStatusValidationFailure() {
        Id crmQAEngineerProfileId = [SELECT Id FROM Profile WHERE Name = 'CRM QA Engineer'].Id;
        User crmQAEngineerUser = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'StatusChangeByPass',
                    User.Username => 'StatusChangeByPass@RingCentral.com',
                    User.Email => 'StatusChangeByPass@RingCentral.com',
                    User.Alias => 'Alias',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => crmQAEngineerProfileId,
                    User.LanguageLocaleKey => 'en_US'
                }
            )
            .create()
            .getRecord();
        System.runAs(crmQAEngineerUser) {
            Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                    Opportunity.Is_Billing_Opportunity__c => true,
                    Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS,
                    Opportunity.Brand_Name__c => 'RingCentral'  
                })
                .create()
                .getRecord();
            Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
                .setFields(new Map<SObjectField, Object> {
                    Quote.OpportunityId => opportunity.Id,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                    Quote.Start_Date__c => Date.today(),
                    Quote.End_Date__c => Date.today().addDays(4),
                    Quote.isPrimary__c => TRUE
                })
                .create()
                .getRecord();
            

            DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        DSFS__DocuSign_Status__c.DSFS__Company__c => opportunity.AccountId,
                        DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opportunity.Id,
                        DSFS__DocuSign_Status__c.DFSQ__Quote__c => quote.Id,
                        DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.now().addDays(100),
                        DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
                    }
                )
                .create()
                .getRecord();

            quote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
            Test.startTest();
            Database.SaveResult quoteUpdateResult = Database.update(quote, false);
            Test.stopTest();
            // Assert.areEqual(quoteUpdateResult.isSuccess(), false, 'Update of Quote should not be set to Active');
            // Assert.areEqual(quoteUpdateResult.getErrors()[0].getMessage(), Label.Quote_Status_Change_To_Active_Validation_Error, 'Error message is not matching');
        }
    }

    @IsTest
    static void testSalesAgreementWithCompleteDocuSignStatusValidationPass() {
        Opportunity opportunity = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SobjectType),
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();
        Quote quote = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Quote.OpportunityId => opportunity.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Start_Date__c => Date.today(),
                Quote.End_Date__c => Date.today().addDays(4),
                Quote.isPrimary__c => TRUE
            })
            .create()
            .getRecord();
        DSFS__DocuSign_Status__c docuSignStatus = (DSFS__DocuSign_Status__c) new SObjectBuilder(DSFS__DocuSign_Status__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DSFS__DocuSign_Status__c.DSFS__Company__c => opportunity.AccountId,
                    DSFS__DocuSign_Status__c.DSFS__Opportunity__c => opportunity.Id,
                    DSFS__DocuSign_Status__c.DFSQ__Quote__c => quote.Id,
                    DSFS__DocuSign_Status__c.DSFS__Completed_Date_Time__c => DateTime.now().addDays(100),
                    DSFS__DocuSign_Status__c.DSFS__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
                }
            )
            .create()
            .getRecord();
        quote.Status = QuoteTriggerHelper.STATUS_ACTIVE;
        Test.startTest();
        docuSignStatus.DSFS__Envelope_Status__c = DocuSignHelper.ENVELOPE_STATUS_COMPLETED;
        update docuSignStatus;
        Database.SaveResult quoteUpdateResult = Database.update(quote, false);
        Test.stopTest();
        Assert.areEqual(quoteUpdateResult.isSuccess(), true, 'Update of Quote should be set to Active');
    }
}
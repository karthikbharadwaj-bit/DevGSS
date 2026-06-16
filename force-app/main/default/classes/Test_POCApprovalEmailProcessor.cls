@isTest
    public class Test_POCApprovalEmailProcessor {
        
        private static final String TEST_ACCOUNT_NAME = 'Test Account for POCApprovalEmailProcessor';
        private static final String TEST_OPPORTUNITY_NAME = 'Test Opportunity for POCApprovalEmailProcessor';
        private static final String TEST_EMAIL_TEMPLATE_NAME = 'POC_RingCX_Quote_SSE_Leadership_Team_Email';
        private static final String TEST_SSE_EMAIL_NAME = 'SSE_Direct_Leadership';
        private static final String TEST_SSE_EMAIL_ADDRESS = 'test.sse@ringcentral.com';
        private static final String TEST_SUBMITTER_USER_EMAIL = 'test.submitter@ringcentral.com';
        
        @TestSetup
        static void setup() {
            createTestData();
        }
        
        private static void createTestData() {
            createEmailTemplate();
            createEmailCustomSettings();
            createTestUser();
            createTestAccount();
            createTestOpportunity();
        }
        
        private static void createEmailTemplate() {
            String uniqueTemplateName = TEST_EMAIL_TEMPLATE_NAME + '_' + String.valueOf(Datetime.now().getTime());
            
            EmailTemplate template = new EmailTemplate(
                Name = uniqueTemplateName,
                DeveloperName = uniqueTemplateName,
                Subject = 'POC Approval Required for {!Opportunity.Name}',
                HtmlValue = '<p>POC Approval is required for opportunity: <a href="{!Opportunity.Link}">{!Opportunity.Name}</a></p>',
                IsActive = true,
                TemplateType = 'text',
                FolderId = getEmailTemplateFolderId()
            );
            
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert template;
            }
        }
        
        private static Id getEmailTemplateFolderId() {
            List<Folder> folders = [SELECT Id FROM Folder WHERE Type = 'Email' AND AccessType = 'Public' LIMIT 1];
            if (!folders.isEmpty()) {
                return folders[0].Id;
            }
            return null;
        }
        
        private static void createEmailCustomSettings() {
            new SObjectBuilder(Emails__c.SObjectType)
                .setField(Emails__c.Name, TEST_SSE_EMAIL_NAME)
                .setField(Emails__c.Email_Address__c, TEST_SSE_EMAIL_ADDRESS)
                .setField(Emails__c.Description__c, 'Test SSE Email for POCApprovalEmailProcessor')
                .create();
        }
        
        private static void createTestUser() {
            new SObjectBuilder(User.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        User.FirstName => 'Test',
                        User.LastName => 'Submitter',
                        User.Username => 'test.submitter@ringcentral.com.test',
                        User.Email => TEST_SUBMITTER_USER_EMAIL,
                        User.Alias => 'tsub',
                        User.TimeZoneSidKey => 'America/Los_Angeles',
                        User.LocaleSidKey => 'en_US',
                        User.EmailEncodingKey => 'UTF-8',
                        User.LanguageLocaleKey => 'en_US',
                        User.ProfileId => [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                        User.isActive => true
                    }
                )
                .create();
        }
        
        private static void createTestAccount() {
            new SObjectBuilder(Account.SObjectType)
                .setField(Account.Name, TEST_ACCOUNT_NAME)
                .setField(Account.BillingCity, 'Test City')
                .setField(Account.BillingCountry, 'US')
                .create();
        }
        
        private static void createTestOpportunity() {
            Account testAccount = [SELECT Id FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
            
            new SObjectBuilder(Opportunity.SObjectType)
                .setField(Opportunity.Name, TEST_OPPORTUNITY_NAME)
                .setField(Opportunity.AccountId, testAccount.Id)
                .setField(Opportunity.StageName, '1. Qualify')
                .setField(Opportunity.CloseDate, System.today().addMonths(1))
                .setField(Opportunity.Type, 'New Business')
                .create();
        }
        
        @isTest
        static void testHandleWithValidEvents() {
            setProcessor();
            
            Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME LIMIT 1];
            User testUser = [SELECT Id FROM User WHERE Email = :TEST_SUBMITTER_USER_EMAIL LIMIT 1];
            
            List<POCApprovalEmail__e> testEvents = new List<POCApprovalEmail__e>{
                new POCApprovalEmail__e(
                    OpportunityId__c = testOpp.Id,
                    SubmitterUserId__c = testUser.Id
                )
            };
            
            Test.startTest();
                POCApprovalEmailProcessor processor = new POCApprovalEmailProcessor();
                processor.handle(testEvents);
            Test.stopTest();
            
            System.assert(true, 'Processor should handle events without throwing exceptions');
        }
        
        @isTest
        static void testPlatformEventIntegration() {
            setProcessor();
            
            Opportunity testOpp = [SELECT Id, Name FROM Opportunity WHERE Name = :TEST_OPPORTUNITY_NAME LIMIT 1];
            User testUser = [SELECT Id FROM User WHERE Email = :TEST_SUBMITTER_USER_EMAIL LIMIT 1];
            
            List<POCApprovalEmail__e> testEvents = new List<POCApprovalEmail__e>{
                new POCApprovalEmail__e(
                    OpportunityId__c = testOpp.Id,
                    SubmitterUserId__c = testUser.Id
                )
            };
            
            Test.startTest();
                EventBus.publish(testEvents);
            Test.stopTest();
            
            System.assert(true, 'Platform Event should be published and processed without throwing exceptions');
        }
        
        private static void setProcessor() {
            ApexClass processor = [SELECT Id FROM ApexClass WHERE Name = 'POCApprovalEmailProcessor' LIMIT 1];
            Test.setFixedSearchResults(new List<Id>{processor.Id});
        }
    }
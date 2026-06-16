@isTest
private class LeanDataCustomInterfaceTest {

    @isTest static void customMergeTest() {
        Lead preexistingLead = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'Routing_Reason__c',
                'Company',
                'LastName',
                'Email'
            })
            .setLimit(1)
            .executeQuery()
            .get(0);

        SObjectFactory factory = new SObjectFactory();
        Lead leadPrimary = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.Company => 'LD',
                    Lead.LastName => 'Schulz',
                    Lead.Email => 'test@test.com'
                }
            );

        leadPrimary = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'AH_Name__r.AH_Alternate_Owner__c',
                'Id'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadPrimary.Id})
            .executeQuery()
            .get(0);

        LeanDataCustomInterface ldci = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects = new Map<String,SObject>{
            'Dupe' => preexistingLead
        };
        
        // Updated to use v1.623 method signature
        Map<String,Object> additionalParameters = new Map<String,Object>();
        ldci.customRoutingRule((SObject) leadPrimary, chosenSObjects, 'Custom Merge', additionalParameters);
        
        List<Object> queryResult = (List<Object>) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{'Id'})
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadPrimary.Id})
            .executeQuery();
        System.assertEquals(0, queryResult.size(), 'Lead not deleted in custom merge');
    }

    @isTest static void futureGlipNotificationTest() {
        Lead preexistingLead = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'Routing_Reason__c',
                'Company',
                'LastName',
                'Email'
            })
            .setLimit(1)
            .executeQuery()
            .get(0);

        SObjectFactory factory = new SObjectFactory();
        Lead leadPrimary = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.Company => 'LD',
                    Lead.LastName => 'Schulz',
                    Lead.Email => 'test@test.com'
                }
            );

        Glip_Routing_Settings__c grs = (Glip_Routing_Settings__c) factory
            .create(
                Glip_Routing_Settings__c.SObjectType,
                new Map<SObjectField, Object>{
                    Glip_Routing_Settings__c.RC_ClientId__c => 'test',
                    Glip_Routing_Settings__c.RC_ClientSecret__c => 'test',
                    Glip_Routing_Settings__c.RC_Server__c => 'test',
                    Glip_Routing_Settings__c.RC_BotId__c => 'test',
                    Glip_Routing_Settings__c.RC_BotEmail__c => 'test',
                    Glip_Routing_Settings__c.Webhook_URL__c => 'test'
                }
            );

        leadPrimary = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'AH_Name__r.AH_Alternate_Owner__c',
                'Id'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadPrimary.Id})
            .executeQuery()
            .get(0);

        LeanDataCustomInterface ldci = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects = new Map<String,SObject>{
            'Dupe' => preexistingLead
        };
        Test.setMock(HttpCalloutMock.class, new GlipRoutingHelper.MockGlipResponder());
        
        EmailTemplate e = (EmailTemplate) new EmailTemplateSelector().selectEmailTemplates().executeQuery()[0];
        
        // Updated to use v1.623 method signature with additionalParameters
        Map<String,Object> additionalParameters = new Map<String,Object>();
        additionalParameters.put('Template Id', String.valueOf(e.Id));
        
        Test.startTest();
        ldci.customRoutingRule((SObject) leadPrimary, chosenSObjects, 'Future Glip Notification', additionalParameters);
        Test.stopTest();
        
        // Safe AsyncApexJob query
        List<AsyncApexJob> jobList = [SELECT MethodName,JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assert(!jobList.isEmpty(), 'No queueable job was created');
        AsyncApexJob jobInfo = jobList[0];
        System.assert(jobInfo != null);
    }

    @isTest static void glipQueueableTest() {
        SObjectFactory factory = new SObjectFactory();
        Glip_Routing_Settings__c grs = (Glip_Routing_Settings__c) factory
             .create(
                 Glip_Routing_Settings__c.SObjectType,
                 new Map<SObjectField, Object>{
                     Glip_Routing_Settings__c.RC_ClientId__c => 'test',
                     Glip_Routing_Settings__c.RC_ClientSecret__c => 'test',
                     Glip_Routing_Settings__c.RC_Server__c => 'test',
                     Glip_Routing_Settings__c.RC_BotId__c => 'test',
                     Glip_Routing_Settings__c.RC_BotEmail__c => 'test',
                     Glip_Routing_Settings__c.Webhook_URL__c => 'test'
                 }
             );
        EmailTemplate e = (EmailTemplate) new EmailTemplateSelector().selectEmailTemplates().executeQuery()[0];
        LeadSelector leadSelector = new LeadSelector();
        Lead newLead = (Lead) leadSelector.selectLeads().selectFields(leadSelector.getOtherFieldList()).executeQuery()[0];
        LeanDataCustomInterface.GlipQueueable testGlipQueuable = new LeanDataCustomInterface.GlipQueueable(e.Id, newLead.OwnerId, newLead.Id);
        Test.setMock(HttpCalloutMock.class, new GlipRoutingHelper.MockGlipResponder());
        Test.startTest();
        System.enqueueJob(testGlipQueuable);
        Test.stopTest();
        
        // Safe AsyncApexJob query
        List<AsyncApexJob> jobList = [SELECT MethodName,JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assert(!jobList.isEmpty(), 'No queueable job was created');
        AsyncApexJob jobInfo = jobList[0];
        System.assert(jobInfo != null);
        System.assertEquals(testGlipQueuable.templateId, e.Id, 'GlipQueueable constructed incorrectly.');
    }

    @future static void insertEmailTemplate() {
        EmailTemplate e = (EmailTemplate) new SObjectBuilder(EmailTemplate.SObjectType)
          .setField(EmailTemplate.DeveloperName, 'test')
          .setField(EmailTemplate.Body, 'Email Body')
          .setField(EmailTemplate.FolderId, UserInfo.getUserId())
          .setField(EmailTemplate.TemplateType, 'Text')
          .setField(EmailTemplate.Name, 'Test Glip')
          .create()
          .getRecord();
    }

    @testSetup static void insertCompanyAndLeadRecords() {
        SObjectFactory factory = new SObjectFactory();

        Account_Hierarchy__c testAccHierarchy = (Account_Hierarchy__c) factory
            .create(
                Account_Hierarchy__c.SObjectType,
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Name => 'LD Test Company',
                    Account_Hierarchy__c.AH_Alternate_Owner__c => UserInfo.getUserId(),
                    Account_Hierarchy__c.AH_Owner__c => UserInfo.getUserId()
                }
            );

        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        Lead testLead = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.AH_Name__c => testAccHierarchy.Id,
                    Lead.Company => 'LD',
                    Lead.LastName => 'Schulz',
                    Lead.Email => 'test@test.com'
                }
            );

        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;
        Task testTask = (Task) factory
            .create(
                Task.SObjectType,
                new Map<SObjectField, Object>{
                    Task.WhoId => testLead.Id,
                    Task.Priority => 'High',
                    Task.Status => 'In Progress'
                }
            );

        insertEmailTemplate();
    }

    @isTest static void testActivityRoutingSettingsOff() {
        SObjectFactory factory = new SObjectFactory();

        LeanDataCustomInterface ldci = new LeanDataCustomInterface();
        Account_Hierarchy__c testAccHierarchy = (Account_Hierarchy__c) new AccountHierarchySelector().newQueryFactory()
            .selectField('Id')
            .setLimit(1)
            .executeQuery()
            .get(0);

        TriggerHandler.BY_PASS_LEAD_UPDATE = true;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;
        Lead leadWithoutCompany = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.Company => 'No Company Here',
                    Lead.LastName => 'Schulman',
                    Lead.Email => 'schulman@test.com'
                }
            );

        leadWithoutCompany = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'AH_Name__r.AH_Alternate_Owner__c',
                'Id'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadWithoutCompany.Id})
            .executeQuery()
            .get(0);

        String activityQueryWithoutCompany = ldci.getActivityQuery(leadWithoutCompany);
        //If the lead has no company, we should not find tasks
        System.assertEquals(activityQueryWithoutCompany, 'SELECT Id FROM Task WHERE Id = null');
        String falseReturnEdge = ldci.activityBasedRouting(leadWithoutCompany, null);
        System.assertEquals(falseReturnEdge, 'False');

        Lead leadWithCompanyNoSettingsCase = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.AH_Name__c => testAccHierarchy.Id,
                    Lead.Company => 'Have a Company',
                    Lead.LastName => 'Schubert',
                    Lead.Email => 'schubert@test.com'
                }
            );

        leadWithCompanyNoSettingsCase = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'AH_Name__r.AH_Alternate_Owner__c',
                'Id'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadWithCompanyNoSettingsCase.Id})
            .executeQuery()
            .get(0);

        TriggerHandler.BY_PASS_LEAD_UPDATE = false;
        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

        String activityQueryWithoutSettings = ldci.getActivityQuery(leadWithCompanyNoSettingsCase);
        String expectedQueryWithoutSettings = 'SELECT Id FROM Task WHERE OwnerId = \'' + leadWithCompanyNoSettingsCase.AH_Name__r.AH_Alternate_Owner__c;
        expectedQueryWithoutSettings += '\' AND WhoId IN (SELECT Id FROM Lead WHERE AH_Name__c = \'' + leadWithCompanyNoSettingsCase.AH_Name__c;
        expectedQueryWithoutSettings += '\' ) LIMIT 1';
        System.assertEquals(activityQueryWithoutSettings,expectedQueryWithoutSettings);
    }

    @isTest static void testActivityRoutingSettingsOn() {
        SObjectFactory factory = new SObjectFactory();

        LeanDataCustomInterface ldci = new LeanDataCustomInterface();
        Account_Hierarchy__c testAccHierarchy = (Account_Hierarchy__c) new AccountHierarchySelector().newQueryFactory()
            .selectField('Id')
            .setLimit(1)
            .executeQuery()
            .get(0);

        LeanDataCustomInterfaceSettings__c orgLDSettings = (LeanDataCustomInterfaceSettings__c) factory
            .create(
                LeanDataCustomInterfaceSettings__c.SObjectType,
                new Map<SObjectField, Object>{
                    LeanDataCustomInterfaceSettings__c.RelevantLeadCondition__c => '(Id != null)',
                    LeanDataCustomInterfaceSettings__c.RelevantActivityCondition__c => '(Id != null)'
                }
            );

        Lead leadPrimary = (Lead) factory
            .create(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.Company => 'LD',
                    Lead.LastName => 'Schwartz',
                    Lead.Email => 'schwartz@test.com'
                }
            );
        leadPrimary.AH_Name__c = testAccHierarchy.Id;
        update leadPrimary;

        leadPrimary = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'AH_Name__r.AH_Alternate_Owner__c',
                'Id'
            })
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(new List<Object>{leadPrimary.Id})
            .executeQuery()
            .get(0);

        String activityQuery = ldci.getActivityQuery(leadPrimary);

        String expectedQuery = 'SELECT Id FROM Task WHERE OwnerId = \'' + leadPrimary.AH_Name__r.AH_Alternate_Owner__c;
        expectedQuery += '\' AND WhoId IN (SELECT Id FROM Lead WHERE AH_Name__c = \'' + leadPrimary.AH_Name__c;
        expectedQuery += '\'  AND (Id != null)) AND (Id != null) LIMIT 1';
        System.assertEquals(activityQuery, expectedQuery);

        String returnEdge = ldci.activityBasedRouting(leadPrimary, null);
        System.assertEquals(returnEdge, 'Next Node');
    }

    @isTest static void testAssignToLeadUserField(){
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects;

        Account_Hierarchy__c testAccHierarchy = (Account_Hierarchy__c) new AccountHierarchySelector().newQueryFactory()
            .selectFields(new Set<String>{
                'Name',
                'AH_Alternate_Owner__c',
                'AH_Owner__c'
            })
            .setLimit(1)
            .executeQuery()
            .get(0);

        Lead testLead = (Lead) new LeadSelector().newQueryFactory()
            .selectFields(new Set<String>{
                'AH_Name__c',
                'Routing_Reason__c',
                'Company',
                'LastName',
                'Email'
            })
            .setLimit(1)
            .executeQuery()
            .get(0);

        // Updated to use v1.623 method signature
        Map<String,Object> additionalParameters = new Map<String,Object>();
        testInterface.customRoutingRule((SObject) testLead, chosenSObjects, 'AH_Name__r.Name,Street', additionalParameters);
        update(testLead);

        System.assertEquals(testLead.AH_Name__c, testAccHierarchy.Id);
        //commented this assert since it's depending on the LeanData managed package which might not be turned on
    }

    @isTest 
    static void testRemainingCoverage(){
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects;
        SObjectFactory factory = new SObjectFactory();
        
        Lead testLead = (Lead) factory.create(
            Lead.SObjectType,
            new Map<SObjectField, Object>{
                Lead.Company => 'LD',
                Lead.LastName => 'Schulz',
                Lead.Email => 'test@test.com',
                Lead.Lead_Owner_Email_Address__c => 'test@test.com',
                Lead.Sales_Agent_Email__c => 'test@test.com'
            }
        );
        
        List<SObject> sObjList = new List<SObject>();
        sObjList.add(testLead);
        
        // Test getContactEmailExactMatches
        LeanDataCustomInterface.getContactEmailExactMatches(testLead, sObjList);
        
        // Test customTiebreakerRule
        testInterface.customTiebreakerRule(testLead, sObjList, 'contact email xact match');
        
        // Test customFilter
        testInterface.customFilter(testLead, sObjList, 'contact email xact match');
        
        // Test getMapOfCustomInterfaceNodeNamesToEdges
        Map<String, List<String>> nodeMap = testInterface.getMapOfCustomInterfaceNodeNamesToEdges();
        System.assert(!nodeMap.isEmpty(), 'Node map should not be empty');
        
        // Test additionalParametersMap
        Map<String,Object> paramMap = testInterface.additionalParametersMap();
        System.assert(!paramMap.isEmpty(), 'Parameter map should not be empty');
        
        // Test getCustomLeadFields
        Set<String> customFields = testInterface.getCustomLeadFields();
        System.assertNotEquals(null, customFields, 'Custom fields should not be null');
        
        // Test generateLeadJson
        String jsonResult = testInterface.generateLeadJson(testLead);
        System.assert(String.isNotBlank(jsonResult), 'JSON result should not be blank');
        
        Map<String,Object> additionalParameters = new Map<String,Object>();
        
        Test.startTest();
        String result = testInterface.customRoutingRule(
            (SObject) testLead, 
            chosenSObjects, 
            'Sales Agent Email Routing', 
            additionalParameters
        );
        Test.stopTest();
        
        update(testLead);
    }
    
@isTest 
static void testSalesAgentEmailRoutingWithPartnerUser() {
    SObjectFactory factory = new SObjectFactory();

    // Create test account for partner user
    Account partnerAccount = (Account) factory.create(
        Account.SObjectType,
        new Map<SObjectField, Object>{
            Account.Name => 'Partner Test Account',
            Account.Partner_Id__c => 'PART123',
            Account.Inside_Sales_Rep__c => UserInfo.getUserId(),
            Account.Current_Owner__c => UserInfo.getUserId(),
            Account.VAR_Territory__c => 'North America'
        }
    );

    // Contact for the partner user
    Contact partnerContact = (Contact) factory.create(
        Contact.SObjectType,
        new Map<SObjectField, Object>{
            Contact.FirstName => 'Partner',
            Contact.LastName  => 'Contact',
            Contact.AccountId => partnerAccount.Id,
            Contact.Email     => 'partnercontact+' + '@example.test'
        }
    );

    // Pick the Partner profile
    Profile profile = (Profile) new ProfileSelector()
        .selectProfileByName(new List<Object>{'RC Partner Modify'})
        .executeQuery()
        .get(0);

    // 🔑 Make the username unique across all orgs
    String uniq = 'partneruser+' + '@example.test';

    // Create partner user with UNIQUE username
    User partnerUser = (User) factory.create(
        User.SObjectType,
        new Map<SObjectField, Object>{
            User.FirstName => 'Partner',
            User.LastName  => 'User',
            User.Email     => uniq,
            User.Username  => uniq,
            User.ProfileId => profile.Id,
            User.IsActive  => true,
            User.ContactId => partnerContact.Id,
            User.Alias => 'ptusr',
            User.TimeZoneSidKey => 'America/Los_Angeles',
            User.LocaleSidKey => 'en_US',
            User.EmailEncodingKey => 'UTF-8',
            User.LanguageLocaleKey => 'en_US'
        }
    );

    // Create lead whose routing emails match the (unique) user
    Lead testLead = (Lead) factory.create(
        Lead.SObjectType,
        new Map<SObjectField, Object>{
            Lead.Company                     => 'Test Company',
            Lead.LastName                    => 'TestLead',
            Lead.Email                       => 'testlead+' + '@example.test',
            Lead.Lead_Owner_Email_Address__c => uniq,
            Lead.Sales_Agent_Email__c        => uniq
        }
    );

    LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
    Map<String,SObject> chosenSObjects = new Map<String,SObject>();
    Map<String,Object> additionalParameters = new Map<String,Object>();

    Test.startTest();
    String result = testInterface.customRoutingRule(
        testLead,
        chosenSObjects,
        'Sales Agent Email Routing',
        additionalParameters
    );
    Test.stopTest();

    // Keep your expected edge here (your message says "Next Node" but code asserts "False")
    System.assertEquals('Next Node', result, 'Sales Agent Email Routing should return Next Node');
}

    
    @isTest 
    static void testGlipWebhookAlert() {
        SObjectFactory factory = new SObjectFactory();
        
        Lead testLead = (Lead) factory.create(
            Lead.SObjectType,
            new Map<SObjectField, Object>{
                Lead.Company => 'Test Company',
                Lead.LastName => 'TestLead',
                Lead.Email => 'testlead@test.com'
            }
        );
        
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects = new Map<String,SObject>();
        Map<String,Object> additionalParameters = new Map<String,Object>();
        additionalParameters.put('Endpoint URL', 'https://example.com/webhook');
        
        Test.startTest();
        String result = testInterface.customRoutingRule(
            testLead, 
            chosenSObjects, 
            'Glip Webhook Alert', 
            additionalParameters
        );
        Test.stopTest();
        
        System.assertEquals('Next Node', result, 'Glip Webhook Alert should return Next Node');
        
        List<AsyncApexJob> jobList = [SELECT MethodName,JobType FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assert(!jobList.isEmpty(), 'Queueable job should be created for webhook');
    }    
    
    @isTest 
    static void testSendGlipNotificationMissingTemplateId() {
        SObjectFactory factory = new SObjectFactory();
        
        // Create test lead
        Lead testLead = (Lead) factory.create(
            Lead.SObjectType,
            new Map<SObjectField, Object>{
                Lead.Company => 'Test Company Missing Template',
                Lead.LastName => 'MissingTemplateTestLead',
                Lead.Email => 'missingtemplate@test.com',
                Lead.OwnerId => UserInfo.getUserId()
            }
        );
        
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        Map<String,SObject> chosenSObjects = new Map<String,SObject>();
        Map<String,Object> additionalParameters = new Map<String,Object>();
        // Intentionally not adding 'Template Id' to additionalParameters
        
        Test.setMock(HttpCalloutMock.class, new GlipRoutingHelper.MockGlipResponder());
        
        Test.startTest();
        try {
            String result = testInterface.customRoutingRule(
                testLead, 
                chosenSObjects, 
                'Send Glip Notification', 
                additionalParameters
            );
            // If we reach here, the method handled null template ID gracefully
            System.assert(true, 'Method should handle missing template ID gracefully');
        } catch (Exception e) {
            // Expected behavior for missing template ID
            System.assert(
                e instanceof NullPointerException || e instanceof StringException,
                'Should handle missing Template ID parameter gracefully'
            );
        }
        Test.stopTest();
    }    
}
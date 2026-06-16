@isTest
public class Test_SEClosedDowngradedEmailAlerts {
    
    @testSetup
    static void setup() { 
        Triggers.switchOff();     
        Profile testOpProfile = [select id from profile where name='CRM Support Engineer'];
        Profile testRepProfile = [select id from profile where name='CRM Support Engineer'];              
         User testManager = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            		User.LastName => 'TestNameManager',
                    User.Username => 'userManager@testorg.com',
                    User.Email => 'userManager@testorg.com',
                	User.emailencodingkey => 'UTF-8',
                    User.Alias => 'uMng',
                    User.Country__c => 'United States',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => testRepProfile.Id,
                    User.LanguageLocaleKey => 'en_US'
        })
        .create()
        .getRecord();
        User getManager = [Select Id,Email from User where name = 'TestNameManager'];       
        User testUserOp = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            		User.LastName => 'TestNameOp',
                    User.Username => 'userOp@testorg.com',
                    User.Email => 'userOp@testorg.com',
                	User.emailencodingkey => 'UTF-8',
                    User.Alias => 'uOp',
                    User.Country__c => 'United States',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => testManager.Id,
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => testOpProfile.Id,
                    User.LanguageLocaleKey => 'en_US'
        })
        .create()
        .getRecord();
        
        User testUserRep = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
            		User.LastName => 'TestNameRep',
                    User.Username => 'userRep@testorg.com',
                    User.Email => 'userRep@testorg.com',
                	User.emailencodingkey => 'UTF-8',
                    User.Alias => 'uRep',
                    User.Country__c => 'United States',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => testManager.Id,
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => testRepProfile.Id,
                    User.LanguageLocaleKey => 'en_US'
        })
        .create()
        .getRecord();
        
        User testUserRep1 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep1',
                            User.Username => 'userRep1@testorg.com',
                            User.Email => 'userRep1@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep1',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep2 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep2',
                            User.Username => 'userRep2@testorg.com',
                            User.Email => 'userRep2@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep2',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep3 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep3',
                            User.Username => 'userRep3@testorg.com',
                            User.Email => 'userRep3@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep3',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep4 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep4',
                            User.Username => 'userRep4@testorg.com',
                            User.Email => 'userRep4@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep4',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep5 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep5',
                            User.Username => 'userRep5@testorg.com',
                            User.Email => 'userRep5@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep5',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep6 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep6',
                            User.Username => 'userRep6@testorg.com',
                            User.Email => 'userRep6@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep6',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep7 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep7',
                            User.Username => 'userRep7@testorg.com',
                            User.Email => 'userRep7@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep7',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep8 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep8',
                            User.Username => 'userRep8@testorg.com',
                            User.Email => 'userRep8@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep8',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

        User testUserRep9 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep9',
                            User.Username => 'userRep9@testorg.com',
                            User.Email => 'userRep9@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep9',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();

		User testUserRep10 = (User) new SObjectBuilder(User.SObjectType)
                    .setFields(new Map<SObjectField, Object>{
                            User.LastName => 'TestNameRep10',
                            User.Username => 'userRep10@testorg.com',
                            User.Email => 'userRep10@testorg.com',
                            User.emailencodingkey => 'UTF-8',
                            User.Alias => 'uRep10',
                            User.Country__c => 'United States',
                            User.TimeZoneSidKey => 'America/Los_Angeles',
                            User.ManagerId => testManager.Id,
                            User.LocaleSidKey => 'en_US',
                            User.EmailEncodingKey => 'UTF-8',
                            User.ProfileId => testRepProfile.Id,
                            User.LanguageLocaleKey => 'en_US'
                })
                .create()
                .getRecord();
        
        Id customerAccRecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
 
        Account accRec = (Account) new SObjectBuilder(Account.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Account.Name => 'Test Account',
                        Account.recordtypeId => customerAccRecId
                    }
                )
                .create()
                .getRecord();
       
        Opportunity oppRec = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Opportunity.Name => 'Test Opportunity',
                            Opportunity.Type => 'Syndicated - New',
                            Opportunity.StageName => '1. Qualify',
                            Opportunity.AccountId => accRec.Id,
                            Opportunity.ForecastCategoryName => 'Pipeline',
                            Opportunity.Estimated_12M_Total_Pipeline__c => 5000,
                            Opportunity.Tier_Name__c => 'Office',
                            Opportunity.Total_Contract_Value__c => 1000,
                            Opportunity.Forecasted_Users__c => 10,
                            Opportunity.CloseDate => system.Today(),
                            Opportunity.Forecasted_RingCentral_Video_Users__c => 0,
                            Opportunity.Forecast_Contact_Center_Users__c => 0
                        })
                    .create()
                    .getRecord();
                    Triggers.switchOn();

        
        Opportunity oppDowngradeRec = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Opportunity.Name => 'Test Opportunity 1',
                            Opportunity.Type => 'Syndicated - New',
                            Opportunity.StageName => '1. Qualify',
                            Opportunity.AccountId => accRec.Id,
                            Opportunity.ForecastCategoryName => 'Pipeline',
                            Opportunity.Estimated_12M_Total_Pipeline__c => 5000,
                            Opportunity.Tier_Name__c => 'Office',
                            Opportunity.Total_Contract_Value__c => 1000,
                            Opportunity.Forecasted_Users__c => 10,
                            Opportunity.Forecasted_RingCentral_Video_Users__c => 0,
                            Opportunity.Forecast_Contact_Center_Users__c => 0
                        })
                    .create()
                    .getRecord();

         List<SObject> opportunityTeamMemberList = new SObjectBuilder(OpportunityTeamMember.SObjectType)
            .quantity(2)
            .setField(OpportunityTeamMember.OpportunityId, oppRec.Id)
            .setField(OpportunityTeamMember.UserId,
                new ValueProvider.ListProvider(new List<String>{testUserOp.Id, testUserRep.Id}))
            .setField(OpportunityTeamMember.TeamMemberRole, 
                new ValueProvider.ListProvider(new List<String>{'Solutions Engineer (Primary)', 'Custom Engineering SE'}))
            .create()
            .getRecords();
        
        List<SObject> opportunityTeamMemberList2 = new SObjectBuilder(OpportunityTeamMember.SObjectType)
            .quantity(12)
            .setField(OpportunityTeamMember.OpportunityId, oppDowngradeRec.Id)
            .setField(OpportunityTeamMember.UserId,
                new ValueProvider.ListProvider(new List<String>{testUserOp.Id, testUserRep.Id, testUserRep1.Id, testUserRep2.Id, testUserRep3.Id,
                    testUserRep4.Id, testUserRep5.Id, testUserRep6.Id, testUserRep7.Id, testUserRep8.Id, testUserRep9.Id, testUserRep10.Id}))
                .setField(OpportunityTeamMember.TeamMemberRole, 
                        new ValueProvider.ListProvider(new List<String>{'Solutions Engineer (Primary)', 'Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)', 
                                                       'Solutions Engineer (Secondary)','Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)', 
                                                       'Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)',
                                                       'Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)', 'Solutions Engineer (Secondary)', 
                                                       'Solutions Engineer (Secondary)', 'Solutions Engineer (Primary)'}))
            .create()
            .getRecords();
        
         List<OppTeamRoles__c> teamRoleList = (List<OppTeamRoles__c>) new SObjectBuilder(OppTeamRoles__c.SObjectType)
        .setFields(new Map<SObjectField, Object> {
            OppTeamRoles__c.Name => ValueProviderBuilder.provideUniqueString('testMapping'),
            OppTeamRoles__c.RoleName__c => ValueProviderBuilder.provideList(
                new List<String>{'Associate Sales Engineer;Solutions Engineer (Primary)','Solutions Engineer (Secondary)'}
            )
        })
        .quantity(2)
        .create()
        .getRecords();
    }
    
    @isTest
    Public static void  whenOppClosedWonAndDowngraded_EmailTriggered() {
        List<Opportunity> updateOpp = new List<Opportunity>();
        List<string> oppIds = new List<String>();
        List<Opportunity> testOpp = [Select Id from Opportunity where name like '%Test Opportunity%'];

        if (!testOpp.isEmpty() && testOpp.Size() > 1) {
            testOpp[0].StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON;
            testOpp[1].StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
            testOpp[1].Downgrade_Reason_Opp__c = 'Lost';
            testOpp[1].Primary_Competitor__c = 'Unknown';
            updateOpp.add(testOpp[0]);
            updateOpp.add(testOpp[1]);
            oppIds.add(testOpp[0].Id);
            oppIds.add(testOpp[1].Id);
        }

        if (!updateOpp.isEmpty()) {
            update updateOpp;
        }
            
        test.startTest();           
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');     
        SEClosedDowngradedEmailAlerts.sendEmailBasedOnOppTeamRoles(oppIds);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
        test.stopTest();
    }
}
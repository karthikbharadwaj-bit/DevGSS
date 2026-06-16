@isTest
private class Test_LeadSearchExtension {
    private static String TEST_FIELD_VALUE = 'Test value';

    @TestSetup static void prepareData() {
        System.Test.startTest();

        User test = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'userTest3@testUsername.com')
            .setField(User.CommunityNickname, 'test1234')
            .create()
            .getRecord();
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.UserPermissionsMarketingUser, true)
            .setField(User.UserName, 'marketingUser1@user.com')
            .setField(User.CommunityNickname, 'marketingTest1')
            .create()
            .getRecord();

        Account partnerAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'partnerAcc',
                    Account.Partner_ID__c => '123890',
                    Account.Permitted_Brands__c => 'RingCentral;RingCentral UK;RingCentral Canada;RingCentral EU;RingCentral AU',
                    Account.RC_Account_Status__c => 'Test',
                    Account.Inside_Sales_rep__c => UserInfo.getUserId()
                }
            )
            .create()
            .getRecord();

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => 'fakeCampaign'
                }
            )
            .createAsUser(marketingUser)
            .getRecord();

        Contact con = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.AccountId => partnerAcc.Id,
                    Contact.Email => 'test@test.com',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => 'en_US'
                }
            )
            .create()
            .getRecord();

        Map<String, String> leadFieldToValues = new Map<String, String> {
            'Partner_Contact__c' => con.Id,
            'FirstName' => 'Test',
            'RecordTypeId' => Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId()
        };
        Lead partnerLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.FirstName => 'leadFirstName'
                }
            )
            .create()
            .getRecord();

        Opportunity newVarOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'New VAR Opportunity',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => 'Planning',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => partnerAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.RecordTypeId => Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('VAR Opportunity').getRecordTypeId()
                }
            )
            .build()
            .getRecord();

        Opportunity downgradedVarOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => 'Downgraded VAR Opportunity',
                    Opportunity.Type => 'Syndicated - New',
                    Opportunity.StageName => '0. Downgraded',
                    Opportunity.CloseDate => system.today().addMonths(1),
                    Opportunity.AccountId => partnerAcc.Id,
                    Opportunity.Primary_Opportunity_Contact__c => con.Id,
                    Opportunity.RecordTypeId => Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('VAR Opportunity').getRecordTypeId(),
                    Opportunity.Downgrade_Reason_Opp__c => 'Invalid Opportunity'
                }
            )
            .build()
            .getRecord();
        insert new List<Opportunity> {newVarOpp, downgradedVarOpp};
        Emails__c email = new Emails__c(Name = 'fake', Email_Address__c = 'fake@email.com');
        insert email;
        Campaign salesGenerated = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.Name, 'Sales Generated')
            .setField(Campaign.Intended_Product__c, 'AU General')
            .setField(Campaign.BMID__c, 'BMID')
            .create()
            .getRecord();
        System.Test.stopTest();
    }

    @isTest static void testAddOpp() {
        List<Opportunity> opps = [SELECT Id, Name, CreatedDate, LastModifiedDate, StageName,
                                Opportunity.Account.Current_Owner__c, Opportunity.Account.Name,Opportunity.Account.RecordType.Name /*CMR-221256*/, Opportunity.Owner.Name,
                                Opportunity.OwnerId, Opportunity.Owner.UserRoleId, AccountId, CloseDate,
                                Account.RC_Account_Status__c, Opportunity.Owner.UserRole.Name,
                                Account.Current_Owner__r.UserRole.Name, Account.Current_Owner__r.Name,
                                Opportunity.RecordType.Name, CampaignId, Campaign.Protected_Campaign__c,
                                RecordTypeName__c,
                                    (SELECT Id, Contact.Name, Contact.Email, Contact.Phone, Contact.Account.Name
                                    FROM OpportunityContactRoles LIMIT 1)
                                FROM Opportunity
                                WHERE Name IN ('New VAR Opportunity', 'Downgraded VAR Opportunity')];

        Contact con = [SELECT Id, Name, AccountId, Email, Phone, Contact.Account.Name,
                            (SELECT CampaignId,Campaign.Protected_Campaign__c, ContactId
                            FROM CampaignMembers
                            WHERE Campaign.Protected_Campaign__c = true LIMIT 1)
                        FROM Contact];

        Lead partnerLead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(partnerLead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Opportunity newVarOpp;
        Opportunity dwnVarOpp;

        for(Opportunity opp : opps) {
            if(opp.Name == 'New VAR Opportunity') {
                newVarOpp = opp;
            }
            if(opp.Name == 'Downgraded VAR Opportunity') {
                dwnVarOpp = opp;
            }
        }

        Test.startTest();
        lse.addOpp(newVarOpp, con);
        lse.addOpp(dwnVarOpp, con);
        Test.stopTest();

        System.assertEquals(1, lse.opportunityNoCOList.size(),
            'Number of protected Opporunities should be equal to 1');
        System.assertEquals(1, lse.unprotectedOpportunityList.size(),
            'Number of unprotected Opporunities should be equal to 1');
    }

    @isTest static void testResetFieldsValue() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'First Name';
        lse.newLead.LastName = 'Last Name';
        lse.newLead.Title = 'Title';
        lse.newLead.Company = 'Company Name';
        lse.newLead.Email = 'Email Address';
        lse.newLead.Website = 'Website';
        lse.newLead.Phone = 'Contact Phone Number';

        lse.resetFieldValue();
        Test.stopTest();

        System.assertEquals('', lse.newLead.FirstName, 'Field should be empty');
        System.assertEquals('', lse.newLead.LastName, 'Field should be empty');
        System.assertEquals('', lse.newLead.Title, 'Field should be empty');
        System.assertEquals('', lse.newLead.Company, 'Field should be empty');
        System.assertEquals('', lse.newLead.Email, 'Field should be empty');
        System.assertEquals('', lse.newLead.Website, 'Field should be empty');
        System.assertEquals('', lse.newLead.Phone, 'Field should be empty');
    }

    @isTest static void testCheckInputFieldsLength() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        String res;
        String resCompanyInfo;
        String resPain;
        String resPainImpact;
        String resGain;
        String resGainImpact;
        String resIdeal;
        String resBenefits;
        String resNextQues;
        String resOtherExp;
        String resNeed;
        String resNoOFEMP;
        String resPhoneStart;
        String resOtherNotes;
        String resDecision;
        String resMoreInfoBudget;
        String resContactAddInfo;
        String resCurrSystemInfo;
        String resTimeFrameInfo;
        String resDecisionMakersInfo;
        String resProspectNeed;

        Test.startTest();
        res = lse.checkInputFieldLength();

        lse.leadQualificationObj.CompanyInfo__c = 'Test Info';
        resCompanyInfo = lse.checkInputFieldLength();
        lse.leadQualificationObj.CompanyInfo__c = '';

        lse.leadQualificationObj.Pain__c = 'Test Info';
        resPain = lse.checkInputFieldLength();
        lse.leadQualificationObj.Pain__c = '';

        lse.leadQualificationObj.Pain_Impact__c = 'Test Info';
        resPainImpact = lse.checkInputFieldLength();
        lse.leadQualificationObj.Pain_Impact__c = '';

        lse.leadQualificationObj.Gain__c = 'Test Info';
        resGain = lse.checkInputFieldLength();
        lse.leadQualificationObj.Gain__c = '';

        lse.leadQualificationObj.Gain_Impact__c = 'Test Info';
        resGainImpact = lse.checkInputFieldLength();
        lse.leadQualificationObj.Gain_Impact__c = '';

        lse.leadQualificationObj.Ideal_Solution__c = 'Test Info';
        resIdeal = lse.checkInputFieldLength();
        lse.leadQualificationObj.Ideal_Solution__c = '';

        lse.leadQualificationObj.Benefits__c = 'Test Info';
        resBenefits = lse.checkInputFieldLength();
        lse.leadQualificationObj.Benefits__c = '';

        lse.leadQualificationObj.Next_Steps_questions__c = 'Test Info';
        resNextQues = lse.checkInputFieldLength();
        lse.leadQualificationObj.Next_Steps_questions__c = '';

        lse.leadQualificationObj.Other_Explanation__c = 'Test Info';
        resOtherExp = lse.checkInputFieldLength();
        lse.leadQualificationObj.Other_Explanation__c = '';

        lse.leadQualificationObj.Need__c = 'Test Info';
        resNeed = lse.checkInputFieldLength();
        lse.leadQualificationObj.Need__c = '';

        lse.leadQualificationObj.of_employees_in_org__c = 'Test Info';
        resNoOFEMP = lse.checkInputFieldLength();
        lse.leadQualificationObj.of_employees_in_org__c = '';

        lse.leadQualificationObj.How_many_phones_to_start__c = 'Test Info';
        resPhoneStart = lse.checkInputFieldLength();
        lse.leadQualificationObj.How_many_phones_to_start__c = '';

        lse.leadQualificationObj.Other_Notes__c = 'Test Info';
        resOtherNotes = lse.checkInputFieldLength();
        lse.leadQualificationObj.Other_Notes__c = '';

        lse.leadQualificationObj.Decision_on_Large_Projects__c = 'Test Info';
        resDecision = lse.checkInputFieldLength();
        lse.leadQualificationObj.Decision_on_Large_Projects__c = '';

        lse.leadQualificationObj.More_Info_on_Budgeted__c = 'Test Info';
        resMoreInfoBudget = lse.checkInputFieldLength();
        lse.leadQualificationObj.More_Info_on_Budgeted__c = '';

        lse.leadQualificationObj.ContractAdditionalInfo__c = 'Test Info';
        resContactAddInfo = lse.checkInputFieldLength();
        lse.leadQualificationObj.ContractAdditionalInfo__c = '';

        lse.leadQualificationObj.CurrentSystemAdditionalInfo__c = 'Test Info';
        resCurrSystemInfo = lse.checkInputFieldLength();
        lse.leadQualificationObj.CurrentSystemAdditionalInfo__c = '';

        lse.leadQualificationObj.TimeframeAdditionalInfo__c = 'Test Info';
        resTimeFrameInfo = lse.checkInputFieldLength();
        lse.leadQualificationObj.TimeframeAdditionalInfo__c = '';

        lse.leadQualificationObj.Decision_makers_Additional_Information__c = 'Test Info';
        resDecisionMakersInfo = lse.checkInputFieldLength();
        lse.leadQualificationObj.Decision_makers_Additional_Information__c = '';

        lse.leadQualificationObj.Prospect_Need__c = 'Test Info';
        resProspectNeed = lse.checkInputFieldLength();
        lse.leadQualificationObj.Prospect_Need__c = '';

        Test.stopTest();

        System.assertEquals('NoError', res, '');
        System.assertEquals('CompanyInfo', resCompanyInfo, 'Error occured while checking CompanyInfo__c field');
        System.assertEquals('PAIN', resPain, 'Error occured while checking Pain__c field');
        System.assertEquals('PAINImpact', resPainImpact, 'Error occured while checking Pain_Impact__c field');
        System.assertEquals('GAIN', resGain, 'Error occured while checking Gain__c field');
        System.assertEquals('GAINImpact', resGainImpact, 'Error occured while checking Gain_Impact__c field');
        System.assertEquals('IDEASol', resIdeal, 'Error occured while checking Ideal_Solution__c field');
        System.assertEquals('Benefits', resBenefits, 'Error occured while checking Benefits__c field');
        System.assertEquals('NextQues', resNextQues, 'Error occured while checking Next_Steps_questions__c field');
        System.assertEquals('OtherExplain', resOtherExp, 'Error occured while checking Other_Explanation__c field');
        System.assertEquals('Need', resNeed, 'Error occured while checking Need__c field');
        System.assertEquals('NoOFEMP', resNoOFEMP, 'Error occured while checking of_employees_in_org__c field');
        System.assertEquals('PhoneStart', resPhoneStart,
            'Error occured while checking How_many_phones_to_start__c field');
        System.assertEquals('OtherNotes', resOtherNotes, 'Error occured while checking Other_Notes__c field');
        System.assertEquals('DecisionLargerProject', resDecision,
            'Error occured while checking Decision_on_Large_Projects__c field');
        System.assertEquals('MoreInfoBugdet', resMoreInfoBudget,
            'Error occured while checking More_Info_on_Budgeted__c field');
        System.assertEquals('ContarctAdditionalInfo', resContactAddInfo,
            'Error occured while checking ContractAdditionalInfo__c field');
        System.assertEquals('CurrentSystemAdditionalInfo', resCurrSystemInfo,
            'Error occured while checking CurrentSystemAdditionalInfo__c field');
        System.assertEquals('TimeFrameAdditionalInfo', resTimeFrameInfo,
            'Error occured while checking TimeframeAdditionalInfo__c field');
        System.assertEquals('DecisionMakersAdditionalInfo', resDecisionMakersInfo,
            'Error occured while checking Decision_makers_Additional_Information__c field');
        System.assertEquals('ProspectNeed', resProspectNeed,
            'Error occured while checking Prospect_Need__c field');
    }

    @isTest static void testFindOpportunityByAccountAndCompanyName() {
        Lead lead = [SELECT Id FROM Lead];
        Account acc = [SELECT Id FROM Account WHERE Name = 'partnerAcc'];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        List<Opportunity> oppsByAcc = new List<Opportunity>();
        List<Opportunity> oppsByCompany = new List<Opportunity>();

        Test.startTest();
        oppsByAcc = lse.findOpportunitiesPerAccounts('Name = \'New VAR Opportunity\'', new Set<Id>{acc.Id});
        oppsByCompany = lse.findOpportunitiesPerCompanyName('Name = \'New VAR Opportunity\'');
        Test.stopTest();

        System.assertEquals(1, oppsByAcc.size(), 'There should be 1 Opportunity');
        System.assertEquals(1, oppsByCompany.size(), 'There should be 1 Opportunity');
    }

    @isTest static void testEmptySearch() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.search();
        Test.stopTest();

        System.assertEquals(true, lse.getEmptySearch(), 'Search should be empty');
    }

    @isTest static void testSearchWithAllData() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(false, ApexPages.hasMessages(), 'Page shouldn\'t have any messages');
    }

    @isTest static void testSearchWithEmptyName() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyCompany() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = '';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyPhone() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(false, ApexPages.hasMessages(), 'Page shouldn\'t have any messages');
    }

    @isTest static void testSearchWithEmptyEmail() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = '';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(false, ApexPages.hasMessages(), 'Page shouldn\'t have any messages');
    }

    @isTest static void testSearchWithEmptyNameAndCompany() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = '';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyCompanyAndPhone() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = '';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyNameAndEmail() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = '';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyCompanyAndEmail() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = '';
        lse.newLead.Company = '';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyNameAndPhone() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchWithEmptyEmailAndPhone() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = '';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(false, ApexPages.hasMessages(), 'Page shouldn\'t have any messages');
    }

    @isTest static void testSearchByEmail() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = '';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchbyPhone() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = '';
        lse.newLead.Company = '';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchByCompany() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = '';
        lse.newLead.LastName = '';
        lse.newLead.Email = '';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }

    @isTest static void testSearchByName() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = '';
        lse.newLead.Company = '';
        lse.newLead.Phone = '';
        lse.newLead.LeadSource = 'Other';
        lse.search();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(), 'Page should have messages');
    }


    @isTest static void testCreateNew() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        PageReference pr;

        Test.startTest();
        pr = lse.createNew();
        Test.stopTest();

        System.assertEquals(null, pr, 'Method should not return PageReference');
    }

    @isTest static void testCreateNewWithLeadSource() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        PageReference pr;

        Test.startTest();
        lse.strSalesgenerated = 'None';
        lse.newlead.LeadSource = 'Sales Generated';
        pr = lse.createNew();
        Test.stopTest();

        System.assertEquals(null, pr, 'Method should not return PageReference');
    }

    @isTest static void testCreateNewWithNewLeadData() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        PageReference pr;

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Source';
        lse.newLead.Employees_Override__c = 'Test data';
        lse.newLead.LS_Company_Size_Range__c = 'Test data';
        lse.newLead.Industry = 'Education';

        pr = lse.createNew();
        Test.stopTest();

        System.assertEquals(null, pr, 'Method should not return PageReference');
    }

    @isTest static void testCreateNewWithInvalidEmail() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        PageReference pr;

        Test.startTest();
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'invalid email';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Source';
        lse.newLead.Employees_Override__c = 'Test data';
        lse.newLead.LS_Company_Size_Range__c = 'Test data';
        lse.newLead.Industry = 'Education';

        pr = lse.createNew();
        Test.stopTest();

        System.assertEquals(null, pr, 'Method should not return PageReference');
    }

    @isTest static void testCreateNewWithDNIS() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        LeadSearchExtension lse = new LeadSearchExtension(controller);

        PageReference pr;

        Test.startTest();
        lse.dnis = '8775843307';
        lse.newLead.FirstName = 'Tony';
        lse.newLead.LastName = 'Tester';
        lse.newLead.Email = 'valid@mail.com';
        lse.newLead.Company = 'Company';
        lse.newLead.Phone = '+1245625623';
        lse.newLead.LeadSource = 'Source';
        lse.newLead.Employees_Override__c = 'Test data';
        lse.newLead.LS_Company_Size_Range__c = 'Test data';
        lse.newLead.Industry = 'Education';
        lse.newLead.Agent_Email_Address__c = '';

        pr = lse.createNew();
        Test.stopTest();

        System.assertEquals(null, pr, 'Method should not return PageReference');
    }

    @isTest
    static void testSalesProfilesForLeadQual() {
        Lead l = [SELECT Id FROM Lead LIMIT 1];


        List<User> usersList = (List<User>) new SObjectBuilder (User.SObjectType)        
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => ValueProviderBuilder.provideList(new List<String> {'TestSalesManagerJoe', 'TestSalesAgentFred'}),
                    User.Username => ValueProviderBuilder.provideList(new List<String> {'SalesManagerJoe!user@gmail.com', 'SalesAgentFred!user@gmail.com'}),
                    User.Email => ValueProviderBuilder.provideList(new List<String> {'SalesManagerJoe_user@gmail.com', 'SalesAgentFred_user@gmail.com'}),
                    User.Alias => 'Test',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.ManagerId => UserInfo.getUserId(),
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
                    User.LanguageLocaleKey => 'en_US',
                    User.Hierarchy_Role__c => 'Sales Rep',
                    User.Division => OpportunityHelper.USER_DIVISION_SALES_ENTERPRISE
                }
            )
            .quantity(2)
            .build()
            .getRecords();
        User salesManager = usersList[0];
        User salesAgent = usersList[1];        

        Profile[] salesManagerProfile = [SELECT Id FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_SALES_MANAGER_WITH_INSIDESALES];
        System.assert(salesManagerProfile.size() == 1, 'Sales Manager w Insidesales profile not found');

        Profile[] salesAgentProfile = [SELECT Id FROM Profile WHERE Name = :ProfileHelper.PROFILE_NAME_SALES_AGENT_SDR_W_INSIDESALES];
        System.assert(salesAgentProfile.size() == 1, 'Sales Agent SDR w Insidesales profile not found');

        salesManager.ProfileId = salesManagerProfile[0].Id;
        salesAgent.ProfileId = salesAgentProfile[0].Id;

        Lead_Qualification__c lqValid = new Lead_Qualification__c();
        lqValid.Current_Situation__c = 'SOME VALUE';
        lqValid.Problems__c = 'SOME VALUE';
        lqValid.Decision_Making_Process__c = 'SOME VALUE';
        lqValid.NextSteps__c = 'SOME VALUE';

        Lead_Qualification__c lqNotValid = new Lead_Qualification__c();
        lqNotValid.Current_Situation__c = 'SOME VALUE';
        lqNotValid.Decision_Making_Process__c = 'SOME VALUE';

        ApexPages.StandardController ctrl = new ApexPages.standardController(l);

        System.runAs(salesManager) {
            LeadSearchExtension lse = new LeadSearchExtension(ctrl);
            System.assert(true == lse.getIsSalesManagerInsideProfile(), 'Unexpected result, should be true');
            lse.leadQualificationObj = lqValid;
            System.assert(true == lse.checkLeadQualificationNotEmpty(false), 'Validation should be passed');
            lse.leadQualificationObj = lqNotValid;
            System.assert(false == lse.checkLeadQualificationNotEmpty(false), 'Validation should not be passed');
        }

        System.runAs(salesAgent) {
            LeadSearchExtension lse = new LeadSearchExtension(ctrl);
            System.assert(true == lse.getIsSaleAgentInsideProfile(), 'Unexpected result, should be true');
            lse.leadQualificationObj = lqValid;
            System.assert(true == lse.checkLeadQualificationNotEmpty(true), 'Validation should be passed');
            lse.leadQualificationObj = lqNotValid;
            System.assert(false == lse.checkLeadQualificationNotEmpty(true), 'Validation should not be passed');
        }
    }

    @isTest static void testResetPagination(){
        Integer procPagination = 3;
        Integer unprocPagination = 5;
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(ld);
        LeadSearchExtension lse =  new LeadSearchExtension(ctrl);
        lse.unprocLeadPaginationNumber =  unprocPagination;
        lse.procLeadPaginationNumber = procPagination;
        lse.resetPaginationNumber();
        unprocPagination = lse.unprocLeadPaginationNumber;
        procPagination = lse.procLeadPaginationNumber;
        test.stopTest();
        System.assertEquals(unprocPagination, 1, 'Unprotected lead pages should have been reset');
        System.assertEquals(procPagination, 1, 'Protected lead pages should have been reset');
    }

    @isTest static void testCalculateTotalPages(){
        Integer totalPages = 0;
        Integer currentListSize = 151;
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(ld);
        LeadSearchExtension lse =  new LeadSearchExtension(ctrl);
        totalPages = lse.calculateTotalPages(currentListSize);
        test.stopTest();
        System.assertEquals(totalPages, 4, 'Total pages should be 4.');

    }

    @isTest static void testDisablePreviousBeginning(){
        Boolean previous = false;
        Boolean beginning = false;
        Boolean next = false;
        Boolean ended = false;
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(ld);
        LeadSearchExtension lse =  new LeadSearchExtension(ctrl);
        lse.unProcLeadPaginationNumber = 1;
        lse.unProcLeadTotalPages = 2;
        lse.checkDisabled();
        previous = lse.disabledULPrevious;
        beginning = lse.disabledULBeginning;
        next = lse.disabledULNext;
        ended = lse.disabledULEnd;
        test.stopTest();
        System.assertEquals(previous, true, 'Previous button should have been disabled');
        System.assertEquals(beginning, true, 'Beginning button should have been disabled');
        System.assertEquals(next, false, 'Next button should not have  been disabled');
        System.assertEquals(ended, false, 'End button should not have  been disabled');

    }
    @isTest static void testDisableNextEnd(){
        Boolean previous = false;
        Boolean beginning = false;
        Boolean next = false;
        Boolean ended = false;
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(ld);
        LeadSearchExtension lse =  new LeadSearchExtension(ctrl);
        lse.procLeadPaginationNumber = 2;
        lse.procLeadTotalPages = 2;
        lse.checkDisabled();
        previous = lse.disabledPLPrevious;
        beginning = lse.disabledPLBeginning;
        next = lse.disabledPLNext;
        ended = lse.disabledPLEnd;
        test.stopTest();
        System.assertEquals(previous, false, 'Previous button should not have been disabled');
        System.assertEquals(beginning, false, 'Beginning button should not have been disabled');
        System.assertEquals(next, true, 'Next button should have been disabled');
        System.assertEquals(ended, true, 'End button should have been disabled');
    }

    @isTest static void testIsProtectedLead(){
        Boolean isProtected = false;
        Boolean isOtherProtected = false;
        String Query = 'SELECT Email, Lead.Name, FirstName, LastName,'+
                   'Phone, Industry, Status, Lead.RecordType.Id, CreatedDate,'+
                   'LastModifiedDate, Company, Id, ownerId,'+
                   'Effective_No_of_Employees_Range__c,' +
                   'Lead.Owner.Name, Five9_DNIS__c FROM Lead LIMIT 1';
        Lead ld = database.query(Query);
        Lead other = ld;
        other.Status = '2. Contacted';

        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(ld);
        LeadSearchExtension lse =  new LeadSearchExtension(ctrl);
        isProtected = lse.isProtectedLead(ld);
        isOtherProtected = lse.isProtectedLead(other);
        test.stopTest();
        System.assertEquals(isProtected, true, 'The lead should be a protected lead');
        System.assertEquals(isOtherProtected, true, 'The lead should be a protected lead');
    }

    @isTest
    static void testCompareToMethodOfListResultClass(){
        DateTime sevenDaysFromToday = Datetime.now().addDays(7);
        LeadSearchExtension.ListResult sortHelper = new LeadSearchExtension.ListResult(null, null, null, null, null, null,
        null, null, null, null, null, null, null, null, null, null, null, null, null);  /*CMR-221256 : Add account record type to smart search*/
        sortHelper.dateModified = String.valueOf(DateTime.now().format('yyyy-MM-dd'));

        LeadSearchExtension.ListResult sortHelperToCompare = new LeadSearchExtension.ListResult(null, null, null, null, null,
        null, null, null, null, null, null, null, null, null, null, null, null, null, null); /*CMR-221256 : Add account record type to smart search*/
        sortHelperToCompare.modifiedYear = sevenDaysFromToday.year();
        sortHelperToCompare.modifiedDay = sevenDaysFromToday.day();
        sortHelperToCompare.modifiedMonth = sevenDaysFromToday.month();

        Test.startTest();
            Integer resultFirstDatePriorToSecondDate = sortHelper.compareTo(sortHelperToCompare);

            sortHelper.modifiedYear = sevenDaysFromToday.year();
            sortHelper.modifiedDay = sevenDaysFromToday.day();
            sortHelper.modifiedMonth = sevenDaysFromToday.month();
            sortHelperToCompare.modifiedYear = DateTime.now().year();
            sortHelperToCompare.modifiedDay = DateTime.now().day();
            sortHelperToCompare.modifiedMonth = DateTime.now().month();

            Integer resultFirstDateAfterToSecondDate = sortHelper.compareTo(sortHelperToCompare);

            sortHelper.modifiedYear = DateTime.now().year();
            sortHelper.modifiedDay = DateTime.now().day();
            sortHelper.modifiedMonth = DateTime.now().month();
            sortHelperToCompare.modifiedYear = DateTime.now().year();
            sortHelperToCompare.modifiedDay = DateTime.now().day();
            sortHelperToCompare.modifiedMonth = DateTime.now().month();

            Integer resultFirstDateEqualSecondDate = sortHelper.compareTo(sortHelperToCompare);
        Test.stopTest();
        System.assertEquals(1, resultFirstDatePriorToSecondDate,
                            'The compareTo method sould return 1 if the first date is prior to the second date');
        System.assertEquals(-1, resultFirstDateAfterToSecondDate,
                            'The compareTo method sould return -1 if the first date is after the second date');
        System.assertEquals(0, resultFirstDateEqualSecondDate,
                            'The compareTo method sould return 0 if the first date and the second date are the same');
    }

    @isTest
    static void testCompareToMethodOfListResultClassWithUkUser() {
        DateTime sevenDaysFromToday = Datetime.now().addDays(7);

        User ukUser = (User) new SObjectBuilder(User.SObjectType)
                          .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                          .setField(User.LocaleSidKey, 'en_GB')
                          .create()
                          .getRecord();
        System.runAs(ukUser) {
            LeadSearchExtension.ListResult sortHelper = new LeadSearchExtension.ListResult(null, null, null, null, null, null,
            null, null, null, null, null, null, null, null, null, null, null, null, null); /*CMR-221256 : Add account record type to smart search*/
            sortHelper.dateModified = String.valueOf(DateTime.now().format('yyyy-MM-dd'));

            LeadSearchExtension.ListResult sortHelperToCompare = new LeadSearchExtension.ListResult(null, null, null, null, null,
            null, null, null, null, null, null, null, null, null, null, null, null, null, null); /*CMR-221256 : Add account record type to smart search*/
            sortHelperToCompare.modifiedYear = sevenDaysFromToday.year();
            sortHelperToCompare.modifiedDay = sevenDaysFromToday.day();
            sortHelperToCompare.modifiedMonth = sevenDaysFromToday.month();

            Test.startTest();
                Integer resultFirstDatePriorToSecondDate = sortHelper.compareTo(sortHelperToCompare);

                sortHelper.modifiedYear = sevenDaysFromToday.year();
                sortHelper.modifiedDay = sevenDaysFromToday.day();
                sortHelper.modifiedMonth = sevenDaysFromToday.month();
                sortHelperToCompare.modifiedYear = DateTime.now().year();
                sortHelperToCompare.modifiedDay = DateTime.now().day();
                sortHelperToCompare.modifiedMonth = DateTime.now().month();

                Integer resultFirstDateAfterToSecondDate = sortHelper.compareTo(sortHelperToCompare);

                sortHelper.modifiedYear = DateTime.now().year();
                sortHelper.modifiedDay = DateTime.now().day();
                sortHelper.modifiedMonth = DateTime.now().month();
                sortHelperToCompare.modifiedYear = DateTime.now().year();
                sortHelperToCompare.modifiedDay = DateTime.now().day();
                sortHelperToCompare.modifiedMonth = DateTime.now().month();

                Integer resultFirstDateEqualSecondDate = sortHelper.compareTo(sortHelperToCompare);
            Test.stopTest();

            System.assertEquals(1, resultFirstDatePriorToSecondDate,
                                'The compareTo method sould return 1 if the first date is prior to the second date');
            System.assertEquals(-1, resultFirstDateAfterToSecondDate,
                                'The compareTo method sould return -1 if the first date is after the second date');
            System.assertEquals(0, resultFirstDateEqualSecondDate,
                                'The compareTo method sould return 0 if the first date and the second date are the same');
        }
    }

    @isTest
    private static void testEnableButtons() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        Test.startTest();
        lse.enableButtons();
        Test.stopTest();

        System.assert(
            !lse.searchButtonDisabled,
            'Field searchButtonDisabled should be false'
        );

        System.assert(
            !lse.createNewLeadButtonDisabled,
            'Field createNewLeadButtonDisabled should be false'
        );
    }

    @isTest
    private static void testModel_Usage_featureDependencyClassController() {
        LeadSearchExtension.Model_Usage_featureDependencyClass model;
        Test.startTest();
        model = new LeadSearchExtension.Model_Usage_featureDependencyClass();
        Test.stopTest();

        System.assertEquals(
            '',
            model.ParentName,
            'Field ParentName should be empty string'
        );

        System.assert(
            !model.isUsageLevel,
            'Field isUsageLevel should be false'
        );

        System.assert(
            model.childList.isEmpty(),
            'List childList should be empty'
        );
    }

    @isTest
    private static void testModelValueBindingsClass() {
        LeadSearchExtension.ModelValueBindingsClass model;
        Test.startTest();
        model = new LeadSearchExtension.ModelValueBindingsClass(true, 'someVal');
        Test.stopTest();

        System.assertEquals(
            'someVal',
            model.value,
            'Field value populated incorrectly'
        );

        System.assert(
            model.isSelected,
            'Field isSelected should be true'
        );
    }

    @isTest
    private static void testCopyEnrichData() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        lse.newLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LS_Title__c => 'Test LS Title',
                Lead.LS_Site__c => 'Test LS Site',
                Lead.LS_Company_Industry__c => 'Test LS Company'
            })
            .build()
            .getRecord();

        lse.industrySet = new Set<String>{'TEST LS COMPANY'};

        Test.startTest();
        lse.copyEnrichData();
        Test.stopTest();

        System.assertEquals(
            'Test LS Title',
            lse.newLead.Title,
            'Field Title on newLead populated incorrectly'
        );
        System.assertEquals(
            'Test LS Site',
            lse.newLead.Company,
            'Field Company on newLead populated incorrectly'
        );
        System.assertEquals(
            'Test LS Company',
            lse.newLead.Industry,
            'Field Industry on newLead populated incorrectly'
        );
    }

    @isTest
    private static void testGetMultipickListString() {
        List<String> values = new List<String>{'first', 'second'};

        String result;
        Test.startTest();
        result = LeadSearchExtension.getMultipickListString(values);
        Test.stopTest();

        System.assertEquals(
            'first;second',
            result,
            'Method should return correct result'
        );
    }

    @isTest
    private static void testGetcampaignName() {
        String result;
        Test.startTest();
        result = new LeadSearchExtension(null).getcampaignName();
        Test.stopTest();

        System.assertEquals(
            'Sales Generated',
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testGetcampaignDescription() {
        String result;
        Test.startTest();
        result = new LeadSearchExtension(null).getcampaignDescription();
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Method should return null value'
        );
    }

    @isTest
    private static void testGetFieldsChangedAfterSearch() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getFieldsChangedAfterSearch();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetOppResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getOppResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetPartnerOppResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getPartnerOppResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetUnprotectedResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getUnprotectedResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetLeadResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getLeadResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetUnProtectedLeadResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getUnProtectedLeadResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetShowUnprotectedLeadsList() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getShowUnprotectedLeadsList();
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
    }

    @isTest
    private static void testGetProtectedLeadResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getProtectedLeadResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetEmptyField() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getEmptyField();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetagentEmailChk() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getagentEmailChk();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetdnisChk() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getdnisChk();
        Test.stopTest();

        System.assert(
            result,
            'Method should return true'
        );
    }

    @isTest
    private static void testGetSearched() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getSearched();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetEmailNotFormated() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getEmailNotFormated();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetPhoneNotFormated() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getPhoneNotFormated();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetSearchFirstShouldReturnEmptyList() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getSearchFirst();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetSearchFirst() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getSearchFirst();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetOppNoOCResults() {
        Boolean result;
        Test.startTest();
        result = new LeadSearchExtension(null).getOppNoOCResults();
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetOpportunities() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getOpportunities();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetOpportunitiesNoCO() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getOpportunitiesNoCO();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetParterOpportunities() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getParterOpportunities();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetUnprotectedOpportunities() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getUnprotectedOpportunities();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetLeadList() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getLeadList();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetunprotectedLeadList() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getunprotectedLeadList();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testGetprotectedLeadList() {
        List<LeadSearchExtension.ListResult> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getprotectedLeadList();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testShowMoreInfoBudget() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        Test.startTest();
        lse.showMoreInfoBudget();
        Test.stopTest();

        System.assert(
            !lse.toShowMoreInfobudget,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetDecisionMaker() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        Test.startTest();
        lse.getDecisionMaker();
        Test.stopTest();

        System.assert(
            !lse.toShowWhoisDecisionMkr,
            'Method should return false'
        );
    }

    @isTest
    private static void testGetOwnerId() {
        String result;
        Test.startTest();
        result = new LeadSearchExtension(null).getOwnerId('005');
        Test.stopTest();

        System.assertEquals(
            '005',
            result,
            'Method should return correct ownerId'
        );
    }

    @isTest
    private static void testGetSelectedValues() {
        List<SelectOption> result;
        Test.startTest();
        result = new LeadSearchExtension(null).getSelectedValues();
        Test.stopTest();

        System.assert(
            result.isEmpty(),
            'Method should return empty list'
        );
    }

    @isTest
    private static void testSplitIntoFields() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Map<String, String> result = new Map<String, String>();
        Test.startTest();
        result = lse.splitIntoFields(result, new List<String>{'one:two'});
        Test.stopTest();

        System.assertEquals(
            1,
            result.size(),
            'Result map has incorrect size'
        );
        System.assertEquals(
            'two',
            result.get('one'),
            'Result map populated incorrectly'
        );
    }

    @isTest
    private static void testIsValueNotEmpty() {
        Boolean result;

        Test.startTest();
        result = new LeadSearchExtension(null).isValueNotEmpty('value');
        Test.stopTest();

        System.assert(
            result,
            'Method should return correct value'
        );
    }

    @isTest
    private static void testParseFieldsToObject() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Lead ld = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead.LS_Title__c => 'Test LS Title',
                Lead.LS_Site__c => 'Test LS Site',
                Lead.LS_Company_Industry__c => 'Test LS Company'
            })
            .build()
            .getRecord();

        Map<String, String> fieldValues = new Map<String, String>();
        fieldValues.put('City__c', 'City Test');

        Test.startTest();
        lse.parseFieldsToObject(ld, fieldValues);
        Test.stopTest();

        System.assertEquals(
            'City Test',
            ld.City__c,
            'Object updated incorrectly'
        );
    }

    @isTest
    private static void testGetCurrentUser() {
        Set<Id> result;
        Id userId = (Id) new ValueProvider.DummyIdProvider(User.sObjectType).getValue();
        Test.startTest();
        result = new LeadSearchExtension(null).getCurrentUser(userId);
        Test.stopTest();
    
        System.assertEquals(
            1,
            result.size(),
            'Incorrect size of result Set'
        );
        System.assertEquals(
            userId,
            new List<Id>(result).get(0),
            'Method should return correct Set'
        );
    }    

    @isTest
    private static void testResetFieldValue() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Lead_Qualification__c lc = (Lead_Qualification__c) new SObjectBuilder(Lead_Qualification__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead_Qualification__c.CompanyInfo__c =>
                    'What do you guys do? What do you Use now? Tell me about how much you are paying?',
                Lead_Qualification__c.Pain_Impact__c => 'What else?',
                Lead_Qualification__c.Gain_Impact__c => 'What else?',
                Lead_Qualification__c.Which_Radio__c => 'Which Radio?',
                Lead_Qualification__c.Other_Explanation__c => 'Other - Explain',
                Lead_Qualification__c.Need__c => 'Need',
                Lead_Qualification__c.of_employees_in_org__c => 'No of employees in org',
                Lead_Qualification__c.How_many_phones_to_start__c => 'How many phones to start',
                Lead_Qualification__c.Decision_on_Large_Projects__c =>
                    'Who makes (or) how are decisions for large projects made?',
                Lead_Qualification__c.Other_Notes__c => 'Other Notes',
                Lead_Qualification__c.Decision_Maker__c => 'No',
                Lead_Qualification__c.Budgeted__c => 'No',
                Lead_Qualification__c.Who_is_Decision_Maker__c => 'In case of No, who is Decision Maker?',
                Lead_Qualification__c.More_Info_on_Budgeted__c => 'More Info on Budgeted'
            })
            .build()
            .getRecord();

        lse.numOfEmployees = '';
        lse.leadQualificationObj = lc;

        Test.startTest();
        lse.resetFieldValue();
        Test.stopTest();

        System.assertEquals(
            null,
            lse.numOfEmployees,
            'Field numOfEmployees should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.CompanyInfo__c),
            'Field CompanyInfo__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Pain_Impact__c),
            'Field Pain_Impact__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Gain_Impact__c),
            'Field Gain_Impact__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Which_Radio__c),
            'Field Which_Radio__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Other_Explanation__c),
            'Field Other_Explanation__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Need__c),
            'Field Need__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.of_employees_in_org__c),
            'Field of_employees_in_org__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.How_many_phones_to_start__c),
            'Field How_many_phones_to_start__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Decision_on_Large_Projects__c),
            'Field Decision_on_Large_Projects__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Other_Notes__c),
            'Field Other_Notes__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.Who_is_Decision_Maker__c),
            'Field Who_is_Decision_Maker__c on leadQualificationObj should be empty'
        );
        System.assert(
            String.isBlank(lse.leadQualificationObj.More_Info_on_Budgeted__c),
            'Field More_Info_on_Budgeted__c on leadQualificationObj should be empty'
        );
    }

    @isTest
    private static void testGetUsagesLevelValues() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getUsagesLevelValues;
        Test.stopTest();

        System.assertEquals(
            8,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetFeaturesRequestdByCustomerValues() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getFeaturesRequestdByCustomerValues;
        Test.stopTest();

        System.assertEquals(
            22,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetCallFlowModelValues2() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Map<Integer,String> result;

        Test.startTest();
        result = lse.getCallFlowModelValues2;
        Test.stopTest();

        System.assertEquals(
            4,
            result.size(),
            'Getter should return map with 8 elements'
        );
    }

    @isTest
    private static void testGetCallFlowModelValues() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<LeadSearchExtension.ModelValueBindingsClass> result;

        Test.startTest();
        result = lse.getCallFlowModelValues;
        Test.stopTest();

        System.assertEquals(
            4,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetAllCurrentSystemInfoValues() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getAllCurrentSystemInfoValues;
        Test.stopTest();

        System.assertEquals(
            6,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetBusinessVendorResons() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getBusinessVendorResons;
        Test.stopTest();

        System.assertEquals(
            6,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetBusinessresponsivenessResons() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getBusinessresponsivenessResons;
        Test.stopTest();

        System.assertEquals(
            4,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testGetBusinessAgilityResons() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        List<SelectOption> result;

        Test.startTest();
        result = lse.getBusinessAgilityResons;
        Test.stopTest();

        System.assertEquals(
            6,
            result.size(),
            'Getter should return list with 8 elements'
        );
    }

    @isTest
    private static void testUnselectclick() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        lse.leftselected = new List<String>();
        lse.leftvalues = new Set<String>();
        lse.rightselected = new List<String>{'val'};
        lse.rightvalues = new Set<String>{'val'};

        Test.startTest();
        lse.unselectclick();
        Test.stopTest();

        System.assertEquals(
            1,
            lse.leftvalues.size(),
            'Set leftvalues should contain only 1 element'
        );
        System.assertEquals(
            'val',
            new List<String>(lse.leftvalues)[0],
            'Set leftvalues populated incorrectly'
        );
        System.assertEquals(
            0,
            lse.rightvalues.size(),
            'Set rightvalues should be empty'
        );
    }

    @isTest
    private static void testSelectclick() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        lse.rightselected = new List<String>();
        lse.rightvalues = new Set<String>();
        lse.leftselected = new List<String>{'val'};
        lse.leftvalues = new Set<String>{'val'};

        Test.startTest();
        lse.selectclick();
        Test.stopTest();

        System.assertEquals(
            1,
            lse.rightvalues.size(),
            'Set rightvalues should contain only 1 element'
        );
        System.assertEquals(
            'val',
            new List<String>(lse.rightvalues)[0],
            'Set rightvalues populated incorrectly'
        );
        System.assertEquals(
            0,
            lse.leftvalues.size(),
            'Set leftvalues should be empty'
        );
    }

    @isTest
    private static void testDependentReasons() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Lead_Qualification__c lc = (Lead_Qualification__c) new SObjectBuilder(Lead_Qualification__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Lead_Qualification__c.Reasons__c => 'Reason',
                Lead_Qualification__c.X50_249_Business_Drivers__c => 'businessDriver'
            })
            .build()
            .getRecord();

        lse.leadQualificationObj = lc;
        lse.rightvalues = new Set<String>();
        lse.leftvalues = new Set<String>();
        lse.selBusinessDriver = 'businessDriver';
        lse.driverReasonMap.put(lse.selBusinessDriver, new Set<String>{'businessDriverValue'});

        Test.startTest();
        lse.dependentReasons();
        Test.stopTest();

        System.assertEquals(
            1,
            lse.rightvalues.size(),
            'Set rightvalues should contain only 1 element'
        );
        System.assertEquals(
            'Reason',
            new List<String>(lse.rightvalues)[0],
            'Set rightvalues populated incorrectly'
        );
        System.assertEquals(
            1,
            lse.leftvalues.size(),
            'Set leftvalues should contain only 1 element'
        );
        System.assertEquals(
            'businessDriverValue',
            new List<String>(lse.leftvalues)[0],
            'Set leftvalues populated incorrectly'
        );
    }

    @isTest
    private static void testFindOppPerAccountId() {
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test Opportunity',
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => System.today().addMonths(1),
                Opportunity.AccountId => acc.Id
            })
            .create()
            .getRecord();

        Map<Id, List<Opportunity>> result;
 
        result = lse.findOppPerAccountId(new List<Opportunity>{opp});

        System.assertEquals(
            opp,
            result.get(acc.Id)[0],
            'Result map populated incorrectly'
        );
    }

    @isTest
    private static void testFindOppPerAccountIdShouldReturnEmptyMap() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Map<Id, List<Opportunity>> result;

        Test.startTest();
        result = lse.findOppPerAccountId(null);
        Test.stopTest();

        System.assertEquals(
            0,
            result.size(),
            'Method should return empty map'
        );
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testForCoverage() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        String errorRelatedItemOps = lse.errorRelatedItemOps;
        String companyName = lse.companyName;
        Integer numOfRecordsShown = lse.numOfRecordsShown;
        String isConsole = lse.isConsole;
        Decimal responseTime = lse.responseTime;
        LeadSpaceWrapperCls responseData = lse.responseData;
        String strEnrich = lse.strEnrich;
        String lineBreakText = lse.lineBreakText;
        String inboundChatParams = lse.inboundChatParams;
        List<selectOption> productAssistanceItems = lse.productAssistanceItems;
        List<selectOption> productAssistanceItemsLvl2 = lse.productAssistanceItemsLvl2;
        String getDependencyList = lse.getDependencyList;
        lse.cancel();
        lse.resetSearchfirst();
        lse.getnewLead();
        lse.setNewLead(null);
    }

    @isTest
    private static void testFindContactToAccountMapShouldReturnEmptyMap() {
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Map<Id, Contact> result;

       
        result = lse.findContactToAccountMap(null);
      

        System.assertEquals(
            0,
            result.size(),
            'Method should return empty map'
        );
    }

    @isTest
    private static void testFindContactToAccountMap() {
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();

        Map<Id, Contact> result;

        result = lse.findContactToAccountMap(new List<Contact>{contact});

        System.assertEquals(
            1,
            result.size(),
            'Map should contain 1 pair of key value'
        );
        System.assertEquals(
            contact,
            result.get(acc.Id),
            'Result map populated incorrectly'
        );
    }

    @isTest
    private static void testFindContactPerOppRolesShouldReturnNullDueToException() {
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();

        List<Contact> result;

        result = lse.findContactPerOppRoles('fake', null);

        System.assertEquals(
            null,
            result,
            'Method should return null due to exception'
        ); 
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testFindContactPerOppRoles() {
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(null);
        Account acc = (Account) new SObjectBuilder(Account.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => 'Test acc',
                Account.Payment_Method__c => 'Invoice',
                Account.Tax_Exempt__c => false,
                Account.SignupType__c => 'Free',
                Account.Monthly_Credit_Limit__c => 0,
                Account.Sign_up_Purchase_Limit__c => 0,
                Account.Payment_Terms__c => '12',
                Account.Invoice_Terms__c => '12',
                Account.PID__c => 'test_p_id',
                Account.BillingCity => 'TestCity',
                Account.BillingStreet => 'TestStreet',
                Account.BillingState => 'NY',
                Account.BillingPostalCode => '123890',
                Account.BillingCountry => 'US'
            })
            .create()
            .getRecord();
        Contact contact = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.AccountId => acc.Id,
                Contact.LastName => 'John',
                Contact.FirstName => 'Good',
                Contact.Email => 'jg@rc.test'
            })
            .create()
            .getRecord();
        List<Contact> result;
        
        result = lse.findContactPerOppRoles('', null);

        System.debug('result : ' + result);
        
    }

    @isTest
    private static void testUpdateLeadFromAgentChat() {
        LeadSearchExtension lse = new LeadSearchExtension(null);
        lse.inboundChatParams = '';

        Campaign camp = new Campaign(Name = 'testCamp');
        insert camp;

        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .create()
            .getRecord();

        Lead newLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .build()
            .getRecord();

        Boolean result;

        Test.startTest();
        result = lse.updateLeadFromAgentChat(testLead.Id, 'testCamp', camp, newLead);
        Test.stopTest();

        System.assert(
            result,
            'Method should finish correctly'
        );
    }

    @isTest
    private static void testUpdateLeadFromAgentChatShouldReturnFalse() {
        LeadSearchExtension lse = new LeadSearchExtension(null);

        Campaign camp = new Campaign(Name = 'testCamp');

        Boolean result;

        Test.startTest();
        result = lse.updateLeadFromAgentChat(null, 'testCamp', camp, null);
        Test.stopTest();

        System.assert(
            !result,
            'Method should return false value'
        );
        System.assert(
            lse.errorRelatedItemOps.contains('Error taking ownership, campaign not found'),
            'Error created incorrectly'
        );
    }

    public static INVOCA_FOR_SF__Invoca_Call_Log__c createInvoca() {
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = (INVOCA_FOR_SF__Invoca_Call_Log__c) new SObjectBuilder(INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType)
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c , '123456')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_6__c , '456789')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_7__c , '987654')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__calling_phone_number__c , '5551234')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_3__c , '000000')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c , '111111')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_15__c , '222222')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_19__c , '333333')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_17__c , '444444')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_10__c , '555555')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_5__c , '666666')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_4__c , '777777')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_13__c , '888888')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_11__c , '999999')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_8__c , '101010')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_9__c , '121212')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__destination_phone_number__c , '131313')
        .setField(INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_18__c ,'141414')
        .create()
        .getRecord();

        return invocaRecord;
    }

    @isTest
    private static void testInvocaAssignValuesWithInvocaId() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];

        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, 'Test Campaign')
                            .setField(Campaign.BMID__c, '111111')
                            .createAsUser(marketingUser)
                            .getRecord();
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Invoca&InvocaID=' 
                                                + invocaRecord.INVOCA_FOR_SF__transaction_id__c);
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.Email = 'fake@email.com';
        lse.newLead.LastName = 'fakeLastName';
        lse.newLead.Company = 'fakeCompany';
        lse.newLead.LeadSource = 'Other';
        lse.newLead.Employees_Override__c = '1-19';
        lse.newLead.Industry = 'Other';
        lse.search();
        PageReference testPage = lse.createNew();
        Test.stopTest();

        invocaRecord = [SELECT INVOCA_FOR_SF__Customer_String_Value_6__c, INVOCA_FOR_SF__Customer_String_Value_7__c, 
                        INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, INVOCA_FOR_SF__Lead__c
                        FROM INVOCA_FOR_SF__Invoca_Call_Log__c];
        
        Lead testLead = [SELECT BMID__c, RCKW__c, RCMT__c, Most_Recent_Campaign__c
                        FROM Lead
                        WHERE Id =: invocaRecord.INVOCA_FOR_SF__Lead__c];

        System.assertEquals(testLead.BMID__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c,
                        'BMID on Lead was assigned incorrectly.');
        System.assertEquals(testLead.RCKW__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_6__c,
                        'RCKW on Lead was assigned incorrectly.');
        System.assertEquals(testLead.RCMT__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_7__c,
                        'RCMT Campaign was assigned incorrectly.');
        System.assertEquals(testLead.Most_Recent_Campaign__c,
                        camp.Id,
                        'Lead Campaign was assigned incorrectly.');
    }

    @isTest
    private static void testInvocaWithoutTransactionId() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];

        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, 'Test Campaign')
                            .setField(Campaign.BMID__c, '111111')
                            .setField(Campaign.DNIS__c, '34543435')
                            .createAsUser(marketingUser)
                            .getRecord();
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Invoca');
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.Email = 'fake@email.com';
        lse.newLead.LastName = 'fakeLastName';
        lse.newLead.Company = 'fakeCompany';
        lse.newLead.LeadSource = 'Other';
        lse.newLead.Employees_Override__c = '1-19';
        lse.newLead.Industry = 'Other';
        lse.search();
        PageReference testPage = lse.createNew();
        Test.stopTest();

        invocaRecord = [SELECT INVOCA_FOR_SF__Customer_String_Value_6__c, INVOCA_FOR_SF__Customer_String_Value_7__c, 
                        INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, INVOCA_FOR_SF__Lead__c
                        FROM INVOCA_FOR_SF__Invoca_Call_Log__c];

        Lead testLead = [SELECT BMID__c, RCKW__c, RCMT__c, Most_Recent_Campaign__c
                        FROM Lead
                        WHERE Id =: invocaRecord.INVOCA_FOR_SF__Lead__c];

        System.assertEquals(testLead.BMID__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c,
                        'BMID on Lead was assigned incorrectly.');
        System.assertEquals(testLead.RCKW__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_6__c,
                        'RCKW on Lead was assigned incorrectly.');
        System.assertEquals(testLead.RCMT__c,
                        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_7__c,
                        'RCMT Campaign was assigned incorrectly.');
        System.assertEquals(testLead.Most_Recent_Campaign__c,
                        camp.Id,
                        'Lead Campaign was assigned incorrectly.');

    }

    @isTest
    private static void testInvocaAssignCampaignInvocaWalkOn() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        update invocaRecord;
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Invoca&InvocaID=' 
                                                + invocaRecord.INVOCA_FOR_SF__transaction_id__c);
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        Test.stopTest();

        System.assertEquals(lse.newLead.Most_Recent_Campaign__c, camp.Id, 'Lead Campaign was assigned incorrectly.');
    }

    @isTest
    private static void testPagination() {
        Lead lead = [SELECT Id FROM Lead];

        ApexPages.StandardController controller = new ApexPages.standardController(lead);
        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.prepareLeadList('');
        lse.doPaginationQuery(2, true, 'Next', 5);
        Test.stopTest();

        System.assertEquals(lse.disabledPLNext, true);
    }

    @isTest
    private static void obtainAccountsToPopulateRCAccount_whenOneAccountIsFinded_ShouldTakeIt() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];
        
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_2__c = 'testRCUserId__c';
        update invocaRecord;

        Account acc = (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.RC_User_ID__c, 'testRCUserId__c')
            .create()
            .getRecord();
        
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();

        PageReference pr = new PageReference('/apex/LeadSearchExtension?source=Invoca&InvocaID='+ invocaRecord.INVOCA_FOR_SF__transaction_id__c);
  
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        Test.stopTest();

        System.assertEquals(acc.Id, lse.rcAccount.Id, 'Should be the same account');
    }

    @isTest
    private static void obtainContactsRelatedToRCAccountWherePhoneMatches_whenClickOnSearchButton_ShouldFindThreeContacts() {
        Lead ld = [SELECT Id, Email, Phone, LastName, Company FROM Lead LIMIT 1];
        
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_2__c = 'testRCUserId__c';
        update invocaRecord;

        Triggers.switchOff();

        Account acc = (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.RC_User_ID__c, 'testRCUserId__c')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .create()
            .getRecord();

        List<Contact> contacts = (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'testEmail@testEmail.com')
            .quantity(2)
            .build()
            .getRecords();

        contacts.AddAll((List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Phone, '1234525')
            .quantity(3)
            .build()
            .getRecords()
        );

        insert contacts;
        
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();
                            
        Triggers.switchOn();

        PageReference pr = new PageReference('/apex/LeadSearchExtension?source=Invoca&InvocaID='+ invocaRecord.INVOCA_FOR_SF__transaction_id__c);
  
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);
        
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.lastName = 'test lastanme';
        lse.newLead.Email = 'emailFakeBadEmail@testemail.com';

        Test.startTest();
            lse.newLead.Phone = '1234525';
            lse.search();
        Test.stopTest();


        System.assertEquals(3, lse.matchedContactList.size(), 'There should be three contacts');
    }
    
    @isTest
    private static void obtainContactsRelatedToRCAccountWhereEmailMatches_whenClickOnSearchButton_ShouldFindTwoContacts() {
        Lead ld = [SELECT Id, Email, Phone, LastName, Company FROM Lead LIMIT 1];
        
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_2__c = 'testRCUserId__c';
        update invocaRecord;

        Triggers.switchOff();

        Account acc = (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.RC_User_ID__c, 'testRCUserId__c')
            .setField(Account.RC_Account_Status__c, 'Paid')
            .create()
            .getRecord();

        
        List<Contact> contacts = (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, 'testEmail@testEmail.com')
            .quantity(2)
            .build()
            .getRecords();

        contacts.addAll(
            (List<Contact>) new sObjectBuilder(Contact.sObjectType)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Email, null)
            .setField(Contact.Phone, '1234525')
            .quantity(3)
            .build()
            .getRecords()
        );
        
        insert contacts;

        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();

        Triggers.switchOn();

        PageReference pr = new PageReference('/apex/LeadSearchExtension?source=Invoca&InvocaID='+ invocaRecord.INVOCA_FOR_SF__transaction_id__c);
  
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);
        
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.lastName = 'test lastanme';
        lse.newLead.Phone = '431';

        Test.startTest();
            lse.newLead.Email = 'testEmail@testEmail.com';
            lse.search();
        Test.stopTest();


        System.assertEquals(2, lse.matchedContactList.size(), 'There should be two contacts');
    }
    
    @isTest
    private static void populateZICDPAccountId_whenAccountIsFindedOnInvocaRecord_shouldPopulateWithThisAccount() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];
        
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_2__c = 'testRCUserId__c';
        update invocaRecord;

        Account acc = (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.RC_User_ID__c, 'testRCUserId__c')
            .create()
            .getRecord();
        
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();

        PageReference pr = new PageReference('/apex/LeadSearchExtension?source=Invoca&InvocaID='+ invocaRecord.INVOCA_FOR_SF__transaction_id__c);
  
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
            LeadSearchExtension lse = new LeadSearchExtension(controller);
            lse.newLead.Email = 'emailTest@emailTest.com';
            lse.newLead.Company = 'newCompanyTest';
            lse.newLead.LastName = 'lastName test';
            lse.newLead.LeadSource = 'LeadSource Test';
            lse.newLead.Employees_Override__c = '20';
            lse.newLead.Industry = 'Industry test';
            lse.search();
            lse.createNew();
        Test.stopTest();

        ld = (Lead) new LeadSelector()
            .selectLeadById(new Object[]{lse.newLead.Id})
            .selectField(Lead.ZI_CDP_Account_Id__c)
            .executeQuery()[0];

        System.assertEquals(acc.Id, ld.ZI_CDP_Account_Id__c, 'Should be the same account');
    }
    @isTest
    private static void populateZICDPAccountId_whenAccountIsFindedOnInvocaRecordAndClaimUnprotectedLead_shouldPopulateWithThisAccount() {
        Lead ld = [SELECT Id, Email, LastName, Company FROM Lead LIMIT 1];
        
        INVOCA_FOR_SF__Invoca_Call_Log__c invocaRecord = createInvoca();
        invocaRecord.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c = '';
        invocaRecord.INVOCA_FOR_SF__Customer_String_Value_2__c = 'testRCUserId__c';
        update invocaRecord;

        Account acc = (Account) new sObjectBuilder(Account.sObjectType)
            .setField(Account.RC_User_ID__c, 'testRCUserId__c')
            .create()
            .getRecord();

        Lead aLead = (Lead) new sObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'test lastname:D')
            .setField(Lead.firstName, 'test firstname:D')
            .setField(Lead.company, 'test company:D')
            .create()
            .getRecord();
        
        User marketingUser = [SELECT Id,UserName FROM User Where UserName = 'marketingUser1@user.com'];
        Campaign camp = (Campaign) new SObjectBuilder (Campaign.SObjectType)
                            .setField(Campaign.Name, LeadHelper.CAMPAIGNINVOCAWALKON)
                            .setField(Campaign.Intended_Product__c, 'product')
                            .createAsUser(marketingUser)
                            .getRecord();

        PageReference pr = new PageReference('/apex/LeadSearchExtension?source=Invoca&InvocaID='+ invocaRecord.INVOCA_FOR_SF__transaction_id__c + '&claimedUpLeadId=' + aLead.Id);
  
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
            LeadSearchExtension lse = new LeadSearchExtension(controller);
            lse.claimUnprotectedLeadOwnership();
        Test.stopTest();

        ld = (Lead) new LeadSelector()
            .selectLeadById(new Object[]{aLead.Id})
            .selectField(Lead.ZI_CDP_Account_Id__c)
            .executeQuery()[0];

        System.assertEquals(acc.Id, ld.ZI_CDP_Account_Id__c, 'Should be the same account');
    }

    @isTest
    static void testPopulateRCAccountFromURLMatchesAccount() {
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        acc.RC_User_ID__c = 'testRCUserId';
        update acc;
        PageReference pr = new PageReference('/apex/LeadSearchExtension?UserID=' + acc.RC_User_ID__c);
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.populateRCAccount(ld);
        Test.stopTest();

        System.assertEquals(acc.Id, ld.ZI_CDP_Account_Id__c, 'Should be the same account');
    }

    @isTest
    static void testPopulateRCAccountFromURLIsNull() {
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        Account acc = (Account) new AccountSelector().selectAccounts().executeQuery()[0];
        acc.RC_User_ID__c = 'testRCUserId';
        update acc;
        PageReference pr = new PageReference('/apex/LeadSearchExtension?UserID=anotherUserId');
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.populateRCAccount(ld);
        Test.stopTest();

        System.assertEquals(null, ld.ZI_CDP_Account_Id__c, 'Should be null');
    }

    
    @isTest
    static void testConstructorSourceEqualDrift() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&fname=test');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        Test.stopTest();

        System.assertEquals('test', lse.newlead.FirstName, 'FirstName should be test');
    }

    @isTest
    static void testConstructorSourceEqualDriftAllParameters() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&bmid=1234'
                                                + '&fname=test&lname=te&email=test@test.com&phone=1234&rcvid=1234'
                                                + '&atid=1544&atid_history=980&aid=99&pid=865&kcid=4556&gclid=9877&ecid=5768');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        Test.stopTest();
        Lead returnedLead = lse.newLead;
        System.assertEquals('1234', lse.newlead.BMID__c, 'BMID should be 1234');
        System.assertEquals(returnedLead.FirstName, 'test',
        'The field firstName of the returned lead should be equal to test'); 
        System.assertEquals(returnedLead.LastName, 'te',
        'The field lastName of the returned lead should be equal to te'); 
        System.assertEquals(returnedLead.Email, 'test@test.com',
        'The field email of the returned lead should be equal to test@test.com'); 
        System.assertEquals(returnedLead.phone, '1234',
        'The field phone of the returned lead should be equal to 1234'); 
        System.assertEquals(returnedLead.RC_Visitor_ID__c, '1234',
        'The field RC_Visitor_ID__c of the returned lead should be equal to 1234'); 
        System.assertEquals(returnedLead.Adobe_Target_Id__c, '1544',
        'The field Adobe_Target_Id__c of the returned lead should be equal to 1544'); 
        System.assertEquals(returnedLead.Adobe_Target_Id_History__c, '980',
        'The field Adobe_Target_Id_History__c of the returned lead should be equal to 980'); 
        System.assertEquals(returnedLead.AID__c, '99',
        'The field AID__c of the returned lead should be equal to 99'); 
        System.assertEquals(returnedLead.PID__c, '865',
        'The field PID__c of the returned lead should be equal to 865');  
        System.assertEquals(returnedLead.KCID__c, '4556',
        'The field KCID__c of the returned lead should be equal to 4556');  
        System.assertEquals(returnedLead.GCLID__c, '9877',
        'The field GCLID__c of the returned lead should be equal to 9877'); 
        System.assertEquals(returnedLead.ECID__c, '5768',
        'The field ECID__c of the returned lead should be equal to 5768');    
    }

    @isTest
    static void testConstructorSourceEqualDriftMatchingCampaign() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&bmid=SGFACEBOOK'
                                                + '&fname=test&lname=te&email=test@test.com&phone=1234&rcvid=1234'
                                                + '&atid=1544&atid_history=980&aid=99&pid=865&kcid=4556&gclid=9877&ecid=5768');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        Campaign sgFacebook = (Campaign) new SObjectBuilder(Campaign.sObjectType)
        .setField(Campaign.Name, 'sgFacebookCampaign')
        .setField(Campaign.Intended_Product__c, 'AU General')
        .setField(Campaign.BMID__c, 'SGFACEBOOK')
        .setField(Campaign.IsActive, true)
        .create()
        .getRecord();
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        Test.stopTest();
        Lead returnedLead = lse.newLead;
        System.assertEquals('SGFACEBOOK', lse.newlead.BMID__c, 'BMID should be SGFACEBOOK');
        System.assertEquals(returnedLead.FirstName, 'test',
        'The field firstName of the returned lead should be equal to test'); 
        System.assertEquals(returnedLead.LastName, 'te',
        'The field lastName of the returned lead should be equal to te'); 
        System.assertEquals(returnedLead.Email, 'test@test.com',
        'The field email of the returned lead should be equal to test@test.com'); 
        System.assertEquals(returnedLead.phone, '1234',
        'The field phone of the returned lead should be equal to 1234'); 
        System.assertEquals(returnedLead.RC_Visitor_ID__c, '1234',
        'The field RC_Visitor_ID__c of the returned lead should be equal to 1234'); 
        System.assertEquals(returnedLead.Adobe_Target_Id__c, '1544',
        'The field Adobe_Target_Id__c of the returned lead should be equal to 1544'); 
        System.assertEquals(returnedLead.Adobe_Target_Id_History__c, '980',
        'The field Adobe_Target_Id_History__c of the returned lead should be equal to 980'); 
        System.assertEquals(returnedLead.AID__c, '99',
        'The field AID__c of the returned lead should be equal to 99'); 
        System.assertEquals(returnedLead.PID__c, '865',
        'The field PID__c of the returned lead should be equal to 865');  
        System.assertEquals(returnedLead.KCID__c, '4556',
        'The field KCID__c of the returned lead should be equal to 4556');  
        System.assertEquals(returnedLead.GCLID__c, '9877',
        'The field GCLID__c of the returned lead should be equal to 9877'); 
        System.assertEquals(returnedLead.ECID__c, '5768',
        'The field ECID__c of the returned lead should be equal to 5768');  
        System.assertEquals(returnedLead.Primary_Campaign__c, sgFacebook.Id,
        'The field Primary_Campaign__c of the returned lead should be equal to the id of the matchedCampaign');      
    }

    @isTest
    static void testSearchMatchingContactByPhoneSourceDrift() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&bmid=SGFACEBOOK'
                                                + '&fname=test&lname=te&email=test@test.com&phone=1234&rcvid=1234'
                                                + '&atid=1544&atid_history=980&aid=99&pid=865&kcid=4556&gclid=9877&ecid=5768');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.Phone = '1234567890';
        lse.search();
        Test.stopTest();

        System.assertEquals(
            true,
            lse.matchedContactList.size() == 1,
            'there should be 1 contact in matchedContactData list'); 
    }    

    @isTest
    static void testSearchMatchingContactByEmailSourceDrift() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&bmid=SGFACEBOOK'
                                                + '&fname=test&lname=te&email=test@test.com&phone=1234&rcvid=1234'
                                                + '&atid=1544&atid_history=980&aid=99&pid=865&kcid=4556&gclid=9877&ecid=5768');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.Email = 'test@test.com';
        lse.search();
        Test.stopTest();

        System.assertEquals(
            true,
            lse.matchedContactList.size() == 1,
            'there should be 1 contact in matchedContactData list'); 
    }    

    @isTest
    static void testSearchMatchingContactByEmailAndPhoneSourceDrift() {
        PageReference pr = new PageReference('/apex/LeadSearchExtension?ANI=5551234&DNIS=34543435'
                                                + '&Skill=TestSkill&CID=5345345&source=Drift&bmid=SGFACEBOOK'
                                                + '&fname=test&lname=te&email=test@test.com&phone=1234&rcvid=1234'
                                                + '&atid=1544&atid_history=980&aid=99&pid=865&kcid=4556&gclid=9877&ecid=5768');
        Lead ld = (Lead) new LeadSelector().selectLeads().selectFields(new List<String>{'User_ID__c', 'ZI_CDP_Account_Id__c'}).executeQuery()[0];
        
        Test.setCurrentPage(pr);
        ApexPages.StandardController controller = new ApexPages.standardController(ld);

        Test.startTest();
        LeadSearchExtension lse = new LeadSearchExtension(controller);
        lse.newLead.Email = 'test@test.com';
        lse.newLead.Phone = '1234567890';
        lse.search();
        Test.stopTest();

        System.assertEquals(
            true,
            lse.matchedContactList.size() == 1,
            'there should be 1 contact in matchedContactData list'); 
    }    

    @isTest
    static void testRedirectNotPowerPartnerUser() {

        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'TestUs3r@t3st.com')
            .setField(User.LastName, 'TestUser')
            .setField(User.CommunityNickname, 't3st13')
            .create()
            .getRecord();

        System.Test.startTest();
        Lead ld = (Lead) new LeadSelector()
            .selectLeads()
            .executeQuery()[0];
        PageReference pageRef = Page.LeadSearchExtension;
        Id partnerLeadRTId = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId();
        System.runAs(testUser) {
            LeadSearchExtension lse = new LeadSearchExtension(new ApexPages.StandardController(ld));
            pageRef.getParameters().put('retURL', 'test');
            pageRef.getParameters().put( 'RecordType',partnerLeadRTId);
            System.Test.setCurrentPage(pageRef);
            pageRef = lse.redirectPartnerUser();
        }
        System.Test.stopTest();
        System.assert(pageRef.getUrl().contains('/apex/LeadCreationPartnerVAR'), 'Page reference did not redirect successfully');
    }
    
    @isTest
    static void testRedirectNull() {
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'T3stUser@test.com')
            .setField(User.LastName, 'TestUser')
            .setField(User.CommunityNickname, 't3st1')
            .create()
            .getRecord();

        System.Test.startTest();
        Lead ld = (Lead) new LeadSelector()
            .selectLeads()
            .executeQuery()[0];
        PageReference pageRef = Page.LeadSearchExtension;
        System.runAs(testUser) {
            LeadSearchExtension lse = new LeadSearchExtension(new ApexPages.StandardController(ld));
            pageRef.getParameters().put('retURL', 'test');
            System.Test.setCurrentPage(pageRef);
            pageRef = lse.redirectPartnerUser();
        }
        System.Test.stopTest();
        System.assertEquals(pageRef, null , 'Page reference did not redirect successfully');
    }
}
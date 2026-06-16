@isTest
private class Test_BatchJob_BmidFix {
    @isTest
    static void testBMIDFixTALStatusDFR() {
        User sdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'sdrUserMail@mailtest.com')
            .setField(User.Email, 'sdrUserMail@mailtest.com')
            .setfield(User.LastName, 'sdrLastName')
            .setField(User.CommunityNickname, 'SDRName')
            .setField(User.Team__c, 'SDR - Upmarket')
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, 'BmidFix')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, sdrUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c'
            }
        );

        dfrList[0].SAL_Handoff_Owner__c = 'testValue2';
        update dfrList[0];

        Test.startTest();
            Database.executeBatch(new BatchJob_BmidFix('Fix'));
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c',
                'Prospect_BMID__c',
                'MQL_BMID__c',
                'TQL_BMID__c',
                'TAL_BMID__c',
                'SQL_BMID__c',
                'SAL_BMID__c',
                'EOL_BMID__c'
            }
        );

        System.assertEquals(1, dfrs.size(), 'DFR creation failed');
        System.assertEquals('testValue2', dfrs[0].Prospect_BMID__c, 'Prospect_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].TAL_BMID__c, 'TAL_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].MQL_BMID__c, 'MQL_BMID__c was not populated');
        System.assertEquals(null, dfrs[0].TQL_BMID__c, 'TQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].SQL_BMID__c, 'SQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].EOL_BMID__c, 'EOL_BMID__c was populated');
    }

    @isTest
    static void testBMIDFixSALStatusDFR() {

        User aeUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME + '2')
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL + '2')
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME + '2')
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME + '2')
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, 'BmidFix')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c'
            }
        );

        dfrList[0].SAL_Handoff_Owner__c = 'testValue2';
        update dfrList[0];

        Test.startTest();
            Database.executeBatch(new BatchJob_BmidFix('Fix'));
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c',
                'Prospect_BMID__c',
                'MQL_BMID__c',
                'TQL_BMID__c',
                'TAL_BMID__c',
                'SAL_BMID__c',
                'SQL_BMID__c',
                'EOL_BMID__c'
            }
        );

        System.assertEquals(1, dfrs.size(), 'DFR creation failed');
        System.assertEquals('testValue2', dfrs[0].Prospect_BMID__c, 'Prospect_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].SAL_BMID__c, 'SAL_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].MQL_BMID__c, 'MQL_BMID__c was not populated');
        System.assertEquals(null, dfrs[0].TAL_BMID__c, 'TAL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].TQL_BMID__c, 'TQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].SQL_BMID__c, 'SQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].EOL_BMID__c, 'EOL_BMID__c was populated');
    }

    @isTest
    static void testBMIDFixOpportunityContactDFR() {

        User aeUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, Test_DemandFunnelHelper.AEUSERNAME)
            .setField(User.Email, Test_DemandFunnelHelper.AELASTNAME + Test_DemandFunnelHelper.LEADEMAIL + '2')
            .setField(User.LastName, Test_DemandFunnelHelper.AELASTNAME)
            .setField(User.CommunityNickname, Test_DemandFunnelHelper.AECOMMUNITYNICKNAME + '2')
            .setField(User.Team__c, Test_DemandFunnelHelper.AETEAM)
            .create()
            .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, 'BmidFix')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, aeUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        Account acc = Test_DemandFunnelHelper.createTestAccount();
        Contact con = Test_DemandFunnelHelper.createTestContact(acc);
        Opportunity opp = Test_DemandFunnelHelper.createTestOpportunity(con);

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c'
            }
        );

        dfrList[0].SAL_Handoff_Owner__c = 'testValue2';
        dfrList[0].Opportunity__c = opp.Id;
        dfrList[0].Contact__c = con.Id;
        update dfrList[0];

        Test.startTest();
            Database.executeBatch(new BatchJob_BmidFix('Fix'));
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c',
                'Prospect_BMID__c',
                'MQL_BMID__c',
                'TQL_BMID__c',
                'TAL_BMID__c',
                'SAL_BMID__c',
                'SQL_BMID__c',
                'EOL_BMID__c'
            }
        );

        System.assertEquals(1, dfrs.size(), 'DFR creation failed');
        System.assertEquals('testValue2', dfrs[0].Prospect_BMID__c, 'Prospect_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].SAL_BMID__c, 'SAL_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].MQL_BMID__c, 'MQL_BMID__c was not populated');
        System.assertEquals(null, dfrs[0].TAL_BMID__c, 'TAL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].TQL_BMID__c, 'TQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].EOL_BMID__c, 'EOL_BMID__c was populated');
    }

    @isTest
    static void testBMIDFixCheckCampaignAssignation() {
        User sdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'sdrUserMail@mailtest.com')
            .setField(User.Email, 'sdrUserMail@mailtest.com')
            .setfield(User.LastName, 'sdrLastName')
            .setField(User.CommunityNickname, 'SDRName')
            .setField(User.Team__c, 'SDR - Upmarket')
            .create()
            .getRecord();
        
        Campaign cn = (Campaign) new SObjectBuilder(Campaign.SObjectType)
        .setField(Campaign.BMID__c, 'testValue2')
        .setField(Campaign.Sell_Type__c, 'Existing Business')
        .setField(Campaign.Name, 'testcm')
        .create()
        .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, 'BmidFix')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, sdrUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c'
            }
        );

        dfrList[0].SAL_Handoff_Owner__c = 'testValue2';
        update dfrList[0];

        Test.startTest();
            Database.executeBatch(new BatchJob_BmidFix('Fix'));
        Test.stopTest();

        List<Demand_Funnel__c> dfrs = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c',
                'First_Activity_ID_after_MQL__c',
                'First_Activity_DateTime_after_MQL__c',
                'First_Activity_Name_after_MQL__c',
                'Prospect_BMID__c',
                'MQL_BMID__c',
                'TQL_BMID__c',
                'TAL_BMID__c',
                'SQL_BMID__c',
                'SAL_BMID__c',
                'EOL_BMID__c',
                'TAL_Campaign__c'
            }
        );

        System.assertEquals(1, dfrs.size(), 'DFR creation failed');
        System.assertEquals('testValue2', dfrs[0].Prospect_BMID__c, 'Prospect_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].TAL_BMID__c, 'TAL_BMID__c was not populated');
        System.assertEquals('testValue2', dfrs[0].MQL_BMID__c, 'MQL_BMID__c was not populated');
        System.assertEquals(null, dfrs[0].TQL_BMID__c, 'TQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].SQL_BMID__c, 'SQL_BMID__c was populated');
        System.assertEquals(null, dfrs[0].EOL_BMID__c, 'EOL_BMID__c was populated');
        System.assertEquals(cn.Id, dfrs[0].TAL_Campaign__c, 'TAL_BMID__c was not populated');
    }


    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void testBMIDFixCheckEmailExport() {
        User sdrUser = (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, 'sdrUserMail@mailtest.com')
            .setField(User.Email, 'sdrUserMail@mailtest.com')
            .setfield(User.LastName, 'sdrLastName')
            .setField(User.CommunityNickname, 'SDRName')
            .setField(User.Team__c, 'SDR - Upmarket')
            .create()
            .getRecord();
        
        BatchJobsConfiguration__c bjc = (BatchJobsConfiguration__c) new SObjectBuilder(BatchJobsConfiguration__c.SObjectType)
            .setField(BatchJobsConfiguration__c.Name, 'BatchJob_BmidFix')
            .setField(BatchJobsConfiguration__c.ErrorEmailDistributionList__c, 'testmail@testmail.com,testtest@mail.com')
            .create()
            .getRecord();

        Campaign cn = (Campaign) new SObjectBuilder(Campaign.SObjectType)
        .setField(Campaign.BMID__c, 'testValue2')
        .setField(Campaign.Sell_Type__c, 'Existing Business')
        .setField(Campaign.Name, 'testcm')
        .create()
        .getRecord();

        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSNEW)
            .setField(Lead.LastName, 'BmidFix')
            .setField(Lead.Email, Test_DemandFunnelHelper.LEADEMAIL)
            .setField(Lead.Status, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Lead.Phone, Test_DemandFunnelHelper.LEADPHONE)
            .setField(Lead.OwnerId, sdrUser.Id)
            .setField(Lead.LeadSource, Test_DemandFunnelHelper.LEADSOURCE)
            .create()
            .getRecord();

        List<Demand_Funnel__c> dfrList = Test_DemandFunnelHelper.getDFRS(
            ld,
            new List<String>{
                'Lead__c'
            }
        );

        dfrList[0].SAL_Handoff_Owner__c = 'testValue2';
        update dfrList[0];

        Test.startTest();
            Database.executeBatch(new BatchJob_BmidFix('Export'));
        Test.stopTest();
    }
}
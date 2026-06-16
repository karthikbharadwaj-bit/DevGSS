@isTest
private class Test_SharedLeadCampaign {

    @testSetup
    static void makeData(){
        User marketingUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
            .setField(User.UserPermissionsMarketingUser, true)
            .create()
            .getRecord();

        List<Campaign> campampaignList = (List<Campaign>) new SObjectBuilder(Campaign.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => ValueProviderBuilder.provideList(
                        new List<String> {
                            'campNonAtt', 
                            'campNonAtt2', 
                            'campAtt', 
                            'campAtt2'
                        }
                    ),
                    Campaign.Non_Attributable__c => ValueProviderBuilder.provideList(
                        new List<Boolean> {
                            true, 
                            true, 
                            false, 
                            false
                        }
                    )
                }
            )
            .quantity(4)
            .createAsUser(marketingUser)
            .getRecords();

        List<Lead> leadList = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake@email.com',
                    Lead.LastName => 'TestLead',
                    Lead.Company => 'fakeCompany',
                    Lead.Lead_System_Source__c => LeadHelper.LEAD_SOURCE_INBOUND_CALL,
                    Lead.Primary_Campaign__c => campampaignList[3].Id
                }
            )
            .quantity(1)
            .create()
            .getRecords();
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttNonAtt() {
        Campaign camp = [SELECT Id
                         FROM Campaign
                         WHERE Name =: 'campAtt'
                         LIMIT 1];

        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];

        ld.Primary_Campaign__c = camp.id;
        ld.Most_Recent_Campaign__c = camp.id;
        update ld;
        Test.startTest();
            Lead lead = [SELECT Most_Recent_Campaign__c 
                         FROM Lead 
                         WHERE LastName = 'TestLead'
                         LIMIT 1];
            Campaign NonAttCampaign = [SELECT Id
                                       FROM Campaign
                                       WHERE Name = 'campNonAtt'
                                       LIMIT 1];

            lead.Primary_Campaign__c = NonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = NonAttCampaign.Id;
            update lead;

        Test.stopTest();
        lead = [SELECT Most_Recent_Campaign__c 
                FROM Lead 
                WHERE LastName = 'TestLead'
                LIMIT 1];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, NonAttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttAtt() {
        Campaign camp = [SELECT Id
                         FROM Campaign
                         WHERE Name =: 'campNonAtt'
                         LIMIT 1];

        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];
        
        ld.Primary_Campaign__c = camp.id;
        ld.Most_Recent_Campaign__c = camp.id;
        update ld;
        Test.startTest();
            Lead lead = [SELECT Most_Recent_Campaign__c 
                         FROM Lead 
                         WHERE LastName = 'TestLead'
                         LIMIT 1];
            
            Campaign AttCampaign = [SELECT Id
                                    FROM Campaign
                                    WHERE Name = 'campAtt'
                                    LIMIT 1];

            lead.Primary_Campaign__c = AttCampaign.Id;
            lead.Most_Recent_Campaign__c = AttCampaign.Id;
            update lead;

        Test.stopTest();

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, AttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNonAttNonAtt() {
        Campaign camp = [SELECT Id
                         FROM Campaign
                         WHERE Name =: 'campNonAtt'
                         LIMIT 1];

        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];

        ld.Primary_Campaign__c = camp.id;
        ld.Most_Recent_Campaign__c = camp.id;
        update ld;
        Test.startTest();
            Lead lead = [SELECT Most_Recent_Campaign__c 
                         FROM Lead 
                         WHERE LastName = 'TestLead'
                         LIMIT 1];

            Campaign NonAttCampaign = [SELECT Id
                                       FROM Campaign
                                       WHERE Name = 'campNonAtt2'
                                       LIMIT 1];

            lead.Primary_Campaign__c = NonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = NonAttCampaign.Id;
            update lead;
        Test.stopTest();

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, NonAttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateAttAtt() {
        Campaign camp = [SELECT Id
                         FROM Campaign
                         WHERE Name =: 'campAtt'
                         LIMIT 1];

        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];

        ld.Primary_Campaign__c = camp.id;
        ld.Most_Recent_Campaign__c = camp.id;
        update ld;
        Test.startTest();
            Lead lead = [SELECT Most_Recent_Campaign__c 
                         FROM Lead 
                         WHERE LastName = 'TestLead'
                         LIMIT 1];
            Campaign AttCampaign = [SELECT Id
                                    FROM Campaign
                                    WHERE Name = 'campAtt2'
                                    LIMIT 1];

            lead.Primary_Campaign__c = AttCampaign.Id;
            lead.Most_Recent_Campaign__c = AttCampaign.Id;
            update lead;
        Test.stopTest();

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, AttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testMostRecentCampaignAfterUpdateNullNonAtt() {
        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];

        ld.Primary_Campaign__c = null;
        ld.Most_Recent_Campaign__c = null;
        update ld;

        Test.startTest();
            Lead lead = [SELECT Most_Recent_Campaign__c 
                         FROM Lead 
                         WHERE LastName = 'TestLead'
                         LIMIT 1];

            Campaign NonAttCampaign = [SELECT Id
                                       FROM Campaign
                                       WHERE Name = 'campNonAtt'
                                       LIMIT 1];

            lead.Primary_Campaign__c = NonAttCampaign.Id;
            lead.Most_Recent_Campaign__c = NonAttCampaign.Id;
            update lead;
        Test.stopTest();

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from null Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, NonAttCampaign.Id,
            'Most Recent Campaign should change after Lead is updated from Null Campaign to Non Attributable');
    }

    @isTest
    private static void testNullMRCAAndOldCamp() {
        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];

        ld.Primary_Campaign__c = null;
        ld.Most_Recent_Campaign__c = null;
        update ld;
        Campaign nonAttCampaign = [SELECT Id
                                   FROM Campaign
                                   WHERE Name = 'campNonAtt'
                                   LIMIT 1];
        CampaignMember  campMemb = new CampaignMember(LeadId = ld.Id,
                                                      CampaignId = nonAttCampaign.Id,
                                                      Old_Campaign__c = null);
        Test.startTest();
            insert campMemb;
        Test.stopTest();
        ld = [SELECT Most_Recent_Campaign__c 
              FROM Lead 
              WHERE LastName = 'TestLead'
              LIMIT 1];
        System.assertEquals(ld.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should update from null to Non att');
    }

    @isTest
    private static void testNullOldCampAndNonAttMRC() {
        Campaign campaign = [SELECT Id
                             FROM Campaign
                             WHERE Name = 'campNonAtt'
                             LIMIT 1];
        List<Lead> leadList = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake123@email.com',
                    Lead.LastName => 'TestLead1234',
                    Lead.Company => 'fakeCompany',
                    Lead.Lead_System_Source__c => LeadHelper.LEAD_SOURCE_INBOUND_CALL,
                    Lead.Primary_Campaign__c => campaign.Id,
                    Lead.Most_Recent_Campaign__c => campaign.Id
                }
            )
            .quantity(1)
            .create()
            .getRecords();
        Lead ld = leadList[0];
        Campaign nonAttCampaign = [SELECT Id
                                   FROM Campaign
                                   WHERE Name = 'campNonAtt2'
                                   LIMIT 1];
        CampaignMember  campMemb = new CampaignMember(LeadId = ld.Id,
                                                      CampaignId = nonAttCampaign.Id,
                                                      Old_Campaign__c = null);
        Test.startTest();
            insert campMemb;
        Test.stopTest();
        ld = [SELECT Most_Recent_Campaign__c 
              FROM Lead 
              WHERE LastName = 'TestLead1234'
              LIMIT 1];
        System.assertEquals(ld.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should update to Non att campaign');
    }


    @isTest
    private static void testAttOldCamp() {
        Campaign firstCampaign = [SELECT Id
                                  FROM Campaign
                                  WHERE Name = 'campNonAtt'
                                  LIMIT 1];
        Campaign attCampaign = [SELECT Id
                                FROM Campaign
                                WHERE Name = 'campAtt2'
                                LIMIT 1];
        Lead ld = [SELECT Most_Recent_Campaign__c 
                   FROM Lead 
                   WHERE LastName = 'TestLead'
                   LIMIT 1];
        ld.Most_Recent_Campaign__c = firstCampaign.Id;
        update ld;
        CampaignMember  campMemb = new CampaignMember(LeadId = ld.Id,
                                                      CampaignId = firstCampaign.Id,
                                                      Old_Campaign__c = attCampaign.Id);
        Test.startTest();
            insert campMemb;
        Test.stopTest();
        ld = [SELECT Most_Recent_Campaign__c 
              FROM Lead 
              WHERE LastName = 'TestLead'
              LIMIT 1];
        System.assertEquals(ld.Most_Recent_Campaign__c, attCampaign.Id,
            'Most Recent Campaign should not update from Att to Non att');
    }

    @isTest
    private static void testNonAttOldCamp() {
        Campaign firstCampaign = [SELECT Id,Non_Attributable__c
                                  FROM Campaign
                                  WHERE Name = 'campNonAtt'
                                  LIMIT 1];
        Campaign nonAttCampaign = [SELECT Id,Non_Attributable__c
                                   FROM Campaign
                                   WHERE Name = 'campNonAtt2'
                                   LIMIT 1];
        List<Lead> leadList = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'fake123@email.com',
                    Lead.LastName => 'TestLead1234',
                    Lead.Company => 'fakeCompany',
                    Lead.Lead_System_Source__c => LeadHelper.LEAD_SOURCE_INBOUND_CALL,
                    Lead.Primary_Campaign__c => firstCampaign.Id,
                    Lead.Most_Recent_Campaign__c => firstCampaign.Id
                }
            )
            .quantity(1)
            .create()
            .getRecords();
        Lead ld = leadList[0];
        CampaignMember  campMemb = new CampaignMember(LeadId = ld.Id,
                                                      CampaignId = nonAttCampaign.Id,
                                                      Old_Campaign__c = firstCampaign.Id);
        Test.startTest();
        insert campMemb;
        Test.stopTest();
        System.assert(campMemb.id <> null);
        Lead lead = [SELECT Most_Recent_Campaign__c,Most_Recent_Campaign__r.name,Most_Recent_Campaign__r.Non_Attributable__c
                        FROM Lead 
                        WHERE LastName = 'TestLead1234'
                        LIMIT 1];

        System.assertEquals(lead.Most_Recent_Campaign__c, nonAttCampaign.Id,
            'Most Recent Campaign should update from Non Att to Non att');
    }


}
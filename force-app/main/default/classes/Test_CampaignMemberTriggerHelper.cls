@isTest
public class Test_CampaignMemberTriggerHelper {

    public static void createCampaigns() {
        List<Campaign> testCamps = new List<Campaign>();
        Campaign campNonAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                                  .setField(Campaign.Non_Attributable__c, true)
                                  .setField(Campaign.Name, 'campNonAtt')
                                  .setField(Campaign.BMID__c, 'NonAttributableBMID')
                                  .build()
                                  .getRecord();
        testCamps.add(campNonAtt);

        Campaign campNonAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                                   .setField(Campaign.Non_Attributable__c, true)
                                   .setField(Campaign.Name, 'campNonAtt2')
                                   .setField(Campaign.BMID__c, 'NonAttributableBMID2')
                                   .build()
                                   .getRecord();
        testCamps.add(campNonAtt2);

        Campaign campAtt = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                               .setField(Campaign.Non_Attributable__c, false)
                               .setField(Campaign.Name, 'campAtt')
                               .setField(Campaign.BMID__c, 'AttributableBMID')
                               .build()
                               .getRecord();
        testCamps.add(campAtt);

        Campaign campAtt2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                                .setField(Campaign.Non_Attributable__c, false)
                                .setField(Campaign.Name, 'campAtt2')
                                .setField(Campaign.BMID__c, 'AttributableBMID2')
                                .build()
                                .getRecord();
        testCamps.add(campAtt2);

        Campaign sharedLeadCamp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                                      .setField(Campaign.Shared_Lead_Campaign__c, true)
                                      .setField(Campaign.Non_Attributable__c, true)
                                      .setField(Campaign.Intended_Product__c, 'US Office')
                                      .setField(Campaign.Name, 'sharedLeadCamp')
                                      .build()
                                      .getRecord();
        testCamps.add(sharedLeadCamp);

        insert testCamps;
    }
    
    public static void insertFeatureToggle() {
        Feature_Toggle__c featureToggle = new Feature_Toggle__c();
        insert featureToggle;
    }

    public static Campaign getCampaign(List<Object> bindings) {
        return (Campaign) new CampaignSelector().selectCampaignsByName(bindings).executeQuery()[0];
    }

    @isTest
    private static void testLeadMRCUpdateAttNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Primary_Campaign__c, attCamp.Id)
                               .setField(Lead.Most_Recent_Campaign__c, attCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
             'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Non Attributable');
         System.assertEquals(lead.Most_Recent_Campaign__c, attCamp.Id,
            'Most Recent Campaign should still be the Attributable Campaign\'s Id');
        System.assertEquals(lead.Primary_Campaign__c, attCamp.Id,
            'Primary Campaign should still be the Attributable Campaign\'s Id');
    }

    @isTest
    private static void testLeadMRCAfterUpdateNonAttAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Primary_Campaign__c, nonAttCamp.Id)
                               .setField(Lead.Most_Recent_Campaign__c, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, attCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, attCamp.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Attributable'); 
        System.assertEquals(lead.Primary_Campaign__c, attCamp.Id,
            'Primary Campaign should change after Lead is updated from Non Attributable Campaign to Attributable');
    }

    @isTest
    private static void testLeadMRCAfterUpdateNonAttNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campNonAtt2');
        Campaign nonAttCamp2 = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Primary_Campaign__c, nonAttCamp.Id)
                               .setField(Lead.Most_Recent_Campaign__c, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                                      .setField(CampaignMember.LeadId, lead.Id)
                                      .setField(CampaignMember.CampaignId, nonAttCamp2.Id)
                                      .create()
                                      .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, nonAttCamp2.Id,
            'Most Recent Campaign should change after Lead is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(lead.Primary_Campaign__c, nonAttCamp2.Id,
            'Primary Campaign should change after Lead is updated from Non Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testLeadMRCAfterUpdateAttAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campAtt2');
        Campaign attCamp2 = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Primary_Campaign__c, attCamp.Id)
                               .setField(Lead.Most_Recent_Campaign__c, attCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, attCamp2.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from Attributable Campaign to Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, attCamp2.Id,
            'Most Recent Campaign should change after Lead is updated from Attributable Campaign to Attributable');
        System.assertEquals(lead.Primary_Campaign__c, attCamp2.Id,
            'Primary Campaign should change after Lead is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testLeadMRCAfterUpdateNullNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Primary_Campaign__c, null)
                               .setField(Lead.Most_Recent_Campaign__c, null)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Lead is updated from null Campaign to Non Attributable');
        System.assertEquals(lead.Most_Recent_Campaign__c, nonAttCamp.Id,
            'Most Recent Campaign should change after Lead is updated from Null Campaign to Non Attributable');
    }
    
    private static void testContactMRCAfterUpdateAttNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, attCamp.Id)
                               .setField(Contact.Most_Recent_Campaign__c, attCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, attCamp.Id,
            'Most Recent Campaign should change after Contact is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testContactMRCAfterUpdateNonAttAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, nonAttCamp.Id)
                               .setField(Contact.Most_Recent_Campaign__c, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, attCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Contact is updated from Non Attributable Campaign to Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, attCamp.Id,
            'Most Recent Campaign should change after Contact is updated from Non Attributable Campaign to Attributable');
    }

    @isTest
    private static void testContactMRCAfterUpdateNonAttNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campNonAtt2');
        Campaign nonAttCamp2 = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, nonAttCamp.Id)
                               .setField(Contact.Most_Recent_Campaign__c, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp2.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Contact is updated from Non Attributable Campaign to Non Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, nonAttCamp2.Id,
            'Most Recent Campaign should change after Contact is updated from Non Attributable Campaign to Non Attributable');
    }

    @isTest
    private static void testContactMRCAfterUpdateAttAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campAtt');
        Campaign attCamp = getCampaign(bindings);
        bindings.clear();
        bindings.add('campAtt2');
        Campaign attCamp2 = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, attCamp.Id)
                               .setField(Contact.Most_Recent_Campaign__c, attCamp.Id)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, attCamp2.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Contact is updated from Attributable Campaign to Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, attCamp2.Id,
            'Most Recent Campaign should change after Contact is updated from Attributable Campaign to Attributable');
    }

    @isTest
    private static void testContactMRCAfterUpdateNullNonAtt() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, null)
                               .setField(Contact.Most_Recent_Campaign__c, null)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assert(con.Most_Recent_Campaign__c != null, 
            'Most Recent Campaign should not be null after Contact is updated from null Campaign to Non Attributable');
        System.assertEquals(con.Most_Recent_Campaign__c, nonAttCamp.Id,
            'Most Recent Campaign should change after Contact is updated from Null Campaign to Non Attributable');
    }

    @isTest
    private static void testContactBMIDfterUpdate() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('campNonAtt');
        Campaign nonAttCamp = getCampaign(bindings);

        Triggers.switchOff();
        Contact con = (Contact) new SObjectBuilder(Contact.sObjectType)
                               .setField(Contact.LastName, 'TestContact')
                               .setField(Contact.Primary_Campaign__c, null)
                               .setField(Contact.Most_Recent_Campaign__c, null)
                               .setField(Contact.BMID__c, 'test')
                               .setField(Contact.AID__c, 'test')
                               .setField(Contact.PID__c, 'test')
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        TriggerHandler.UPDATE_CONTACT_BMID = true;
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.ContactId, con.Id)
                               .setField(CampaignMember.CampaignId, nonAttCamp.Id)
                               .create()
                               .getRecord();
        TriggerHandler.UPDATE_CONTACT_BMID = false;
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{con.Id});
        con = (Contact) new ContactSelector().selectContactsByIds(bindings).executeQuery()[0];

        System.assertEquals(con.BMID__c, 'SOLVETHENSELL', 
            'Contacts BMID should change to SOLVETHENSELL');
        System.assertEquals(con.AID__c, null, 
            'Contacts AID should change to blank');
        System.assertEquals(con.PID__c, null, 
            'Contacts PID should change to blank');
    }

    @isTest
    private static void testNullSharedLeadCounterfterUpdate() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('sharedLeadCamp');
        Campaign sharedLeadCamp = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Shared_Lead_Counter__c, null)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, sharedLeadCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Shared_Lead_Counter__c != null, 
            'Shared Lead Counter should not be null after Lead is updated with a Shared Lead Campaign');
        System.assertEquals(lead.Shared_Lead_Counter__c, 1,
            'Shared Lead Counter should from null to 1 if Lead is updated with a Shared Lead Campaign');
    }

    @isTest
    private static void testSharedLeadCounterfterUpdate() {
        insertFeatureToggle();
        createCampaigns();
        List<Object> bindings = new List<Object>();
        bindings.add('sharedLeadCamp');
        Campaign sharedLeadCamp = getCampaign(bindings);

        Triggers.switchOff();
        Lead lead = (Lead) new SObjectBuilder(Lead.sObjectType)
                               .setField(Lead.LastName, 'TestLead')
                               .setField(Lead.Shared_Lead_Counter__c, 1)
                               .create()
                               .getRecord();
        Triggers.switchOn();

        Test.startTest();
        CampaignMember campMemb = (CampaignMember) new SObjectBuilder(CampaignMember.sObjectType)
                               .setField(CampaignMember.LeadId, lead.Id)
                               .setField(CampaignMember.CampaignId, sharedLeadCamp.Id)
                               .create()
                               .getRecord();
        Test.stopTest();

        bindings.clear();
        bindings.add(new Set<Id>{lead.Id});
        lead = (Lead) new LeadSelector().selectLeadsByIds(bindings).executeQuery()[0];

        System.assert(lead.Shared_Lead_Counter__c != null, 
            'Shared Lead Counter should not be null after Lead is updated with a Shared Lead Campaign');
        System.assertEquals(lead.Shared_Lead_Counter__c, 2,
            'Shared Lead Counter should increase by 1 if Lead is updated with a Shared Lead Campaign');
    }
    @isTest
    public static void update_MostRecentCampaignMemberStatus_on_LeadCreation() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
        Lead leadTest;
        Test.startTest();
            leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.lastName, 'LEAD TEST')
                .setField(Lead.BMID__c, '1')
                .setField(Lead.AID__c, '1')
                .setField(Lead.PID__c, '1')
                .create()
                .getRecord();
        Test.stopTest();

        List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(new Object[]{
                new Id[]{leadTest.Id}, 
                new Id[]{camp.Id}
            })
            .selectField(CampaignMember.Status)
            .executeQuery();

        System.assertEquals(1, cms.size(), 'Should be exist 1 Campaign Member');

        leadTest = (Lead) new LeadSelector()
            .selectLeadById(new Object[]{leadTest.Id})
            .selectField(Lead.Most_Recent_Campaign__c)
            .selectField(Lead.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(camp.Id, leadTest.Most_Recent_Campaign__c, 'The "Most Recent Campaign" should be equals that the campaign created in the test.');
        System.assertEquals(cms[0].Status, leadTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be the same as the campaign member');
    }
    @isTest
    public static void update_MostRecentCampaignMemberStatus_on_ContactCreation() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
        Contact contactTest;
        Test.startTest();
            contactTest = (Contact) new SObjectBuilder(Contact.sObjectType)
                .setField(Contact.lastName, 'Contact TEST')
                .setField(Contact.BMID__c, '1')
                .setField(Contact.AID__c, '1')
                .setField(Contact.PID__c, '1')
                .create()
                .getRecord();
        Test.stopTest();

        List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByContactAndCampaignIds(new Object[]{
                new Id[]{contactTest.Id}, 
                new Id[]{camp.Id}
            })
            .selectField(CampaignMember.Status)
            .executeQuery();

        System.assertEquals(1, cms.size(), 'There Should exist 1 Campaign Member');

        contactTest = (Contact) new ContactSelector()
            .selectContactById(new Object[]{contactTest.Id})
            .selectField(Contact.Most_Recent_Campaign__c)
            .selectField(Contact.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(camp.Id, contactTest.Most_Recent_Campaign__c, 'The "Most Recent Campaign" should be equals the id of the Campaign generated in the test');
        System.assertEquals(cms[0].Status, contactTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be equals the Status of the Campaign Member generated in the test');
    }
    @isTest
    public static void update_MostRecentCampaignMemberStatus_on_LeadUpdate() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'LEAD TEST')
            .setField(Lead.BMID__c, '1')
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        Test.startTest();
            leadTest.BMID__c = '2';
            update leadTest;
        Test.stopTest();

        List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(new Object[]{
                new Id[]{leadTest.Id}, 
                new Id[]{camp.Id}
            })
            .selectField(CampaignMember.Status)
            .executeQuery();

        System.assertEquals(1, cms.size(), 'Should be exist 1 Campaign Member');

        leadTest = (Lead) new LeadSelector()
            .selectLeadById(new Object[]{leadTest.Id})
            .selectField(Lead.Most_Recent_Campaign__c)
            .selectField(Lead.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(camp.Id, leadTest.Most_Recent_Campaign__c, 'The "Most Recent Campaign" should be equals that the campaign created in the test.');
        System.assertEquals(cms[0].Status, leadTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be the same as the campaign member');
    }
    @isTest
    public static void update_MostRecentCampaignMemberStatus_on_ContactUpdate() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();
        
        Contact contactTest = (Contact) new SObjectBuilder(Contact.sObjectType)
                .setField(Contact.lastName, 'Contact TEST')
                .setField(Contact.BMID__c, null)
                .setField(Contact.AID__c, '1')
                .setField(Contact.PID__c, '1')
                .create()
                .getRecord();
        
        Test.startTest();
            contactTest.BMID__c = '1';
            update contactTest;
        Test.stopTest();

        List<CampaignMember> cms = (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByContactAndCampaignIds(new Object[]{
                new Id[]{contactTest.Id}, 
                new Id[]{camp.Id}
            })
            .selectField(CampaignMember.Status)
            .executeQuery();

        System.assertEquals(1, cms.size(), 'There Should exist 1 Campaign Member');

        contactTest = (Contact) new ContactSelector()
            .selectContactById(new Object[]{contactTest.Id})
            .selectField(Contact.Most_Recent_Campaign__c)
            .selectField(Contact.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(camp.Id, contactTest.Most_Recent_Campaign__c, 'The "Most Recent Campaign" should be equals the id of the Campaign generated in the test');
        System.assertEquals(cms[0].Status, contactTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be equals the Status of the Campaign Member generated in the test');
    }
    @isTest
    public static void blank_MostRecentCampaignMemberStatus_CampaignMemberDeletion_on_Lead() {

        Test.startTest();
            Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .setField(Campaign.IsActive, true)
                .setField(Campaign.Non_Attributable__c, false)
                .setField(Campaign.Name, 'campAtt3')
                .setField(Campaign.BMID__c, '1')
                .setField(Campaign.AID__c, '1')
                .setField(Campaign.PID__c, '1')
                .setField(Campaign.DNIS__c, '1')
                .create()
                .getRecord();
            
            Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
                .setField(Lead.lastName, 'LEAD TEST')
                .setField(Lead.BMID__c, '1')
                .setField(Lead.AID__c, '1')
                .setField(Lead.PID__c, '1')
                .create()
                .getRecord();
        Test.stopTest();

            delete (List<CampaignMember>) new CampaignMemberSelector()
            .selectCampaignMemberByLeadAndCampaignIds(new Object[]{
                new Id[]{leadTest.Id}, 
                new Id[]{camp.Id}
            })
            .executeQuery();

        leadTest = (Lead) new LeadSelector()
            .selectLeadsByIds(new Object[]{new Id[]{leadTest.Id}})
            .selectField(Lead.Most_Recent_Campaign__c)
            .selectField(Lead.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(null, leadTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be null');
    }
    @isTest
    public static void blank_MostRecentCampaignMemberStatus_CampaignMemberDeletion_on_Contact() {

        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt3')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();

        Test.startTest();
            Contact contactTest = (Contact) new SObjectBuilder(Contact.sObjectType)
                .setField(Contact.lastName, 'Contact TEST')
                .setField(Contact.BMID__c, '1')
                .setField(Contact.AID__c, '1')
                .setField(Contact.PID__c, '1')
                .create()
                .getRecord();
        Test.stopTest();
        
        //This is the real test. The creation of Contact should be inside "Test.startTest" and "Test.stopTest" because it has an asynchronous process.
        delete (List<CampaignMember>) new CampaignMemberSelector()
        .selectCampaignMemberByContactAndCampaignIds(new Object[]{
            new Id[]{contactTest.Id}, 
            new Id[]{camp.Id}
        })
        .executeQuery();

        contactTest = (Contact) new ContactSelector()
            .selectContactById(new Object[]{contactTest.Id})
            .selectField(Contact.Most_Recent_Campaign__c)
            .selectField(Contact.Most_Recent_Campaign_Member_Status__c)
            .executeQuery()[0];

        System.assertEquals(null, contactTest.Most_Recent_Campaign_Member_Status__c, 'The "Most Recent Campaign Member Status" should be null');
    }

    public static void update_MostRecentCampaignMemberStatus_on_ContactWhenUpdatesMostRecentCampaign() {
        
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt1')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();

        Campaign camp2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt2')
            .create()
            .getRecord();

        Contact contactTest = (Contact) new SObjectBuilder(Contact.sObjectType)
            .setField(Contact.lastName, 'Contact TEST')
            .setField(Contact.BMID__c, '1')
            .setField(Contact.AID__c, '1')
            .setField(Contact.PID__c, '1')
            .create()
            .getRecord();

        CampaignMember cm = (CampaignMember )new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.ContactId, contactTest.Id)
            .setField(CampaignMember.CampaignId, camp2.Id)
            .setField(CampaignMember.Status, 'Responded')
            .create()
            .getRecord();
        
        System.assertEquals('Sent', contactTest.Most_Recent_Campaign_Member_Status__c, 
            'The value of "Most Recent Campaign Member Status" should be Sent, current value: ' + contactTest.Most_Recent_Campaign_Member_Status__c
        );

        Test.startTest();
            contactTest.Most_Recent_Campaign__c = camp2.Id;
            update contactTest;
        Test.stopTest();
        
        System.assertEquals(cm.Status, contactTest.Most_Recent_Campaign_Member_Status__c, 
            'The value of "Most Recent Campaign Member Status" should be "Responded", current value: ' + contactTest.Most_Recent_Campaign_Member_Status__c
        );
    }
    public static void update_MostRecentCampaignMemberStatus_on_LeadWhenUpdatesMostRecentCampaign() {
        
        Campaign camp = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt1')
            .setField(Campaign.BMID__c, '1')
            .setField(Campaign.AID__c, '1')
            .setField(Campaign.PID__c, '1')
            .setField(Campaign.DNIS__c, '1')
            .create()
            .getRecord();

        Campaign camp2 = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .setField(Campaign.IsActive, true)
            .setField(Campaign.Non_Attributable__c, false)
            .setField(Campaign.Name, 'campAtt2')
            .create()
            .getRecord();

        Lead leadTest = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.lastName, 'Lead TEST')
            .setField(Lead.BMID__c, '1')
            .setField(Lead.AID__c, '1')
            .setField(Lead.PID__c, '1')
            .create()
            .getRecord();

        CampaignMember cm = (CampaignMember )new SObjectBuilder(CampaignMember.sObjectType)
            .setField(CampaignMember.ContactId, leadTest.Id)
            .setField(CampaignMember.CampaignId, camp2.Id)
            .setField(CampaignMember.Status, 'Responded')
            .create()
            .getRecord();
        
        System.assertEquals('Sent', leadTest.Most_Recent_Campaign_Member_Status__c, 
            'The value of "Most Recent Campaign Member Status" should be Sent, current value: ' + leadTest.Most_Recent_Campaign_Member_Status__c
        );

        Test.startTest();
            leadTest.Most_Recent_Campaign__c = camp2.Id;
            update leadTest;
        Test.stopTest();
        
        System.assertEquals(cm.Status, leadTest.Most_Recent_Campaign_Member_Status__c, 
            'The value of "Most Recent Campaign Member Status" should be "Responded", current value: ' + leadTest.Most_Recent_Campaign_Member_Status__c
        );
    }
}
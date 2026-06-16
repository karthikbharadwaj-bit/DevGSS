public class Test_DemandFunnelHelper {

    public static String LEADLASTNAME = 'TestLead';
    public static String LEADEMAIL = 'test@test.com';
    public static String LEADPHONE = '1234567890';
    public static String LEADSOURCE = 'FR Office Weblead';
    public static String AEUSERNAME = 'ae@rcmockDomain.com';
    public static String SDRUSERNAME = 'sdr@rcmockDomain.com';
    public static String BDRUSERNAME = 'bdr@rcmockDomain.com';
    public static String AELASTNAME = 'AEDFRTest';
    public static String SDRLASTNAME = 'SDRDFRTest';
    public static String BDRLASTNAME = 'BDRDFRTest';
    public static String AECOMMUNITYNICKNAME = 'testnicknameAE';
    public static String SDRCOMMUNITYNICKNAME = 'testnicknameSDR';
    public static String BDRCOMMUNITYNICKNAME = 'testnicknameBDR';
    public static String AETEAM = 'Managers';
    public static String SDRTEAM = 'SDR - Upmarket';
    public static String BDRTEAM = 'BDR';
    public static String SDRSEGMENT = 'SOHO';
    public static final String BACKFILLED = 'Backfilled';
    public static final String CREATED = 'Created';
    public static final String PROSPECTFUNNELSTATUS = '1 - Prospect';
    public static final String MQLFUNNELSTATUS = '2 - MQL';
    public static final String TALFUNNELSTATUS = '2a - TAL';
    public static final String SALFUNNELSTATUS = '3 - SAL';
    public static final String SQLFUNNELSTATUS = '4 - SQL';
    public static final String DOWNGRADEDFUNNELSTATUS = '0 - Downgraded';
    public static final String PROSPECT = 'Prospect';
    public static final String RENEW = 'Re-New';
    public static final String DOWNGRADED = 'Downgraded';
    public static final String MQL = 'MQL';
    public static final String TAL = 'TAL';
    public static final String TQL = 'TQL';
    public static final String SAL = 'SAL';
    public static final String SQL = 'SQL';

    static void setupData() {
        createSDRUser();
        createBDRUser();
        createAEUser();
        setupCustomSetting();


        Account acc = createTestAccount();
        Contact con = createTestContact(acc);
        Opportunity opp = createTestOpportunity(con);
    }

    public static void setupCustomSetting() {
        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'}) 
                }
            )
            .quantity(2)
            .create();
    }

    public static Account createTestAccount() {
        return (Account) new SObjectBuilder(Account.SObjectType)
            .setField(Account.Name, 'Opty test account')
            .setField(Account.Partner_ID__c, 'testID')
            .setField(Account.Permitted_Brands__c, 'RingCentral')
            .setField(Account.Phone, LEADPHONE)
            .create()
            .getRecord();
    }

    public static Opportunity createTestOpportunity(Contact con) {
        Date oldCloseDate = Date.today().addMonths(1);
        return (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, 'Planning')
            .setField(Opportunity.CloseDate, oldCloseDate)
            .setField(Opportunity.Primary_Opportunity_Contact__c, con.Id)
            .create()
            .getRecord();
    }

    public static Contact createTestContact(Account acc) {
        User aeUser = getUser(AELASTNAME);
        return (Contact) new SObjectBuilder(Contact.SObjectType)
            .setField(Contact.FirstName, 'John')
            .setField(Contact.LastName, 'Doe')
            .setField(Contact.Email, LEADEMAIL)
            .setField(Contact.Phone, LEADPHONE)
            .setField(Contact.Contact_Status__c, LeadTriggerHelper.LEADSTATUSCONTACTED)
            .setField(Contact.Preferred_Language__c, 'en_US')
            .setField(Contact.OwnerId, aeUser.Id)
            .setField(Contact.AccountId, acc.Id)
            .setField(Contact.Customer_Record__c, false)
            .create()
            .getRecord();
    }

    public static Account getTestAccount() {
        return (Account) new AccountSelector()
            .selectAccountByName(new List<Object>{ 'Opty test account' })
            .selectFields(new List<String>{ 'Name', 'Partner_ID__c', 'Permitted_Brands__c', 'Phone' })
            .executeQuery()[0];
    }

    public static Contact getTestContact(Account acc) {
        return (Contact) new ContactSelector()
            .selectContactsByAccountId(new List<Object>{ acc.Id })
            .selectFields(
                new List<String>{ 'FirstName', 'LastName', 'Email', 'Phone', 'Preferred_Language__c', 'AccountId', 'Contact_Status__c', 'Downgrade_Reason__c' }
            )
            .executeQuery()[0];
    }

    public static Opportunity getTestOpportunity() {
        return (Opportunity) new OpportunitySelector()
            .selectOpportunityByName('Test Opportunity')
            .selectFields(
                new List<String>{ 'Name', 'Type', 'StageName', 'CloseDate', 'Primary_Opportunity_Contact__c' }
            )
            .executeQuery()[0];
    }

    public static void createAEUser() {
        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, AEUSERNAME)
            .setField(User.Email, AELASTNAME + LEADEMAIL)
            .setField(User.LastName, AELASTNAME)
            .setField(User.CommunityNickname, AECOMMUNITYNICKNAME)
            .setField(User.Team__c, AETEAM)
            .create();
    }

    public static User createBDRUser() {
        return (User) new SObjectBuilder(User.SObjectType)
            .setField(User.Username, BDRUSERNAME)
            .setField(User.Email, BDRLASTNAME + LEADEMAIL)
            .setfield(User.LastName, BDRLASTNAME)
            .setField(User.CommunityNickname, BDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, BDRTEAM)
            .create()
            .getRecord();
    }

    public static void createSDRUser() {
        new SObjectBuilder(User.SObjectType)
            .setField(User.Username, SDRUSERNAME)
            .setField(User.Email, SDRLASTNAME + LEADEMAIL)
            .setfield(User.LastName, SDRLASTNAME)
            .setField(User.CommunityNickname, SDRCOMMUNITYNICKNAME)
            .setField(User.Team__c, SDRTEAM)
            .setField(User.SegmentPicklist__c, SDRSEGMENT)
            .create();
    }

    public static User getUser(String userType) {
        List<Object> bindings = new List<Object>{ userType };
        return (User) new UserSelector()
            .selectUserByLastName(bindings)
            .selectFields(
                new List<String>{
                    'Username',
                    'Email',
                    'LastName',
                    'CommunityNickname',
                    'Team__c',
                    'SegmentPicklist__c'
                }
            )
            .executeQuery()[0];
    }

    public static List<Demand_Funnel__c> getDFRsByOpportunity(Opportunity opp, List<String> selectedFields) {
        List<Object> bindings = new List<Object>{ opp.Id };
        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByOpportunityId(bindings)
            .selectFields(selectedFields)
            .executeQuery();
        return dfrList;
    }

    
    public static List<Demand_Funnel__c> getDFRs(Lead lead, List<String> selectedFields) {
        List<Object> bindings = new List<Object>{ lead.Id };
        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByLeadId(bindings)
            .selectFields(selectedFields)
            .executeQuery();
        return dfrList;
    }

    public static List<Demand_Funnel__c> getDFRList(List<Lead> leads) {
        List<Object> bindings = new List<Object>{ leads };
        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> dfrList = selectDFR.selectMQLOwnersByLeadID(bindings).executeQuery();
        return dfrList;
    }
    
    public static List<Demand_Funnel__c> getDFRsByContact(List<Contact> listCon, List<String> selectedFields) {
        List<List<Contact>> bindings = new List<List<Contact>>{ listCon };
        DemandFunnelSelector selectDFR = new DemandFunnelSelector();
        List<Demand_Funnel__c> dfrList = selectDFR
            .selectDFRByContactTest(bindings)
            .selectFields(selectedFields)
            .executeQuery();
        return dfrList;
    }

    public static User getSystemUser() {
        Set<String> userIds = new Set<String>();
        for (String key : 
        DG_DFR_Class_Helper.getDFRSystemUsers().keySet()) {
            userIds.add(key);
        }
        List<Object> bindings = new List<Object>();
        bindings.add(userIds);
        User sysUser = (User) new UserSelector()
            .selectUsersByIdNoFields(bindings)
            .selectFields(new List<String>{ 'Profile.Name' })
            .setCondition('Name = \'LeanData Queue\'')
            .executeQuery()[0];
        return sysUser;
    }

    public static boolean isAEUser(String team) {
        return team != null && !team.containsIgnoreCase('SDR') && !team.containsIgnoreCase('BDR');
    }

    public static PriceBook2 getPriceBooks() {
        return (PriceBook2) new Pricebook2Selector().selectPricebooks().executeQuery()[0];
    }

}
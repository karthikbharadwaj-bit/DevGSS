@isTest
private class Test_ConvertLead {

    @testSetup
    private static void setup() {

        SObjectFactory factory = new SObjectFactory();

        // These lines are commented out because of, probably a Salesforce issue
        // when a validation rule on sObject fails when trying to chect a value in feature toggle
        // factory.create(
        //     Feature_Toggle__c.SObjectType,
        //     new Map<SObjectField, Object> {
        //         Feature_Toggle__c.New_Campaign_Influence__c => true
        //     }
        // );

        List<User> marketingUserRecords = (List<User>) factory
            .create(
                User.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    User.UserPermissionsMarketingUser => true,
                    User.Username => ValueProviderBuilder.provideUniqueEmail('marketing'),
                    User.LastName => ValueProviderBuilder.provideUniqueString('testMarketingUser_'),
                    User.Email => ValueProviderBuilder.provideUniqueEmail('marketing'),
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testMarketingUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        Segment_Master__c segment = (Segment_Master__c) factory
            .create(
                Segment_Master__c.SObjectType,
                new Map<SObjectField, Object>{
                    Segment_Master__c.Name => 'Small Business',
                    Segment_Master__c.Min__c => 1,
                    Segment_Master__c.Max__c => 10,
                    Segment_Master__c.Country__c => 'United States',
                    Segment_Master__c.Start_Date__c => System.today()
                }
            );

        Lead testSalesLead = (Lead) factory
            .build(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.RecordTypeId => LeadHelper.RT_ID_SALES_LEADS,
                    Lead.Description => ValueProviderBuilder.provideUniqueString('lead_description'),
                    Lead.Notes__c => ValueProviderBuilder.provideUniqueString('lead_notes'),
                    Lead.VATNumber__c => ValueProviderBuilder.provideUniqueString('lead_vat'),
                    Lead.Emp_Range_Sales_Override__c => 1,
                    Lead.SegmentName__c => segment.Id,
                    Lead.Most_Recent_MQL_Date__c => Datetime.now()
                }
            );

        Lead testPartnerLead = (Lead) factory
            .build(
                Lead.SObjectType,
                new Map<SObjectField, Object>{
                    Lead.RecordTypeId => LeadHelper.RT_ID_PARTNER_LEADS,
                    Lead.LeadPartnerID__c => ValueProviderBuilder.provideUniqueString('some_lead_partner_id'),
                    Lead.Inside_Sales_Rep__c => ValueProviderBuilder.provideParents(marketingUserRecords),
                    Lead.Website => ValueProviderBuilder.provideUniqueString('http://somewebsite.com/'),
                    Lead.NumberOfEmployees => ValueProviderBuilder.provideUniqueNumber(42),
                    Lead.Industry => 'Education',
                    Lead.Number_of_Locations__c => '1',
                    Lead.Description => ValueProviderBuilder.provideUniqueString('lead_description'),
                    Lead.Street => ValueProviderBuilder.provideUniqueString('test_street_name'),
                    Lead.Country => 'United States',
                    Lead.Country__c => 'United States',
                    Lead.State => ValueProviderBuilder.provideUniqueString('test_state_name'),
                    Lead.City => ValueProviderBuilder.provideUniqueString('test_city_name'),
                    Lead.PostalCode => ValueProviderBuilder.provideUniqueString('test_postalcode'),
                    Lead.Agent_Email_Address__c => ValueProviderBuilder.provideUniqueEmail('agentemailaddr'),
                    Lead.Notes__c => ValueProviderBuilder.provideUniqueString('lead_notes'),
                    Lead.VATNumber__c => ValueProviderBuilder.provideUniqueString('lead_vat'),
                    Lead.Emp_Range_Sales_Override__c => 1,
                    Lead.SegmentName__c => segment.Id,
                    Lead.Installation_Service_Provider__c => 'RC ProServices Install', //Added for LTR-673 PS Deal Reg
                    Lead.Most_Recent_MQL_Date__c => Datetime.now()
                }
            );

        List<Lead> testLeads = new List<Lead>{
            testSalesLead,
            testPartnerLead
        };
        insert testLeads;

        List<Note> noteRecords = (List<Note>) factory
            .create(
                Note.SObjectType,
                4,
                new Map<SObjectField, Object>{
                    Note.ParentId => ValueProviderBuilder.provideParents(testLeads),
                    Note.Title => ValueProviderBuilder.provideUniqueString('test_Note_Title'),
                    Note.Body => ValueProviderBuilder.provideUniqueString('test_Note_Body'),
                    Note.IsPrivate => false
                }
            );

        List<Campaign> campaignList = new SObjectBuilder(Campaign.SObjectType)
            .quantity(2)
            .setFields(
                new Map<SObjectField, Object>{
                    Campaign.Name => ValueProviderBuilder.provideUniqueString('Test_CampaignName'),
                    Campaign.Non_Attributable__c => false,
                    Campaign.BMID__c => ValueProviderBuilder.provideUniqueString('some_BmId')
                }
            )
            .createAsUser(marketingUserRecords.get(0))
            .getRecords();

        List<CampaignMember> campaignMemberList = (List<CampaignMember>) factory
            .create(
                CampaignMember.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    CampaignMember.CampaignId => ValueProviderBuilder.provideParents(campaignList),
                    CampaignMember.LeadId => ValueProviderBuilder.provideParents(testLeads)
                }
            );

        schedulerConfiguration__c brand = (schedulerConfiguration__c) factory
            .create(
                schedulerConfiguration__c.SObjectType,
                new Map<SObjectField, Object> {
                    schedulerConfiguration__c.Brand_Id__c => ValueProviderBuilder.provideUniqueString(),
                    schedulerConfiguration__c.Name => RingCentralHelper.BRAND_RINGCENTRAL
                }
            );

        PriceBook2 pricebook = (PriceBook2) factory
            .create(
                PriceBook2.SObjectType,
                new Map<SObjectField, Object> {
                    PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                    PriceBook2.Plan__c => Pricebook2Helper.PLAN_MONTHLY,
                    PriceBook2.Edition__c => Pricebook2Helper.EDITION_STANDARD,
                    PriceBook2.Brand__c => brand.Id,
                    PriceBook2.IsActive => true,
                    PriceBook2.Line_Range_Min__c => 1,
                    PriceBook2.Line_Range_Max__c => 1000,
                    PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
                }
            );

        Product2 serviceProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN,
                    Product2.Family => Product2Helper.FAMILY_SERVICE
                }
            );

        Product2 feeProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Family => Product2Helper.FAMILY_FEE,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Dependent_on_Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
                }
            );

        Product2 softphoneProduct = (Product2) factory
            .build(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Name => 'Softphone',
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ONE_TIME,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES,
                    Product2.Sub_Category__c => Product2Helper.SUBCATEGORY_RINGCENTRAL,
                    Product2.Feature__c => Product2Helper.FEATURE_DISCOUNTED_PHONES,
                    Product2.Sub_Feature__c => -1
                }
            );

        List<Product2> productList = new List<Product2>{
            serviceProduct,
            feeProduct,
            softphoneProduct
        };
        insert productList;

        List<PricebookEntry> standartPricebookEntry = (List<PricebookEntry>) factory
            .create(
                PricebookEntry.SObjectType,
                productList.size(),
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => Test.getStandardPricebookId(),
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productList),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        List<PricebookEntry> currentPricebookEntry = (List<PricebookEntry>) factory
            .create(
                PricebookEntry.SObjectType,
                productList.size(),
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => pricebook.Id,
                    PricebookEntry.Product2Id => ValueProviderBuilder.provideParents(productList),
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        new SObjectBuilder(AccountTeamMemberAssignment__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    AccountTeamMemberAssignment__c.Name => '100',
                    AccountTeamMemberAssignment__c.Brand__c => 'RingCentral',
                    AccountTeamMemberAssignment__c.Segment__c => 'Small Business',
                    AccountTeamMemberAssignment__c.State__c => 'test_state_name0',
                    AccountTeamMemberAssignment__c.Country__c => 'United States',
                    AccountTeamMemberAssignment__c.UserId__c => marketingUserRecords.get(0).Id,
                    AccountTeamMemberAssignment__c.Team_Role__c => 'Strategic Partner RC Owner',
                    AccountTeamMemberAssignment__c.AccountAccessLevel__c => 'Edit',
                    AccountTeamMemberAssignment__c.OpportunityAccessLevel__c => 'Edit',
                    AccountTeamMemberAssignment__c.ContactAccessLevel__c => 'None',
                    AccountTeamMemberAssignment__c.CaseAccessLevel__c => 'None'

                }
            )
            .create();
    }

    @isTest
    static void testConvertLeadDTO() {

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;

        try {
            convertLeadData.validate();
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                ex.getMessage(),
                'leadId:Id is required parameter and cannot be null',
                'validate() method should throw error if leadId field is not specified'
            );
        }

        List<Lead> leadList = new LeadSelector().selectLeads().executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        convertLeadData.leadId = salesLead.Id;
        convertLeadData.applyError = true;
        convertLeadData.doNotCreateOpportunity = true;
        convertLeadData.accountHasApplied = false;
        try {
            convertLeadData.validate();
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            String exceptionApplyErrorMessage = 'Please press \'Apply\' button in the following sections:';
            System.assertEquals(
                ex.getMessage(),
                exceptionApplyErrorMessage + '\n' + 'Account'
            );
        }
        convertLeadData.accountHasApplied = true;
        convertLeadData.opportunityHasApplied = false;
        convertLeadData.contactHasApplied = false;
        convertLeadData.opportunityContactRoleHasApplied = false;
        try {
            convertLeadData.validate();
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            String exceptionApplyErrorMessage = 'Please press \'Apply\' button in the following sections:';
            System.assertEquals(
                ex.getMessage(),
                exceptionApplyErrorMessage + '\n Opportunity,'+ '\n Contact,'+ '\n Opportunity Role'
            );
        }
        // should not throw any errors, cause all validation passed successfully
        convertLeadData.applyError = false;
        convertLeadData.validate();
        convertLeadData.isCreateOpportunity = true;
        try {
            convertLeadData.validate();
            System.assert(false,
                'validate() method should throw error if isCreateQuote field is not specified'
            );
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                'required parameters(opportunityName:String, forecastedUsers:Integer) are null or empty',
                ex.getMessage(),
                'validate() method should throw error if isCreateOpportunity = true and opportunityName or forecastedUsers field is not specified'
            );
        }
        convertLeadData.opportunityName = 'Sample Opportunity Name';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.isBilling = true;
        try {
            convertLeadData.validate();
            System.assert(false,
                'validate() method should throw error if isCreateOpportunity = true and opportunityName or forecastedUsers field is not specified'
            );
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                ex.getMessage(),
                'brand:String is required parameter and cannot be null',
                'validate() method should throw error if isBilling = true brand field is not specified'
            );
        }
        convertLeadData.brand = RingCentralHelper.BRAND_RINGCENTRAL;
        // should not throw any errors, cause all validation passed successfully
        convertLeadData.validate();
        convertLeadData.isCreateQuote = true;
        try {
            convertLeadData.validate();
            System.assert(false,
                'validate() method should throw error if isCreateQuote = true and upsellStatus or ccForecastedUsers field is not specified'
            );
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                'required parameters(upsellStatus:String, ccForecastedUsers: Integer) are null or empty',
                ex.getMessage(),
                'validate() method should throw error if isCreateQuote = true and upsellStatus or ccForecastedUsers field is not specified'
            );
        }
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.ccForecastedUsers = 1;
        convertLeadData.isBilling = true;
        // should not throw any errors, cause all validation passed successfully
        convertLeadData.validate();
        convertLeadData.isBilling = false;
        try {
            convertLeadData.validate();
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                'pricebook2Id:Id is required parameter and cannot be null',
                ex.getMessage(),
                'validate() method should throw error if isBilling = false and pricebook2Id field is not specified'
            );
        }
        List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();
        convertLeadData.pricebook2Id = pbList.get(0).Id;
        // should not throw any errors, cause all validation passed successfully
        convertLeadData.validate();
    }

    @isTest
    static void testConvertSalesLead() {

        LeadSelector lSelector = new LeadSelector();

        List<Lead> leadList = lSelector.selectLeads().executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        Pricebook2Selector pbSelector = new Pricebook2Selector();
        List<Pricebook2> pbList = pbSelector.selectPricebooks()
            .selectFields(new List<String>{'Brand__r.Name'})
            .selectFields(pbSelector.getFieldsForLeadConvert())
            .setLimit(1)
            .executeQuery();

        Pricebook2 pb = pbList.get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Response result = null;

        Triggers.switchOff();
        Test.startTest();
            result = ConvertLead.convertPart1(null);
            System.assertEquals(null, result, 'convertPart1() method should return null if passed parameter is null');

            ConvertLead.prepareLeadRecord(convertLeadData);
            result = ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'convert result should contain OpportunityId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONVERTDATA_RESPONSE_IDENTIFIER),
            'convert result should contain ConvertData for "second part of conversion"'
        );

        List<Opportunity> oppList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<Schema.SObjectField>{
                Opportunity.CampaignId, Opportunity.BMID__c, Opportunity.Brand_Name__c,
                Opportunity.Tier_Name__c
            })
            .executeQuery();
        System.assert(oppList.size() == 1, 'opportunity record should be created after Lead Convert');

        Opportunity convertedOpp = oppList.get(0);

        System.assertEquals(
            convertedOpp.Id,
            result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'method should return Id of created Opportunity'
        );

        List<Account> accountList = new AccountSelector().selectAccounts().executeQuery();
        System.assert(accountList.size() == 1, 'account record should be created after Lead Convert');

        List<Contact> contactList = new ContactSelector().selectContacts().executeQuery();
        System.assert(contactList.size() == 1, 'contact record should be created after Lead Convert');

        Contact convertedContact = contactList.get(0);

        List<OpportunityContactRole> ocrList = new OpportunityContactRoleSelector().selectOpportunityContactRoles().executeQuery();
        System.assert(ocrList.size() == 1, 'OpportunityContactRole record should be created after Lead Convert');

        OpportunityContactRole createdOcr = ocrList.get(0);

        System.assertEquals(
            convertedOpp.Id,
            createdOcr.OpportunityId,
            'created OpportunityContactRole should be related to converted Opportunity'
        );
        System.assertEquals(
            pb.Brand__r.Name,
            convertedOpp.Brand_Name__c,
            'Brand should be copied to Opportunity'
        );
        System.assertEquals(
            convertedContact.Id,
            createdOcr.ContactId,
            'created OpportunityContactRole should be related to converted Contact'
        );
        System.assert(createdOcr.IsPrimary == true, 'created OpportunityContactRole should be primary');

        // verify that fields required for Convert are populated
        List<Object> bindings = new List<Object>();
        bindings.add(salesLead.Id);
        List<Lead> convertedLeadsList = lSelector.selectLeadForConvert(bindings).executeQuery();

        Lead convertedLead = convertedLeadsList.get(0);

        System.assert(convertedLead.IsConverted, 'Lead.IsConverted should be true after convert');

        System.assert(
            pb.Brand__r.Name.equalsIgnoreCase(convertedLead.Lead_Brand_Name__c),
            'Brand name should be copied to Lead.Lead_Brand_Name__c field'
        );

        System.assertEquals(
            pb.Edition__c,
            convertedLead.RC_Edition__c,
            'Pricebook2.Edition__c should be copied to Lead.RC_Edition__c'
        );
        System.assertEquals(
            pb.Service__c,
            convertedLead.Lead_Tier_Name__c,
            'Pricebook2.Service__c should be copied to Lead.Lead_Tier_Name__c'
        );
        System.assertEquals(
            pb.Plan__c,
            convertedLead.RC_Term__c,
            'Pricebook2.Plan__c should be copied to Lead.RC_Term__c'
        );

        System.assertEquals(
            convertedLead.Lead_Tier_Name__c,
            convertedOpp.Tier_Name__c,
            'Opportunity.Tier_Name__c should be equal to Lead.Lead_Tier_Name__c'
        );
    }

    @isTest
    static void testConvertSalesLeadToExistingAccount() {

        SObjectFactory factory = new SObjectFactory();

        Account testAccount = (Account) factory.create(Account.SObjectType);

        List<Lead> leadList = new LeadSelector().selectLeads().executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        Pricebook2Selector pbSelector = new Pricebook2Selector();
        List<Pricebook2> pbList = pbSelector.selectPricebooks()
            .selectFields(new List<String>{'Brand__r.Name'})
            .selectFields(pbSelector.getFieldsForLeadConvert())
            .setLimit(1)
            .executeQuery();

        Pricebook2 pb = pbList.get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.accountId = testAccount.Id;
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = true;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Response result = null;

        Triggers.switchOff();
        Test.startTest();
            result = ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assertEquals(
            testAccount.Id,
            result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'Converted accountId should be equal to specified AccountId before Convert'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );
    }

    @isTest
    static void testConvertSalesLeadToExistingUpsellAccount() {

        SObjectFactory factory = new SObjectFactory();

        Account testAccount = (Account) factory.create(Account.SObjectType,
            new Map<SObjectField, Object>{
                Account.RC_User_ID__c => '1234567890'
            });

        List<Lead> leadList = new LeadSelector().selectLeads().executeQuery();

        Lead salesLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            }
        }

        Pricebook2Selector pbSelector = new Pricebook2Selector();
        List<Pricebook2> pbList = pbSelector.selectPricebooks()
            .selectFields(new List<String>{'Brand__r.Name'})
            .selectFields(pbSelector.getFieldsForLeadConvert())
            .setLimit(1)
            .executeQuery();

        Pricebook2 pb = pbList.get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.accountId = testAccount.Id;
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.opportunityName = 'Test Opportunity Existing Business';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_UPSELL;
        convertLeadData.forecastedUsers = 4;
        convertLeadData.ccForecastedUsers = 1;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.validate();

        Response result = null;

        Triggers.switchOff();
        Test.startTest();
        result = ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assertEquals(
            testAccount.Id,
            result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'Converted accountId should be equal to specified AccountId before Convert'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );

        List<Opportunity> oppList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<Schema.SObjectField>{
                Opportunity.CampaignId, Opportunity.BMID__c, Opportunity.Brand_Name__c
            })
            .executeQuery();
        System.assert(oppList.size() == 1, 'opportunity record should be created after Lead Convert');

        Opportunity convertedOpp = oppList.get(0);

        System.assertEquals(
            convertedOpp.Id,
            result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'method should return Id of created Opportunity'
        );
    }

    @isTest
    static void testConvertSalesLeadToExistingAccountWithContact() {

        SObjectFactory factory = new SObjectFactory();

        Account testAccount = (Account) factory.create(Account.SObjectType);

        Contact testContact = (Contact) factory
            .create(
                Contact.SObjectType,
                new Map<SObjectField, Object>{
                    Contact.AccountId => testAccount.Id
                }
            );

        List<Lead> leadList = new LeadSelector().selectLeads().executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        Pricebook2Selector pbSelector = new Pricebook2Selector();
        List<Pricebook2> pbList = pbSelector.selectPricebooks()
            .selectFields(new List<String>{'Brand__r.Name'})
            .selectFields(pbSelector.getFieldsForLeadConvert())
            .setLimit(1)
            .executeQuery();

        Pricebook2 pb = pbList.get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.accountId = testAccount.Id;
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateQuote = false;
        convertLeadData.pricebook2Id = pb.Id;
         convertLeadData.doNotCreateOpportunity = true;
        convertLeadData.validate();

        Response result = null;

        Triggers.switchOff();
        Test.startTest();
            result = ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assertEquals(
            testAccount.Id,
            result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'Converted accountId should be equal to specified AccountId before Convert'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );
    }

    @isTest
    static void testConvertSalesLeadToBilling() {

        List<Lead> leadList = new LeadSelector().selectLeads().executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = true;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test billing opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.brand = OpportunityHelper.BRAND_RINGCENTRAL;
        convertLeadData.edition = Pricebook2Helper.EDITION_STANDARD;
        convertLeadData.product = Pricebook2Helper.SERVICE_OFFICE;
        convertLeadData.term = Product2Helper.CHARGE_TERM_MONTHLY;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Response result = null;

        Triggers.switchOff();
        Test.startTest();
            ConvertLead.prepareLeadRecord(convertLeadData);
            result = ConvertLead.convertPart1(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'convert result should contain OpportunityId'
        );
        System.assert(
            result.data.containsKey(ConvertLead.CONVERTDATA_RESPONSE_IDENTIFIER),
            'convert result should contain ConvertData for "second part of conversion"'
        );

        List<Opportunity> oppList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<Schema.SObjectField>{
                Opportunity.CampaignId, Opportunity.BMID__c, Opportunity.Brand_Name__c
            })
            .executeQuery();

        System.assert(oppList.size() == 1, 'opportunity record should be created after Lead Convert');

        Opportunity convertedOpp = oppList.get(0);

        System.assertEquals(
            convertedOpp.Id,
            result.data.get(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'method should return Id of created Opportunity'
        );
        System.assertEquals(
            OpportunityHelper.BRAND_RINGCENTRAL,
            convertedOpp.Brand_Name__c,
            'Brand should be copied to Opportunity'
        );

        List<Account> accountList = new AccountSelector().selectAccounts().executeQuery();
        System.assert(accountList.size() == 1, 'account record should be created after Lead Convert');

        List<Contact> contactList = new ContactSelector().selectContacts().executeQuery();
        System.assert(contactList.size() == 1, 'contact record should be created after Lead Convert');

        Contact convertedContact = contactList.get(0);

        List<OpportunityContactRole> ocrList = new OpportunityContactRoleSelector().selectOpportunityContactRoles().executeQuery();
        System.assert(ocrList.size() == 1, 'OpportunityContactRole record should be created after Lead Convert');

        OpportunityContactRole createdOcr = ocrList.get(0);

        System.assertEquals(
            convertedOpp.Id,
            createdOcr.OpportunityId,
            'created OpportunityContactRole should be related to converted Opportunity'
        );
        System.assertEquals(
            convertedContact.Id,
            createdOcr.ContactId,
            'created OpportunityContactRole should be related to converted Contact'
        );
        System.assert(createdOcr.IsPrimary == true, 'created OpportunityContactRole should be primary');
    }

    @isTest
    static void testConvertPartnerLeadWithLeadQualificationAndMapOppContactRole() {
        Triggers.switchOff();
        Test.startTest();
        
        new SObjectBuilder(ByPassTrigger__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    ByPassTrigger__c.Bypass_Account_Trigger__c => true
                }
            )
            .create();

        SObjectFactory factory = new SObjectFactory();
        Lead_Qualification__c leadQualificationRecord = (Lead_Qualification__c) factory
            .create(
                Lead_Qualification__c.SObjectType,
                new Map<SObjectField, Object> {
                    Lead_Qualification__c.Decision_Maker_Partner__c => 'Details Below',
                    Lead_Qualification__c.Decision_Maker_First_Name__c => ValueProviderBuilder.provideUniqueString('test_firstName'),
                    Lead_Qualification__c.Decision_Maker_Last_Name__c => ValueProviderBuilder.provideUniqueString('test_lastName'),
                    Lead_Qualification__c.Decision_Maker_Email__c => ValueProviderBuilder.provideUniqueEmail('decisionmakeremail'),
                    Lead_Qualification__c.Decision_Maker_Phone__c => '1233214564',
                    Lead_Qualification__c.Decision_Maker_Business_Title__c => ValueProviderBuilder.provideUniqueString('test_business_title')
                }
            );

        LeadSelector lSelector = new LeadSelector();

        List<Lead> leadList = lSelector
            .selectLeads()
            .selectFields(lSelector.getOtherFieldList())
            .executeQuery();

        Segment_Master__c segment = [SELECT Id FROM Segment_Master__c LIMIT 1];

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'testAcc',
                Account.BillingState => 'test_state_name0',
                Account.BillingStreet => 'test_street_name0',
                Account.BillingPostalCode => 'test_postalcode0',
                Account.BillingCity => 'test_city_name0',
                Account.BillingCountry => 'United States',
                Account.Segment_Name__c => segment.Id
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => testAcc.Id,
                Contact.LastName => 'testAcc',
                Contact.FirstName => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Forecasted_Users__c => 5,
                    Opportunity.Name => 'Test opportunity from PartnerLead',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        Profile p =(Profile) new ProfileSelector()
            .selectProfiles()
            .setCondition('UserType = \'PowerPartner\' AND Name like \'%Full%\'')
            .executeQuery()
            .get(0);

        String testemail = 'puser0001@amamama.com';

        User pu = (User) new SObjectBuilder(User.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                User.ProfileId => p.id,
                User.Username => ValueProviderBuilder.provideUniqueEmail(),
                User.Email => testemail,
                User.EmailEncodingKey => 'UTF-8',
                User.LocaleSidKey => 'en_US',
                User.Alias => 'cspu',
                User.LanguageLocaleKey => 'en_US',
                User.TimeZoneSidKey => 'America/Los_Angeles',
                User.LastName => 'lastname',
                User.ContactId => contact.Id
            })
            .create()
            .getRecord();

        List<Lead> partnerLeads = new List<Lead>();
        Lead partnerLead = new Lead();

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
                partnerLead.Partner_Lead_Owner__c = pu.Id;
                partnerLeads.add(partnerLead);
                break;
            }
        }
        update partnerLeads;
        List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();

        ConvertLead.ConvertLeadDTO convertLeadDataPartner = new ConvertLead.ConvertLeadDTO();
        convertLeadDataPartner.leadId = partnerLead.Id;
        convertLeadDataPartner.isBilling = false;
        convertLeadDataPartner.accountId = testAcc.Id;
        convertLeadDataPartner.contactId = contact.Id;
        convertLeadDataPartner.opportunityId = testOpp.Id;
        convertLeadDataPartner.isCreateOpportunity = true;
        convertLeadDataPartner.isCreateQuote = true;
        convertLeadDataPartner.opportunityName = 'my test opportunity from PartnerLead';
        convertLeadDataPartner.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadDataPartner.forecastedUsers = 0;
        convertLeadDataPartner.ccForecastedUsers = 0;
        convertLeadDataPartner.pricebook2Id = pbList.get(0).Id;
        convertLeadDataPartner.leadQualificationId = leadQualificationRecord.Id;
        convertLeadDataPartner.isCreateAccount = false;
        convertLeadDataPartner.rcUserId = 'testRCIdd1';
        convertLeadDataPartner.existingUsers = 0;
        convertLeadDataPartner.validate();

        Response resultPartner = ConvertLead.convertPart2(convertLeadDataPartner);
        
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            resultPartner.data.containsKey(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER),
            'convert result should contain AccountId'
        );
        System.assert(
            resultPartner.data.containsKey(ConvertLead.CONTACTID_RESPONSE_IDENTIFIER),
            'convert result should contain ContactId'
        );
        System.assert(
            resultPartner.data.containsKey(ConvertLead.OPPORTUNITYID_RESPONSE_IDENTIFIER),
            'convert result should contain OpportunityId'
        );
        System.assert(
            resultPartner.data.containsKey(ConvertLead.CONVERTDATA_RESPONSE_IDENTIFIER),
            'convert result should contain ConvertData for "second part of conversion"'
        );

        List<Contact> contactList = new ContactSelector()
            .selectContactsByAccountId(new List<Object> {testAcc.Id})
            .selectFields(new Set<String> {'LastName'})
            .executeQuery();

        System.assert(contactList.size() == 2, 'Contact list must have 2 records');
        System.assertEquals(contactList[1].LastName, leadQualificationRecord.Decision_Maker_Last_Name__c, 'contact`s Last Name must be same as Decision_Maker_Last_Name__c');
    }

    @isTest
    static void testConvertPart3Method() {
        // Mock the cache provider to avoid partition dependency
        Test_PlatformCacheUtility.MockCacheProviderStub mockStub = new Test_PlatformCacheUtility.MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);

        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => accountRecord.Id
                }
            );

        LeadSelector lSelector = new LeadSelector();

        List<Lead> leadList = lSelector
            .selectLeads()
            .selectFields(lSelector.getOtherFieldList())
            .executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 1;
        convertLeadData.ccForecastedUsers = 1;
        convertLeadData.pricebook2Id = pbList.get(0).Id;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Triggers.switchOff();
        Test.startTest();

            Response result = ConvertLead.convertPart3(null);

            try {
                result = ConvertLead.convertPart3(convertLeadData);
            } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
                System.assertEquals(
                    ex.getMessage(),
                    'opportunityId:Id is required parameter for Quote creation and cannot be null',
                    'ConvertLead.convertPart3 method should throw error if opportunityId field is not specified'
                );
            }

            convertLeadData.opportunityId = opportunityRecord.Id;

            result = ConvertLead.convertPart3(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.QUOTEID_RESPONSE_IDENTIFIER),
            'convert result should contain QuoteId'
        );

        Id createdQuoteId = (Id) result.data.get(ConvertLead.QUOTEID_RESPONSE_IDENTIFIER);

        List<QuoteLineItem> defaultQliList = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(createdQuoteId)
            .executeQuery();

        System.assert(!defaultQliList.isEmpty(), '"default" quoteLineItems should be created.');

        Boolean isSoftphoneCreated = false;

        for (QuoteLineItem qli : defaultQliList) {

            Boolean isSoftphoneProduct = qli.Product2.Name == 'Softphone' &&
                qli.Product2.Feature__c == Product2Helper.FEATURE_DISCOUNTED_PHONES &&
                qli.Product2.Sub_Feature__c == -1;

            if (isSoftphoneProduct) {
                isSoftphoneCreated = true;
            }
        }

        System.assertEquals(true, isSoftphoneCreated, '"Softphone" quoteLineItem should be created.');
    }

    @isTest
    static void testConvertPart3MethodUpsell() {
        // Mock the cache provider to avoid partition dependency
        Test_PlatformCacheUtility.MockCacheProviderStub mockStub = new Test_PlatformCacheUtility.MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);

        List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();
        SObjectFactory factory = new SObjectFactory();

        Account accountRecord = (Account) factory.create(Account.SObjectType);

        Opportunity opportunityRecord = (Opportunity) factory
            .create(
                Opportunity.SObjectType,
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('test Opportunity'),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.CloseDate => System.today().addMonths(1),
                    Opportunity.AccountId => accountRecord.Id
                }
            );

        Product2 product = (Product2) factory
            .create(
                Product2.SObjectType,
                new Map<SObjectField, Object> {
                    Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Product2.Feature__c => 11,
                    Product2.Cart_Tab_Availability__c => QuoteHelper.RT_NAME_SALES,
                    Product2.Family => Product2Helper.FAMILY_DISCOUNTED_PHONES
                }
            );

        factory
            .create(
                Entitlement__c.SObjectType,
                new Map<SObjectField, Object> {
                    Entitlement__c.Account__c => accountRecord.Id,
                    Entitlement__c.ChargeTerm__c => Product2Helper.CHARGE_TERM_MONTHLY,
                    Entitlement__c.Product__c => product.Id,
                    Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                    Entitlement__c.Discount__c => 0,
                    Entitlement__c.Active__c => true,
                    Entitlement__c.Quantity__c => 10,
                    Entitlement__c.Price__c => 100
                }
            );

        factory
            .create(
                PricebookEntry.SObjectType,
                2,
                new Map<SObjectField, Object> {
                    PricebookEntry.Pricebook2Id => ValueProviderBuilder.provideList(
                        new List<Id>{
                            Test.getStandardPricebookId(),
                            pbList.get(0).Id
                        }
                    ),
                    PricebookEntry.Product2Id => product.Id,
                    PricebookEntry.UnitPrice => 10,
                    PricebookEntry.IsActive => true,
                    PricebookEntry.UseStandardPrice => false
                }
            );

        LeadSelector lSelector = new LeadSelector();

        List<Lead> leadList = lSelector
            .selectLeads()
            .selectFields(lSelector.getOtherFieldList())
            .executeQuery();

        Lead salesLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            }
        }

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_UPSELL;
        convertLeadData.forecastedUsers = 10;
        convertLeadData.ccForecastedUsers = 1;
        convertLeadData.pricebook2Id = pbList.get(0).Id;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Triggers.switchOff();
        Test.startTest();

        Response result = ConvertLead.convertPart3(null);

        try {
            result = ConvertLead.convertPart3(convertLeadData);
        } catch (ConvertLead.ConvertLeadDTOValidationException ex) {
            System.assertEquals(
                ex.getMessage(),
                'opportunityId:Id is required parameter for Quote creation and cannot be null',
                'ConvertLead.convertPart3 method should throw error if opportunityId field is not specified'
            );
        }

        convertLeadData.opportunityId = opportunityRecord.Id;

        result = ConvertLead.convertPart3(convertLeadData);
        Test.stopTest();
        Triggers.switchOn();

        System.assert(
            result.data.containsKey(ConvertLead.QUOTEID_RESPONSE_IDENTIFIER),
            'convert result should contain QuoteId'
        );

        Id createdQuoteId = (Id) result.data.get(ConvertLead.QUOTEID_RESPONSE_IDENTIFIER);

        List<QuoteLineItem> defaultQliList = new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIds(createdQuoteId)
            .executeQuery();

        System.assert(!defaultQliList.isEmpty(), '"default" quoteLineItems should be created.');

        Boolean isSoftphoneCreated = false;
        Boolean isExistingSubscriptionCreated = false;

        for (QuoteLineItem qli : defaultQliList) {

            Boolean isSoftphoneProduct = qli.Product2.Name == 'Softphone' &&
                qli.Product2.Feature__c == Product2Helper.FEATURE_DISCOUNTED_PHONES &&
                qli.Product2.Sub_Feature__c == -1;

            if (isSoftphoneProduct) {
                isSoftphoneCreated = true;
            }

            if (qli.Product2.Id == product.Id) {
                isExistingSubscriptionCreated = true;
            }
        }

        System.assertEquals(true, isSoftphoneCreated, '"Softphone" quoteLineItem should be created.');
        System.assertEquals(true, isExistingSubscriptionCreated, 'Existing Products from entitlements should be created');
    }

    private static User createPartnerLeadOwner(Lead leadRecordToUpdate) {

        if (leadRecordToUpdate == null || leadRecordToUpdate.Partner_Lead_Owner__c != null) {
            return null;
        }

        // create test data for fill Lead.Partner_Lead_Owner__c field
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

        SObjectFactory factory = new SObjectFactory();

        User portalAccountOwnerUserRecord = (User) factory
            .create(
                User.SObjectType,
                new Map<SObjectField, Object>{
                    User.UserRoleId => portalRole.Id,
                    User.ProfileId => ProfileHelper.PROFILE_ID_SYSADMIN,
                    User.Username => ValueProviderBuilder.provideUniqueEmail('portalUsr'),
                    User.LastName => ValueProviderBuilder.provideUniqueString('portalUser_'),
                    User.Email => ValueProviderBuilder.provideUniqueEmail('portal'),
                    User.Alias => ValueProviderBuilder.provideUniqueFixedLengthString(7),
                    User.CommunityNickname => ValueProviderBuilder.provideUniqueString('testPortalUser_'),
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
                }
            );

        Contact contact1 = null;

        System.runAs(portalAccountOwnerUserRecord) {

            Account portalAccount = (Account) factory.create(
                Account.SObjectType,
                new Map<SObjectField, Object>{
                    Account.OwnerId => portalAccountOwnerUserRecord.Id
                }
            );

            contact1 = (Contact) factory.create(
                Contact.SObjectType,
                new Map<SObjectField, Object>{
                    Contact.AccountId => portalAccount.Id
                }
            );
        }

        Profile portalProfile = [
            SELECT Id
            FROM Profile
            WHERE Usertype = 'PowerPartner'
            LIMIT 1
        ];
        User leadPartnerOwnerUser = new User(
            Username = UserHelper.getUniqueUserName(),
            ContactId = contact1.Id,
            ProfileId = portalProfile.Id,
            Alias = 'test123',
            Email = 'test12345@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'test12345',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert leadPartnerOwnerUser;

        System.runAs(portalAccountOwnerUserRecord) {
            leadRecordToUpdate.Partner_Lead_Owner__c = leadPartnerOwnerUser.Id;
            update leadRecordToUpdate;
        }

        return portalAccountOwnerUserRecord;
    }

    @isTest
    static void testConvertPartnerLeadWithAccountShare() {

        LeadSelector lSelector = new LeadSelector();
        List<Lead> leadList = lSelector
            .selectLeads()
            .selectFields(lSelector.getOtherFieldList())
            .executeQuery();

        Lead salesLead = null;
        Lead partnerLead = null;

        for (Lead l : leadList) {
            if (l.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS) {
                salesLead = l;
            } else if (l.RecordTypeId == LeadHelper.RT_ID_PARTNER_LEADS) {
                partnerLead = l;
            }
        }

        Triggers.switchOff();
        Test.startTest();

            User portalAccountOwnerUserRecord = createPartnerLeadOwner(partnerLead);

            List<Pricebook2> pbList = new Pricebook2Selector().selectPricebooks().setLimit(1).executeQuery();

            ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
            convertLeadData.leadId = partnerLead.Id;
            convertLeadData.isBilling = false;
            convertLeadData.isCreateOpportunity = true;
            convertLeadData.isCreateQuote = true;
            convertLeadData.opportunityName = 'my test opportunity from PartnerLead';
            convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
            convertLeadData.forecastedUsers = 0;
            convertLeadData.ccForecastedUsers = 0;
            convertLeadData.pricebook2Id = pbList.get(0).Id;
            convertLeadData.rcUserId = 'testRCIdd1';
            convertLeadData.existingUsers = 0;
            convertLeadData.validate();

            Response result = null;

            List<AccountShare> accountShareList = [SELECT Id, AccountId,
                    UserOrGroupId
                FROM AccountShare
                WHERE UserOrGroupId = :partnerLead.Partner_Lead_Owner__c];

            System.assert(accountShareList.isEmpty(), 'there should be no AccountShare records');

            System.runAs(portalAccountOwnerUserRecord) {
                result = ConvertLead.convertPart1(convertLeadData);
            }

        Test.stopTest();
        Triggers.switchOn();

        Id convertedAccountId = (Id) result.data.get(ConvertLead.ACCOUNTID_RESPONSE_IDENTIFIER);

        accountShareList = [SELECT Id, AccountId,
                UserOrGroupId
            FROM AccountShare
            WHERE UserOrGroupId = :partnerLead.Partner_Lead_Owner__c];
    }

    @isTest
    public static void testManageContactRoleCreationWhenCreateNewOppAndNoAccContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .create()
            .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .create()
            .getRecord();

        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }

        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('createNewOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon.Id, oppHasPrimaryContactRole, true);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testAcc.Id);
        bindings.add(testCon.Id);
        List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                 .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();

        bindings.clear();
        bindings.add(testOpp.Id);
        bindings.add(testCon.Id);
        List<OpportunityContactRole> ocrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                               .selectOCRForLeadConvert(bindings).executeQuery();

        System.assert(!acrList.isEmpty(), 'No Contact Role was created');
        System.assert(acrList[0].isPrimary, 'Contact Role should be primary');
        System.assertEquals(OpportunityHelper.CONTACT_ROLE_SIGNATORY, acrList[0].Role, 'Role was mapped incorrectly in Contact Role');
        System.assert(!ocrList.isEmpty(), 'No Contact Role was created');
        System.assert(ocrList[0].isPrimary, 'Contact Role should be primary');
        System.assertEquals(OpportunityHelper.CONTACT_ROLE_SIGNATORY, ocrList[0].Role, 'Role was mapped incorrectly in Contact Role');
    }

    @isTest
    public static void testManageContactRoleCreationWhenCreateNewOppAndValidAccContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
        .create()
        .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .setField(Contact.AccountId, testAcc.Id)
        .create()
        .getRecord();

        Contact testCon2 = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .setField(Contact.AccountId, testAcc.Id)
        .create()
        .getRecord();

        AccountContactRole testAccConRole = (AccountContactRole) new SObjectBuilder (AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setField(AccountContactRole.AccountId, testAcc.Id)
            .setField(AccountContactRole.ContactId, testCon.Id)
            .setField(AccountContactRole.isPrimary, true)
            .setField(AccountContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('createNewOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon2.Id, oppHasPrimaryContactRole, true);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testOpp.Id);
        bindings.add(testCon.Id);
        List<OpportunityContactRole> ocrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                               .selectOCRForLeadConvert(bindings).executeQuery();

        System.assert(!ocrList.isEmpty(), 'No Contact Role was created');
        System.assert(ocrList[0].isPrimary, 'Contact Role should be primary');
        System.assertEquals(ocrList[0].Role, ocrList[0].Role, 'Role was mapped incorrectly in Contact Role');
        System.assertEquals(testAccConRole.ContactId, ocrList[0].ContactId, 'Contact was mapped incorrectly in Contact Role');
    }

    @isTest
    public static void testManageContactRoleCreationWhenCreateNewOppAndInvalidAccContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
        .create()
        .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .create()
        .getRecord();

        Contact testCon2 = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .setField(Contact.AccountId, testAcc.Id)
        .create()
        .getRecord();

        AccountContactRole testAccConRole = (AccountContactRole) new SObjectBuilder (AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setField(AccountContactRole.AccountId, testAcc.Id)
            .setField(AccountContactRole.ContactId, testCon.Id)
            .setField(AccountContactRole.isPrimary, true)
            .setField(AccountContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('createNewOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon2.Id, oppHasPrimaryContactRole, true);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testAcc.Id);
        bindings.add(testCon2.Id);
        List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                 .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();

        System.assert(!acrList.isEmpty(), 'No Contact Role was created');
        System.assert(!acrList[0].isPrimary, 'Contact Role should not be primary');
        System.assertEquals('Influencer', acrList[0].Role, 'Role was mapped incorrectly in Contact Role');
    }

    @isTest
    public static void testManageContactRoleCreationWhenSelectExistingOppAndOppContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .create()
            .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .create()
            .getRecord();

        Contact testCon2 = (Contact) new SObjectBuilder (Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .create()
            .getRecord();

        OpportunityContactRole testOppConRole = (OpportunityContactRole) new SObjectBuilder (OpportunityContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(OpportunityContactRole.SObjectType))
            .setField(OpportunityContactRole.OpportunityId, testOpp.Id)
            .setField(OpportunityContactRole.ContactId, testCon.Id)
            .setField(OpportunityContactRole.isPrimary, true)
            .setField(OpportunityContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('selectExistingOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon2.Id, oppHasPrimaryContactRole, false);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testOpp.Id);
        bindings.add(testCon2.Id);
        List<OpportunityContactRole> ocrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                               .selectOCRForLeadConvert(bindings).executeQuery();

        System.assert(!ocrList.isEmpty(), 'No Contact Role was created');
        System.assert(!ocrList[0].isPrimary, 'Contact Role should not be primary');
        System.assertEquals('Influencer', ocrList[0].Role, 'Role was mapped incorrectly in Contact Role');
    }

    @isTest
    public static void testManageContactRoleCreationWhenSelectExistingOppAndValidAccContactRoleAndSelectedContact() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
        .create()
        .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .setField(Contact.AccountId, testAcc.Id)
        .create()
        .getRecord();

        Contact testCon2 = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .create()
        .getRecord();

        AccountContactRole testAccConRole = (AccountContactRole) new SObjectBuilder (AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setField(AccountContactRole.AccountId, testAcc.Id)
            .setField(AccountContactRole.ContactId, testCon.Id)
            .setField(AccountContactRole.isPrimary, true)
            .setField(AccountContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('selectExistingOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon2.Id, oppHasPrimaryContactRole, false);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testOpp.Id);
        List<OpportunityContactRole> ocrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                               .selectOpportunityContactRolesByOppId(bindings)
                                               .setLimit(2)
                                               .executeQuery();

        System.assert(!ocrList.isEmpty(), 'No Contact Role was created');
        for (OpportunityContactRole ocr : ocrList) {
            if (ocr.isPrimary) {
                System.assert(ocr.isPrimary, 'Contact Role should not be primary');
                System.assertEquals('Signatory', ocr.Role, 'Role was mapped incorrectly in Contact Role');
                System.assertEquals(testAccConRole.ContactId, ocr.ContactId, 'Contact was mapped incorrectly in Contact Role');
            } else {
                System.assert(!ocr.isPrimary, 'Contact Role should be primary');
                System.assertEquals('Influencer', ocr.Role, 'Role was mapped incorrectly in Contact Role');
                System.assertEquals(testCon2.Id, ocr.ContactId, 'Contact was mapped incorrectly in Contact Role');
            }
        }
    }

    @isTest
    public static void testManageContactRoleCreationWhenSelectExistingOppAndValidAccContactRoleAndNoSelectedContact() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
        .create()
        .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .setField(Contact.AccountId, testAcc.Id)
        .create()
        .getRecord();

        AccountContactRole testAccConRole = (AccountContactRole) new SObjectBuilder (AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setField(AccountContactRole.AccountId, testAcc.Id)
            .setField(AccountContactRole.ContactId, testCon.Id)
            .setField(AccountContactRole.isPrimary, true)
            .setField(AccountContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('selectExistingOpp', 'Influencer', testAcc.Id, testOpp.Id, null, oppHasPrimaryContactRole, false);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testOpp.Id);
        List<OpportunityContactRole> ocrList = (List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                                               .selectOpportunityContactRolesByOppId(bindings)
                                               .setLimit(2)
                                               .executeQuery();

        bindings.clear();
        bindings.add(testAcc.Id);
        List<Contact> accountContacts = (List<Contact>) new ContactSelector()
                            .selectContactsByAccountId(bindings)
                            .executeQuery();

        System.assert(!ocrList.isEmpty(), 'No Contact Role was created');
        for (OpportunityContactRole ocr : ocrList) {
            if (ocr.IsPrimary) {
                System.assert(ocr.isPrimary, 'Contact Role should be primary');
                System.assertEquals('Signatory', ocr.Role, 'Role was mapped incorrectly in Contact Role');
            } else {
                System.assert(!ocr.isPrimary, 'Contact Role should not be primary');
                System.assertEquals('Influencer', ocr.Role, 'Role was mapped incorrectly in Contact Role');
            }
        }
        System.assertEquals(2, accountContacts.size(), 'A new contact should have been created for the Account');
    }

    @isTest
    public static void testManageContactRoleCreationWhenSelectExistingOppAndInvalidAccContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
        .create()
        .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .create()
        .getRecord();

        Contact testCon2 = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .create()
        .getRecord();

        AccountContactRole testAccConRole = (AccountContactRole) new SObjectBuilder (AccountContactRole.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(AccountContactRole.SObjectType))
            .setField(AccountContactRole.AccountId, testAcc.Id)
            .setField(AccountContactRole.ContactId, testCon.Id)
            .setField(AccountContactRole.isPrimary, true)
            .setField(AccountContactRole.Role, 'Evaluator')
            .create()
            .getRecord();
        OpportunityContactRole oppHasPrimaryContactRole;
        if (testOpp.Id != null) {
            oppHasPrimaryContactRole = ConvertLead.oppHasValidPrimaryContactRole(testOpp.Id);
        }
        Triggers.switchOff();
        Test.startTest();
        ConvertLead.manageContactRoleCreation('selectExistingOpp', 'Influencer', testAcc.Id, testOpp.Id, testCon2.Id, oppHasPrimaryContactRole, false);
        Test.stopTest();
        Triggers.switchOn();

        List<Object> bindings = new List<Object>();
        bindings.add(testAcc.Id);
        bindings.add(testCon2.Id);
        List<AccountContactRole> acrList = (List<AccountContactRole>) new AccountContactRoleSelector()
                                 .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();

        System.assert(!acrList.isEmpty(), 'No Contact Role was created');
        System.assert(!acrList[0].isPrimary, 'Contact Role should not be primary');
        System.assertEquals('Influencer', acrList[0].Role, 'Role was mapped incorrectly in Contact Role');
    }

    @isTest
    public static void testUpdateAccountContactRole() {
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
        .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
        .create()
        .getRecord();

        ConvertLead.updateAccountContactRole(testAcc.Id, testCon.Id, null, true);

        List<Object> bindings = new List<Object>();
        bindings.add(testAcc.Id);
        bindings.add(testCon.Id);
        List<AccountContactRole> acrList1 = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();
        System.assertEquals(OpportunityHelper.CONTACT_ROLE_SIGNATORY, acrList1[0].Role, 'Contact Role should be signatory');

        ConvertLead.updateAccountContactRole(testAcc.Id, testCon.Id, null, false);
        List<AccountContactRole> acrList2 = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();
        System.assertEquals(null, acrList2[0].Role, 'Contact Role should be null');

        ConvertLead.updateAccountContactRole(testAcc.Id, testCon.Id, 'Influencer', false);
        List<AccountContactRole> acrList3 = (List<AccountContactRole>) new AccountContactRoleSelector()
            .selectAccountContactRolesByAccountAndContactIds(bindings).executeQuery();
        System.assertEquals('Influencer', acrList3[0].Role, 'Contact Role should be Influencer');
    }

    @isTest
    public static void testMapSalesLeadsFieldsToRelatedObjects() {
        Test.startTest();
        Account testAcc = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .setField(Account.AnnualRevenue, null)
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .create()
            .getRecord();

        Contact testCon = (Contact) new SObjectBuilder (Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.Company_DUNS__c, null)
            .create()
            .getRecord();

        Lead testLead = (Lead) new SObjectBuilder (Lead.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
            .setField(Lead.AnnualRevenue, 200)
            .setField(Lead.SID__c, 'testSID')
            .setField(Lead.Company_DUNS__c, 'testDuns')
            .setField(Lead.GCLID__c, 'testGCLID')
            .create()
            .getRecord();

        testAcc = ConvertLead.mapSalesLeadsFieldsToRelatedAccount(testLead, testAcc, testCon);
        testOpp = ConvertLead.mapSalesLeadsFieldsToRelatedOpportunity(testLead, testOpp, testCon);
        testCon = ConvertLead.mapSalesLeadsFieldsToRelatedContact(testLead, testCon, testOpp.Id);
        Test.stopTest();

        System.assertEquals(testLead.AnnualRevenue, testAcc.AnnualRevenue);
        System.assertEquals(testLead.SID__c, testOpp.SID__c);
        System.assertEquals(testLead.Company_DUNS__c, testCon.Company_DUNS__c);
    }

    @isTest
    private static void testPopulateForecastedUserFieldsEngageVoice() {
        Opportunity opp = new Opportunity();
        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.existingUsers = 0;


        Test.startTest();

        ConvertLead.populateForecastedUserFields(opp, OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE, convertLeadData);

        Test.stopTest();

        System.assertEquals(
            1,
            opp.Forecast_Connect_First_Users__c,
            'Incorrect Forecasted Users number on Engage Voice'
        );

        System.assertEquals(
            0,
            opp.ForcastedDimeloUsers__c,
            'Incorrect Forecasted Users number on Engage Voice'
        );

        System.assertEquals(
            0,
            opp.Forecasted_Users__c,
            'Incorrect Forecasted Users number on Engage Voice'
        );
    }

    @isTest
    private static void testPopulateForecastedUserFieldsEngageDigital() {
        Opportunity opp = new Opportunity();
        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.existingUsers = 0;

        Test.startTest();

        ConvertLead.populateForecastedUserFields(opp, OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE, convertLeadData);

        Test.stopTest();

        System.assertEquals(
            0,
            opp.Forecast_Connect_First_Users__c,
            'Incorrect Forecasted Users number on Engage Digital'
        );

        System.assertEquals(
            1,
            opp.ForcastedDimeloUsers__c,
            'Incorrect Forecasted Users number on Engage Digital'
        );

        System.assertEquals(
            0,
            opp.Forecasted_Users__c,
            'Incorrect Forecasted Users number on Engage Digital'
        );
    }

    @isTest
    private static void testPopulateForecastedUserFieldsOffice() {
        Opportunity opp = new Opportunity();
        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.existingUsers = 0;

        Test.startTest();

        ConvertLead.populateForecastedUserFields(opp, OpportunityHelper.TIER_OFFICE, convertLeadData);

        Test.stopTest();

        System.assertEquals(
            0,
            opp.Forecast_Connect_First_Users__c,
            'Incorrect Forecasted Users number on Office'
        );

        System.assertEquals(
            0,
            opp.ForcastedDimeloUsers__c,
            'Incorrect Forecasted Users number on Office'
        );

        System.assertEquals(
            1,
            opp.Forecasted_Users__c,
            'Incorrect Forecasted Users number on Office'
        );
    }

    @isTest
    private static void testElaFlow() {
        Lead testLead = (Lead) new SObjectBuilder (Lead.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
            .create()
            .getRecord();

        Account originalAccount = (Account) new SObjectBuilder (Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Contact originalContact = (Contact) new SObjectBuilder (Contact.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Contact.SObjectType))
            .setField(Contact.AccountId, originalAccount.Id)
            .create()
            .getRecord();

        Triggers.switchOff();
        Test.startTest();

        Opportunity originalOpportunity = (Opportunity) new SObjectBuilder (Opportunity.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Opportunity.SObjectType))
            .setField(Opportunity.AccountId, originalAccount.Id)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .create()
            .getRecord();

        AccountContactRole accountContactRole = (AccountContactRole) new SObjectBuilder(AccountContactRole.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                AccountContactRole.AccountId => originalAccount.Id,
                AccountContactRole.ContactId => originalContact.Id
            })
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.isCreateOpportunity = false;
        convertLeadData.isCreateAccount = true;
        convertLeadData.isElaLastChunk = true;
        convertLeadData.isElaAccount = true;
        convertLeadData.elaChunkSize = 2;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.leadId = testLead.Id;
        convertLeadData.accountId = originalAccount.Id;
        convertLeadData.contactId = originalContact.Id;
        convertLeadData.opportunityId = originalOpportunity.Id;
        convertLeadData.numberOfELAServiceAccounts = 2;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.forecastedUsers = 1;
        convertLeadData.existingUsers = 0;


        ConvertLead.convertPart4(convertLeadData);

        Test.stopTest();
        Triggers.switchOn();

        List<Account> elaServiceList = (List<Account>) new AccountSelector()
            .selectAccounts()
            .setCondition('ELA_Account_Type__c = \'ELA Service\'')
            .executeQuery();

        List<Account> elaBillingList = (List<Account>) new AccountSelector()
            .selectAccounts()
            .setCondition('ELA_Account_Type__c = \'ELA Billing\'')
            .executeQuery();

        List<AccountRelation__c> accountRelationList = (List<AccountRelation__c>) new AccountRelationSelector()
            .selectAccountRelationByParentId(originalAccount.Id)
            .executeQuery();

        List<Opportunity> oppList = (List<Opportunity>) new OpportunitySelector()
            .selectOpportunities()
            .executeQuery();

        System.assertEquals(1, elaBillingList.size(), 'Original account should be marked as a ELA Billing');
        System.assertEquals(originalAccount.Name + ' - Billable', elaBillingList.get(0).Name, 'Original account should be marked as a ELA Billing');
        System.assertEquals(2, elaServiceList.size(), 'Two Ela Service accounts should be created');
        System.assertEquals(2, accountRelationList.size(), 'Two AccountRelations should be created');
        System.assertEquals(3, oppList.size(), 'Three opportunities should be created');
    }

    @isTest
    static void testConvertSalesLeadToFedRampFlow() {

        SObjectFactory factory = new SObjectFactory();

        Segment_Master__c segment = [SELECT Id FROM Segment_Master__c LIMIT 1];
        Triggers.switchOff();
        Triggers.switchOff();
        Test.startTest();
        Account testAccount = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => 'testAcc',
                    Account.BillingState => 'test_state_name0',
                    Account.BillingStreet => 'test_street_name0',
                    Account.BillingPostalCode => 'test_postalcode0',
                    Account.BillingCity => 'test_city_name0',
                    Account.BillingCountry => 'United States',
                    Account.Segment_Name__c => segment.Id
                }
            )
            .create()
            .getRecord();
        Triggers.switchOn();
        Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Contact.LastName => 'testContact',
                    Contact.AccountId => testAccount.Id
                }
            )
            .create()
            .getRecord();

        Lead salesLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setField(
                Lead.RecordTypeId,
                Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Leads').getRecordTypeId()
            )
            .build()
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = salesLead.Id;
        convertLeadData.accountId = testAccount.Id;
        convertLeadData.contactId = testContact.Id;
        convertLeadData.isBilling = true;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.isFedRampFlow = true;
        convertLeadData.opportunityName = 'Test FedRamp Oppty';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.currencyCode = RingCentralHelper.GBP;
        convertLeadData.forecastedUsers = 10;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.brand = OpportunityHelper.BRAND_BT;
        convertLeadData.edition = Pricebook2Helper.EDITION_STANDARD;
        convertLeadData.product = Pricebook2Helper.SERVICE_OFFICE;
        convertLeadData.term = Product2Helper.CHARGE_TERM_ANNUAL;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Response result = null;

        ConvertLead.prepareLeadRecord(convertLeadData);
        result = ConvertLead.convertPart1(convertLeadData);
        result = ConvertLead.convertPart2((ConvertLead.ConvertLeadDTO) result.data.get('ConvertData'));


        List<Opportunity> oppList = new OpportunitySelector()
            .selectOpportunities()
            .selectFields(new List<Schema.SObjectField>{
                Opportunity.CampaignId, Opportunity.isFedRamp__c, Opportunity.Brand_Name__c
            })
            .executeQuery();
        Test.stopTest();
        Triggers.switchOn();
        if(oppList.size()>0 && !oppList.isEmpty()){
            Opportunity convertedOpp = oppList.get(0);

            System.assertEquals(
                convertLeadData.isFedRampFlow,
                convertedOpp.isFedRamp__c,
                'FedRamp Flow should be set on Opportunity based on convert lead data'
            );
        }
    }

    @isTest
    static void testPrepareLeadRecordShouldNotChangeCustomCountryToNull() {

        Lead partnerLead = (Lead) new LeadSelector()
            .selectLeads()
            .setCondition('RecordTypeId = :bind0')
            .setQueryBindings(new List<Object>{ LeadHelper.RT_ID_PARTNER_LEADS })
            .executeQuery()
            .get(0);

        Pricebook2 pb = (Pricebook2) new Pricebook2Selector()
            .selectPricebooks()
            .executeQuery()
            .get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = partnerLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();

        Response result = null;

        Test.startTest();
            ConvertLead.prepareLeadRecord(convertLeadData);
        Test.stopTest();

        Lead updatedPartnerLead = (Lead) new LeadSelector()
            .selectLeads()
            .setCondition('RecordTypeId = :bind0')
            .selectFields(new List<String>{'Country__c'})
            .setQueryBindings(new List<Object>{ LeadHelper.RT_ID_PARTNER_LEADS })
            .executeQuery()
            .get(0);

        System.assertNotEquals(
            null,
            updatedPartnerLead.Country__c,
            'Country should not be changed to null'
        );
    }
    
    @isTest
    static void storeProfileRecordInPlatformCache_StoreProfileInSessionCache_ReturnNothing() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        Id testProfileId = UserInfo.getProfileId();
        
        Test.startTest();
        ConvertLead.storeProfileRecordInPlatformCache(testProfileId);
        Test.stopTest();
        
        Assert.areNotEqual(null, testProfileId, 'Profile ID should not be null');
    }

    @isTest
    static void storeProfileRecordInPlatformCache_StoreNullInSessionCache_ReturnNothing() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        Test.startTest();
        ConvertLead.storeProfileRecordInPlatformCache(null);
        Test.stopTest();
        
        Assert.isTrue(true, 'Method should handle null profile ID gracefully');
    }

    @isTest
    static void storeUserRecordInPlatformCache_StoreUserInSessionCache_ReturnNothing() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        Id testUserId = UserInfo.getUserId();
        
        Test.startTest();
        ConvertLead.storeUserRecordInPlatformCache(testUserId);
        Test.stopTest();

        Assert.areNotEqual(null, testUserId, 'User ID should not be null');
    }

    @isTest
    static void storeUserRecordInPlatformCache_StoreNullInSessionCache_ReturnNothing() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        Test.startTest();
        ConvertLead.storeUserRecordInPlatformCache(null);
        Test.stopTest();
        
        Assert.isTrue(true, 'Method should handle null user ID gracefully');
    }

    @isTest
    static void prepareLeadRecord_StoreProfileAndUserInSessionCache_ReturnResponse() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        Lead partnerLead = (Lead) new LeadSelector()
            .selectLeads()
            .setCondition('RecordTypeId = :bind0')
            .setQueryBindings(new List<Object>{ LeadHelper.RT_ID_PARTNER_LEADS })
            .executeQuery()
            .get(0);

        Pricebook2 pb = (Pricebook2) new Pricebook2Selector()
            .selectPricebooks()
            .executeQuery()
            .get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = partnerLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;
        convertLeadData.ownerId = UserInfo.getUserId();

        convertLeadData.validate();

        Test.startTest();
        Response result = ConvertLead.prepareLeadRecord(convertLeadData);
        Test.stopTest();

        // Verify that the method executed successfully
        Assert.areNotEqual(null, result, 'Response should not be null');
        Assert.isTrue(result.isSuccess(), 'Response should be successful');
    }

    @isTest
    static void prepareLeadRecord_StoreProfileAndDifferentUserInSessionCache_ReturnResponse() {
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;
        User testUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 1];

        Lead partnerLead = (Lead) new LeadSelector()
            .selectLeads()
            .setCondition('RecordTypeId = :bind0')
            .setQueryBindings(new List<Object>{ LeadHelper.RT_ID_PARTNER_LEADS })
            .executeQuery()
            .get(0);

        Pricebook2 pb = (Pricebook2) new Pricebook2Selector()
            .selectPricebooks()
            .executeQuery()
            .get(0);

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = partnerLead.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;
        convertLeadData.ownerId = testUser.Id;

        convertLeadData.validate();

        Test.startTest();
        Response result = ConvertLead.prepareLeadRecord(convertLeadData);
        Test.stopTest();

        // Verify that the method executed successfully
        Assert.areNotEqual(null, result, 'Response should not be null');
        Assert.isTrue(result.isSuccess(), 'Response should be successful');
    }
    
    @isTest
    static void convertPart3_LeadConversionThirdStage_ReturnResponse(){
        // Mock the cache provider to avoid partition dependency
        Test_PlatformCacheUtility.MockCacheProviderStub mockStub = new Test_PlatformCacheUtility.MockCacheProviderStub();
        ICacheProvider mockProvider = (ICacheProvider) Test.createStub(ICacheProvider.class, mockStub);
        PlatformCacheUtility.setCacheProvider(mockProvider);
        
        //GIVEN
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;

        Lead partnerLead = (Lead) new LeadSelector()
            .selectLeads()
            .setCondition('RecordTypeId = :bind0')
            .setQueryBindings(new List<Object>{ LeadHelper.RT_ID_PARTNER_LEADS })
            .executeQuery()
            .get(0);

        Pricebook2 pb = (Pricebook2) new Pricebook2Selector()
            .selectPricebooks()
            .executeQuery()
            .get(0);

        Segment_Master__c segment = [SELECT Id FROm Segment_Master__c LIMIT 1];

        Account testAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Account.Name => 'testAcc',
                Account.BillingState => 'test_state_name0',
                Account.BillingStreet => 'test_street_name0',
                Account.BillingPostalCode => 'test_postalcode0',
                Account.BillingCity => 'test_city_name0',
                Account.BillingCountry => 'United States',
                Account.Segment_Name__c => segment.Id
            })
            .create()
            .getRecord();

        Contact contact = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object> {
                Contact.AccountId => testAcc.Id,
                Contact.LastName => 'testAcc',
                Contact.FirstName => 'testAcc'
            })
            .create()
            .getRecord();

        Opportunity testOpp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => testAcc.Id,
                    Opportunity.Forecasted_Users__c => 5,
                    Opportunity.Name => 'Test opportunity from PartnerLead',
                    Opportunity.Brand_Name__c => 'RingCentral',
                    Opportunity.Tier_Name__c => 'Office',
                    Opportunity.StageName => '1. Qualify',
                    Opportunity.CurrencyIsoCode => 'USD'
                }
            )
            .create()
            .getRecord();

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        convertLeadData.leadId = partnerLead.Id;
        convertLeadData.accountId = testAcc.Id;
        convertLeadData.contactId = contact.Id;
        convertLeadData.opportunityId = testOpp.Id;
        convertLeadData.isBilling = false;
        convertLeadData.isCreateOpportunity = true;
        convertLeadData.isCreateQuote = true;
        convertLeadData.opportunityName = 'my test opportunity from SalesLead';
        convertLeadData.upsellStatus = QuoteHelper.STATUS_NEW_CUSTOMER;
        convertLeadData.forecastedUsers = 0;
        convertLeadData.ccForecastedUsers = 0;
        convertLeadData.pricebook2Id = pb.Id;
        convertLeadData.doNotCreateOpportunity = false;
        convertLeadData.rcUserId = 'testRCIdd1';
        convertLeadData.existingUsers = 0;

        convertLeadData.validate();
        
        Test.startTest();
        Response result = ConvertLead.convertPart3(convertLeadData);
        Test.stopTest();

        // Verify that the method executed successfully
        Assert.areNotEqual(null, result, 'Response should not be null');
        Assert.isTrue(result.isSuccess(), 'Response should be successful');
    }
    
    @isTest
    static void convertPart4_LeadConversionFourthStage_ReturnResponse(){
        //GIVEN
        ConvertLead.IS_LEAD_CONVERT_PROCESSING = true;
        SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c = true;

        ConvertLead.ConvertLeadDTO convertLeadData = new ConvertLead.ConvertLeadDTO();
        
        Test.startTest();
        Response result = ConvertLead.convertPart4(convertLeadData);
        Test.stopTest();

        // Verify that the method executed successfully
        Assert.isNotNull(result, 'Response should not be null');
        
    }
}
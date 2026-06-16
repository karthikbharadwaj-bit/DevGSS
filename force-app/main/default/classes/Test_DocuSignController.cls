@IsTest
private class Test_DocuSignController {

    @IsTest
    static private void testGetDataOnInit() {
        Account testAcc = new Account(
            Name = 'testAccount'
        );
        insert testAcc;

        Contact testContact = new Contact(
            AccountId = testAcc.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'jd@rc.tld'
        );
        insert testContact;

        Opportunity testOpp = new Opportunity(
            Name = 'test opp',
            StageName = '1. Qualify',
            AccountId = testAcc.Id,
            Primary_Opportunity_Contact__c = testContact.Id
        );
        insert testOpp;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.id,
            Status = QuoteHelper.QUOTE_STATUS_DRAFT
        );
        insert testQuote;

        Attachment att = new Attachment(
            ParentId = testOpp.Id,
            Name = 'TestPDF.pdf',
            Body = Blob.valueOf('testBody')
        );
        insert att;

        Test.startTest();
        Response r = DocuSignController.getDataOnInit(testOpp.Id, null);
        Test.stopTest();

        List<Attachment> atts = (List<Attachment>) r.data.get('attachmentList');
        List<DocuSignController.Recipient> rcpnts = (List<DocuSignController.Recipient>) r.data.get('recipientList');
        List<Opportunity> opportunities = (List<Opportunity>) r.data.get('opportunityList');
        Map<Id, Response> oppErrors = (Map<Id, Response>) r.data.get('opportunityErrors');
        System.assertEquals(1, rcpnts.size(), 'Recipients Should be selected');

        // Used on Legacy only
        System.assertEquals(1, atts.size(), 'Attachments should be selected');

        // Used on NGBS only
        System.assertEquals(1, opportunities.size(), 'Opportunities should be selected');
        System.assertEquals(1, opportunities.get(0).Attachments.size(), 'Attachments should be selected under with Opportunities');
        System.assertEquals(1, oppErrors.get(testOpp.Id).messages.size(), 'Opportunity should be validated');
        System.assertEquals(
            'Primary Quote should be in \'Agreement\' stage and has \'Approved\' or \'Not Required\' approved status ' +
                'in order to be sent with DocuSign',
            oppErrors.get(testOpp.Id).messages.get(0).message,
            'Opportunity should be validated'
        );
        System.debug(oppErrors.get(testOpp.Id).messages.get(0));
    }

    @IsTest
    static private void testGetDataOnInitWithEngageLegal() {
        User leader = new User(
            Username = UserHelper.getUniqueUserName(),
            LastName = 'John Leader',
            Email = 'jd@rc.tld',
            Alias = 'jd',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN,
            LanguageLocaleKey = 'en_US',
            Hierarchy_Role__c = UserHelper.SEGMENT_LEADER_ROLE
        );
        insert leader;

        User oppOwner = new User(
            Username = UserHelper.getUniqueUserName(),
            LastName = 'John Sales',
            Email = 'jd@rc.tld',
            Alias = 'jd',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = ProfileHelper.PROFILE_ID_SYSADMIN,
            LanguageLocaleKey = 'en_US',
            Hierarchy_Role__c = UserHelper.SALES_REP_ROLE,
            ManagerId = leader.Id
        );
        insert oppOwner;

        Account testAcc = new Account(
            Name = 'testAccount'
        );
        insert testAcc;

        Contact testContact = new Contact(
            AccountId = testAcc.Id,
            LastName = 'John',
            FirstName = 'Doe',
            Email = 'jd@rc.tld'
        );
        insert testContact;

        Opportunity testOpp = new Opportunity(
            Name = 'test opp',
            StageName = '1. Qualify',
            AccountId = testAcc.Id,
            OwnerId = oppOwner.Id,
            Primary_Opportunity_Contact__c = testContact.Id
        );
        insert testOpp;

        Approval__c elAooApproval = new Approval__c(
            Name = 'Test',
            RecordTypeId = ApprovalHelper.RT_ID_ENGAGE_LEGAL,
            Opportunity__c = testOpp.Id
        );
        insert elAooApproval;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.id,
            Status = QuoteHelper.QUOTE_STATUS_DRAFT
        );
        Test.startTest();
        insert testQuote;

        Attachment att = new Attachment(
            ParentId = testOpp.Id,
            Name = 'TestPDF.pdf',
            Body = Blob.valueOf('testBody')
        );
        insert att;

        
        Response r = DocuSignController.getDataOnInit(testOpp.Id, null);
        Test.stopTest();

        List<Attachment> atts = (List<Attachment>) r.data.get('attachmentList');
        List<DocuSignController.Recipient> rcpnts = (List<DocuSignController.Recipient>) r.data.get('recipientList');
        System.assertEquals(1, atts.size());
        System.assertEquals(2, rcpnts.size());

        // first signer should be a user with OpportunityContactRole = 'Signatory'
        DocuSignController.Recipient firstSigner = rcpnts.get(0);
        System.assertEquals(testContact.Email, firstSigner.Email);
    }

    @IsTest
    static private void testGetDataOnInitwithRelatedQuote() {
        Account[] accounts = (Account[]) new SObjectBuilder(Account.SObjectType)
            .quantity(2)
            .setFields(new Map<SObjectField, Object>{
                Account.Name => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecords();
        Test.startTest();
            Contact testContact = (Contact) new SObjectBuilder(Contact.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    Contact.LastName => ValueProviderBuilder.provideUniqueString(),
                    Contact.FirstName => ValueProviderBuilder.provideUniqueString(),
                    Contact.Email => ValueProviderBuilder.provideUniqueEmail(),
                    Contact.AccountId => accounts.get(0).Id
                })
                .create()
                .getRecord();

            Opportunity[] testOpportunities = (Opportunity[]) new SObjectBuilder(Opportunity.SObjectType)
                .quantity(2)
                .setFields(new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString(),
                    Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                    Opportunity.AccountId => ValueProviderBuilder.provideParents(accounts),
                    Opportunity.Primary_Opportunity_Contact__c => testContact.Id,
                    Opportunity.Is_Billing_Opportunity__c => true
                })
                .create()
                .getRecords();

            Quote[] quotes = (Quote[]) new SObjectBuilder(Quote.SObjectType)
                .quantity(2)
                .setFields(new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideUniqueString(),
                    Quote.OpportunityId => ValueProviderBuilder.provideParents(testOpportunities),
                    Quote.Status => QuoteHelper.QUOTE_STATUS_DRAFT,
                    Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING
                })
                .create()
                .getRecords();
            update new Quote(Id = quotes.get(1).Id, ParentQuote__c = quotes.get(0).Id);

            Attachment[] attachments = (Attachment[]) new SObjectBuilder(Attachment.SObjectType)
                .quantity(2)
                .setFields(new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideUniqueString(),
                    Attachment.ParentId => ValueProviderBuilder.provideParents(testOpportunities),
                    Attachment.Body => ValueProviderBuilder.provideUniqueBlob()
                })
                .create()
                .getRecords();

            Response r = DocuSignController.getDataOnInit(testOpportunities.get(0).Id, quotes.get(0).Id);
        Test.stopTest();

        List<Attachment> atts = (List<Attachment>) r.data.get('attachmentList');
        List<DocuSignController.Recipient> rcpnts = (List<DocuSignController.Recipient>) r.data.get('recipientList');
        List<Opportunity> opportunities = (List<Opportunity>) r.data.get('opportunityList');
        Map<Id, Response> oppErrors = (Map<Id, Response>) r.data.get('opportunityErrors');
        System.assertEquals(1, rcpnts.size(), 'Recipients Should be selected');
        System.assertEquals(testContact.Id, rcpnts.get(0).Id, 'Recipient should be created from contact');

        System.debug('|'+testContact.Email+'|'+rcpnts.get(0).Email+'|');
        System.assert(testContact.Email == rcpnts.get(0).Email, 'Recipient should have contact Email');

        // Used on Legacy only
        System.assertEquals(1, atts.size(), 'Attachments for requested opportunity should be selected');
        System.assertEquals(attachments.get(0).Id, atts.get(0).Id, 'Attachments for requested opportunity should be selected');

        // Used on NGBS only
        System.assertEquals(2, opportunities.size(), 'requested and linked Opportunity should be selected');
        System.assertEquals(1, opportunities.get(0).Attachments.size(), 'Attachments should be selected with Opportunities respectfully');
        System.assertEquals(1, opportunities.get(1).Attachments.size(), 'Attachments should be selected with Opportunities respectfully');
        System.assertEquals(attachments.get(1).Id, opportunities.get(1).Attachments.get(0).Id, 'Attachments should be selected with Opportunities respectfully');
        System.assertEquals(1, oppErrors.get(opportunities.get(0).Id).messages.size(), 'Opportunity should be validated');
        System.assertEquals(
            'Primary Quote should be in \'Agreement\' stage and has \'Approved\' or \'Not Required\' approved status ' +
                'in order to be sent with DocuSign',
            oppErrors.get(opportunities.get(0).Id).messages.get(0).message,
            'Opportunity should be validated'
        );
        System.assertEquals(
            'Primary Quote should be in \'Agreement\' stage and has \'Approved\' or \'Not Required\' approved status ' +
                'in order to be sent with DocuSign',
            oppErrors.get(opportunities.get(1).Id).messages.get(0).message,
            'Opportunity should be validated'
        );
        System.assertEquals(1, oppErrors.get(opportunities.get(1).Id).messages.size(), 'Opportunity should be validated');
    }

    @IsTest
    static private void testPrepareDocuSign() {
        List<Account> accList = (List<Account>) new SObjectBuilder(Account.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('Test account')
                }
            )
            .quantity(2)
            .create()
            .getRecords();

        Account masterAcc = accList[0];
        Account childAcc = accList[1];
        
        List<Opportunity> oppList = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('Test opportunity')
                }
            )
            .setFields(
                new Map<SObjectField, Object>{
                    Opportunity.AccountId => ValueProviderBuilder.provideList(new List<Id>{
                        masterAcc.Id, childAcc.Id
                    })
                }
            )
            .setField(Opportunity.StageName, '1. Qualify')
            .quantity(2)
            .create()
            .getRecords();

        Opportunity masterOpty = oppList[0];
        Opportunity childOpty = oppList[1];


        List<Quote> quoteList = (List<Quote>) new SObjectBuilder(Quote.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.Name => ValueProviderBuilder.provideUniqueString('Test quote')
                }
            )
            .setFields(
                new Map<SObjectField, Object>{
                    Quote.OpportunityId => ValueProviderBuilder.provideList(new List<Id>{
                      masterOpty.Id, childOpty.Id
                    })
                }
            )
            .setField(Quote.Status, QuoteHelper.QUOTE_STATUS_DRAFT)
            .setField(Quote.isPrimary__c, true)
            .quantity(2)
            .create()
            .getRecords();

        Quote masterQuote = quoteList[0];
        Quote childQuote = quoteList[1];

        List<Attachment> attList = (List<Attachment>) new SObjectBuilder(Attachment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.Name => ValueProviderBuilder.provideList(new List<String>{
                        'TestPDFold.pdf', 'TestPDFmasterOpp.pdf', 'TestPDFchildOpp.pdf'
                    })
                }
            )
            .setFields(
                new Map<SObjectField, Object>{
                    Attachment.ParentId => ValueProviderBuilder.provideList(new List<Id>{
                        masterQuote.Id, masterOpty.Id, childOpty.Id
                    })
                }
            )
            .setField(Attachment.Body, Blob.valueOf('testBody'))
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
        Response r = DocuSignController.send(masterQuote.Id, new List<Id>{
          attList[1].Id, attList[2].Id
        });
        Test.stopTest();

        List<Attachment> atts = [SELECT Id, Name FROM Attachment WHERE ParentId = :masterQuote.Id];
        System.assertEquals(2, atts.size());

        Boolean isCorrectMasterOppAttachmentName = false;
        Boolean isCorrectChildOppAttachmentName = false;
        for (Attachment att : atts) {
            if (att.Name == 'TestPDFmasterOpp.pdf') {
                isCorrectMasterOppAttachmentName = true;
            }
            if (att.Name == 'TestPDFchildOpp ' + '{' + childAcc.Id + '}' + '.pdf') {
                isCorrectChildOppAttachmentName = true;
          }
        }
        System.assert(isCorrectMasterOppAttachmentName, 'Master account attachments names should not be changed');
        System.assert(isCorrectChildOppAttachmentName, 'Child account attachments names should have accountId marker');
    }

    @IsTest
    static private void testValidateBeforeStart() {
        Opportunity testOpp = new Opportunity(
            Name = 'test opp',
            StageName = '1. Qualify'
        );
        insert testOpp;

        Test.startTest();
        Response r = DocuSignController.validateBeforeStart(testOpp.Id, null);
        Test.stopTest();

        System.assertNotEquals(0, r.data.values().size());
    }

    @isTest
    private static void testGetEnvelopesOnCurrentQuote() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        Product2 productMonthly = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString(),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_MONTHLY,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Product2 productAnnual = (Product2) new SObjectBuilder(Product2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Product2.Name => ValueProviderBuilder.provideUniqueString(),
                Product2.Charge_Term__c => Product2Helper.CHARGE_TERM_ANNUAL,
                Product2.Family => Product2Helper.FAMILY_SERVICE,
                Product2.Feature__c => Product2Helper.FEATURE_SERVICE_PLAN
            })
            .create()
            .getRecord();

        Entitlement__c ent = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Name => ValueProviderBuilder.provideUniqueString(),
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Product__c => productMonthly.Id
            })
            .create()
            .getRecord();

        Entitlement__c entForQLI = (Entitlement__c) new SObjectBuilder(Entitlement__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Entitlement__c.Name => ValueProviderBuilder.provideUniqueString(),
                Entitlement__c.Active__c => true,
                Entitlement__c.Account__c => billingAcc.Id,
                Entitlement__c.Price__c => 10,
                Entitlement__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY,
                Entitlement__c.Discount__c => 0,
                Entitlement__c.Quantity__c => 5,
                Entitlement__c.Product__c => productMonthly.Id
            })
            .create()
            .getRecord();

        PriceBook2 pricebook = (PriceBook2) new SObjectBuilder(PriceBook2.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                PriceBook2.Service__c => Pricebook2Helper.SERVICE_OFFICE,
                PriceBook2.IsActive => true,
                PriceBook2.Line_Range_Min__c => 5,
                PriceBook2.Tier_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Quote qt = (Quote) new SObjectBuilder(Quote.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Quote.OpportunityId => opp.Id,
                Quote.RecordTypeId => QuoteHelper.RT_ID_BILLING,
                Quote.Upsell_Status__c => QuoteHelper.STATUS_UPGRADE,
                Quote.Pricebook2Id => pricebook.Id,
                Quote.CurrentService__c => ent.Id
            })
            .create()
            .getRecord();

        List<dsfs__DocuSign_Status__c> status =
            (List<dsfs__DocuSign_Status__c>) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    dsfs__DocuSign_Status__c.dsfs__Company__c => billingAcc.Id,
                    dsfs__DocuSign_Status__c.dsfs__Opportunity__c => opp.Id,
                    dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => ApprovalHelper.STATUS_COMPLETED
                })
                .quantity(3)
                .create()
                .getRecords();

        List<dsfs__DocuSign_Status__c> testStatus =
            (List<dsfs__DocuSign_Status__c>) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    dsfs__DocuSign_Status__c.dsfs__Opportunity__c => opp.Id,
                    dsfs__DocuSign_Status__c.dfsq__Quote__c => qt.Id,
                    dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => QuoteHelper.QUOTE_STATUS_DRAFT
                })
                .create()
                .getRecords();

        Test.startTest();

        Response resp = DocuSignController.getEnvelopes(opp.Id, qt.Id);

        Test.stopTest();

        System.assertEquals(
            1,
            ((List<dsfs__DocuSign_Status__c>) resp.data.get('envelopeList')).size(),
            'Incorrect DocuSign Statuses was selected'
        );

        System.assert(
            ((Boolean) resp.data.get('isOpportunityHasActiveEnvelopes')),
            'Opportunity should have Envelopes'
        );
    }

    @isTest
    private static void testGetEnvelopesWithoutQuote() {

        Account billingAcc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString()
            })
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Opportunity.CloseDate => System.today(),
                Opportunity.AccountId => billingAcc.Id,
                Opportunity.Is_Billing_Opportunity__c => true
            })
            .create()
            .getRecord();

        List<dsfs__DocuSign_Status__c> status =
            (List<dsfs__DocuSign_Status__c>) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
                .setFields(new Map<SObjectField, Object>{
                    dsfs__DocuSign_Status__c.dsfs__Company__c => billingAcc.Id,
                    dsfs__DocuSign_Status__c.dsfs__Opportunity__c => opp.Id,
                    dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => ApprovalHelper.STATUS_COMPLETED
                })
                .quantity(3)
                .create()
                .getRecords();

        Test.startTest();

        Response resp = DocuSignController.getEnvelopes(opp.Id, null);

        Test.stopTest();

        System.assertEquals(
            3,
            ((List<dsfs__DocuSign_Status__c>) resp.data.get('envelopeList')).size(),
            'Incorrect DocuSign Statuses was selected'
        );

        System.assert(
            ((Boolean) resp.data.get('isOpportunityHasActiveEnvelopes')),
            'Opportunity should have Envelopes'
        );
    }

    @isTest
    private static void testGetEnvelopesWithoutOppty() {

        Test.startTest();

        Response resp = DocuSignController.getEnvelopes(null, null);

        Test.stopTest();

        System.assert(
            ((List<dsfs__DocuSign_Status__c>) resp.data.get('envelopeList')).isEmpty(),
            'Empty list of Envelopes should be returned without Oppty'
        );

        System.assert(
            !((Boolean) resp.data.get('isOpportunityHasActiveEnvelopes')),
            'Oppty should not have active Envelopes'
        );
    }
}
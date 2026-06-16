@isTest
public class Test_DocuSignStatusSelector {
    @TestSetup
    static void prepareData() {
        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Account.SObjectType))
            .create()
            .getRecord();

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setField(Opportunity.Name, 'Test Opportunity')
            .setField(Opportunity.Type, 'Syndicated - New')
            .setField(Opportunity.StageName, OpportunityHelper.STAGE_NAME_QUALIFY)
            .setField(Opportunity.CloseDate, System.today().addMonths(1))
            .setField(Opportunity.AccountId, acc.Id)
            .create()
            .getRecord();

        Quote q = (Quote) new SObjectBuilder(Quote.sObjectType)
            .setField(Quote.Pricebook2Id, Test.getStandardPricebookId())
            .setField(Quote.OpportunityId, opp.Id)
            .create()
            .getRecord();

        dsfs__DocuSign_Status__c env1 = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dfsq__Quote__c => q.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_SENT
            })
            .create()
            .getRecord();

        dsfs__DocuSign_Status__c env2 = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dfsq__Quote__c => q.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_COMPLETED
            })
            .create()
            .getRecord();

        dsfs__DocuSign_Status__c env3 = (dsfs__DocuSign_Status__c) new SObjectBuilder(dsfs__DocuSign_Status__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                dsfs__DocuSign_Status__c.dsfs__Company__c => acc.Id,
                dsfs__DocuSign_Status__c.dsfs__DocuSign_Envelope_ID__c => '2155d73219918144d3',
                dsfs__DocuSign_Status__c.dsfs__Envelope_Status__c => DocuSignHelper.ENVELOPE_STATUS_COMPLETED
            })
            .create()
            .getRecord();
    }

    @isTest
    static void testSelectDocuSignStatuses() {
        List<dsfs__DocuSign_Status__c> records = (List<dsfs__DocuSign_Status__c>) new docuSignStatusSelector()
            .selectDocuSignStatuses()
            .executeQuery();

        System.assertEquals(3, records.size(), 'Three records should be selected');

    }

    @isTest
    static void testSelectDocuSignStatusesByIds() {
        List<dsfs__DocuSign_Status__c> records = (List<dsfs__DocuSign_Status__c>) new docuSignStatusSelector()
            .selectDocuSignStatuses()
            .executeQuery();

        dsfs__DocuSign_Status__c randomRecord = records.get(0);

        List<dsfs__DocuSign_Status__c> recordsById = (List<dsfs__DocuSign_Status__c>) new DocuSignStatusSelector()
            .selectDocuSignStatusesByIds(new List<Object> {new List<Id> {randomRecord.Id}})
            .executeQuery();

        System.assertEquals(randomRecord.Id, recordsById.get(0).Id, 'Two records should have the same Id');
    }

    @isTest
    static void testSelectDocuSignStatusesByAttachments() {
        List<dsfs__DocuSign_Status__c> records = (List<dsfs__DocuSign_Status__c>) new docuSignStatusSelector()
            .selectDocuSignStatuses()
            .executeQuery();

        Id completedRecordId;

        for (dsfs__DocuSign_Status__c r : records) {
            if (r.dsfs__Envelope_Status__c == DocuSignHelper.ENVELOPE_STATUS_COMPLETED) {
                completedRecordId = r.Id;
            }
        }

        List<Object> bindings = new List<Object>();
        bindings.add(DocuSignHelper.ENVELOPE_STATUS_COMPLETED);
        bindings.add(new List<Id>{completedRecordId});

        List<dsfs__DocuSign_Status__c> completedRecordsById = (List<dsfs__DocuSign_Status__c>) new DocuSignStatusSelector()
            .selectDocuSignStatusesByAttachments(bindings)
            .executeQuery();

        System.assertEquals(completedRecordId, completedRecordsById.get(0).Id, 'Wrong record selected');
    }

    @isTest
    static void testSelectDocuSignStatusForSignUp() {
        List<Quote> quotes = (List<Quote>) new QuoteSelector()
            .selectQuotes()
            .executeQuery();

        List<dsfs__DocuSign_Status__c> records = new DocuSignStatusSelector()
            .selectDocuSignStatusForSignUp(quotes.get(0).Id)
            .executeQuery();

        System.assertEquals(DocuSignHelper.ENVELOPE_STATUS_COMPLETED,
            records.get(0).dsfs__Envelope_Status__c,
            'Completed record should be retrieved');
    }

    @isTest static void testSelectCompletedDocuSignStatusesForNdaById() {
        
        List<dsfs__DocuSign_Status__c> records = (List<dsfs__DocuSign_Status__c>) new docuSignStatusSelector()
            .selectDocuSignStatuses()
            .executeQuery();
        Set<Id> dssIds = new Set<Id>();
        for (dsfs__DocuSign_Status__c dss : records) {
            dssIds.add(dss.Id);
        }

        Test.startTest();

        List<dsfs__DocuSign_Status__c> recordsById = (List<dsfs__DocuSign_Status__c>) new DocuSignStatusSelector()
            .selectCompletedDocuSignStatusesForNdaById(new List<Object> { dssIds })
            .executeQuery();

        Test.stopTest();

        System.assertEquals(1, recordsById.size(), 'Incorrect Completed DocuSign Statuses were retrieved');
    }

}
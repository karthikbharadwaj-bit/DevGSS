@isTest
public with sharing class Test_EventTriggerHelper {

    private static Event createEvent(Id wId) {
        return (Event) new SObjectBuilder(Event.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Event.ActivityDateTime => System.now(),
                    Event.WhoId => wId,
                    Event.Subject => 'test subject',
                    Event.CreatedDate => System.now(),
                    Event.DurationInMinutes => 1
                }
            )
            .create()
            .getRecord();
    }

    private static Demand_Funnel__c getResultDmf(Id dmfId) {
        return (Demand_Funnel__c) new ListOptional(new DemandFunnelSelector()
            .selectDFRById(new List<Object> { dmfId })
            .selectField('First_Activity_Name_after_MQL__c')
            .executeQuery()
        ).getFirst();
    }
    
    @isTest
    private static void testPopulateDFRActivityFieldsWithContact() {
        Contact ct = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Contact.FirstName => 'Test1',
                    Contact.LastName => 'Test1',
                    Contact.Email => 'something@mostcommon.fake',
                    Contact.Phone => '1234567890',
                    Contact.Preferred_Language__c => ContactHelper.PREFERRED_LANGUAGE_EN_US
                }
            )
            .create()
            .getRecord();

        Event eventRecord = createEvent(ct.Id);

        Demand_Funnel__c dmf = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Demand_Funnel__c.MQL_DateTime_Entered__c => System.now().addDays(-1),
                    Demand_Funnel__c.First_Activity_DateTime_after_MQL__c => null,
                    Demand_Funnel__c.Contact__c => ct.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        EventTriggerHelper.populateDFRActivityFields(new List<Event> {eventRecord});
        Test.stopTest();

        Demand_Funnel__c resultDmf = getResultDmf(dmf.Id);
        Assert.areEqual(eventRecord.Subject, resultDmf.First_Activity_Name_after_MQL__c, 'Values must be equal');
    }

    @isTest
    private static void testPopulateDFRActivityFieldsWithLead() {
        Lead ld = (Lead) new SObjectBuilder(Lead.SObjectType)
            .create()
            .getRecord();

        Event eventRecord = createEvent(ld.Id);

        Demand_Funnel__c dmf = (Demand_Funnel__c) new SObjectBuilder(Demand_Funnel__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Demand_Funnel__c.MQL_DateTime_Entered__c => System.now().addDays(-1),
                    Demand_Funnel__c.EOL_DateTime_Entered__c => System.now().addDays(1),
                    Demand_Funnel__c.SAL_DateTime_Entered__c => System.now().addDays(1),
                    Demand_Funnel__c.First_Activity_DateTime_after_MQL__c => null,
                    Demand_Funnel__c.Lead__c => ld.Id
                }
            )
            .create()
            .getRecord();

        Test.startTest();
        EventTriggerHelper.populateDFRActivityFields(new List<Event> { eventRecord });
        Test.stopTest();

        Demand_Funnel__c resultDmf = getResultDmf(dmf.Id);
        Assert.areEqual(eventRecord.Subject, resultDmf.First_Activity_Name_after_MQL__c, 'Values must be equal');
    }
}
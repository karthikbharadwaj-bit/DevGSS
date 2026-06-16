@isTest
private class JIRA_Test_Termination {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void test1(){

        test.starttest();

        //Create Account
        Account Acc = new Account();
        Acc.Name = 'RC Internal';
        insert Acc;

        //Create Contact
        Contact cont = new Contact();
        cont.LastName = 'Mutya';
        cont.AccountId = Acc.Id;
        insert Cont;

        // Get Record Type
        Id CaseRecordTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByName().get('IT Helpdesk').getRecordTypeId();

        Case c = new Case();
        c.recordtypeid = CaseRecordTypeInfo;
        c.Status='New';
        c.Request_Type__c = 'Helpdesk'; // This is the Request Branch field name
        c.Request_Subtype_1__c = 'Hardware'; // This is the Request Type field name
        c.ContactId = Cont.Id;
        c.AccountId = Acc.Id;

        insert c;
        
        JIRA_CreateUpdate_Termination.fromTrigger(c.Id);
     
        c.status = 'WIP';
        update c;
        
        JIRA_CreateUpdate_Termination.fromTrigger(c.Id);
        
        test.stoptest();

    }

    @isTest
    static void test2() {

        JIRA_GlobalMethods gm = new JIRA_GlobalMethods();
        JIRA_JSONDeserialize obj1 = JIRA_JSONDeserialize.parse(gm.getJasonString());
        JIRA_JSONDeserialize_errHandler obj2 = JIRA_JSONDeserialize_errHandler.parse(gm.getJasonStringError());
        DateTime dt = gm.FormatDate('2015-11-06T13:04:19.000-0800');
        String sValue;
        sValue = gm.getJirBaseaURL(True);
        sValue = gm.getJirBaseaURL(False);
        sValue = gm.GetBaseURL(True);
        sValue = gm.GetBaseURL(False);
        sValue = gm.GetAPIKey(True);
        sValue = gm.GetAPIKey(False);
        sValue = gm.GetAPIKey(True);
        sValue = gm.GetAPIKey(False);
        
        System.assert(obj1 != null);
        System.assert(obj2 != null);
        
    }
    
    
}
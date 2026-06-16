@istest
public class Test_Case_StandardCaseCreate_Ctrl {
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
@isTest
    private static void check_SupportBilling_ACO() {

        Triggers.switchOff();
        SObjectFactory factory = new SObjectFactory();

        List<Account> accountRecords = (List<Account>) factory
            .create(
                Account.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Account.Name => ValueProviderBuilder.provideUniqueString('TestAccountName_'),
                    Account.RC_Brand__c => ValueProviderBuilder.provideUniqueString('Avaya Cloud Office')
                }
            );
		
        List<Opportunity> oppRecords = (List<Opportunity>) factory
            .create(
                Opportunity.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Opportunity.Name => ValueProviderBuilder.provideUniqueString('TestOppName_'),
                    Opportunity.StageName => ValueProviderBuilder.provideUniqueString('Qualify'),
		    	    Opportunity.AccountId => ValueProviderBuilder.provideParents(accountRecords),
                    Opportunity.CloseDate => system.today().addMonths(1)
                }
            );
        
        List<Contact> contactRecords = (List<Contact>) factory
            .create(
                Contact.SObjectType,
                1,
                new Map<SObjectField, Object>{
                    Contact.AccountId => ValueProviderBuilder.provideParents(accountRecords)
                }
            );

        List<Case> caseRecords = (List<Case>) factory
            .build(
                Case.SObjectType,
                2,
                new Map<SObjectField, Object>{
                    Case.AccountId => ValueProviderBuilder.provideParents(accountRecords),
                    Case.ContactId => ValueProviderBuilder.provideParents(contactRecords),
                    Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_INTEGRATIONS,
                    Case.Subject => ValueProviderBuilder.provideUniqueString('TestSubject_'),
                    Case.Description => ValueProviderBuilder.provideUniqueString('TestDescription_')
                }
            );
        
        Triggers.switchOn();
        
        Test.startTest();
        Case_StandardCaseCreate_Ctrl.getInitialData(caseRecords[0].id);
        Case_StandardCaseCreate_Ctrl.getAccntData(accountRecords[0].id);
        Case_StandardCaseCreate_Ctrl.getBrandName(accountRecords[0].id);
        Case_StandardCaseCreate_Ctrl.getBrandName(contactRecords[0].id);
        Case_StandardCaseCreate_Ctrl.getBrandName(oppRecords[0].id);
        Case_StandardCaseCreate_Ctrl.checkfieldAccess();
        Test.stopTest();
        }
}
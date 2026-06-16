@isTest
public class Test_EscalateERTTeam {
	@isTest
    static void testERTCASE(){
        EscalateERTTeam ertObj = new EscalateERTTeam();

        Test.startTest();
        Account acctest = new Account();
        acctest.Name='TestAccount22';
        acctest.RecordTypeId  = AccountHelper.RT_ID_CUSTOMER_ACCOUNT;
        insert acctest; 

        Contact contObj = new Contact();
        contObj.AccountId =  acctest.Id;
        contObj.Email = 'abc22@test.com';
        contObj.LastName = 'Test Last22';
        insert contObj;

        Case caseObj = new Case();
        caseObj.AccountId = acctest.Id;
        caseObj.ContactId = contObj.Id;
        insert caseObj;	
        Test.stopTest();
        String testEscalation = EscalateERTTeam.escalateToERT(caseObj.Id);

        System.assertEquals(testEscalation, EscalateERTTeam.ERT_TEAM);
    }
}
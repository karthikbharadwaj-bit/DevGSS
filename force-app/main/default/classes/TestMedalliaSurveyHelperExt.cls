/*
* Project Name..........: Medallia                                                               
* File..................: MedalliaSurveyHelperExt.class                                              
* Version...............: 1.0                                                                   
* Created by............: eugenebasianomutya                                                   
* Created Date..........: 09022016
* Description...........: This class is created to retrieve the User, User Manager of the CSM Account Team of Case, Opp and Acc
*/
@isTest
public class TestMedalliaSurveyHelperExt{

    static Set<Id> AccIdSet = new Set<Id>();

    static void recordSetup(){
        Test_Utils testRecordClass = new Test_Utils();
        
        try{
            // Creating Test User Records.
            User testUser = testRecordClass.createUserRecord(new List<User>{new User()})[0];
            
            // Creating Account Record.
            List<Account> testAccountList = new List<Account>();
            Account accountRecord = new Account();
            accountRecord.type = 'Customer';
            accountRecord.RC_Signup_Date__c = Date.Today().addDays(-92);
            accountRecord.Current_Owner__c = testUser.Id;
            testAccountList.add(accountRecord);
            testAccountList = testRecordClass.createAccountRecord(testAccountList);
            system.debug('#### testAccount - '+testAccountList);
            
            // Creating Contact Record.
            List<Contact> testContactList = new List<Contact>();
            Contact contactRecord = new Contact();
            contactRecord.AccountId = testAccountList[0].Id;
            testContactList.add(contactRecord);
            testContactList = testRecordClass.createContactRecord(testContactList);
            system.debug('#### testContact - '+testContactList);
            
            AccIdSet.add(testAccountList[0].Id);
            
            // Creating Account Team.
            AccountTeamMember  atm = new AccountTeamMember ();
            atm.AccountId=testAccountList[0].Id;
            atm.UserId=testUser.id;
            atm.TeamMemberRole ='Customer Success Manager (CSM)';
            insert atm; 

            system.debug('#### acrRecord - '+ atm);

        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }

    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void MedalliaSurveyHelperExtTest() {
        try{
            recordSetup();
            system.debug('#### Account Id - '+ AccIdSet);
            Test.startTest();

                 // Case 04840827 - Medallia Report Update - START
                MedalliaSurveyHelperExt medSurHelpExt = new MedalliaSurveyHelperExt();
                map<Id, List<MedalliaSurveyHelperExt.myUser>> medSurHelpExtUser = new map<Id, List<MedalliaSurveyHelperExt.myUser>>();
                medSurHelpExtUser = medSurHelpExt.MedalliaSurveyHelperProcess(AccIdSet);
                List<MedalliaSurveyHelperExt.myUser> lUser = new List<MedalliaSurveyHelperExt.myUser>();            
                // Case 04840827 - Medallia Report Update - START 

            Test.stopTest();
            
        }catch(Exception ex){
            system.debug('#### Error on line - '+ex.getLineNumber());
            system.debug('#### Error message - '+ex.getMessage());
        }
    }
    
	@isTest
	public static void getMedalliaSurveyEmailMappingToCase_WhenRecordTypeNameIsCorrect_ShouldBeOk() {

		List<Medallia_Mapping_Email_to_Case__mdt> setupMappingMDT = (List<Medallia_Mapping_Email_to_Case__mdt>)Json.deserialize('['+
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "UID",' +
			'"Record_API_Name_Field__c" : "UID"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Test",' +
			'"Record_API_Name_Field__c" : "Tested"' +
			'},' + 
			'{"Record_Type__c": "'+ CaseHelper.RT_NAME_CUSTOMER_FEEDBACK +'",' +
			'"Key_tag_in_Email__c": "Key tag in email",' +
			'"Record_API_Name_Field__c" : "Record API Name Field"' + 
			'}' + 
		']', List<Medallia_Mapping_Email_to_Case__mdt>.class);

		MedalliaSurveyHelper.MedalliaSurveyEmailMappingMDT = setupMappingMDT;

		Test.startTest();
			Map<String, Medallia_Mapping_Email_to_Case__mdt> medalliaSurveyEmailMapping = MedalliaSurveyHelper.getMedalliaSurveyEmailMappingToCase(
				CaseHelper.RT_NAME_CUSTOMER_FEEDBACK
			);
		Test.stopTest();

		System.assertEquals(3, medalliaSurveyEmailMapping.size(), 'There should be 3 records in the map, current map: ' + medalliaSurveyEmailMapping);
		System.assertEquals('UID', medalliaSurveyEmailMapping.get('UID').Record_API_Name_Field__c,
			'The value for KEY "UID" should be "UID"' 
		);
		System.assertEquals('Tested', medalliaSurveyEmailMapping.get('Test').Record_API_Name_Field__c, 
			'The value for KEY "Test" should be "Tested"'
		);
		System.assertEquals('Record API Name Field', medalliaSurveyEmailMapping.get('Key tag in email').Record_API_Name_Field__c,
			'The value for KEY "Key tag in email" should be "Record API Name Field"'
		);
	}

	@isTest
	public static void getMedalliaSurveyEmailMappingToCase_WhenRecordTypeNameIsInvalid_ShouldBeOk() {
		Boolean hasThrownException = false;
		String errorMessage = '';

		Test.startTest();
			try{
				Map<String, Medallia_Mapping_Email_to_Case__mdt> medalliaSurveyEmailMapping = MedalliaSurveyHelper.getMedalliaSurveyEmailMappingToCase(
					'Invalid recordType'
				);
			}catch(Exception e){
				hasThrownException = true;
				errorMessage = e.getMessage();
			}
		Test.stopTest();

		system.assertEquals(true, hasThrownException, 'Since invalid record type name was given as parameter, it should throw an exception');
		system.assertEquals(MedalliaSurveyHelper.INVALID_RECORDTYPE_NAME, errorMessage, 'Error message must be: ' + MedalliaSurveyHelper.INVALID_RECORDTYPE_NAME);
	}
}
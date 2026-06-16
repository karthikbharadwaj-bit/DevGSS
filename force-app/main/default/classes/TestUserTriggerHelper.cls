@isTest
private class TestUserTriggerHelper {
    private static final String KCS_CANDIDATE_ROLE = 'KCS Candidate';
    private static final String KCS_CONTRIBUTOR_ROLE = 'KCS Contributor';
    private static final String KCS_PUBLISHER_ROLE = 'KCS Publisher';
    private static final String KCS_COACH_ROLE = 'KCS Coach';
    private static final String KCS_KNOWLEDGE_DOMAIN_EXPERT_ROLE = 'Knowledge Domain Expert';

    @isTest
    static void verifyDeactivationDate () {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();

        User checkUser = [SELECT Id, DeactivationDate__c FROM User WHERE Id = :sysAdmin.Id];
        System.assertEquals(null, checkUser.DeactivationDate__c);

        sysAdmin.IsActive = false;
        update sysAdmin;

        checkUser = [SELECT Id, DeactivationDate__c FROM User WHERE Id = :sysAdmin.Id];
        System.assertEquals(Date.today(), checkUser.DeactivationDate__c);

        sysAdmin.IsActive = true;
        update sysAdmin;

        checkUser = [SELECT Id, DeactivationDate__c FROM User WHERE Id = :sysAdmin.Id];
        System.assertEquals(null, checkUser.DeactivationDate__c);
    }

	/* Test Data:
	User IsActive ManagerId
	U1   -        -
	M1   +        -
	Result: reassign cases from U1 to M1
	*/
	@isTest static void test_AutomatedCaseAssignment_1NestingManagerIsActive(){
		User m1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager1',
					User.Username => 'manager1!user@gmail.com',
					User.Email => 'manager1_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => null
				}
			)
			.create()
			.getRecord();

		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m1.Id,
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES
				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			insert createCase();
		}

		test.startTest();
			u1.IsActive = false;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 0, 'User U1 shouldn\'t have assigned cases');
		System.assertEquals(countCasesByOwner(u1.ManagerId), 1, 'User Manager M1 should have assigned cases');
	}

	/* Test Data:
	User IsActive ManagerId
	U1   -        -
	Result: don't reassign cases from U1
	*/
	@isTest static void test_AutomatedCaseAssignment_1NestingManagerIsEmpty(){
		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES,
					User.IsActive => true
				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			insert createCase();
		}

		test.startTest();
			u1.IsActive = false;
			u1.ManagerId = null;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 1, 'User U1 should have assigned case, because he hasn\'t active maager');
	}

	/* Test Data:
	User IsActive ManagerId
	U1   -        M1
	M1   -        M2
	M2   -        -
	Result: don't reassign cases from U1
	*/
	@isTest static void test_AutomatedCaseAssignment_2NestingManagerIsEmpty(){
		User m2 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager2!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => null,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User m1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager1',
					User.Username => 'manager1!user@gmail.com',
					User.Email => 'manager1_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m2.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m1.Id,
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES,
					User.IsActive => true
				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			insert createCase();
		}

		test.startTest();
			u1.IsActive = false;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 1, 'User U1 should have assigned case, because he hasn\'t nearest active managers');
		System.assertEquals(countCasesByOwner(m1.Id), 0, 'User Manager M1 shouldn\'t have assigned cases, because he is inactive');
		System.assertEquals(countCasesByOwner(m2.Id), 0, 'User Manager M2 shouldn\'t have assigned cases, because he is inactive');
	}

	/* Test Data:
	User IsActive ManagerId
	U1   -        M1
	M1   -        M2
	M2   +        -
	Result: reassign cases from U1 to M2
	*/
	@isTest static void test_AutomatedCaseAssignment_2NestingManagerIsActive(){
		User m2 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager2!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => null
				}
			)
			.create()
			.getRecord();

		User m1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager1',
					User.Username => 'manager1!user@gmail.com',
					User.Email => 'manager1_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m2.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m1.Id,
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES,
					User.IsActive => true

				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			insert createCase();
		}

		test.startTest();
			u1.IsActive = false;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 0, 'User U1 shouldn\'t have assigned case, because he hasn\'t nearest active managers');
		System.assertEquals(countCasesByOwner(m1.Id), 0, 'User Manager M1 shouldn\'t have assigned cases, because he has active manager');
		System.assertEquals(countCasesByOwner(m2.Id), 1, 'User Manager M2 shouldn have assigned case, because he is active');
	}

	/* Test Data:
	User IsActive ManagerId
	U1   -        M1
	M1   -        M2
	M2   -        M3
	M3   +        -
	Result: reassign cases from U1 to M3
	*/
	@isTest static void test_AutomatedCaseAssignment_3NestingManagerIsActive(){
		User m3 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager2!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => null
				}
			)
			.create()
			.getRecord();

		User m2 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager21!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m3.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User m1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager1',
					User.Username => 'manager1!user@gmail.com',
					User.Email => 'manager1_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m2.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m1.Id,
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES,
					User.IsActive => true
				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			List<Case> cases = new List<Case>();
			for(Integer i=0; i<10; i++){
				cases.add(createCase());
			}
			insert cases;
		}

		test.startTest();
			u1.IsActive = false;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 0, 'User U1 shouldn\'t have assigned case, because he hasn\'t nearest active managers');
		System.assertEquals(countCasesByOwner(m1.Id), 0, 'User Manager M1 shouldn\'t have assigned cases, because he is inactive');
		System.assertEquals(countCasesByOwner(m2.Id), 0, 'User Manager M2 shouldn\'t have assigned cases, because he is inactive');
		System.assertEquals(countCasesByOwner(m3.Id), 10, 'User Manager M3 shouldn have assigned cases, because he is active');
	}

	/* Test Data:
	User IsActive ManagerId
	U1   -        M1
	M1   -        M2
	M2   -        M3
	M3   -        -
	Result: don't reassign cases from U1
	*/
	@isTest static void test_AutomatedCaseAssignment_3NestingManagerIsEmpty(){
		User m3 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager2!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => null,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User m2 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager2',
					User.Username => 'manager23!user@gmail.com',
					User.Email => 'manager2_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m3.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User m1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager1',
					User.Username => 'manager1!user@gmail.com',
					User.Email => 'manager1_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m2.Id,
					User.IsActive => false
				}
			)
			.create()
			.getRecord();

		User u1 = (User) new SObjectBuilder (User.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					User.LastName => 'Testmanager',
					User.Username => 'manager!user@gmail.com',
					User.Email => 'manager_user@gmail.com',
					User.Alias => 'Test',
					User.TimeZoneSidKey => 'America/Los_Angeles',
					User.LocaleSidKey => 'en_US',
					User.EmailEncodingKey => 'UTF-8',
					User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
					User.LanguageLocaleKey => 'en_US',
					User.Hierarchy_Role__c => 'Sales Rep',
					User.ManagerId => m1.Id,
					User.Employee_Location__c => UserHelper.EMPLOYEE_LOCATION_MANILA_PHILIPPINES,
					User.IsActive => true
				}
			)
			.create()
			.getRecord();

		system.runAs(u1){
			List<Case> cases = new List<Case>();
			for(Integer i=0; i<10; i++){
				cases.add(createCase());
			}
			insert cases;
		}

		test.startTest();
			u1.IsActive = false;
			update u1;
		test.stopTest();

		System.assertEquals(countCasesByOwner(u1.Id), 10,'User U1 shouldn have assigned cases, because he hasn\'t nearest active managers');
		System.assertEquals(countCasesByOwner(m1.Id), 0, 'User Manager M1 shouldn\'t have assigned cases, because he is inactive');
		System.assertEquals(countCasesByOwner(m2.Id), 0, 'User Manager M2 shouldn\'t have assigned cases, because he is inactive');
		System.assertEquals(countCasesByOwner(m3.Id), 0, 'User Manager M3 shouldn\'t have assigned cases, because he is inactive');
	}

	static Integer countCasesByOwner(Id ownerId){
		return new List<Case>(
		[
			SELECT Id
			FROM Case
			WHERE OwnerId = :ownerId
		]).size();
	}

	static Case createCase(){
		Case c = (Case) new SObjectBuilder(Case.SObjectType)
			.setFields(
				new Map<SObjectField, Object>{
					Case.Status => 'New',
					Case.RecordTypeId => CaseHelper.RT_ID_SUPPORT_T1
				}
			)
			.build()
			.getRecord();
		return c;
	}

	static Id getProfileId(String profileName){
		Profile p =
		[
			SELECT Id, Name
			FROM Profile
			WHERE Name = :profileName
			LIMIT 1
		];
		return (p != null ? p.Id : null);
	}

	@isTest
	private static void verifyThatUserHelperReturnCorrectOffsetForUserTZ() {
		User testUser = (User) new SObjectBuilder(User.SObjectType)
			.create()
			.getRecord();

		System.runAs(testUser) {
			Test.startTest();
				Integer resultOffset = UserHelper.getUserTZOffset();
			Test.stopTest();

			Integer expectedResult = UserInfo.getTimezone().getOffset(System.now());

			System.assertEquals(expectedResult, resultOffset, 'Offset for TZ calculated incorrectly');
		}
	}

    @isTest
    private static void userKCSCandidateHasCorrectGroupAndPermissionAfterUserInsert() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_CANDIDATE_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_CANDIDATE_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0]== 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSContributorHasCorrectGroupAndPermissionAfterUserInsert() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_CONTRIBUTOR_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_CONTRIBUTOR_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSPublisherHasCorrectGroupAndPermissionAfterUserInsert() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_PUBLISHER_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_PUBLISHER_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSCoachHasCorrectGroupAndPermissionAfterUserInsert() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_COACH_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_COACH_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSExpertHasCorrectGroupAndPermissionAfterUserInsert() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_KNOWLEDGE_DOMAIN_EXPERT_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_KNOWLEDGE_DOMAIN_EXPERT_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSCandidateHasNoGroupAndPermissionWhenFTOff() {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, false)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User nonKCSUser = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .setField(User.KCS_Role__c, KCS_CANDIDATE_ROLE)
                .create()
                .getRecord();
            Test.stopTest();

            List<Integer> countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_CANDIDATE_ROLE, nonKCSUser.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 0, 'User should not be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 0, 'Should not be KCS permission set on this user');
        }
    }

    @isTest
    private static void userKCSHasCorrectGroupAndPermissionAfterRoleUpdate () {
        User sysAdmin = (User) new SObjectBuilder(User.SObjectType).create().getRecord();
        new SObjectBuilder(KCSSettings__c.SObjectType)
            .setField(KCSSettings__c.EnableTriggerDefineGroupMembers__c, true)
            .create();

        System.runAs(sysAdmin) {
            Test.startTest();
            User userKCS = (User) new SObjectBuilder(User.SObjectType)
                .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                .create()
                .getRecord();

            List<Integer> countGroupMembersAndPermissionSets = new List<Integer>();
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser('', userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 0, 'User should not be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 0, 'Should not be KCS permission set on this user');

            userKCS.KCS_Role__c = KCS_CANDIDATE_ROLE;
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_CANDIDATE_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');

            userKCS.KCS_Role__c = KCS_CONTRIBUTOR_ROLE;
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_CONTRIBUTOR_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');

            userKCS.KCS_Role__c = KCS_PUBLISHER_ROLE;
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_PUBLISHER_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');

            userKCS.KCS_Role__c = KCS_COACH_ROLE;
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_COACH_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');

            userKCS.KCS_Role__c = KCS_KNOWLEDGE_DOMAIN_EXPERT_ROLE;
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser(KCS_KNOWLEDGE_DOMAIN_EXPERT_ROLE, userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 1, 'KCS User should be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 1, 'Should be KCS permission set on this user');

            userKCS.KCS_Role__c = '';
            update userKCS;
            countGroupMembersAndPermissionSets =
                getCountGroupMembersAndPermissionSetsForKCSUser('', userKCS.Id);
            System.assert(countGroupMembersAndPermissionSets[0] == 0, 'User should not be in KCS group');
            System.assert(countGroupMembersAndPermissionSets[1] == 0, 'Should not be KCS permission set on this user');
            Test.stopTest();
        }
    }

    private static List<Integer> getCountGroupMembersAndPermissionSetsForKCSUser(String roleKCS, Id userKCSId) {
        List<Integer> countGroupMembersAndPermissionSets = new List<Integer>();
        String groupName = GroupHelper.getGroupNameBasedOnUserKCSRole(roleKCS);
        List<GroupMember> gmListForUser = selectGroupMembersBasedOnUserIdAndGroupName(userKCSId, groupName);
        countGroupMembersAndPermissionSets.add(gmListForUser.size());
        List<PermissionSetAssignment> listPSAForUser = selectPSABasedOnAssigneeAndGroupName(userKCSId, groupName);
        countGroupMembersAndPermissionSets.add(listPSAForUser.size());
        return countGroupMembersAndPermissionSets;
    }

    private static List<GroupMember> selectGroupMembersBasedOnUserIdAndGroupName(Id userId, String groupName) {
        Map<String, Id> mapGroupNameAndId = GroupHelper.defineGroupIdsBasedOnName(new Set<String>{groupName});
        List<Object> bindings = new List<Object>();
        bindings.add(new List<Id>{userId});
        bindings.add(new List<Id>{mapGroupNameAndId.get(groupName)});
        List<GroupMember> listGM = new GroupMemberSelector()
            .selectExistGroupMembersBasedOnUserIdAndGroupId(bindings)
            .executeQuery();
        return listGM;
    }

    private static List<PermissionSetAssignment> selectPSABasedOnAssigneeAndGroupName(Id assigneeId, String groupName) {
        Map<String, Id> mapPermissionSetIdAndGroupName = GroupHelper.definePermissionSetIdBasedOnGroupName();
        Id permissionSetId = mapPermissionSetIdAndGroupName.get(groupName);
        List<Object> bindings = new List<Object>();
        bindings.add(new List<Id>{assigneeId});
        bindings.add(new List<String>{permissionSetId});
        List<PermissionSetAssignment> listPSA = new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssigneeAndPermissionSet(bindings)
            .executeQuery();
        return listPSA;
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest static void validateEURestricted_Validation(){
        Map<String, String> profileNameIdMap = new Map<String,String>();
        List<String> prfoileName = new List<String>{'System Administrator','ICSM Lightning - EU Restricted'};
            List<Profile> userProfileMap = [Select id,Name from Profile where Name in : prfoileName];
        for(Profile pf: userProfileMap) {
            profileNameIdMap.put(pf.Name,pf.Id);
        }
        User u1 = (User) new SObjectBuilder (User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.LastName => 'EU Restricted',
                        User.Username => 'user1EURestricted@gmail.com',
                        User.Email => 'user1EURestricted@gmail.com',
                        User.Alias => 'Test',
                        User.TimeZoneSidKey => 'America/Los_Angeles',
                        User.LocaleSidKey => 'en_US',
                        User.EmailEncodingKey => 'UTF-8',
                        User.Country__c => 'United States',
                        User.ProfileId => profileNameIdMap.get('ICSM Lightning - EU Restricted'),
                        User.LanguageLocaleKey => 'en_US',
                        User.Hierarchy_Role__c => 'Sales Rep',
                        User.ManagerId => null
                        }
            )
            .create()
            .getRecord();
        
        test.startTest();
        u1.Country__c = 'India';
        update u1;
        test.stopTest();
    }

	private static void createTestData_RelationshipSurvey(Id csm){
 	
        Segment_Master__c testSM = new Segment_Master__c();
        testSM.Name = 'Small Business';
       	testSM.Min__c = 20;
        testSM.Max__c = 100;
        testSM.Country__c = 'United States';
        testSM.Start_Date__c = Date.today();
        insert testSM;
          
        Account testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RC_Account_Status__c = 'Paid';
		testAccount.RC_Service_name__c = 'office123';
        testAccount.Segment_Name__c = testSM.Id;
		testAccount.RC_Activation_Date__c = null;
        testAccount.RC_Upgrade_Date__c = Date.today().addMonths(-10);
		testAccount.Partner_ID__c = '9852';
        testAccount.wave__c = 'Wave 1';
		testAccount.CSM__c = csm;
        
		insert testAccount;
    }

	@isTest static void updateCSMUserNameChangesInScopeProfile(){
        Account_CSM_Profiles__c accProfile = new Account_CSM_Profiles__c();
        accProfile.Profile_Name__c = 'Signature - CSM Lightning';
        accProfile.Name = 'Signature - CSM Lightning';
        insert accProfile;

		List<Profile> userProfileMap = [Select id,Name from Profile where Name = :accProfile.Profile_Name__c];
		User u1 = new User();
		if (userProfileMap.size() > 0) {
			u1 = (User) new SObjectBuilder (User.SObjectType)
						.setFields(
							new Map<SObjectField, Object>{
								User.LastName => 'CSM Test',
									User.Username => 'csmuser1@gmail.com',
									User.Email => 'user1@gmail.com',
									User.Alias => 'Test',
									User.TimeZoneSidKey => 'America/Los_Angeles',
									User.LocaleSidKey => 'en_US',
									User.EmailEncodingKey => 'UTF-8',
									User.Country__c => 'United States',
									User.ProfileId => userProfileMap[0].Id,
									User.LanguageLocaleKey => 'en_US',
									User.Hierarchy_Role__c => 'Sales Rep',
									User.ManagerId => null
									}
						)
						.create()
						.getRecord();
		}
		createTestData_RelationshipSurvey(u1.Id);
	
        test.startTest();
        try{
            u1.FirstName = 'Test';
			update u1;
			List<Account> acc1 = [SELECT Id, CSM__c, CSM__r.Name, CSM_Name__c from Account];
			for (Account acc : acc1) {
				if (u1.Id == acc.CSM__c) {
					System.assert(acc.CSM__r.Name == acc.CSM_Name__c, 'User Name changes should be reflected in the Account CSM Name');
				}
			}
        } catch (Exception ex) {
            
        }
        test.stopTest();
    }

	@isTest static void updateCSMUserNameChangesOutOfScopeProfile(){
		Account_CSM_Profiles__c accProfile = new Account_CSM_Profiles__c();
        accProfile.Profile_Name__c = 'Signature - CSM Lightning';
        accProfile.Name = 'Signature - CSM Lightning';
        insert accProfile;
		User u1 = (User) new SObjectBuilder (User.SObjectType)
						.setFields(
							new Map<SObjectField, Object>{
								User.LastName => 'CSM Test 1',
									User.Username => 'csmuser2@gmail.com',
									User.Email => 'user2@gmail.com',
									User.Alias => 'Test',
									User.TimeZoneSidKey => 'America/Los_Angeles',
									User.LocaleSidKey => 'en_US',
									User.EmailEncodingKey => 'UTF-8',
									User.Country__c => 'United States',
									User.ProfileId => [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
									User.LanguageLocaleKey => 'en_US',
									User.Hierarchy_Role__c => 'Sales Rep',
									User.ManagerId => null
									}
						)
						.create()
						.getRecord();
		Account testAccount = new Account();
		testAccount.Name = 'Test123';
		testAccount.RC_Account_Status__c = 'Canceled';
		testAccount.CSM__c = u1.Id;
        
		insert testAccount;
	
        test.startTest();
        try{
            u1.FirstName = 'Test';
			update u1;
			List<Account> acc1 = [SELECT Id, CSM__c, CSM__r.Name, CSM_Name__c from Account];
			for (Account acc : acc1) {
				if (u1.Id == acc.CSM__c) {
					System.assert(acc.CSM__r.Name != acc.CSM_Name__c, 'User Name changes should not be reflected in the Account CSM Name for out of scope profiles');
				}
			}
        } catch (Exception ex) {
            
        }
        test.stopTest();
    }
}
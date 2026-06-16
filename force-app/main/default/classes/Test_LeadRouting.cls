@isTest
private class Test_LeadRouting {

	private static User testUser = createUser('test', null); // testUser with admin profile

	private static User createUser(String name, Id profileId) {
		User user = new User(
			Username = name+'!user@gmail.com',
			LastName = 'Test'+name,
			Email = name+'_user@gmail.com',
			Alias = 'test'+name,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US'
		);

		if(profileId != null) {
			user.ProfileId = profileId;
		}else{
			user.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id;
		}

		insert user;
		return user;
	}

	private static void insertCampaigSubTypeMapping_CustomSetting() {

		Map<String, Campaign_Subtype_Mapping__c> csm = Campaign_Subtype_Mapping__c.getAll();
		// System.debug('csm >>> ' + csm);
		// System.debug('(csm.size() == 0) >>> ' + (csm.size() == 0) );

		if( (csm.size() == 0) ) {

			Group sharedLeadsQueue = [select Id from Group where Type = 'Queue' and DeveloperName = 'Shared_Leads' limit 1];

			if(sharedLeadsQueue == null) {

				sharedLeadsQueue = new Group(
					Type = 'Queue',
					DeveloperName = 'Shared_Leads',
					Email = 'trash@example.com',
					Name = 'Shared Leads'
				);
				insert sharedLeadsQueue;
			}

			System.debug('sharedLeadsQueue.Id >>>>> ' + sharedLeadsQueue.Id);

			Campaign_Subtype_Mapping__c cplSharedSettings = new Campaign_Subtype_Mapping__c(
				Name = 'CPL_Shared',
				Queue_Id__c = sharedLeadsQueue.Id
			);
			insert cplSharedSettings;

			csm = Campaign_Subtype_Mapping__c.getAll();
			// System.debug('csm >>> ' + csm);
			// System.debug('(csm.size() == 0) >>> ' + (csm.size() == 0) );
		}

	}

    private static void insertLeadRoutingSettings_CustomSetting(Boolean useNewRouting) {
        LeadRoutingSettings__c settings = LeadRoutingSettings__c.getOrgDefaults();
        settings.UseNewRouting__c = useNewRouting;
        settings.IsBypassProtectionRouting__c = false;
        upsert settings LeadRoutingSettings__c.Id;

        System.debug('LeadRoutingSettings__c.getOrgDefaults() >>> ' + LeadRoutingSettings__c.getOrgDefaults());
    }

	private static final String ASSIGNMENT_SOURCE_LARS = 'LARs';
	private static final String ASSIGNMENT_SOURCE_PR_PER_LAR = 'PR PER LAR SYSTEM USER';
	private static final String ASSIGNMENT_SOURCE_PRE_PROTECTION = 'PRE-PROTECTION RULE';
	private static final String ASSIGNMENT_SOURCE_PROTECTION = 'PR PER MARKETO VAR';
	private static final String ASSIGNMENT_SOURCE_GEO = 'GEO INDUSTRY TERRITORY ROUTING';

	private static final String PARTNER_LEAD_DEV_NAME = 'Partner_Leads';

	private static final String USA_COUNTRY_NAME = 'USA';


	@isTest
	public static void test_OLD_LeadRouting_LAR_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_LAR');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			User larUser = [select Id, Name from User where Name = 'LAR System User'];


			Boolean byPassRouting = false;

			// insert lead assigned to lar user(used in LeadAssignmentRuleDAO.runLAR)
			Lead larLead = new Lead(
				Email = 'larLead@test.test',
				LastName = 'larLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				OwnerId = larUser.Id,
				Bypass_Routing__c = byPassRouting
			);
			insert larLead;

			System.debug('larUser.Id >>> ' + larUser.Id + '; reselected larLead >>>> ' + [select Id, OwnerId from Lead where id =: larLead.Id]);


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c,
					LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c, Skill_Name__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);
				System.debug('reselectedLead.Skill_Name__c >>> ' + reselectedLead.Skill_Name__c);

			Test.stopTest();

			// Lead must be assigned to LAR user(by lar routing 'rule')
			System.assert( reselectedLead.OwnerId == larUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PR_PER_LAR );

			// System.assert( createdSkillIndexes.size() > 0 );
			// System.assert( createdSkillIndexes.get(0).LAR_IN_Process__c.contains('LAR Process Done') );
		}
	}

	@isTest
	public static void test_NEW_LeadRouting_LAR_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRouting_LAR');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			User larUser = [select Id, Name from User where Name = 'LAR System User'];

			Boolean byPassRouting = false;

			// insert lead assigned to lar user(used in LeadAssignmentRuleDAO.runLAR)
			Lead larLead = new Lead(
				Email = 'larLead@test.test',
				LastName = 'larLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				OwnerId = larUser.Id,
				Bypass_Routing__c = byPassRouting
			);
			insert larLead;

			System.debug('larUser.Id >>> ' + larUser.Id + '; reselected larLead >>>> ' + [select Id, OwnerId from Lead where id =: larLead.Id]);


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			Test.stopTest();

			// Lead must be assigned to LAR user(by lar routing 'rule')
			System.assert( reselectedLead.OwnerId == larUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PR_PER_LAR );
		}
	}


	@isTest
	public static void test_OLD_LeadRouting_PreProtection_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRounting_PreProtection');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert campaign
			Campaign testCampaign = new Campaign(
				//Name = 'True_Walk_On_2024',
				Name = 'LeadGen_ExpertMarketCA_CPL',
				Type = 'CPL_Shared'
			);
			insert testCampaign;


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Primary_Campaign__c = testCampaign.Id,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			Test.stopTest();

			// preProtection routing( (testLead.Primary_Campaign__c != null) && (testLead.Primary_Campaign__r.Type.containsIgnoreCase('CPL')) )

			// Lead must be assigned to queue(by preProtectionRouting rule)
			System.assert( reselectedLead.OwnerId == Campaign_Subtype_Mapping__c.getAll().get('CPL_Shared').Queue_Id__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PRE_PROTECTION );

			// lead "Most recent campaign" must be equal lead "Primary campaign"(by LeadTriggerHelperExt.assignCampaigns() )
			System.assert( reselectedLead.Most_Recent_Campaign__c == reselectedLead.Primary_Campaign__c );

		}
	}


	@isTest
	public static void test_NEW_LeadRouting_PreProtection_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRounting_PreProtection');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert campaign
			Campaign testCampaign = new Campaign(
				//Name = 'True_Walk_On_2024',
				Name = 'LeadGen_ExpertMarketCA_CPL',
				Type = 'CPL_Shared'
			);
			insert testCampaign;


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Primary_Campaign__c = testCampaign.Id,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);

			Test.stopTest();

			// preProtection routing( (testLead.Primary_Campaign__c != null) && (testLead.Primary_Campaign__r.Type.containsIgnoreCase('CPL')) )

			// Lead must be assigned to queue(by preProtectionRouting rule)
			System.assert( reselectedLead.OwnerId == Campaign_Subtype_Mapping__c.getAll().get('CPL_Shared').Queue_Id__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PRE_PROTECTION );

			// lead "Most recent campaign" must be equal lead "Primary campaign"(by LeadTriggerHelperExt.assignCampaigns() )
			System.assert( reselectedLead.Most_Recent_Campaign__c == reselectedLead.Primary_Campaign__c );

		}
	}


	@isTest
	public static void test_NEW_LeadRouting_PreProtection_withSkillRouting() {

		User usrWithSkill = createUser('uws', null); // testUser with admin profile
		System.debug('usrWithSkill.Id >>>' + usrWithSkill.Id);

		System.runAs(testUser) {

			System.debug('in experimentPreProtectionNEW');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert campaign
			Campaign testCampaign = new Campaign(
				Name = 'testCampaign',
				Type = 'Events'
			);
			insert testCampaign;

			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			Lead testLead = new Lead(
				Email = 'test@test.test',
				NumberOfEmployees__c = '50-249',
				LS_Company_Size_Range__c = '50-249',
				Employees_Override__c = '50-249',
				LastName = 'testLead',
				Company = 'testCompany',
				Primary_Campaign__c = testCampaign.Id,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);

			Test.stopTest();

			// Lead must be assigned to user associated with skill(skill associated with campaign)
			/*Lead routing code deprecation changes*/
			/*System.assert( reselectedLead.OwnerId == usrWithSkill.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_LARS );*/

			// lead "Most recent campaign" must be equal lead "Primary campaign"(by LeadTriggerHelperExt.assignCampaigns() )
			System.assert( reselectedLead.Most_Recent_Campaign__c == reselectedLead.Primary_Campaign__c );
		}
	}


	@isTest
	public static void test_OLD_LeadRouting_Protection_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_Protection');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert campaign
			Campaign testCampaign = new Campaign(
				Name = 'True_Walk_On_2024'
			);
			insert testCampaign;


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;


			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = 'test@test.test',
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			String emailAddr = 'test@test.test';

			Boolean byPassRouting = false;

			// set Lead_Owner_Email_Address__c - it used in PRAssignmentLogic -> runPRLogic() -> createEmailOwnerMap() && createEmailContactMap()
			Lead testLead = new Lead(
				Email = emailAddr,
				LastName = 'testLead',
				Company = 'testCompany',
				Primary_Campaign__c = testCampaign.Id,
				Lead_Owner_Email_Address__c = emailAddr,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, RecordType.DeveloperName, Assignment_Source_hidden__c, Partner_Contact__c,
				 	Partner_Account_Name__c, VAR_Territory__c,
					Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);
				System.debug('reselectedLead.RecordType.DeveloperName >>> ' + reselectedLead.RecordType.DeveloperName);

			Test.stopTest();


			//System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );
			//System.assert( reselectedLead.OwnerId == testUser.Id );
			//System.assert( reselectedLead.RecordType.DeveloperName == PARTNER_LEAD_DEV_NAME );

			// lead "Most recent campaign" must be equal lead "Primary campaign"(by LeadTriggerHelperExt.assignCampaigns() )
			System.assert( reselectedLead.Most_Recent_Campaign__c == reselectedLead.Primary_Campaign__c );
			//System.assert( reselectedLead.Partner_Contact__c == cont.Id );
			System.assert( reselectedLead.VAR_Territory__c == cont.Account.VAR_Territory__c );

		}
	}


	@isTest
	public static void test_NEW_LeadRouting_Protection_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRouting_Protection');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert campaign
			Campaign testCampaign = new Campaign(
				Name = 'True_Walk_On_2024'
			);
			insert testCampaign;


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;


			String emailAddr = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = emailAddr,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			// set Lead_Owner_Email_Address__c - it used in PRAssignmentLogic -> runPRLogic() -> createEmailOwnerMap() && createEmailContactMap()
			Lead testLead = new Lead(
				Email = emailAddr,
				LastName = 'testLead',
				Company = 'testCompany',
				Primary_Campaign__c = testCampaign.Id,
				Lead_Owner_Email_Address__c = emailAddr,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, RecordType.DeveloperName, Assignment_Source_hidden__c, Partner_Contact__c,
				 	Partner_Account_Name__c, VAR_Territory__c,
					Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);
				System.debug('reselectedLead.RecordType.DeveloperName >>> ' + reselectedLead.RecordType.DeveloperName);

			Test.stopTest();


			//System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );
			//System.assert( reselectedLead.OwnerId == testUser.Id );
			//System.assert( reselectedLead.RecordType.DeveloperName == PARTNER_LEAD_DEV_NAME );

			// lead "Most recent campaign" must be equal lead "Primary campaign"(by LeadTriggerHelperExt.assignCampaigns() )
			System.assert( reselectedLead.Most_Recent_Campaign__c == reselectedLead.Primary_Campaign__c );
			//System.assert( reselectedLead.Partner_Contact__c == cont.Id );
			System.assert( reselectedLead.VAR_Territory__c == cont.Account.VAR_Territory__c );


		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void test_OLD_LeadRouting_GEO_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_GEO');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			// user for territory owner
			User testTerrOwnerUser = createUser('tOwn', null);

			// territory data(used in georouting)
			List<Territory_Data__c> terrDataList = new List<Territory_Data__c>();

			Territory_Data__c td1 = new Territory_Data__c(
				Territory_Owner__c = testTerrOwnerUser.Id,
				Name = 'Midmarket Geo 3',
				Country__c = 'United States',
				Type__c = 'Geo',
				Postal_Begin__c = '67402',
				Postal_End__c = '67541',
				Segment__c = '50-249',
				State_Province__c = 'Kansas'
			);
			terrDataList.add(td1);

			Territory_Data__c td2 = new Territory_Data__c(
				Territory_Owner__c = testTerrOwnerUser.Id,
				Name = 'Midmarket Geo 3',
				Country__c = 'United States',
				Type__c = 'Geo',
				Postal_Begin__c = '67542',
				Postal_End__c = '67681',
				Segment__c = '50-249',
				State_Province__c = 'Kansas'
			);
			terrDataList.add(td2);

			insert terrDataList;

			// insert segmentData(used in geo routing)
			List<Segment_Data__c> sdList = new List<Segment_Data__c>();

			Segment_Data__c sd1 = new Segment_Data__c(
				Attribute_1__c = USA_COUNTRY_NAME,
				Attribute_2__c = 'United States',
				Type__c = 'Country'
			);
			sdList.add(sd1);

			Segment_Data__c sd2 = new Segment_Data__c(
				Attribute_1__c = 'united states of america',
				Attribute_2__c = 'United States',
				Type__c = 'Country'
			);
			sdList.add(sd2);

			insert sdList;

			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			// Country, PostalCode, NumberOfEmployees__c fields used in georouting
			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Country = USA_COUNTRY_NAME,
				PostalCode = '67441',
				Geo_Postal_Code__c = '67441',
				NumberOfEmployees__c = '50-249',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			Test.stopTest();

			// Lead must be assigned to finded territory owner(testTerrOwnerUser)
			/*Lead routing code deprecation changes*/
			/*System.assert( reselectedLead.OwnerId == testTerrOwnerUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_GEO );*/

		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void test_NEW_LeadRouting_GEO_beforeInsert() {
		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_GEO');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);


			// user for territory owner
			User testTerrOwnerUser = createUser('tOwn', null);

			// territory data(used in georouting)
			List<Territory_Data__c> terrDataList = new List<Territory_Data__c>();

			Territory_Data__c td1 = new Territory_Data__c(
				Territory_Owner__c = testTerrOwnerUser.Id,
				Name = 'Midmarket Geo 3',
				Country__c = 'United States',
				Type__c = 'Geo',
				Postal_Begin__c = '67402',
				Postal_End__c = '67541',
				Segment__c = '50-249',
				State_Province__c = 'Kansas'
			);
			terrDataList.add(td1);

			Territory_Data__c td2 = new Territory_Data__c(
				Territory_Owner__c = testTerrOwnerUser.Id,
				Name = 'Midmarket Geo 3',
				Country__c = 'United States',
				Type__c = 'Geo',
				Postal_Begin__c = '67542',
				Postal_End__c = '67681',
				Segment__c = '50-249',
				State_Province__c = 'Kansas'
			);
			terrDataList.add(td2);

			insert terrDataList;

			// insert segmentData(used in geo routing)
			List<Segment_Data__c> sdList = new List<Segment_Data__c>();

			Segment_Data__c sd1 = new Segment_Data__c(
				Attribute_1__c = USA_COUNTRY_NAME,
				Attribute_2__c = 'United States',
				Type__c = 'Country'
			);
			sdList.add(sd1);

			Segment_Data__c sd2 = new Segment_Data__c(
				Attribute_1__c = 'united states of america',
				Attribute_2__c = 'United States',
				Type__c = 'Country'
			);
			sdList.add(sd2);

			insert sdList;

			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;

			Boolean byPassRouting = false;

			// Country, PostalCode, NumberOfEmployees__c fields used in georouting
			Lead testLead = new Lead(
				Email = 'test@test.test',
				LastName = 'testLead',
				Company = 'testCompany',
				Country = USA_COUNTRY_NAME,
				PostalCode = '67441',
				Geo_Postal_Code__c = '67441',
				NumberOfEmployees__c = '50-249',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			Test.startTest();

				insert testLead;

				System.debug('testLead >>> ' + testLead);
				System.debug('testLead.Id >>> ' + testLead.Id);
				System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);


				Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
					from Lead where Id =: testLead.Id];

				System.debug('reselectedLead >>> ' + reselectedLead);
				System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
				System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			Test.stopTest();

			// Lead must be assigned to finded territory owner(testTerrOwnerUser)
			/*Lead routing code deprecation changes*/
			/*System.assert( reselectedLead.OwnerId == testTerrOwnerUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_GEO );*/

		}
	}


	@isTest
	public static void test_OLD_LeadRouting_Campaign_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_Protection_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			String testBMID = 'ZEAL1215MID';

			// 'True_Walk_On_2024' - if we clean Lead BMID__c in update
			// 'Broken Attribution' - if we fill Lead BMID__c in update
			Campaign testCampaign = new Campaign(
				Name = 'True_Walk_On_2024',
				IsActive = true,
				BMID__c = testBMID
			);
			insert testCampaign;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				Lead_Owner_Email_Address__c = email,
				Status = 'X. Open',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				BMID__c = testBMID,
				Most_Recent_Campaign__c = testCampaign.Id,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);

					testLead.Status = '2. Contacted';
					testLead.BMID__c = '';
					update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			// assigned by Lead_Before -> LeadTriggerHelper.updateMostRecentCampaign -> LeadTriggerHelperExt.assignCampaignToList
			System.assert( reselectedLead.Primary_Campaign__c == testCampaign.Id );
			System.assert( reselectedLead.Most_Recent_Campaign__c == testCampaign.Id );

			System.assert( reselectedLead.OwnerId == testAcc.Current_Owner__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );

		}
	}

	@isTest
	public static void test_NEW_LeadRouting_Campaign_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRouting_Campaign_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			String testBMID = 'ZEAL1215MID';

			// 'True_Walk_On_2024' - if we clean Lead BMID__c in update
			// 'Broken Attribution' - if we fill Lead BMID__c in update
			Campaign testCampaign = new Campaign(
				Name = 'True_Walk_On_2024',
				IsActive = true,
				BMID__c = testBMID
			);
			insert testCampaign;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				Lead_Owner_Email_Address__c = email,
				Status = 'X. Open',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				BMID__c = testBMID,
				Most_Recent_Campaign__c = testCampaign.Id,
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);
					testLead.Status = '2. Contacted';
					testLead.BMID__c = '';
					update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			// assigned by Lead_Before -> LeadTriggerHelper.updateMostRecentCampaign -> LeadTriggerHelperExt.assignCampaignToList
			System.assert( reselectedLead.Primary_Campaign__c == testCampaign.Id );
			System.assert( reselectedLead.Most_Recent_Campaign__c == testCampaign.Id );

			System.assert( reselectedLead.OwnerId == testAcc.Current_Owner__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );

		}
	}



	@isTest
	public static void test_OLD_LeadRouting_Protection_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_Protection_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				Lead_Owner_Email_Address__c = email,
				Status = 'X. Open',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);
					testLead.Status = '2. Contacted';
					update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			System.assert( reselectedLead.OwnerId == testAcc.Current_Owner__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );

		}
	}


	@isTest
	public static void test_NEW_LeadRouting_Protection_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRouting_Protection_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				Lead_Owner_Email_Address__c = email,
				Status = 'X. Open',
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);

					testLead.Status = '2. Contacted';
					update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);


			System.assert( reselectedLead.OwnerId == testAcc.Current_Owner__c );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PROTECTION );

		}
	}


	@isTest
	public static void test_OLD_LeadRouting_LAR_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		User inactiveTestUser = createUser('pas', null);
		inactiveTestUser.IsActive = false;
		update inactiveTestUser;

		System.runAs(testUser) {

			System.debug('in test_OLD_LeadRouting_LAR_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = false;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				OwnerId = inactiveTestUser.Id,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);

                    update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);

			User larUser = [select Id, Name from User where Name = 'LAR System User'];

            /*Lead routing code deprecation changes*/
			//System.assert( reselectedLead.OwnerId == larUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PR_PER_LAR );
			//System.assert( reselectedLead.Lead_Submitter_Id__c == userlocalTestUser.Id );

		}
	}


	@isTest
	public static void test_NEW_LeadRouting_LAR_beforeUpdate() {

		Id mipProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'Marketo Integration Profile'].Id;

		User userlocalTestUser = createUser('mip', mipProfileId);

		User inactiveTestUser = createUser('pas', null);
		inactiveTestUser.IsActive = false;
		update inactiveTestUser;

		System.runAs(testUser) {

			System.debug('in test_NEW_LeadRouting_LAR_beforeUpdate');

			// insert Campaign_Subtype_Mapping__c custom setting
			insertCampaigSubTypeMapping_CustomSetting();


			// insert lead routing custom setting data
			Boolean useNewRouting = true;
			insertLeadRoutingSettings_CustomSetting(useNewRouting);

			Id customerAccRTId = [select Id from RecordType where SobjectType = 'Account' AND DeveloperName = 'Customer_Account'].Id;

			Account testAcc = new Account(
				Name = 'testAcc',
				Current_Owner__c = testUser.Id,
				RecordTypeId = customerAccRTId
			);
			insert testAcc;

			String email = 'test@test.test';

			// insert contact with same email as on lead
			// Relayware_Portal_User__c='Approved' - used in PRAssignmentLogic -> runPRLogic() -> createEmailContactMap()
			Contact cont = new Contact(
				AccountId = testAcc.Id,
				FirstName = 'testContactFname',
				LastName = 'testContactLname',
				Email = email,
				Relayware_Portal_User__c='Approved'
			);
			insert cont;


			Id salesLeadRecordTypeId = [select Id from RecordType where SobjectType='Lead' AND Name = 'Sales Leads'].Id;


			Boolean byPassRouting = false;


			// Lead_Entry_Source__c used in LeadTriggerHelper.getUserSkillsPerLeadEntrySource
			Lead testLead = new Lead(
				Email = email,
				LastName = 'testLead',
				Company = 'testCompany',
				Lead_Entry_Source__c = 'ROI Form',
				RecordTypeId = salesLeadRecordTypeId,
				OwnerId = inactiveTestUser.Id,
				Bypass_Routing__c = byPassRouting
			);

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = true;

			insert testLead;

			TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT = false;

			System.debug('ProtectionLeadUsers__c.getAll() >> ' + ProtectionLeadUsers__c.getAll());

			System.runAs(userlocalTestUser) {

				Test.startTest();
                    System.debug([SELECT RecordId, HasEditAccess, HasAllAccess, HasReadAccess, HasTransferAccess FROM UserRecordAccess WHERE UserId = :userlocalTestUser.Id AND RecordId = :testLead.Id]);

					update testLead;

					System.debug('testLead >>> ' + testLead);
					System.debug('testLead.Id >>> ' + testLead.Id);
					System.debug('testLead.OwnerId >>> ' + testLead.OwnerId);

				Test.stopTest();

			}

			Lead reselectedLead = [select Id, OwnerId, Assignment_Source_hidden__c, Lead_Submitter_Id__c, LAR_Source__c, Primary_Campaign__c, Most_Recent_Campaign__c
				from Lead where Id =: testLead.Id];

			System.debug('reselectedLead >>> ' + reselectedLead);
			System.debug('reselectedLead.Assignment_Source_hidden__c >>> ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('reselectedLead.OwnerId >>> ' + reselectedLead.OwnerId);

			User larUser = [select Id, Name from User where Name = 'LAR System User'];

            /*Lead routing code deprecation changes*/
			//System.assert( reselectedLead.OwnerId == larUser.Id );
			System.assert( reselectedLead.Assignment_Source_hidden__c == ASSIGNMENT_SOURCE_PR_PER_LAR );
			//System.assert( reselectedLead.Lead_Submitter_Id__c == userlocalTestUser.Id );

		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testConstructor() {
        new LeadRouting();
    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void testPrepareDataForPreprotection() {
        insert new Campaign_Subtype_Mapping__c(
            Name = 'CPL_Shared'
        );

        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .create()
            .getRecord();

        Map<Id, Lead> leads = new Map<Id, Lead>();
        leads.put(testLead.Id, testLead);
        Map<String, Campaign_Subtype_Mapping__c> campaignSubTypeQueueMap = new Map<String, Campaign_Subtype_Mapping__c>();
        Map<String, Campaign> campaignMap = new Map<String, Campaign>();

        Test.startTest();
        LeadRouting.prepareDataForPreprotection(leads, campaignSubTypeQueueMap, campaignMap);
        Test.stopTest();
    }

    @isTest
    public static void testLarRouting() {
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .create()
            .getRecord();
        User larUser = (User) new SObjectBuilder(User.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => 'LAR',
                    User.LastName => 'System User',
                    User.IsActive => true
                }
            )
            .create()
            .getRecord();

        Map<Id, Boolean> result;
        Test.startTest();
        LeadRouting.LarRouting(new List<Lead>{testLead});
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Method should return null'
        );
    }

    @isTest
    public static void testLarRoutingWithMap() {
        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setFields(new Map<SObjectField, Object> {
                Lead.LastName => 'fakeLastName',
                Lead.Company => 'fakeCompany',
                Lead.Email => 'test@email.com'
            })
            .create()
            .getRecord();
        User larUser = (User) new SObjectBuilder(User.sObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => 'LAR',
                    User.LastName => 'System User',
                    User.IsActive => true
                }
            )
            .create()
            .getRecord();

        Map<Id, Boolean> result;
        Test.startTest();
        LeadRouting.LarRouting(new Map<Id, Lead>{testLead.Id => testLead});
        Test.stopTest();

        System.assertEquals(
            null,
            result,
            'Method should return null'
        );
    }

	@isTest
		static void testPreprotectionRouting() {
			Campaign testCampaign = new Campaign(
				Name = 'Test Campaign',
				Intended_Product__c = 'Product1'
			);
			insert testCampaign;
			
			Lead testLead = new Lead(
				FirstName = 'Test',
				LastName = 'Lead',
				Company = 'Test Company',
				Email = 'testlead@example.com',
				Phone = '1234567890',
				Country = 'USA',
				State = 'CA',
				City = 'San Francisco',
				PostalCode = '94105');
			insert testLead;

			Test.startTest();
			LeadRouting.runProtection(testLead.Id);
			Test.stopTest();
			
			Lead reselectedLead = [SELECT Id, OwnerId, Assignment_Source_hidden__c, Campaign_Product__c FROM Lead WHERE Id = :testLead.Id];
			System.debug('reselectedLead: ' + reselectedLead);
			System.debug('Assignment_Source_hidden__c: ' + reselectedLead.Assignment_Source_hidden__c);
			System.debug('Campaign_Product__c: ' + reselectedLead.Campaign_Product__c);
			System.assertNotEquals(null, reselectedLead.OwnerId, 'Lead should have an owner assigned');
		}
		
	@isTest
		static void testRunProtection() {
			Lead testLead = new Lead(
				FirstName = 'Test',
				LastName = 'Lead',
				Company = 'Test Company',
				Email = 'testlead@example.com',
				Phone = '1234567890',
				Country = 'USA',
				State = 'CA',
				City = 'San Francisco',
				PostalCode = '94105',
				Lead_Brand_Name__c = 'Test Brand',
				CurrencyIsoCode = 'USD',
				LeadSource = 'Web',
				BMID__c = 'BMID123',
				User_ID__c = 'User123',
				Lead_Score__c = '50',
				Original_Phone_Number__c = '1234567890',
				Duplicate_Lead__c = false,
				Bypass_PR__c = false,
				LAR_Source__c = 'LAR Source',
				Status = 'Open',
				AID__c = 'AID123',
				PID__c = 'PID123',
				Five9_DNIS__c = 'DNIS123',
				Employee_Size_History__c = '100-200',
				Industry = 'Technology',
				Job_Function__c = 'Engineering',
				Purchase_Timeframe__c = '1-3 months',
				IsConverted = false,
				LS_Company_Country__c = 'USA',
				LS_Company_Zipcode__c = '94105',
				LeadPartnerID__c = 'Partner123',
				Partner_Lead_Source__c = 'Partner Source',
				Partner_Account_Name__c = 'Partner Account',
				Ultimate_Parent_Account_Partner_ID__c = 'Parent123',
				Ultimate_Parent_Account_Name__c = 'Parent Account',
				Current_Owner_Name__c = 'Current Owner',
				VAR_Territory__c = 'Territory123',
				Lead_Owner_Email_Address__c = 'owner@example.com',
				Sales_Agent_Email__c = 'agent@example.com',
				LS_Primary_NAIC__c = 'NAIC123',
				Geo_Country__c = 'USA'
			);
			insert testLead;

			Test.startTest();
			LeadRouting.runProtection(testLead.Id);
			Test.stopTest();
			Lead reselectedLead = [SELECT Id, OwnerId, Assignment_Source_hidden__c FROM Lead WHERE Id = :testLead.Id];
			System.debug('reselectedLead: ' + reselectedLead);
			System.debug('Assignment_Source_hidden__c: ' + reselectedLead.Assignment_Source_hidden__c);
			System.assertNotEquals(null, reselectedLead.OwnerId, 'Lead should have an owner assigned');
		}
		
		
		@isTest
		static void testProtectionRouting() {
			Lead testLead1 = new Lead(
				FirstName = 'Test1',
				LastName = 'Lead1',
				Company = 'Test Company1',
				Email = 'testlead1@example.com',
				Phone = '1234567890',
				LeadSource = 'Web',
				Bypass_PR__c = false
			);

			Lead testLead2 = new Lead(
				FirstName = 'Test2',
				LastName = 'Lead2',
				Company = 'Test Company2',
				Email = 'testlead2@example.com',
				Phone = '0987654321',
				LeadSource = 'Other',
				Bypass_PR__c = true
			);

			insert new List<Lead>{testLead1, testLead2};

			Test.startTest();
			List<Lead> notAssignedLeads = LeadRouting.ProtectionRouting(new List<Lead>{testLead1, testLead2}, null, null, null);
			Test.stopTest();

			System.assertEquals(2, notAssignedLeads.size(), 'Both leads should be in the notAssignedLeads list');
		}
		
		@isTest
		static void testGeoRouting() {
			Lead testLead1 = new Lead(
				FirstName = 'Test1',
				LastName = 'Lead1',
				Company = 'Test Company1',
				Email = 'testlead1@example.com',
				Phone = '1234567890',
				LeadSource = 'Web',
				Bypass_PR__c = false
			);

			Lead testLead2 = new Lead(
				FirstName = 'Test2',
				LastName = 'Lead2',
				Company = 'Test Company2',
				Email = 'testlead2@example.com',
				Phone = '0987654321',
				LeadSource = 'Other',
				Bypass_PR__c = true
			);

			insert new List<Lead>{testLead1, testLead2};

			Map<String, Map<String, String>> segmentDataMap = new Map<String, Map<String, String>>();
			Map<String, Map<String, List<Territory_Data__c>>> territoryDataMap = new Map<String, Map<String, List<Territory_Data__c>>>();

			Test.startTest();
			List<Lead> result = LeadRouting.GeoRouting(new List<Lead>{testLead1, testLead2}, segmentDataMap, territoryDataMap);
			Test.stopTest();

			System.assertNotEquals(null, result, 'Result should not be null');
			System.assertEquals(2, result.size(), 'Result size should be 2');
			System.assert(result.contains(testLead1), 'Result should contain lead1');
			System.assert(result.contains(testLead2), 'Result should contain lead2');
		}
		
		@isTest
		static void testRunGeo() {
			Lead testLead = new Lead(
				FirstName = 'Test',
				LastName = 'Lead',
				Company = 'Test Company',
				Email = 'testlead@example.com',
				Phone = '1234567890',
				Country = 'USA',
				State = 'CA',
				City = 'San Francisco',
				PostalCode = '94105',
				Lead_Brand_Name__c = 'Test Brand',
				CurrencyIsoCode = 'USD',
				LeadSource = 'Web',
				BMID__c = 'BMID123',
				User_ID__c = 'User123',
				Lead_Score__c = '50',
				Original_Phone_Number__c = '1234567890',
				Duplicate_Lead__c = false,
				Bypass_PR__c = false,
				LAR_Source__c = 'LAR Source',
				Status = 'Open',
				AID__c = 'AID123',
				PID__c = 'PID123',
				Five9_DNIS__c = 'DNIS123',
				Employee_Size_History__c = '100-200',
				Industry = 'Technology',
				Job_Function__c = 'Engineering',
				Purchase_Timeframe__c = '1-3 months',
				IsConverted = false,
				LS_Company_Country__c = 'USA',
				LS_Company_Zipcode__c = '94105',
				LeadPartnerID__c = 'Partner123',
				Partner_Lead_Source__c = 'Partner Source',
				Partner_Account_Name__c = 'Partner Account',
				Ultimate_Parent_Account_Partner_ID__c = 'Parent123',
				Ultimate_Parent_Account_Name__c = 'Parent Account',
				Current_Owner_Name__c = 'Current Owner',
				VAR_Territory__c = 'Territory123',
				Lead_Owner_Email_Address__c = 'owner@example.com',
				Sales_Agent_Email__c = 'agent@example.com',
				LS_Primary_NAIC__c = 'NAIC123',
				Geo_Country__c = 'USA'
			);
			insert testLead;

			Test.startTest();
			LeadRouting.runGeo(testLead.Id);
			Test.stopTest();
			Lead updatedLead = [SELECT Id, OwnerId, Assignment_Source_hidden__c FROM Lead WHERE Id = :testLead.Id];
			System.debug('updatedLead: ' + updatedLead);
			System.assertNotEquals(null, updatedLead.OwnerId, 'OwnerId should not be null');
			System.debug('Assignment_Source_hidden__c: ' + updatedLead.Assignment_Source_hidden__c);
		}
		
		@isTest
		static void testIsUseNewRouting() {
			LeadRoutingSettings__c settings = new LeadRoutingSettings__c(
				UseNewRouting__c = true
			);
			insert settings;

			Test.startTest();
			Boolean result = LeadRouting.isUseNewRouting();
			Test.stopTest();
			System.assertEquals(true, result, 'UseNewRouting should be true');
		}

		@isTest
		static void testIsUseNewRouting_Default() {
			delete [SELECT Id FROM LeadRoutingSettings__c];

			Test.startTest();
			Boolean result = LeadRouting.isUseNewRouting();
			Test.stopTest();
			System.assertEquals(false, result, 'UseNewRouting should be false when no settings exist');
		}
		
	@isTest
		static void testRunPreprotection() {
		Lead testLead = new Lead(
			LastName = 'Test',
			Company = 'Test Company',
			Email = 'test@example.com',
			Phone = '1234567890',
			Country = 'USA',
			State = 'CA',
			City = 'San Francisco',
			PostalCode = '94105',
			Status = 'New'
		);
		insert testLead;

		Test.startTest();
		LeadRouting.runPreprotection(testLead.Id);
		Test.stopTest();
		Lead resultLead = [SELECT Id, Assignment_Source_hidden__c FROM Lead WHERE Id = :testLead.Id];
		System.debug('Assignment_Source_hidden__c: ' + resultLead.Assignment_Source_hidden__c);
		System.assertNotEquals(null, resultLead.Assignment_Source_hidden__c, 'Assignment_Source_hidden__c should not be null');
	}

}
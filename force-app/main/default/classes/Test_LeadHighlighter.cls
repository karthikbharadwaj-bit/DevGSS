@isTest
private class Test_LeadHighlighter {

	static Lead createLead() {
		Lead testLead = new Lead(Email = 'fake@email.com',
								LastName = 'test_Doe',
								Company = 'test_Com',
								SIA_Information__c = 'SIA information',
								LeadSource = 'SIA',
								PartnerDeal_Status__c = 'BT Approved',
								Domain_Type__c = 'test domain');
		insert testLead;
		return testLead;
	}

	static Document createDocument(String name) {
		Document doc = new Document(Body = Blob.valueOf('Test body for document'),
									ContentType = 'application/pdf',
									IsPublic = true,
									Name = name,
									FolderId = UserInfo.getUserId());
		insert doc;
		return doc;
	}

	static DomainTypeLeadContact__C createDomainTypeSettings() {
		DomainTypeLeadContact__C domainType = new DomainTypeLeadContact__C(Name = 'test domain',
																			Contact__c = true,
																			Lead__c = true);
		insert domainType;
		return domainType;
	}

	static LeadHighlighter createController(Lead controllerLead) {
		return new LeadHighlighter(new ApexPages.StandardController(controllerLead));
	}

	@isTest
	static void testHighlighterCreation() {
		DomainTypeLeadContact__C testDomainType = createDomainTypeSettings();
		Lead testLead = createLead();
		Document testLeadSourceDoc = createDocument('LeadSourceMap');
		PageReference currentPage = Page.LeadHighlighter;
		currentPage.getParameters().put('id', testLead.Id);
		Test.setCurrentPage(currentPage);
		LeadHighlighter controller = createController(testLead);

		System.assertEquals(String.valueOf(controller.sDomainType),
							String.valueOf('<' + testDomainType.Name + '>'),
							'Partner Deal Status is incorrect.');
	}

	@isTest
	static void testLongDescription() {
		Lead testLead = createLead();
		testLead.SIA_Information__c = 'Test long SIA field description. Test long SIA field description.'
										+ 'Test long SIA field description. Test long SIA field description.'
										+ 'Test long SIA field description. Test long SIA field description.'
										+ 'Test long SIA field description. Test long SIA field description.';
		update testLead;
		Document testFranchiseDoc = createDocument('Frandata Franchise Executive List2');
		PageReference currentPage = Page.LeadHighlighter;
		currentPage.getParameters().put('id', testLead.Id);
		Test.setCurrentPage(currentPage);
		DomainTypeLeadContact__C testDomainType = createDomainTypeSettings();
		LeadHighlighter controller = createController(testLead);

		System.assertEquals(controller.isLongDescription, true,
							'Length of SIA description was detected wrong.');
	}

    @isTest
    private static void testSetEmailString() {
        User us = [
                    SELECT Id
                    FROM User
                    WHERE Profile.Name = 'System Administrator'
                    AND isActive = true
                    LIMIT 1
                    ];
        System.runAs (us) {
            Test.startTest();
                Map<String, String> emailMap = LeadHighlighter.setEmailString('Implied - ONCE', false, 'Canada');
            Test.stopTest();

            System.assertNotEquals(emailMap,
                                    null,
                                    'Email map was not assigned.');
            System.assertNotEquals(emailMap.get('title'),
                                    null,
                                    'Email Title was not assigned.');
            System.assertEquals(emailMap.get('message'),'This person has opted in and you may email this person.',
                            'Email Title was not assigned.');
        }
    }
    @isTest
    private static void testSetEmailStringWrongProfile() {
        User us = (User) new SObjectBuilder (User.SObjectType)
                                        .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                        .setField(User.LastName, 'testLastName')
                                        .setField(User.FirstName, 'testFirstName')
                                        .build()
                                        .getRecord();

        Profile proservProfile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{'CRM Developer'})
            .executeQuery()
            .get(0);
        us.ProfileId = proservProfile.Id;
        insert us;

        Map<String, String> emailMap;
        System.runAs (us) {
            Test.startTest();
            emailMap = LeadHighlighter.setEmailString('Implied - ONCE', false, 'Canada');
            Test.stopTest();
        }

        System.assertEquals(null, emailMap,
                          'Email map should not be assigned for this profile.');
    }

    @isTest
    private static void testSetEmailStringBlankOkToEmail() {
        Map<String, String> emailMap;
        Test.startTest();
        emailMap = LeadHighlighter.setEmailString('', false, 'Canada');
        Test.stopTest();

        System.assertEquals(null, emailMap,
                          'Email map should not be assigned if okToEmail is blank.');
    }

    @isTest
    private static void testSetEmailStringForYesSingle() {
        User us = (User) new SObjectBuilder (User.SObjectType)
                                        .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                        .setField(User.LastName, 'testLastName')
                                        .setField(User.FirstName, 'testFirstName')
                                        .build()
                                        .getRecord();

        Profile profile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{'Sales Rep - Lightning'})
            .executeQuery()
            .get(0);
        us.ProfileId = profile.Id;
        insert us;
        System.runAs (us) {
            Test.startTest();
                Map<String, String> emailMap = LeadHighlighter.setEmailString('Yes-Single', false, 'Canada');
            Test.stopTest();

            System.assertNotEquals(emailMap,
                                    null,
                                    'Email map was not assigned.');
            System.assertNotEquals(emailMap.get('title'),
                                    null,
                                    'Email Title was not assigned.');
            System.assert(emailMap.get('title').startsWithIgnoreCase('EMAIL: '),
                            'Email Title was not assigned.');
            System.assertEquals('This person has opted in and you may email this person.', emailMap.get('message'),
                            'Email message was not assigned correctly.');
        }
    }

    @isTest
    private static void testSetEmailStringForYesDouble() {
        User us = (User) new SObjectBuilder (User.SObjectType)
                                        .setFields(SObjectFactoryFieldDefaults.getDefaults(User.SObjectType))
                                        .setField(User.LastName, 'testLastName')
                                        .setField(User.FirstName, 'testFirstName')
                                        .build()
                                        .getRecord();

        Profile profile = (Profile) new ProfileSelector()
            .selectProfileByName(new List<Object>{'Sales Rep - Lightning'})
            .executeQuery()
            .get(0);
        us.ProfileId = profile.Id;
        insert us;
        System.runAs (us) {
            Test.startTest();
                Map<String, String> emailMap = LeadHighlighter.setEmailString('Yes-Double', false, 'Canada');
            Test.stopTest();

            System.assertNotEquals(emailMap,
                                    null,
                                    'Email map was not assigned.');
            System.assertNotEquals(emailMap.get('title'),
                                    null,
                                    'Email Title was not assigned.');
            System.assert(emailMap.get('title').startsWithIgnoreCase('EMAIL: '),
                            'Email Title was not assigned.');
            System.assertEquals('This person has opted in and you may email this person.', emailMap.get('message'),
                            'Email message was not assigned correctly.');
        }
    }
}
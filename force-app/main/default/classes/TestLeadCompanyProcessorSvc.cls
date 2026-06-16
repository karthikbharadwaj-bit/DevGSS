@isTest
private class TestLeadCompanyProcessorSvc {

    private static final String DUNS_NUMBER = '123456000';
    private static final String DUNS_NUMBER2 = '222222000';
    private static final String DUNS_NUMBER_UNEX2 = 'Unex2';
    private static final String COUNTRY_DOMAIN1 = 'united states|yahoo.com';

    private static Integer lastRandomKey = 1;
    public static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(lastRandomKey++);
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
    }

    private static Lead getLeadById(Id leadId){
        return [SELECT Id, Company_Duns__c, SiteDunsNumber__c, AH_Name__c
            FROM Lead
            WHERE Id =: leadId];
    }

    private static List<Lead> getLeadsById(Set<Id> leadIds){
        return [SELECT Id, Company_Duns__c, SiteDunsNumber__c, AH_Name__c
            FROM Lead
            WHERE Id IN: leadIds];
    }

    private static List<Account_Hierarchy__c> getAllAccountHierarchies(){
        return [SELECT Id, D_U_N_S_Number__c, Name
            FROM Account_Hierarchy__c];
    }

    private static Account_Hierarchy__c getAccountHierarchyByDunsNumber(String dunsNumber, List<Account_Hierarchy__c> accountHierarchies){
        for(Account_Hierarchy__c accountHierarchy : accountHierarchies){
            if(accountHierarchy.D_U_N_S_Number__c == dunsNumber){
                return accountHierarchy;
            }
        }
        return null;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void integrationTestWhenInsertingALeadAccountExistingHierarchyShouldBeAssociatedFindingBySiteDunsNumber(){
        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.D_U_N_S_Number__c => DUNS_NUMBER,
                    Account_Hierarchy__c.Company_Status__c => 'test status'
                }
            )
            .create()
            .getRecord();

        Lead testLead = new Lead();

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany',
                        Lead.SiteDunsNumber__c => DUNS_NUMBER
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        Lead leadAfterProcessing = getLeadById(testLead.Id);
        //System.assertEquals(testAccountHierarchy.Id, leadAfterProcessing.AH_Name__c,
            //'Existing hierarchy should be associated finding by SiteDunsNumber');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void integrationVolumeTestWhenInsertingALeadAccountExistingHierarchyShouldBeAssociatedFindingByCompanyDunsNumber(){

		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.D_U_N_S_Number__c => DUNS_NUMBER,
                    Account_Hierarchy__c.Company_Status__c => 'test status'
                }
            )
            .create()
            .getRecord();

        List<Lead> leadsToInsert = new List<Lead>();

        Test.startTest();

            for(Integer i=0; i<50; i++){
                Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Lead.email => 'fake@email.com',
                            Lead.LastName => 'fakeLastName',
                            Lead.Company => 'fakeCompany',
                            Lead.SiteDunsNumber__c => DUNS_NUMBER
                        }
                    )
                    .build()
                    .getRecord();
                leadsToInsert.add(testLead);
            }
            insert leadsToInsert;
        Test.stopTest();

        Set<Id> insertedLeadIds = new Set<Id>();
        for(Lead leadInserted : leadsToInsert){
            insertedLeadIds.add(leadInserted.Id);
        }
        List<Lead> leadsAfterProcessing = getLeadsById(insertedLeadIds);
        //for(Lead processedLead : leadsAfterProcessing){
            //System.assertEquals(testAccountHierarchy.Id, processedLead.AH_Name__c,
               // 'Existing hierarchy should be associated finding by CompanyDunsNumber');
        //}
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void integrationVolumeTestWhenInsertingALeadAccountExistingHierarchyShouldBeAssociatedFindingByDomainCountryDUWebsite(){

		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Country_Domain__c => COUNTRY_DOMAIN1,
                    Account_Hierarchy__c.Company_Status__c => 'test status'
                }
            )
            .create()
            .getRecord();

        List<Lead> leadsToInsert = new List<Lead>();

        Test.startTest();
            for(Integer i=0; i<100; i++){
                Lead testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                    .setFields(
                        new Map<SObjectField, Object>{
                            Lead.email => 'fake@email.com',
                            Lead.LastName => 'fakeLastName',
                            Lead.Company => 'fakeCompany',
                            Lead.LS_Company_Website__c => 'yahoo.com',
                            Lead.Country => 'United States'
                        }
                    )
                    .build()
                    .getRecord();
                leadsToInsert.add(testLead);
            }
            insert leadsToInsert;
        Test.stopTest();

        Set<Id> insertedLeadIds = new Set<Id>();
        for(Lead leadInserted : leadsToInsert){
            insertedLeadIds.add(leadInserted.Id);
        }
        List<Lead> leadsAfterProcessing = getLeadsById(insertedLeadIds);
        //for(Lead processedLead : leadsAfterProcessing){
            //System.assertEquals(testAccountHierarchy.Id, processedLead.AH_Name__c,
                //'Existing hierarchy should be associated finding by DomainCountryDUWebsite');
        //}
    }

    @isTest
    static void integrationTestWhenInsertingALeadANewAccountHierarchyShouldNotBeCreatedIfTheBasicConditionsAreNotMet(){

		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Lead testLead = new Lead();

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany',
                        Lead.SiteDunsNumber__c => 'Unex..',
                        Lead.LS_Site__c => null
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        Lead leadAfterProcessing = getLeadById(testLead.Id);
        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();

        System.assertEquals(0, accountHierarchiesCreated.size(),
            'New Account_Hierarchy__c should not be created because basic conditions in ' +
            ' accountHierarchyCanBeCreatedFromLead method are not met');
    }

    @isTest
    static void integrationTestWhenInsertingALeadANewAccountHierarchyShouldNotBeCreatedIfThereIsNoMatchWithAnExistingOne() {
		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Lead testLead = new Lead();

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany',
                        Lead.SiteDunsNumber__c => 'Unex..',
                        Lead.LS_Site__c => 'Super Company Name'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();
        System.assert(accountHierarchiesCreated.isEmpty(), 'New Account_Hierarchy__c should not be created');
    }

    @isTest
    static void integrationTestWhenInsertingABatchOfLeadsTheCorrectNumberOfAccountHierarchiesShouldBeInserted() {
        //testLead1 -> testAccountHierarchy1 (match by SiteDunsNumber__c)
        //testLead2 -> testAccountHierarchy2 (match by Company_Duns__c)
        //testLead3 -> testAccountHierarchy3 (match by countryDomain email)
        //testLead4 -> testAccountHierarchy3 (match by countryDomain DUwebsite)
        List<Lead> testLeadsToInsert = new List<Lead>();

		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();


        List<Account_Hierarchy__c> testAccountHierarchiesToInsert = (List<Account_Hierarchy__c>) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.D_U_N_S_Number__c => ValueProviderBuilder.provideList(new List<String> {DUNS_NUMBER,DUNS_NUMBER2,DUNS_NUMBER_UNEX2}),
                    Account_Hierarchy__c.Company_Status__c => 'test status',
                    Account_Hierarchy__c.Country_Domain__c => ValueProviderBuilder.provideList(new List<String> {'','',COUNTRY_DOMAIN1})
                }
            )
            .quantity(3)
            .create()
            .getRecords();

        Test.startTest();
            testLeadsToInsert = (List<Lead>) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'fake@email.com',
                        Lead.LastName => ValueProviderBuilder.provideList(new List<String> {'LUCHO1','LUCHO2','LUCHO7','LUCHO8'}),
                        Lead.Company => 'fakeCompany',
                        Lead.SiteDunsNumber__c => ValueProviderBuilder.provideList(new List<String> {DUNS_NUMBER,'','090909','090908'}),
                        Lead.Company_DUNS__c => ValueProviderBuilder.provideList(new List<String> {'',DUNS_NUMBER2,'',''}),
                        Lead.Country => ValueProviderBuilder.provideList(new List<String> {'','','United States','United States'}),
                        Lead.LS_Company_Website__c => ValueProviderBuilder.provideList(new List<String> {'','','','www.yahoo.com'})
                    }
                )
                .quantity(4)
                .create()
                .getRecords();
        Test.stopTest();

        Lead testLead1AfterProcessing = getLeadById(testLeadsToInsert[0].Id);

        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();

        System.assertEquals(3, accountHierarchiesCreated.size(),
            'Only 3 Account_Hierarchies__c should be created for this batch');

        //System.assertEquals(getAccountHierarchyByDunsNumber(DUNS_NUMBER, accountHierarchiesCreated).Id,
            //testLead1AfterProcessing.AH_Name__c,
            //'testAccountHierarchy1 should be associated to testLead1 match by SiteDunsNumber__c');

        //System.assertEquals(getAccountHierarchyByDunsNumber(DUNS_NUMBER2, accountHierarchiesCreated).Id,
            //getLeadById(testLeadsToInsert[1].Id).AH_Name__c,
            //'testAccountHierarchy2 should be associated to testLead2 match by Company_Duns__c');

        //System.assertEquals(getAccountHierarchyByDunsNumber(DUNS_NUMBER_UNEX2, accountHierarchiesCreated).Id,
            //getLeadById(testLeadsToInsert[3].Id).AH_Name__c,
            //'testAccountHierarchy3 should be associated to testLead8 match by country domain DU Website');
    }

    @isTest
    static void integrationTestWhenInsertingALeadExistingAccountHierarchyShouldBeAssociatedFindingByCountryDomainEmail(){

        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Country_Domain__c => COUNTRY_DOMAIN1,
                    Account_Hierarchy__c.Company_Status__c => 'test status',
                    Account_Hierarchy__c.D_U_N_S_Number__c => 'NewDuns'
                }
            )
            .create()
            .getRecord();

        Lead testLead = new Lead();

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Lead.email => 'test@yahoo.com',
                    Lead.LastName => 'fakeLastName',
                    Lead.Company => 'fakeCompany',
                    Lead.Country => 'United States'
                }
            )
            .create()
            .getRecord();
        Test.stopTest();

        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();

        System.assertEquals(1, accountHierarchiesCreated.size(),
            'The only Account_Hierarchy__c created should be the one intentionally inserted in the test');

        Lead leadAfterProcessing = getLeadById(testLead.Id);
        //System.assertEquals(testAccountHierarchy.Id, leadAfterProcessing.AH_Name__c,
            //'Existing hierarchy should be associated finding by CountryDomain');
    }

    @isTest
    static void integrationTestWhenInsertingALeadExistingAccountHierarchyShouldBeAssociatedFindingByCountryDomainDUWebsite(){

		new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Country_Domain__c => COUNTRY_DOMAIN1,
                    Account_Hierarchy__c.Company_Status__c => 'test status',
                    Account_Hierarchy__c.D_U_N_S_Number__c => 'NewDuns'
                }
            )
            .create()
            .getRecord();

        Lead testLead = new Lead();

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'nomatch@nomatch.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany',
                        Lead.LS_Company_Country__c => 'United States',
                        Lead.Country => null,
                        Lead.LS_Company_Website__c => 'www.yahoo.com'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();

        System.assertEquals(1, accountHierarchiesCreated.size(),
            'The only Account_Hierarchy__c created should be the one intentionally inserted in the test');

        Lead leadAfterProcessing = getLeadById(testLead.Id);
        //System.assertEquals(testAccountHierarchy.Id, leadAfterProcessing.AH_Name__c,
            //'Existing hierarchy should be associated finding by CountryDomain and AHWebsite');
    }

    @isTest
    static void integrationTestWhenInsertingALeadExistingAccountHierarchyShouldBeAssociatedFindingByCountryDomainWebsite(){

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Account_Hierarchy__c.Country_Domain__c => COUNTRY_DOMAIN1,
                    Account_Hierarchy__c.Company_Status__c => 'test status',
                    Account_Hierarchy__c.D_U_N_S_Number__c => 'NewDuns'
                }
            )
            .create()
            .getRecord();

        Lead testLead = new Lead();
        testLead.Country = null;
        testLead.LS_Company_Country__c = 'United States';
        testLead.Email = 'nomatch@nomatch.com';
        testLead.LS_Company_Website__c = 'wontmatchanything.com';
        testLead.Website = 'www.yahoo.com';

        Test.startTest();
            testLead = (Lead) new SObjectBuilder(Lead.SObjectType)
                .setFields(
                    new Map<SObjectField, Object>{
                        Lead.email => 'nomatch@nomatch.com',
                        Lead.LastName => 'fakeLastName',
                        Lead.Company => 'fakeCompany',
                        Lead.LS_Company_Country__c => 'United States',
                        Lead.Country => null,
                        Lead.LS_Company_Website__c => 'wontmatchanything.com',
                        Lead.Website => 'www.yahoo.com'
                    }
                )
                .create()
                .getRecord();
        Test.stopTest();

        List<Account_Hierarchy__c> accountHierarchiesCreated = getAllAccountHierarchies();

        System.assertEquals(1, accountHierarchiesCreated.size(),
            'The only Account_Hierarchy__c created should be the one intentionally inserted in the test');

        Lead leadAfterProcessing = getLeadById(testLead.Id);
        //System.assertEquals(testAccountHierarchy.Id, leadAfterProcessing.AH_Name__c,
            //'Existing hierarchy should be associated finding by CountryDomain and Website');
    }

    @isTest
    static void testNoDuplicatesShouldBeCreatedOnManualChangeOfFields() {

        new SObjectBuilder(Emails__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    Emails__c.Name => ValueProviderBuilder.provideList(new List<String> {'rcsfsyncuser', 'suniluser'}),
                    Emails__c.Email_Address__c => ValueProviderBuilder.provideList(new List<String> {'rcsf@fakemail.com', 'sunil@fakemail.com'})
                }
            )
            .quantity(2)
            .create();

        Account_Hierarchy__c testAccountHierarchy = (Account_Hierarchy__c) new SObjectBuilder(Account_Hierarchy__c.sObjectType)
            .setField(Account_Hierarchy__c.Name, 'test accountHierarchy')
            .setField(Account_Hierarchy__c.D_U_N_S_Number__c, DUNS_NUMBER)
            .setField(Account_Hierarchy__c.Company_Status__c, 'testStatus')
            .create()
            .getRecord();

        Lead testLead = (Lead) new SObjectBuilder(Lead.sObjectType)
            .setField(Lead.LastName, 'fakeLastName')
            .setField(Lead.Company, 'fakeCompany')
            .setField(Lead.Email, 'test@email.com')
            .setField(Lead.Company_Duns__c, DUNS_NUMBER)
            .create()
            .getRecord();

        testLead.AH_Name__c = null;
        update testLead;

        List<Object> bindings = new List<Object>();
        bindings.add(testLead.Id);

        CompanyPersonSelector getCompanyPersonInfoBefore = new CompanyPersonSelector();
        List<Company_Persons__c> companyPersonCountBefore = getCompanyPersonInfoBefore
                                                                .selectCountCompanyPersonsForCompanyMatching(bindings)
                                                                .executeQuery();
        System.assertEquals(0, companyPersonCountBefore.size(),
            'No Company Person should be created on manual update');

        ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'selectCompanyPersonsForCompanyMatching');

        Test.startTest();
        testLead.Website = 'www.fakewebsite.com';
        update testLead;
        Test.stopTest();

        CompanyPersonSelector getCompanyPersonInfo = new CompanyPersonSelector();
        List<Company_Persons__c> companyPersonCount = getCompanyPersonInfo
                                                          .selectCountCompanyPersonsForCompanyMatching(bindings)
                                                          .executeQuery();
        //System.assertEquals(1, companyPersonCount.size(),
            //'More than one Company Person was created');
    }

    @isTest
    static void testGetOnlyNewLeadsOrLeadsWhichAHSearchCriteriaFieldsHaveBeenModified() {
        Map<Double, LeadCompanyProcessorSvc.LeadAccountHierarchy> results;
        Lead newLead = (Lead) new SObjectBuilder (Lead.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                        .setField(Lead.Status, '.5 Re-New')
                        .create()
                        .getRecord();
        Lead oldLead = newLead.clone();
        oldLead.Status = 'x. Open';

        List<Lead> newLeadList = new List<Lead>();
        newLeadList.add(newLead);
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
        oldLeadMap.put(oldLead.Id, oldLead);

        Test.startTest();
        LeadCompanyProcessorSvc companyProcessorservice = new LeadCompanyProcessorSvc();
        results = companyProcessorservice.getOnlyNewLeadsOrLeadsWhichAHSearchCriteriaFieldsHaveBeenModified(newLeadList, oldLeadMap);
        Test.stopTest();

        System.assert(results.size() > 0);
        System.assertEquals(results.values()[0].lead.Id, newLead.Id);
    }

    @isTest
    static void testdetermineCountrySearchKey() {

        Lead USTestLead = (Lead) new SObjectBuilder (Lead.SObjectType)
            .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
            .setField(Lead.LS_Company_Country__c, 'US')
            .create()
            .getRecord();

        CompanyMatchingCountryMapping__c testCustomSetting = (CompanyMatchingCountryMapping__c)
            new SObjectBuilder (CompanyMatchingCountryMapping__c.SObjectType)
            .setField(CompanyMatchingCountryMapping__c.Name, 'US')
            .setField(CompanyMatchingCountryMapping__c.ToCountry__c, 'United States')
                .create()
                .getRecord();

        Test.startTest();
        LeadCompanyProcessorSvc comProcServ = new LeadCompanyProcessorSvc();
        String results = comProcServ.determineCountrySearchKey(USTestLead);
        Test.stopTest();

        System.assertEquals('united states', results);

    }

    @isTest
    static void testPaddingOnDunsNumber() {
        Map<Double, LeadCompanyProcessorSvc.LeadAccountHierarchy> lahsMap = new Map<Double, LeadCompanyProcessorSvc.LeadAccountHierarchy>();

        Account_Hierarchy__c newAh = (Account_Hierarchy__c) new SObjectBuilder (Account_Hierarchy__c.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account_Hierarchy__c.SObjectType))
                        .setField(Account_Hierarchy__c.D_U_N_S_Number__c, '123450000')
                        .setField(Account_Hierarchy__c.Company_Status__c, 'testStatus')
                        .create()
                        .getRecord();

        Lead newLead = (Lead) new SObjectBuilder (Lead.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                        .setField(Lead.Company_Duns__c, '12345')
                        .create()
                        .getRecord();

        LeadCompanyProcessorSvc.LeadAccountHierarchy lah = new LeadCompanyProcessorSvc.LeadAccountHierarchy(newLead, null);
        lahsMap.put(lah.id, lah);

        Test.startTest();
        LeadCompanyProcessorSvc companyProcessorservice = new LeadCompanyProcessorSvc();
        companyProcessorservice.processAccountHierarchyMatchingByDunsNumber(lahsMap);
        Test.stopTest();

        System.assertEquals(lahsMap.get(lah.id).accountHierarchy.Id, newAh.Id);
    }

    @isTest
    static void testOldCompanyShouldBeRemovedIfNoCompanyIsFound() {
        Account_Hierarchy__c newAh = (Account_Hierarchy__c) new SObjectBuilder (Account_Hierarchy__c.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account_Hierarchy__c.SObjectType))
                        .setField(Account_Hierarchy__c.D_U_N_S_Number__c, '123450000')
                        .setField(Account_Hierarchy__c.Company_Status__c, 'testStatus')
                        .create()
                        .getRecord();

        Lead testLead = (Lead) new SObjectBuilder (Lead.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                        .setField(Lead.AH_Name__c, newAh.Id)
                        .setField(Lead.Company_Duns__c, newAh.D_U_N_S_Number__c)
                        .create()
                        .getRecord();

        delete newAh;

        List<sObject> objectsToProcess = new List<sObject>();
        objectsToProcess.add(testLead);

        Test.startTest();
        LeadCompanyProcessorSvc companyProcessorservice = new LeadCompanyProcessorSvc();
        companyProcessorservice.processAccountHierarchy(objectsToProcess, null);
        Test.stopTest();

        System.assertEquals(null, testLead.AH_Name__c,
                            'The Accounts Company Name should have been deleted');
        System.assertEquals('', testLead.Company_Duns__c,
                            'The Accounts Company Duns should have been deleted');
    }

    @isTest
    static void testDeletionOfCompanyPersonsIfNoCompanyIsFound() {
        Account_Hierarchy__c newAh = (Account_Hierarchy__c) new SObjectBuilder (Account_Hierarchy__c.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Account_Hierarchy__c.SObjectType))
                        .setField(Account_Hierarchy__c.D_U_N_S_Number__c, '123450000')
                        .setField(Account_Hierarchy__c.Company_Status__c, 'testStatus')
                        .create()
                        .getRecord();

        Lead testLead = (Lead) new SObjectBuilder (Lead.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Lead.SObjectType))
                        .setField(Lead.AH_Name__c, newAh.Id)
                        .setField(Lead.Company_Duns__c, newAh.D_U_N_S_Number__c)
                        .create()
                        .getRecord();

        Company_Persons__c compPerson = (Company_Persons__c) new SObjectBuilder (Company_Persons__c.SObjectType)
                        .setFields(SObjectFactoryFieldDefaults.getDefaults(Company_Persons__c.SObjectType))
                        .setField(Company_Persons__c.Lead__c, testLead.Id)
                        .setField(Company_Persons__c.Company__c, newAh.Id)
                        .create()
                        .getRecord();

        delete newAh;

        Test.startTest();
        List<Object> bindings = new List<Object>();
        bindings.add(new Set<String>{newAh.Id});
        bindings.add(new Set<String>{testLead.Id});
        List<Company_Persons__c> compPersons = (List<Company_Persons__c>) new CompanyPersonSelector()
                                               .selectCountCompanyPersonsByLeadAndCompanyId(bindings)
                                               .executeQuery();
        Test.stopTest();

        System.assertEquals(0, compPersons.size(),
                            'The Accounts Company Person should have been deleted');
    }

    @isTest
    static void testConstructor() {
        LeadCompanyProcessorSvc.AccountHierarchyToInsert accountHierarchyToInsert = new LeadCompanyProcessorSvc.AccountHierarchyToInsert();

        System.assertEquals(0, accountHierarchyToInsert.leads.size(), 'Leads list should be empty after constructor');
    }
}
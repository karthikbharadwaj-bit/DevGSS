@isTest
private class TestDomainManagerSvc {
    @isTest
    static void testGetDomainPartFromUrlShouldReturnAValidDomainFromValidUrls(){
        String expectedDomain = 'yahoo.com';
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('www.yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('www.yahoo.com/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('www.yahoo.com/subdomain/asdf'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('www.yahoo.com/subdomain/asdf/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://www.yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://www.yahoo.com/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://www.yahoo.com/subdomain/asdf'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://www.yahoo.com/subdomain/asdf/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('https://www.yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('https://www.yahoo.com/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('https://www.yahoo.com/subdomain/asdf'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('https://www.yahoo.com/subdomain/asdf/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('yahoo.com/'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('yahoo.com/subdomain/asdf'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('yahoo.com/subdomain/asdf/'));
        System.assertEquals('save-a-lot.com', serviceUnderTest.getDomainPartFromUrl('www.save-a-lot.com'));
    }

    @isTest
    static void testGetDomainPartFromUrlShouldReturnAnEmptyStringFromInvalidUrls(){
        String expectedDomain = '';
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://www.yahoo.com .ar'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http://1'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http:/yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http//yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('http:yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('htp:yahoo.com'));
        System.assertEquals(expectedDomain, serviceUnderTest.getDomainPartFromUrl('3@yahoo.com/subdomain/asdf/'));
    }

     @isTest
    static void testGetDomainPartFromUrlShouldReturnNullWhenAnEmptyUrlIsProvided(){
        String expectedDomain = null;
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();

        Test.startTest();
            String returnedDomain = serviceUnderTest.getDomainPartFromUrl('');
        Test.stopTest();
        
        System.assertEquals(expectedDomain, returnedDomain, 
            'GetDomainPartFromUrl should return null when an empty url is provided');
    }

    @isTest
    static void testGetDomainPartFromEmailAddressShouldReturnValidDomainsFromValidEmailAddresses(){
        String expectedDomain = 'lanacion.com';
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();

        Test.startTest();
            String returnedDomain = serviceUnderTest.getDomainPartFromEmailAddress('john@lanacion.com');
        Test.stopTest();

        System.assertEquals(expectedDomain, returnedDomain, 
            'Valid domain should be returned from valid email address');
    }

    @isTest
    static void testGetDomainPartFromEmailAddressShouldReturnNullWhenEmptyEmailIsProvided(){
        String expectedDomain = null;
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();

        Test.startTest();
            String returnedDomain = serviceUnderTest.getDomainPartFromEmailAddress('');
        Test.stopTest();

        System.assertEquals(expectedDomain, returnedDomain, 
            'Returned domain should be null when empty email is provided');
    }

    @isTest
    static void testDomainIsInIgnoredDomainListShouldReturnTrueIfTheDomainIsInTheList(){
        CompanyMatchingIgnoredDomains__c companyMatchingIgnoredDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => 'yahoo.com'
                }
            )
            .create()
            .getRecord();

        String domainToTest = 'yahoo.com';
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();
        
        Test.startTest();
            Boolean domainIsInIgnoredDomainList = serviceUnderTest.domainIsInIgnoredDomainList(domainToTest);
        Test.stopTest();

        System.assertEquals(true, domainIsInIgnoredDomainList, 
            'DomainIsInIgnoredDomainList should return true if the domain is in the list');
    }

    @isTest
    static void testDomainIsInIgnoredDomainListShouldReturnFalseIfTheDomainIsNotInTheList(){
        CompanyMatchingIgnoredDomains__c companyMatchingIgnoredDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => 'yahoo.com'
                }
            )
            .create()
            .getRecord();

        String domainToTest = 'microsoft.com';
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();
        Test.startTest();
            Boolean domainIsInIgnoredDomainList = serviceUnderTest.domainIsInIgnoredDomainList(domainToTest);
        Test.stopTest();

        System.assertEquals(false, domainIsInIgnoredDomainList, 
            'DomainIsInIgnoredDomainList should return false if the domain is not in the list');
    }

    @isTest
    static void testDomainIsInIgnoredDomainListIncludingWildcardsShouldReturnCorrectResults(){
        List<CompanyMatchingIgnoredDomains__c> blackListToInsert = new List<CompanyMatchingIgnoredDomains__c>();
        CompanyMatchingIgnoredDomains__c blackDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => 'google.com'
                }
            )
            .build()
            .getRecord();
        blackListToInsert.add(blackDomain);
        blackDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => 'yahoo*'
                }
            )
            .build()
            .getRecord();
        blackListToInsert.add(blackDomain);
        blackDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => 'gmail*'
                }
            )
            .build()
            .getRecord();
        blackListToInsert.add(blackDomain);
        blackDomain = (CompanyMatchingIgnoredDomains__c) new SObjectBuilder(CompanyMatchingIgnoredDomains__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    CompanyMatchingIgnoredDomains__c.Name => '.rr.*'
                }
            )
            .build()
            .getRecord();
        blackListToInsert.add(blackDomain);

        insert blackListToInsert;
       
        DomainManagerSvc serviceUnderTest = new DomainManagerSvc();

        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('yahoo.com.ru'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('www.yahoo.com.ru'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('gmail.com'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('agmail.com'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('google.com'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(true, serviceUnderTest.domainIsInIgnoredDomainList('la.rr.com'),
            'DomainIsInIgnoredDomainList should return true');
        System.assertEquals(false, serviceUnderTest.domainIsInIgnoredDomainList('la.microsoft.com'),
            'DomainIsInIgnoredDomainList should return false');
        System.assertEquals(false, serviceUnderTest.domainIsInIgnoredDomainList('google.com.ar'),
            'DomainIsInIgnoredDomainList should return false');
    }
}
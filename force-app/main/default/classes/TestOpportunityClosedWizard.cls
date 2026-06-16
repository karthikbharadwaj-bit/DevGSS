@isTest
private class TestOpportunityClosedWizard {

    @isTest
    static void opportunityWizardTest() { 
        Account acctest12 = new Account();
        acctest12.Name='TestAccount12';
        acctest12.RC_Attribution_Channel__c = 'National Accounts';
        acctest12.Partner_ID__c ='123';
        acctest12.Number_of_DL_s__c = 10;
        acctest12.RecordTypeId  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        
        TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
        insert acctest12;
        
        Opportunity Oppval12 = new Opportunity();
        Oppval12.Name = 'Test Opp12';
        Oppval12.AccountId = acctest12.Id;
        Oppval12.Type = 'Existing Business';
        Oppval12.StageName = '3. ActivePipe';
        Oppval12.Sales_Model__c = 'Direct';
        Oppval12.StageName= '7.Closed Won';
        Oppval12.Probability = 100;
        Oppval12.Who_What_are_we_replacing__c ='test';
        Oppval12.Who_Did_We_Beat__c ='Hosted Pbx';
        Oppval12.CloseDate = System.Today() + 10;
        Oppval12.CurrencyIsoCode = 'USD';
        Oppval12.Brand_Name__c= 'RingCentral';
        Oppval12.Forecasted_Users__c =12;
        Oppval12.Tier_Name__c ='100';
        Oppval12.Why_did_we_win__c='Integrations';
        Oppval12.Competitor_Why_did_We_Win__c = 'Quality of Service / Product';
        Oppval12.Competitor_Other_Cloud__c ='test';      
       // Oppval12.Why_did_we_win__c 
        Oppval12.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Saves Opportunity').getRecordTypeId();
        TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
        insert Oppval12;
         Test.startTest(); 
        
        ApexPages.currentPage().getParameters().put('id', Oppval12	.id);     
        boolean toshowWonReasonIntegrations ;
        boolean  toshowWonReasonServiceAndFeatures;
        boolean toshowWonReasonAll;
        String  strSelectedWhoDidWeWin = 'Integration' ;
        List<String> testclosOppty = new List<String>();
        testclosOppty.add('Services and Features');
        testclosOppty.add('Integrations');
        testclosOppty.add('Won Reason-All');
        
        set<String> tests = new set<String>();       
        tests.add('Google Integration');
        tests.add('Quality of Service / Product');
        tests.add(' Multi-Level IVR');
        
        String strSectedWonReasonOption = '';
        Set<String> setSelectedWonReasonOption = new Set<String>();
        OpportunityClosedWizard obj = new OpportunityClosedWizard(new ApexPages.StandardController(Oppval12));
        obj.getHostedPBX();
        obj.getHostedPBX1();
        obj.getHostedPBXRCandRCCanada();
        obj.getHostedPBXRCUK();
        obj.getWhoDidWeBeat();
        obj.getWhoDidWeWin();
        obj.getWhoWhatAreWeReplacing();
        obj.getWonReasonServiceAndFeatures();
        obj.getWonReasonIntegrations();
        obj.getWonReasonAll();
        obj.cancel();
        obj.showtoOtherOnPremisePBX1();
        obj.showtoOtherHostedPBX1();      
        obj.showtoOtheronPremisePBX();
        obj.showtoOtherHostedPBX();
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1();
        obj.strSelectedWhoDidWeBeat = 'On-Premise PBX';
        obj.strSelectedWhoDidWeBeat1 = 'On-Premise PBX';
        obj.showSubSectionOfWhoDidWeWin();
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1(); 
        obj.strSelectedWhoDidWeBeat = 'Hosted PBX';
        obj.strSelectedWhoDidWeBeat1 = 'Hosted PBX';
        obj.toShowImplementationScheduler = true;
        obj.lstSelectedWonReasonIntegrations = testclosOppty; 
        obj.toshowWonReasonIntegrations = true;
        obj.lstSelectedWonReasonAll = testclosOppty;
        obj.toshowWonReasonServiceAndFeatures = true;
        obj.lstSelectedWonReasonIntegrations =testclosOppty;
        obj.showSubSectionOfWhoDidWeBeat();
        obj.showSubSectionOfWhoDidWeBeat1();
        obj.showSubSectionOfWhoDidWeWin();
        obj.OpportunityUpdate();
        obj.strSelectedWhoDidWeBeat = 'Land Lines';
        obj.strSelectedWhoDidWeBeat1 = 'Land Lines';
        obj.OpportunityUpdate();
        obj.strSelectedWhoDidWeBeat = 'On-Premise PBX';
        obj.strsectedOnPremisePBXdetail = 'Cisco';
        obj.strSelectedWhoDidWeBeat1 = 'Hosted PBX';
        obj.strsectedHostedPBXdetail1 = 'Mitel'; 
         obj.toShowImplementationAppointment(Oppval12) ;   
        obj.getImplementationContact(Oppval12);      
        obj.OpportunityUpdate();
        Test.stopTest();

        //For coverage
        List<String> tempList = obj.tempList;
        Map<String, List<String>> mapBrandAndHostedPBX = obj.mapBrandAndHostedPBX;
        List<String> BrandRingCentralUSOrCanada = obj.BrandRingCentralUSOrCanada;
        List<String> BrandRingCentralUK = obj.BrandRingCentralUK;
        String strvalOtherWonReasonIntegrations = obj.strvalOtherWonReasonIntegrations;
        String strvalOtherOnWonReasonServiceAndFeature = obj.strvalOtherOnWonReasonServiceAndFeatures;
        String strvalOtherOnWonReasonAll = obj.strvalOtherOnWonReasonAll;
        List<Opportunity> oppobj1 = obj.oppobj1;
        String strsectiontOtherWhoDidWeBeat = obj.strsectiontOtherWhoDidWeBeat;
        Boolean toOtherWonReasonIntegrations = obj.toOtherWonReasonIntegrations;
        Boolean toOtherWonReasonServiceAndFeature = obj.toOtherWonReasonServiceAndFeature;
        Boolean toOtherWonReasonAll = obj.toOtherWonReasonAll;
        Boolean toOnPremisePBX = obj.toOnPremisePBX;
        Id implementationContact = obj.implementationContact;
        String opportunityId = obj.opportunityId;

        //Test showtoOtherOnPremisePBX1
        obj.strsectedOnPremisePBXdetail1 = 'Other (provide detailed reason)';
        obj.showtoOtherOnPremisePBX1();
        System.assert(
            obj.toOtherOnPremisePBX1,
            'Property toOtherOnPremisePBX1 should be true'
        );

        //Test showtoOtherHostedPBX1
        obj.strsectedHostedPBXdetail1 = 'Other (provide detailed reason)';
        obj.showtoOtherHostedPBX1();
        System.assert(
            obj.toOtherHostedPBX1,
            'Property toOtherHostedPBX1 should be true'
        );

        //Test showtoOtheronPremisePBX
        obj.strsectedOnPremisePBXdetail = 'Other (provide detailed reason)';
        obj.showtoOtheronPremisePBX();
        System.assert(
            obj.toOtherOnPremisePBX,
            'Property toOtherOnPremisePBX should be true'
        );

        //Test showtoOtherHostedPBX
        obj.strsectedHostedPBXdetail = 'Other (provide detailed reason)';
        obj.showtoOtherHostedPBX();
        System.assert(
            obj.toOtherHostedPBX,
            'Property toOtherHostedPBX should be true'
        );

        //Test showSubSectionOfWhoDidWeBeat
        obj.strSelectedWhoDidWeBeat = 'Other';
        obj.showSubSectionOfWhoDidWeBeat();
        System.assert(
            !obj.toshowHostedPBX,
            'Property toshowHostedPBX should be false'
        );
        System.assert(
            !obj.toshowOnPremisePBX,
            'Property toshowOnPremisePBX should be false'
        );
        System.assert(
            obj.toOtherWhoDidWeBeat,
            'Property toOtherWhoDidWeBeat should be true'
        );

        //Test showSubSectionOfWhoDidWeWin
        obj.setSelectedWhoDidWeWin = new Set<String>{'Services and Features'};
        obj.showSubSectionOfWhoDidWeWin();
        System.assert(
            obj.toshowWonReasonServiceAndFeatures,
            'Property toshowWonReasonServiceAndFeatures should be true'
        );
        System.assert(
            !obj.toshowWonReasonAll,
            'Property toshowWonReasonAll should be false'
        );

        obj.setSelectedWhoDidWeWin = new Set<String>{'Integrations'};
        obj.showSubSectionOfWhoDidWeWin();
        System.assert(
            obj.toshowWonReasonIntegrations,
            'Property toshowWonReasonIntegrations should be true'
        );
        System.assert(
            !obj.toshowWonReasonAll,
            'Property toshowWonReasonAll should be false'
        );

        obj.setSelectedWhoDidWeWin = new Set<String>{'Won Reason - All'};
        obj.showSubSectionOfWhoDidWeWin();
        System.assert(
            obj.toshowWonReasonAll,
            'Property toshowWonReasonAll should be true'
        );
        System.assert(
            !obj.toshowWonReasonIntegrations,
            'Property toshowWonReasonIntegrations should be false'
        );
        System.assert(
            !obj.toshowWonReasonServiceAndFeatures,
            'Property toshowWonReasonServiceAndFeatures should be false'
        );
    }
}
@isTest
private class Test_Partner_Deal_Registration_Generic {
    /*
	@isTest(SeeAllData=true)
    public static void test_createDealRegistration1() {
        String jsonStr = '{"Partner_Contact__c":"0032H00002ALkgxQAD","Brand_Name__c":"Avaya Cloud Office","Number_of_Employees__c":"1-19","Competitor_s__c":"8x8","Edition__c":"Standard","Tier_Name__c":"Office","Inside_Sales_Rep__c":"","First_Name__c":"RTan202203041301_API","Last_Name__c":"RTan202203041301_API","Business_Title__c":"RTan202203041301_API","Company_Name__c":"RTan202203041301_API5","Email_Address__c":"bizserv_qa+202203041301@ringcentral.com","Phone_Number__c":"16502342345","Address__c":"2007 St Jean Baptiste St","City__c":"East Broughton","State__c":"Quebec","Country__c":"Canada","Postal_Code__c":"G0N 1G0","Forecasted_RingCentral_Video_Users__c":"","Forecasted_Users__c":12,"Term__c":"Annual","Number_of_Locations__c":"2-4","Industry__c":"Government","Estimated_Close_Date__c":"2022-12-20","Website__c":"www.test.com","How_did_you_acquire_this_Lead__c":"Test how did you acquire this lead","Description__c":"Test description","Budget_available_for_project__c":"Yes","Existing_Solution_Provider__c":"8x8","Competitors_Other__c":"24324234","Whats_prompting_change__c":"End of life equipment;Collaboration challenges","Decision_Maker__c":"President","Currently_in_a_contract__c":"No","Sales_Notes__c":"Test sales note","Forecasted_Contact_Center_Users__c":"","Partner_System_ID__c":"RTan2022076574766565756_API7"}';
        Deal_Registration__c dealReg = (Deal_Registration__c)JSON.deserializeStrict(jsonStr, Deal_Registration__c.class);
        String res = Partner_Deal_Registration_Generic.createDealRegistration(dealReg);
    }
	*/
    @isTest
    private static void test_createDealRegistration(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        
        Deal_Registration__c dealRegObj2 = new Deal_Registration__c();
        List<Deal_Registration__c> lstDealReg = new List<Deal_Registration__c>();
        Test.startTest();
         system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){    
             for(Integer i=0;i<4;i++){
                Deal_Registration__c dealRegObj = new Deal_Registration__c();
                dealRegObj.Partner_Contact__c = PartnerRecordsUtil.partnerContact.Id;
                dealRegObj.Partner_Account__c = PartnerRecordsUtil.partnerAccount.Id;
                dealRegObj.First_Name__c = 'Test';
                dealRegObj.Last_Name__c = 'DealReg';
                dealRegObj.Business_Title__c = 'Consultant';
                dealRegObj.Company_Name__c = 'Test Company';
                dealRegObj.Email_Address__c = 'testdealreg@mail.com';
                dealRegObj.Phone_Number__c = '123456789';
                dealRegObj.Address__c = 'ABC street';
                dealRegObj.City__c = 'abc city';
                dealRegObj.State__c = 'ALASKA';
                dealRegObj.Postal_Code__c = '123456';
                dealRegObj.Country__c = 'United States';
                dealRegObj.Forecasted_Users__c = 5;
                dealRegObj.Brand_Name__c = 'Avaya Cloud Office';
                dealRegObj.Tier_Name__c = 'Office';
                dealRegObj.Edition__c = 'Standard';
                dealRegObj.Term__c = 'Annual';
                dealRegObj.Number_of_Employees__c = '1-19';
                dealRegObj.Number_of_Locations__c = '2-4';
                dealRegObj.Industry__c = 'Banking';
                dealRegObj.Estimated_Close_Date__c = System.today()+90;
                dealRegObj.Website__c = 'www.testsite.com';
                dealRegObj.How_did_you_acquire_this_Lead__c = 'Testing Acquisition';
                dealRegObj.Description__c = 'Test Deal Reg description';
                dealRegObj.Budget_available_for_project__c = 'Yes'; 
                dealRegObj.Existing_Solution_Provider__c = 'Avaya';
                dealRegObj.Competitor_s__c = 'Avaya';
                dealRegObj.What_s_prompting_change__c = 'Other';
                dealRegObj.Whats_prompting_change__c = 'Other';
                dealRegObj.Decision_Maker__c = 'Other';
                dealRegObj.Currently_in_a_contract__c = 'Yes'; 
                dealRegObj.Sales_Notes__c = 'Test Sales notes';
                dealRegObj.Avaya_Partnership_Deal__c = true;
                dealRegObj.Status__c = 'Approved';
                dealRegObj.Avaya_Cloud_Specialist__c = PartnerRecordsUtil.partnerContact.Id;
                dealRegObj.RC_Overlay__c = 'test';
                dealRegObj.Portal_Cloud_Specialist__c = PartnerRecordsUtil.partnerContact.Id;
                dealRegObj.Decision_Maker_Other__c = 'test';
                dealRegObj.What_s_prompting_change_Other__c = 'other';
                dealRegObj.Partner_System_ID__c = 'RTan20220304sdfdsfer1301_API'+i;
                lstDealReg.add(dealRegObj);
             }
           String res = Partner_Deal_Registration_Generic.createDealRegistration(lstDealReg[0]);
           Partner_Deal_Registration_Generic.ResponseWrapper responsewrap = (Partner_Deal_Registration_Generic.ResponseWrapper) JSON.deserializeStrict(res,Partner_Deal_Registration_Generic.ResponseWrapper.class);
           System.assertEquals(responsewrap.apiStatus,'Success');
           lstDealReg[1].Number_of_Employees__c = '400-4999';
           String res2 = Partner_Deal_Registration_Generic.createDealRegistration(lstDealReg[1]);
           Partner_Deal_Registration_Generic.ResponseWrapper responsewrap1 = (Partner_Deal_Registration_Generic.ResponseWrapper) JSON.deserializeStrict(res2,Partner_Deal_Registration_Generic.ResponseWrapper.class);
           System.assertEquals(responsewrap1.apiMessage,'Duplicate Deal Registration record detected, stopped Deal Registration conversion to Lead.');
           
           lstDealReg[2].Existing_Solution_Provider__c = 'Other';
           lstDealReg[2].Competitor_s__c = 'Other';
           String res3 = Partner_Deal_Registration_Generic.createDealRegistration(lstDealReg[2]);
           Partner_Deal_Registration_Generic.ResponseWrapper responsewrap3 = (Partner_Deal_Registration_Generic.ResponseWrapper) JSON.deserializeStrict(res3,Partner_Deal_Registration_Generic.ResponseWrapper.class);
           System.assertEquals(responsewrap.apiStatus,'Success');
		}
        Test.stopTest();
    }
    @isTest
    private static void test_createDealRegistration2(){
        PartnerRecordsUtil objutil = new PartnerRecordsUtil();
        Test.startTest();
         system.runAs(PartnerRecordsUtil.runAsAvayaAdmin){    
            String jsonStr = '{"Partner_Contact__c":'+' "' + PartnerRecordsUtil.partnerContact.Id +'" ' +',"Brand_Name__c":"Avaya Cloud Office","Number_of_Employees__c":"400-4999","Competitor_s__c":"8x8","Edition__c":"Standard","Tier_Name__c":"Office","Inside_Sales_Rep__c":"","First_Name__c":"skjdfhksdhjgkdsgsdgdhwrgscmbjsesgjhdkv","Last_Name__c":"xckjdhfgdajvmxbvjhdvfhjsabxnvdz","Business_Title__c":"zklkxnvjkdgjbvmbvjhdgjhghvdv","Company_Name__c":"z,mnvjkdbhjvzdbvnmcxbvmcnbv","Email_Address__c":"kfgjzcvnvhjhdj@dkhfjdhvjdgjdshgf.com","Phone_Number__c":"dkfjksdgfjhdsd","Address__c":"arafdfsdfsdfdsfdf","City__c":"East Broughton","State__c":"Quebec","Country__c":"Canada","Postal_Code__c":"G0N 1G0","Forecasted_RingCentral_Video_Users__c":"","Forecasted_Users__c":12,"Term__c":"Annual","Number_of_Locations__c":"2-4","Industry__c":"Government","Estimated_Close_Date__c":"2022-12-20","Website__c":"dskjhfjsdgjfhsdgd","How_did_you_acquire_this_Lead__c":"Test how did you acquire this lead","Description__c":"Test description","Budget_available_for_project__c":"Yes","Existing_Solution_Provider__c":"8x8","Competitors_Other__c":"24324234","Whats_prompting_change__c":"End of life equipment;Collaboration challenges","Decision_Maker__c":"President","Currently_in_a_contract__c":"No","Sales_Notes__c":"Test sales note","Forecasted_Contact_Center_Users__c":"","Deal_Reg_RC_UID__c":"RTan20220304sdfdsfer1301_API7","Partner_System_ID__c":"RTan20220304sdfdsfer1301_API7"}';
          	Deal_Registration__c dealReg = (Deal_Registration__c)JSON.deserializeStrict(jsonStr, Deal_Registration__c.class);
            String res3 = Partner_Deal_Registration_Generic.createDealRegistration(dealReg);
            Partner_Deal_Registration_Generic.ResponseWrapper responsewrap = (Partner_Deal_Registration_Generic.ResponseWrapper) JSON.deserializeStrict(res3,Partner_Deal_Registration_Generic.ResponseWrapper.class);
         	System.assertEquals(responsewrap.apiMessage,'No Errors. Skipped Auto-Conversion.');
         }
        Test.stopTest();
    }
	@isTest
    private static void test_createDealRegistration4() {
        Account portalAccount1 = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
        Account.Name => 'TestAccount',
		Account.RC_Brand__c => 'Avaya Cloud Office',
        Account.type => 'Partner',
        Account.Avaya_partnership_account__c => true,
        Account.Permitted_Brands__c=>'Avaya Cloud Office'
		})
        .create()
        .getRecord();
         
        Contact contact1 = (Contact) new SObjectBuilder(Contact.SObjectType)
        .setFields(new Map<SObjectField, Object>{
                    Contact.FirstName => 'Test 2',
                    Contact.Lastname => 'McTestysdf',
                    Contact.AccountId => portalAccount1.id,
                    Contact.Partner_Portal_View__c => 'Full',
                    Contact.Email => System.now().millisecond() + 'test@2test.com'
                })
        .create()
        .getRecord();
        Test.startTest();
        String jsonStr = '{"Partner_Contact__c":'+' "' + contact1.Id +'" ' +',"Brand_Name__c":"Avaya Cloud Office","Number_of_Employees__c":"1-19","Competitor_s__c":"8x8","Edition__c":"Standard","Tier_Name__c":"Office","Inside_Sales_Rep__c":"","First_Name__c":"skjdfhksdhjgkdsgsdgdhwrgscmbjsesgjhdkv","Last_Name__c":"xckjdhfgdajvmxbvjhdvfhjsabxnvdz","Business_Title__c":"zklkxnvjkdgjbvmbvjhdgjhghvdv","Company_Name__c":"z,mnvjkdbhjvzdbvnmcxbvmcnbv","Email_Address__c":"kfgjzcvnvhjhdj@dkhfjdhvjdgjdshgf.com","Phone_Number__c":"dkfjksdgfjhdsd","Address__c":"arafdfsdfsdfdsfdf","City__c":"East Broughton","State__c":"Quebec","Country__c":"Canada","Postal_Code__c":"G0N 1G0","Forecasted_RingCentral_Video_Users__c":"","Forecasted_Users__c":12,"Term__c":"Annual","Number_of_Locations__c":"2-4","Industry__c":"Government","Estimated_Close_Date__c":"2022-12-20","Website__c":"dskjhfjsdgjfhsdgd","How_did_you_acquire_this_Lead__c":"Test how did you acquire this lead","Description__c":"Test description","Budget_available_for_project__c":"Yes","Existing_Solution_Provider__c":"8x8","Competitors_Other__c":"24324234","Whats_prompting_change__c":"End of life equipment;Collaboration challenges","Decision_Maker__c":"President","Currently_in_a_contract__c":"No","Sales_Notes__c":"Test sales note","Forecasted_Contact_Center_Users__c":"","Deal_Reg_RC_UID__c":"RTan20220304sdfdsfer1301_API7","Partner_System_ID__c":"RTan20220304sdfdsfer1301_API7"}';
        Deal_Registration__c dealReg = (Deal_Registration__c)JSON.deserializeStrict(jsonStr, Deal_Registration__c.class);
        String res = Partner_Deal_Registration_Generic.createDealRegistration(dealReg);
        Partner_Deal_Registration_Generic.ResponseWrapper responsewrap = (Partner_Deal_Registration_Generic.ResponseWrapper) JSON.deserializeStrict(res,Partner_Deal_Registration_Generic.ResponseWrapper.class);
        System.assertEquals(responsewrap.apiStatus,'Success');
        Test.stopTest();
    }
}
@isTest
private class DocumentHelperTest {

    @isTest
    private static void salesCalculationsAndCSVRetrievalTest() {

        String csvBody = ''
            + 'Brand,Currency,Service,Price,MinimumUserRange,MaximumUserRange\n'
            + 'RingCentral,USD,Office,149.99,1,1\n'
            + 'RingCentral,USD,Contact Center,149.99,1,1\n'
            + 'RingCentral,USD,Global Office,149.99,1,1\n'
            + 'RingCentral,USD,Engage Digital,149.99,1,1\n'
            + 'RingCentral,USD,Engage Voice,149.99,1,1\n'
            + 'RingCentral,USD,RC Meetings,149.99,1,1\n';

        Folder fd = [SELECT Id FROM Folder WHERE Name='Public Documents' LIMIT 1];
        Document doc = new Document();
        doc.name = 'Pipeline_Forecast_Amounts';
        doc.body = Blob.valueOf(csvBody);
        doc.folderId=fd.Id;
        doc.isPublic=true;
        doc.type='csv';
        insert doc;

        Account acc = (Account) new SObjectBuilder(Account.SObjectType)
        .setFields(new Map<SObjectField, Object>{
            Account.Name => 'Test acc',
            Account.Billing_ID__c => ValueProviderBuilder.provideUniqueString(),
            Account.RC_User_ID__c => ValueProviderBuilder.provideUniqueString(),
            Account.BillingStreet => '2078 Adamsville Road',
            Account.BillingCity => 'Laredo',
            Account.BillingPostalCode => '78040',
            Account.BillingState => 'Texas',
            Account.BillingCountry => 'United States',
            Account.EnabledLBO__c => true,
            Account.RC_Account_Status__c => AccountHelper.PAID_STATUS
        })
        .create()
        .getRecord();

        Contact cont = (Contact) new SObjectBuilder(Contact.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Contact.FirstName => 'Test2',
                Contact.LastName => 'Test2',
                Contact.AccountId => acc.Id,
                Contact.Email => 'test@test.com',
                Contact.Phone => '1234567890',
                Contact.Preferred_Language__c => 'en_US'
            })
            .create()
            .getRecord();

        Test.startTest();
        Opportunity opportunityWithoutValues = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.Tier_Name__c => 'Office'
            })
            .create()
            .getRecord();

        Opportunity oppWithNoValues = [SELECT id, Estimated_12M_Office_Pipeline__c, Estimated_12M_Contact_Center_Pipeline__c,
                                              Estimated_12M_Engage_Digital_Pipeline__c, Estimated_12M_Engage_Voice_Pipeline__c, Estimated_12M_Global_Office_Pipeline__c,
                                              Estimated_Hardware__c, EstimatedProfessionalServices12Month__c, Estimated_12M_RingCentral_Video_Pipeline__c, Estimated_12M_Total_Pipeline__c
                                       FROM Opportunity
                                       WHERE Id =: opportunityWithoutValues.id];
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Office_Pipeline__c, 'Value should be 0 since there was no Forecasted_Users__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Contact_Center_Pipeline__c, 'Value should be 0 since there was no Forecast_Contact_Center_Users__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Engage_Digital_Pipeline__c, 'Value should be 0 since there was no ForcastedDimeloUsers__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Engage_Voice_Pipeline__c, 'Value should be 0 since there was no Forecast_Connect_First_Users__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Global_Office_Pipeline__c, 'Value should be 0 since there was no Forecasted_Global_Office_Users__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_Hardware__c, 'Value should be 0 since there was no Estimated_Hardware__c value');
        System.assertEquals(0, oppWithNoValues.EstimatedProfessionalServices12Month__c, 'Value should be 0 since there was no EstimatedProfessionalServices12Month__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_RingCentral_Video_Pipeline__c, 'Value should be 0 since there was no Forecasted_RingCentral_Video_Users__c value');
        System.assertEquals(0, oppWithNoValues.Estimated_12M_Total_Pipeline__c, 'Value should be 0 since there was no values for any category');

        Opportunity opportunityWithValues = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.Name => 'Test1',
                Opportunity.Brand_Name__c => OpportunityHelper.BRAND_RINGCENTRAL,
                Opportunity.Type => OpportunityHelper.OPPORTUNITY_TYPE_EX_BUSINESS,
                Opportunity.RecordTypeId => OpportunityHelper.RT_ID_NEW_SALES_OPPORTUNITY,
                Opportunity.AccountId => acc.Id,
                Opportunity.Is_Billing_Opportunity__c => true,
                Opportunity.StageName => OpportunityHelper.STAGE_NAME_QUALIFY,
                Opportunity.CloseDate => system.today().addMonths(1),
                Opportunity.Primary_Opportunity_Contact__c => cont.Id,
                Opportunity.CurrencyIsoCode => RingCentralHelper.USD,
                Opportunity.Tier_Name__c => 'Contact Center',
                Opportunity.Forecasted_Users__c => 1,
                Opportunity.Forecast_Contact_Center_Users__c => 1,
                Opportunity.Forecasted_Global_Office_Users__c => 1,
                Opportunity.Estimated_Hardware__c => 10,
                Opportunity.EstimatedProfessionalServices12Month__c => 20
            })
            .create()
            .getRecord();

        Opportunity oppWithValues = [SELECT id, Estimated_12M_Office_Pipeline__c, Estimated_12M_Contact_Center_Pipeline__c,
                                                Estimated_12M_Engage_Digital_Pipeline__c, Estimated_12M_Engage_Voice_Pipeline__c, Estimated_12M_Global_Office_Pipeline__c,
                                                Estimated_Hardware__c, EstimatedProfessionalServices12Month__c, Estimated_12M_RingCentral_Video_Pipeline__c, Estimated_12M_Total_Pipeline__c
                                       FROM Opportunity
                                       WHERE Id =: opportunityWithValues.id];

        System.assertEquals(1799.88, oppWithValues.Estimated_12M_Office_Pipeline__c, 'Value should be 1799.88 since 12 * Forecasted_Users__c * 149.99');
        System.assertEquals(1799.88, oppWithValues.Estimated_12M_Contact_Center_Pipeline__c, 'Value should be 1799.88 since 12 * Forecast_Contact_Center_Users__c * 149.99');
        System.assertEquals(1799.88, oppWithValues.Estimated_12M_Global_Office_Pipeline__c, 'Value should be 1799.88 since 12 * Forecasted_Global_Office_Users__c * 149.99');
        System.assertEquals(10, oppWithValues.Estimated_Hardware__c, 'Value should be 10 since value was set to 10');
        System.assertEquals(20, oppWithValues.EstimatedProfessionalServices12Month__c, 'Value should be 20 since value was set to 20');
        System.assertEquals(5399.64, oppWithValues.Estimated_12M_Total_Pipeline__c, '5399.64 should be the total without hardware & proserv');

        oppWithValues.Forecasted_Users__c = 0;
        oppWithValues.Forecast_Contact_Center_Users__c = 0;
        oppWithValues.Forecasted_Global_Office_Users__c = 0;
        oppWithValues.Estimated_Hardware__c = 0;
        oppWithValues.EstimatedProfessionalServices12Month__c = 0;

        update oppWithValues;

        Opportunity updatedOpp = [SELECT id, Estimated_12M_Office_Pipeline__c, Estimated_12M_Contact_Center_Pipeline__c,
                                            Estimated_12M_Engage_Digital_Pipeline__c, Estimated_12M_Engage_Voice_Pipeline__c, Estimated_12M_Global_Office_Pipeline__c,
                                            Estimated_Hardware__c, EstimatedProfessionalServices12Month__c, Estimated_12M_RingCentral_Video_Pipeline__c, Estimated_12M_Total_Pipeline__c, stagename
                                     FROM Opportunity
                                     WHERE Id =: oppWithValues.id];

        System.assertEquals(0, updatedOpp.Estimated_12M_Office_Pipeline__c, 'Value should be 0 since there was no Forecasted_Users__c value');
        System.assertEquals(0, updatedOpp.Estimated_12M_Contact_Center_Pipeline__c, 'Value should be 0 since there was no Forecast_Contact_Center_Users__c value');
        System.assertEquals(0, updatedOpp.Estimated_12M_Engage_Digital_Pipeline__c, 'Value should be 0 since there was no ForcastedDimeloUsers__c value');
        System.assertEquals(0, updatedOpp.Estimated_12M_Engage_Voice_Pipeline__c, 'Value should be 0 since there was no Forecast_Connect_First_Users__c value');
        System.assertEquals(0, updatedOpp.Estimated_12M_Global_Office_Pipeline__c, 'Value should be 0 since there was no Forecasted_Global_Office_Users__c value');
        System.assertEquals(0, updatedOpp.Estimated_Hardware__c, 'Value should be 0 since there was no Estimated_Hardware__c value');
        System.assertEquals(0, updatedOpp.EstimatedProfessionalServices12Month__c, 'Value should be 0 since there was no EstimatedProfessionalServices12Month__c value');

        updatedOpp.stagename = '3. Solution';
        updatedOpp.Forecasted_Users__c = 1;
        update updatedOpp;

        System.assertEquals(0, updatedOpp.Estimated_12M_Office_Pipeline__c, 'Value should be 0 since there was no quote on the opp');
        System.assertEquals(0, updatedOpp.Estimated_12M_Total_Pipeline__c, 'Value should be 0 since there was no values for any category');

        updatedOpp.Tier_Name__c = 'RC Meetings';
        updatedOpp.Forecasted_RingCentral_Video_Users__c = 1;
        update updatedOpp;

        updatedOpp = [SELECT id, Forecasted_Users__c
                      FROM Opportunity
                      WHERE Id =: oppWithValues.id];

        system.assertEquals(0, updatedOpp.Forecasted_Users__c, 'Forecasted Users should be 0 since a change on service was performed');

        updatedOpp.Tier_Name__c = 'Engage Voice StandAlone';
        updatedOpp.Forecast_Connect_First_Users__c = 1;
        update updatedOpp;

        updatedOpp = [SELECT id, Forecasted_RingCentral_Video_Users__c
                      FROM Opportunity
                      WHERE Id =: oppWithValues.id];

        system.assertEquals(0, updatedOpp.Forecasted_RingCentral_Video_Users__c, 'Forecasted Video Users should be 0 since a change on service was performed');

        updatedOpp.Tier_Name__c = 'Engage Digital StandAlone';
        updatedOpp.ForcastedDimeloUsers__c = 1;
        update updatedOpp;

        updatedOpp = [SELECT id, Forecast_Connect_First_Users__c
                      FROM Opportunity
                      WHERE Id =: oppWithValues.id];

        system.assertEquals(0, updatedOpp.Forecast_Connect_First_Users__c, 'Forecasted Voice Users should be 0 since a change on service was performed');
        Test.stopTest();
    }
}
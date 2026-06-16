@isTest
private class Test_DealQualificationDiscountSelector {

    @isTest
    private static void testSelectDQDiscountsForSync() {

        Opportunity opp = (Opportunity) new SObjectBuilder(Opportunity.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                Opportunity.AccountId => ValueProviderBuilder.provideGenericParent(Account.SObjectType),
                Opportunity.Name => ValueProviderBuilder.provideUniqueString('test opportunity')
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification__c testDqRecord = (DQ_Deal_Qualification__c) new SObjectBuilder(DQ_Deal_Qualification__c.SObjectType)
            .setFields(new Map<SObjectField, Object>{
                DQ_Deal_Qualification__c.Opportunity__c => opp.Id
            })
            .create()
            .getRecord();

        DQ_Deal_Qualification_Discounts__c dqDiscount = (DQ_Deal_Qualification_Discounts__c) new SObjectBuilder(DQ_Deal_Qualification_Discounts__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    DQ_Deal_Qualification_Discounts__c.Deal_Qualification__c => testDqRecord.Id,
                    DQ_Deal_Qualification_Discounts__c.Product_Category__c => 'GOA_All_Contact_Center',
                    DQ_Deal_Qualification_Discounts__c.RecordTypeId => DQServiceHelper.DQ_CC_RECORD_TYPE_ID,
                    DQ_Deal_Qualification_Discounts__c.Quantity__c => 10,
                    DQ_Deal_Qualification_Discounts__c.Discount__c => 5,
                    DQ_Deal_Qualification_Discounts__c.Discount_Type__c => QuoteLineItemHelper.DISCOUNT_TYPE_PERCENTAGE
                }
            )
            .create()
            .getRecord();

        DealQualificationDiscountSelector dqDiscountsSelector = new DealQualificationDiscountSelector();

        List<Schema.SObjectField> fieldsForSync = new List<Schema.SObjectField>(dqDiscountsSelector.getDefaultFieldList());
        fieldsForSync.addAll(dqDiscountsSelector.getFieldsForDqSync());
        List<String> fieldNameList = new List<String>();
        for (Schema.SObjectField field : fieldsForSync) {
            fieldNameList.add(field.getDescribe().getName());
        }

        List<DQ_Deal_Qualification_Discounts__c> dqDiscountsList = dqDiscountsSelector
            .selectDQDiscountsForSync()
            .executeQuery();

        DQ_Deal_Qualification_Discounts__c dqDiscountRecord = dqDiscountsList.get(0);

        Map<String, Object> fieldNameToValueMap = dqDiscountRecord.getPopulatedFieldsAsMap();
        for (String populatedField : fieldNameToValueMap.keySet()) {
            System.assert(
                fieldNameList.contains(populatedField),
                'required field are not populated: "' + populatedField + '"'
            );
        }


        dqDiscountsList = dqDiscountsSelector
            .selectAllFieldsForCloning(new List<Object>{ new Set<Id>{testDqRecord.Id} })
            .executeQuery();

        System.assertEquals(
            1,
            dqDiscountsList.size(),
            'selector should return 1 record'
        );
    }
}
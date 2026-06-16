public inherited sharing class InvocaSelector extends SObjectSelector {

    public override Schema.SObjectType getSObjectType()  {
        return INVOCA_FOR_SF__Invoca_Call_Log__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            INVOCA_FOR_SF__Invoca_Call_Log__c.Id,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__calling_phone_number__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_2__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_3__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_15__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_Business_Object_Value_3__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Opportunity__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Contact__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Account__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Lead__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_6__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_7__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_10__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_5__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_4__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_11__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_8__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__destination_phone_number__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__transaction_id__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_16__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_19__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_13__c,
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_17__c, 
            INVOCA_FOR_SF__Invoca_Call_Log__c.INVOCA_FOR_SF__Customer_String_Value_9__c
        };
    }

    public Set<String> getInvocaFields() {
        Set<String> setInvocaFields = new Set<String>();
        List<Fields_Mapping__mdt> mappings = FieldMappingEngine.getFieldsMappingsForObject('INVOCA_FOR_SF__Invoca_Call_Log__c');
        for (Fields_Mapping__mdt fieldMapping : mappings) {
            setInvocaFields.add(fieldMapping.Source__c.substringAfter('.'));
        }
        return setInvocaFields;
    }

    public QueryFactory selectInvocaRecordById(Object binding) {
        return newQueryFactory()
                .setFactoryName('selectInvocaRecordById')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getInvocaFields())
                .setCondition('INVOCA_FOR_SF__transaction_id__c =: bind0')
                .setQueryBindings(binding)
                .setLimit(1);
    }

    public QueryFactory selectInvocaRecordByCallerId(Object binding) {
        return newQueryFactory()
                .setFactoryName('selectInvocaRecordByCallerId')
                .withSelectorFieldsIncluded()
                .withoutSelectorOrderByIncluded()
                .selectFields(getInvocaFields())
                .setCondition('INVOCA_FOR_SF__calling_phone_number__c =: bind0')
                .setQueryBindings(binding)
                .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
                .setLimit(1);
    }

}
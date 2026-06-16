public with sharing class SaasquatchUserSelector extends SObjectSelector {
    public override Schema.SObjectType getSObjectType()  {
        return saasquatch__SaaSquatch_User__c.SObjectType;
    }

    public List<String> getContactFieldListForSaasquatchReferrals() {
        List<String> fieldsList = new List<String>();
        List<ReferralProgramFieldMapping__mdt> programs = ReferralProgramFieldMapping__mdt.getAll().values();
        for (ReferralProgramFieldMapping__mdt program: programs) {
            if(program.isMapedToContact__c){
                fieldsList.add('saasquatch__Contact__r.' + program.FieldAPIName__c);
            }
        }
        return fieldsList;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField> {
            saasquatch__SaaSquatch_User__c.Id,
            saasquatch__SaaSquatch_User__c.Name,
            saasquatch__SaaSquatch_User__c.saasquatch__Account_Id__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Contact__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Email__c,
            saasquatch__SaaSquatch_User__c.saasquatch__First_Name__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Lead__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Referral_Code__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Referral_Link__c,
            saasquatch__SaaSquatch_User__c.saasquatch__User_Id__c,
            saasquatch__SaaSquatch_User__c.saasquatch__Last_Name__c
        };
    }

    public QueryFactory selectUsersByReferralCode(List<Object> binding) {
        return newQueryFactory()
            .setFactoryName('selectUsersByReferralCode')
            .withSelectorFieldsIncluded()
            .setCondition('saasquatch__Referral_Code__c IN :bind0')
            .setQueryBindings(binding);
    }

    public QueryFactory selectUsersByContactCode(List<Object> bindings, String condition) {
        return newQueryFactory()
            .setFactoryName('selectUsersByContactCode')
            .withSelectorFieldsIncluded()
            .selectFields(getContactFieldListForSaasquatchReferrals())
            .setCondition(condition)
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectUsersById(List<Object> binding) {
        return newQueryFactory()
            .setFactoryName('selectUserByID')
            .withSelectorFieldsIncluded()
            .setCondition('Id IN :bind0')
            .setQueryBindings(binding);
    }
    
}
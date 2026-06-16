public class LocalSubscribedAddressHelper {
    public static final Schema.describeSObjectResult DESCRIBE = LocalSubscribedAddress__c.SObjectType.getDescribe();
    public static final Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
    public static final Map<String,Schema.SObjectField> FIELDS_MAP = LocalSubscribedAddress__c.SObjectType.getDescribe()?.fields.getMap();

    public static final String RT_NAME_REGISTERED_ADDRESS_OF_COMPANY = 'Registered Address of Company';
    public static final Id RT_ID_REGISTERED_ADDRESS_OF_COMPANY = RT_INFO_BY_NAME.get(RT_NAME_REGISTERED_ADDRESS_OF_COMPANY).getRecordTypeId();

    public static final String RT_NAME_BILLING_ADDRESS = 'Billing Address';
    public static final Id RT_ID_BILLING_ADDRESS = RT_INFO_BY_NAME.get(RT_NAME_BILLING_ADDRESS).getRecordTypeId();
    public static final String RECORD_NAME_BILLING_ADDRESS_SYSTEM = 'Billing Address (System)';

    public static final List<String> PRESERVE_TIMESTAMPS = new List<String>{'createddate', 'lastmodifiedbyid', 'lastmodifieddate', 'createdbyid'};

    public static Map<Id, LocalSubscribedAddress__c> getApprovalLocalSubscribedAddressesMap(Id recordtypeId, Set<Id> approvalIds) {
        Map<Id, LocalSubscribedAddress__c> approvalIdToLocalSubscribedAddressesMap = new Map<Id, LocalSubscribedAddress__c>();
        List<LocalSubscribedAddress__c> listLsa = new LocalSubscribedAddressSelector()
            .selectLocalSubscribedAddressesByApprovals(recordtypeId, new List<Object>{ approvalIds })
            .executeQuery();
        if (!listLsa.isEmpty()) {
            for (LocalSubscribedAddress__c lsa : listLsa) {
                approvalIdToLocalSubscribedAddressesMap.put(lsa.Approval__c, lsa);
            }
        }
        return approvalIdToLocalSubscribedAddressesMap;
    }

    public static LocalSubscribedAddress__c createBillingAddress(Account acc, Approval__c app) {
        LocalSubscribedAddress__c lsaBillAddress = (LocalSubscribedAddress__c) new SObjectBuilder(LocalSubscribedAddress__c.sObjectType)
            .setFields(new Map<SObjectField, Object>{
                LocalSubscribedAddress__c.Approval__c => app.Id,
                LocalSubscribedAddress__c.Name => RECORD_NAME_BILLING_ADDRESS_SYSTEM,
                LocalSubscribedAddress__c.City__c => acc.BillingCity,
                LocalSubscribedAddress__c.District__c => acc.BillingCountry,
                LocalSubscribedAddress__c.PinCode__c => acc.BillingPostalCode,
                LocalSubscribedAddress__c.State__c => acc.BillingState,
                LocalSubscribedAddress__c.StreetAddress__c => acc.BillingStreet,
                LocalSubscribedAddress__c.RecordTypeId => RT_ID_BILLING_ADDRESS
            })
            .build()
            .getRecord();
        return lsaBillAddress;
    }
}
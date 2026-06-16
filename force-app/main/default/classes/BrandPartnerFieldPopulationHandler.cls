public abstract inherited sharing class BrandPartnerFieldPopulationHandler extends Triggers.TriggerHandlerBase
{
    public static final List<SObjectType> relatedSoTypes = new List<SObjectType>{
        Agent_Credit__c.sObjectType,
        Approval__c.sObjectType,
        Demand_Funnel__c.sObjectType,
        Implementation__c.sObjectType,
        Order__c.sObjectType,
        Phase__c.sObjectType
    };
    public static final List<SObjectType> TYPES_TO_SKIP_ON_CONVERT_LEAD = new List<SObjectType>{
        Approval__c.sObjectType,
        Demand_Funnel__c.sObjectType
    };
    private SObjectType soType;
    private SObjectField accountField;
    private SObjectField brandPartnerField;

    public BrandPartnerFieldPopulationHandler(SObjectType soType) {
        super();
        this.soType = soType;
        Map<String, SObjectField> fieldsMap = this.soType.getDescribe().fields.getMap();
        this.accountField = fieldsMap.get('Account__c');
        this.brandPartnerField = fieldsMap.get('Brand_Partner__c');
    }

    override public void handle() {
        List<SObject> changedRecords = new List<SObject>();

        // on convert lead, 
        if (ConvertLead.isLeadBeingConverted && Trigger.isInsert && TYPES_TO_SKIP_ON_CONVERT_LEAD.contains(this.soType)) {
            return;
        }

        // find changed records
        List<Id> changedAccIds = new List<Id>();
        for (SObject record : this.triggerRecords) {
            if (isChangedField(record, accountField)) {
                if (record.get(accountField) != null) {
                    changedRecords.add(record);
                    changedAccIds.add((Id)record.get(accountField));
                } else {
                    record.put(brandPartnerField, 'None');
                }
            }
        }

        if (changedRecords.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsMap = new Map<Id, Account>((List<Account>)new AccountSelector()
            .selectAccountsByIds(new List<Object>{changedAccIds})
            .selectField(Account.RC_Brand__c)
            .executeQuery());
        
        for (SObject record : changedRecords) {
            record.put(brandPartnerField, getBrandPartnerValue(accountsMap.get((Id)record.get(accountField))));
        }
    }

    public static String getBrandPartnerValue(Account acc) {
        return acc.RC_Brand__c == RingCentralHelper.BRAND_AVAYA
            ? 'Avaya'
            : 'None';
    }

    public static QueryFactory getRelatedRecordsQuery(SObjectType soType) {
        return new QueryFactory(soType)
            .selectField(soType.getDescribe().isCustom()
                ? 'Account__r.RC_Brand__c'
                : 'Account.RC_Brand__c')
            .selectField('Brand_Partner__c');
    }

}
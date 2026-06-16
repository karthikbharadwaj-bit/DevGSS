public inherited sharing class CPUMonitorSelector extends SObjectSelector {
    public CPUMonitorSelector() {
        super();
    }

    public override Schema.SObjectType getSObjectType() {
        return CPU_Monitor__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFieldList() {
        return new List<Schema.SObjectField>{
            CPU_Monitor__c.Id,
            CPU_Monitor__c.CPU_Usage__c,
            CPU_Monitor__c.Transaction_Type__c,
            CPU_Monitor__c.Error__c
        };
    }

    public static List<String> getLeadConversionMonitoringFields() {
        return new List<String>{
            'Create_Account__c',
            'Create_Opportunity__c',
            'Create_Quotes__c',
            'Is_ELA_Account__c',
            'SOQL_Queries__c',
            'Opportunity__c',
            'Account__c',
            'Contact__c',
            'Error_Part__c',
            'CreatedDate',
            'Lead_Type__c'
        };
    }

    public QueryFactory selectCPUMonitorByTransactionType(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCPUMonitorByTransactionType')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Transaction_Type__c = :bind0')
            .setQueryBindings(bindings);
    }
    
    public QueryFactory selectCPUMonitorForSendingEmail(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCPUMonitorByTransactionType')
            .withSelectorFieldsIncluded()
            .withoutSelectorOrderByIncluded()
            .setCondition('Transaction_Type__c = :bind0 AND Error__c != \'\'')
            .addOrdering(CPU_Monitor__c.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .selectFields(new List<Schema.SObjectField>{
                CPU_Monitor__c.Id,
                CPU_Monitor__c.Name,
                CPU_Monitor__c.Lead_Type__c,
                CPU_Monitor__c.Error__c,
                CPU_Monitor__c.CreatedDate,
                CPU_Monitor__c.Lead__c
            })
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectCPUMonitorForLeadConversionMonitor(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCPUMonitorForLeadConversionMonitor')
            .withSelectorFieldsIncluded()
            .selectFields(getLeadConversionMonitoringFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Lead__c = :bind0 AND Transaction_Type__c = \'Lead Conversion\'')
            .addOrdering(CPU_Monitor__c.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setLimit(1)
            .setQueryBindings(bindings);
    }

    public QueryFactory selectLastErrorLeadConversionCPUMonitor() {
        return newQueryFactory()
            .setFactoryName('selectLastErrorLeadConversionCPUMonitor')
            .withSelectorFieldsIncluded()
            .selectFields(getLeadConversionMonitoringFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Transaction_Type__c = \'Lead Conversion\' AND Error__c != \'\'')
            .addOrdering(CPU_Monitor__c.CreatedDate, QueryFactory.SortOrder.DESCENDING)
            .setLimit(1);
    }

    public QueryFactory selectCPUMonitorById(List<Object> bindings) {
        return newQueryFactory()
            .setFactoryName('selectCPUMonitorById')
            .withSelectorFieldsIncluded()
            .selectFields(getLeadConversionMonitoringFields())
            .withoutSelectorOrderByIncluded()
            .setCondition('Id = :bind0')
            .setLimit(1)
            .setQueryBindings(bindings);
    }
}
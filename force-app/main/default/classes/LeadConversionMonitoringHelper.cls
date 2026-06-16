public with sharing class LeadConversionMonitoringHelper {
    public static final String VALIDATION_ERROR = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
    public static final String LIMIT_EXCEPTION = 'System.LimitException';
    public static final String SOQL_EXCEPTION = 'Too many SOQL queries';
    public static final String CPU_EXCEPTION = 'Apex CPU time limit exceeded';
    public static final String CREATE_ACCOUNT = 'CreateAccount';
    public static final String EXISTING_ACCOUNT = 'ExistingAccount';
    public static final String CREATE_OPPORTUNITY = 'CreateOpportunity';
    public static final String EXISTING_OPPORTUNITY = 'ExistingOpportunity';
    public static final String ACCOUNT_NAME = 'Account';
    public static final String OPPORTUNITY_NAME = 'Opportunity';

    public static final Map<Integer, String> mapConvertPart = new Map<Integer, String>{
        0 => 'prepareLeadRecord',
        1 => 'convertPart1',
        2 => 'convertPart2',
        3 => 'convertPart3',
        4 => 'convertPart4'
    };

    public static final Map<Integer, String> mapConvertPartToNode = new Map<Integer, String>{
        0 => 'PrepareLead',
        1 => 'ConvertLead',
        3 => 'CreateQuotes',
        4 => 'ELAAccount'
    };

    public static void processTrigger(List<Lead_Conversion_Monitoring__e> events) {
        List<CPU_Monitor__c> cpuMonitorList = (List<CPU_Monitor__c>) new CPUMonitorSelector()
            .selectCPUMonitorForLeadConversionMonitor(new List<Object>{ events[0].LeadId__c })
            .executeQuery();

        CPU_Monitor__c cpuMonitor;
        Boolean isValidationError = false;
        if (cpuMonitorList.isEmpty() || events[0].Convert_Part__c == 0) {
            String today = '' + Date.today().month() + '-' + Date.today().day();
            List<Lead> leadList = (List<Lead>) new LeadSelector()
                .selectLeadForConvert(new List<Object>{ events[0].LeadId__c })
                .executeQuery();
            Lead leadToConvert = leadList.get(0);
            cpuMonitor = new CPU_Monitor__c(
                Name = 'Monitor Lead Conversion ' + today,
                CPU_Usage__c = 0,
                SOQL_Queries__c = 0,
                Transaction_Type__c = 'Lead Conversion',
                Opportunity__c = events[0].OpportunityId__c,
                Lead__c = events[0].LeadId__c,
                Contact__c = events[0].ContactId__c,
                Account__c = events[0].AccountId__c,
                Create_Account__c = events[0].Create_Account__c,
                Create_Opportunity__c = events[0].Create_Opportunity__c,
                Create_Quotes__c = events[0].Create_Quotes__c,
                Is_ELA_Account__c = events[0].Is_ELA_Account__c,
                RecordTypeId = Schema.SObjectType.CPU_Monitor__c.RecordTypeInfosByName.get('Lead Conversion')
                    .RecordTypeId,
                Lead_Type__c = leadToConvert?.RecordTypeId == LeadHelper.RT_ID_SALES_LEADS
                    ? LeadHelper.RT_NAME_SALES_LEADS
                    : LeadHelper.RT_NAME_PARTNER_LEADS
            );
        } else {
            cpuMonitor = cpuMonitorList[0];
        }

        Integer convertPart;
        if (events[0].Error_Type__c == LIMIT_EXCEPTION) {
            for (Integer part : mapConvertPart.keySet()) {
                if (
                    String.isNotEmpty(events[0].Error_stacktrace__c) &&
                    events[0].Error_stacktrace__c.contains(mapConvertPart.get(part))
                ) {
                    convertPart = part;
                }
            }
            if (events[0].Error__c?.contains(SOQL_EXCEPTION)) {
                cpuMonitor.SOQL_Queries__c = 101;
                cpuMonitor.Queries_Convert_part__c = mapConvertPart.get(convertPart);
            } else if (events[0].Error__c.contains(CPU_EXCEPTION)) {
                cpuMonitor.CPU_Usage__c = 10000;
                cpuMonitor.CPU_Convert_part__c = mapConvertPart.get(convertPart);
            }
        } else {
            convertPart = (Integer) events[0].Convert_Part__c;
            if (cpuMonitor.CPU_Usage__c < events[0].CPU_Time__c) {
                cpuMonitor.CPU_Usage__c = events[0].CPU_Time__c;
                cpuMonitor.CPU_Convert_part__c = mapConvertPart.get(convertPart);
            }
            if (cpuMonitor.SOQL_Queries__c < events[0].SOQL_Queries__c) {
                cpuMonitor.SOQL_Queries__c = events[0].SOQL_Queries__c;
                cpuMonitor.Queries_Convert_part__c = mapConvertPart.get(convertPart);
            }
        }

        if (events[0].Error__c != null) {
            if (events[0].Error__c.contains(VALIDATION_ERROR)) {
                isValidationError = true;
            } else {
                cpuMonitor.Error__c = events[0].Error__c;
                cpuMonitor.Error_Type__c = events[0].Error_Type__c;
                cpuMonitor.Error_stacktrace__c = events[0].Error_stacktrace__c;
                if (mapConvertPart.get(convertPart) != 'convertPart2') {
                    cpuMonitor.Error_Part__c = mapConvertPartToNode.get(convertPart);
                    if (convertPart == 3) {
                        cpuMonitor.Notes__c = 'Lead was converted to Opportunity. Quote Creation failed.';
                    } else if (convertPart == 4) {
                        cpuMonitor.Notes__c = 'Lead was converted to Opportunity. ELA Account processing failed.';
                    }
                } else {
                    if (
                        events[0].Convert_Part_Node__c == ACCOUNT_NAME || String.isEmpty(events[0].Convert_Part_Node__c)
                    ) {
                        if (events[0].Error_Type__c == LIMIT_EXCEPTION) {
                            cpuMonitor.Notes__c = 'Lead was converted to Opportunity. Error found in Field Mapping or Contact Role creation.';
                        }
                        if (cpuMonitor.Create_Account__c) {
                            cpuMonitor.Error_Part__c = CREATE_ACCOUNT;
                        } else {
                            cpuMonitor.Error_Part__c = EXISTING_ACCOUNT;
                        }
                    } else if (events[0].Convert_Part_Node__c == OPPORTUNITY_NAME) {
                        if (cpuMonitor.Create_Opportunity__c) {
                            cpuMonitor.Error_Part__c = CREATE_OPPORTUNITY;
                        } else {
                            cpuMonitor.Error_Part__c = EXISTING_OPPORTUNITY;
                        }
                    }
                }
            }
        }
        try {
            if (isValidationError) {
                if (events[0].Convert_Part__c != 0 && !cpuMonitorList.isEmpty()) {
                    delete cpuMonitor;
                }
            } else {
                upsert cpuMonitor;
            }
        } catch (Exception e) {
            ExceptionHelper.createExceptionAndNotificacionHistory(e, cpuMonitor, 'Lead Conversion Exception');
        }
    }

    public static void publishLeadConversionPlatformEvent(
        Integer cpuTime,
        Integer soqlQueries,
        Id accId,
        Id conId,
        Id oppId,
        Id leadId,
        Integer convertPart,
        String errorMsg,
        String errorStacktrace,
        Boolean createAccount,
        Boolean createOpportunity,
        Boolean createQuotes,
        Boolean isElaAccount,
        String convertPartNode
    ) {
        PlatformEvents.publishPlatformEvent(
            new Lead_Conversion_Monitoring__e(
                CPU_Time__c = cpuTime,
                SOQL_Queries__c = soqlQueries,
                AccountId__c = accId,
                ContactId__c = conId,
                OpportunityId__c = oppId,
                LeadId__c = leadId,
                Convert_Part__c = convertPart,
                Error__c = errorMsg,
                Error_stacktrace__c = errorStacktrace,
                Create_Account__c = createAccount,
                Create_Opportunity__c = createOpportunity,
                Create_Quotes__c = createQuotes,
                Is_ELA_Account__c = isElaAccount,
                Convert_Part_Node__c = convertPartNode
            ),
            'LeadConversionMonitoring'
        );
    }

    @AuraEnabled
    public static CPU_Monitor__c getLastErrorLeadConversionCPUMonitor() {
        try {
            List<CPU_Monitor__c> listCPUMonitor = (List<CPU_Monitor__c>) new CPUMonitorSelector()
                .selectLastErrorLeadConversionCPUMonitor()
                .executeQuery();
            return listCPUMonitor.isEmpty() ? null : listCPUMonitor[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static CPU_Monitor__c getCPUMonitorByRecordId(Id recordId) {
        try {
            List<CPU_Monitor__c> listCPUMonitor = (List<CPU_Monitor__c>) new CPUMonitorSelector()
                .selectCPUMonitorById(new List<Object>{ recordId })
                .executeQuery();
            return listCPUMonitor.isEmpty() ? null : listCPUMonitor[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
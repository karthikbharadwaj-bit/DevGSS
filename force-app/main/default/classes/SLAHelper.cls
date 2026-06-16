public with sharing class SLAHelper {
    public static Map<String, SLA__c> loadSLAByServiceTypeForAccount(Id accountId) {
        Map<String, SLA__c> mapSLAByServiceType = new Map<String, SLA__c>();
        List<SLA__c> listSLA = new SLASelector()
            .selectSLAsForAccount(new List<Object>{
                accountId
            })
            .executeQuery();

        for (SLA__c sla : listSLA) {
            mapSLAByServiceType.put(sla.ServiceType__c, sla);
        }

        return mapSLAByServiceType;
    }

    public static Approval__c loadApproval(Id approvalId) {
        List<Approval__c> listApproval = new ApprovalSelector()
            .selectApprovalByIdForSLA(new List<String>{
                approvalId
            })
            .executeQuery();

        return listApproval.size() > 0 ? listApproval.get(0) : null;
    }

    public static SLA__c loadSLAById(Id slaId) {
        List<SLA__c> listSLA = new SLASelector()
            .selectSLAById(new List<String>{
                slaId
            })
            .executeQuery();

        return listSLA.size() > 0 ? listSLA.get(0) : null;
    }

    public static List<SLA__c> loadMultipleSLAsById(Set<Id> slaIds) {
        List<SLA__c> listSLA = new SLASelector()
            .selectMultipleSLAById(new List<Object>{
                slaIds
            })
            .executeQuery();

        return listSLA;
    }

    public static Map<String, SLAController.ServiceLevelAgreement> getStandardSLAsByServiceType() {
        Map<String, SLASettings__c> slaDefaults = SLASettings__c.getAll();
        Map<String, SLAController.ServiceLevelAgreement> standardSLAs = new Map<String, SLAController.ServiceLevelAgreement>();

        for (String st : slaDefaults.keySet()) {
            SLAController.ServiceLevelAgreement sla = new SLAController.ServiceLevelAgreement(slaDefaults.get(st));

            standardSLAs.put(st, sla);
        }

        return standardSLAs;
    }

    public static SLAController.ServiceLevelAgreement getStandardSLA(String serviceType) {
        SLASettings__c slaDefaults = SLASettings__c.getInstance(serviceType);

        if (slaDefaults == null) {
            return null;
        }

        SLAController.ServiceLevelAgreement sla = new SLAController.ServiceLevelAgreement(slaDefaults);
        return sla;
    }

    public static SLA__c saveSLA(SLAController.ServiceLevelAgreement request) {
        SLA__c sla = request.getSLA();
        upsert sla;

        List<SLACreditChart__c> sccToCreate = new List<SLACreditChart__c>();
        for (SLAController.ServiceLevelAgreementCreditChart reqSCC : request.creditCharts) {
            SLACreditChart__c scc = reqSCC.getCreditChart(sla);

            sccToCreate.add(scc);
        }

        List<SLACreditChart__c> sccToDelete = new SLACreditChartSelector()
            .selectSLACreditChartsForSLA(new List<String>{
                sla.Id
            })
            .executeQuery();

        delete sccToDelete;
        insert sccToCreate;

        return loadSLAById(sla.Id);
    }

    public static Map<Id, Map<String, SLA__c>> getSLAsByAccountIdByServiceType(List<Approval__c> approvals) {
        List<Id> accountIds = new List<Id>();

        for (Approval__c approval : approvals) {
            accountIds.add(approval.Account__c);
        }

        Map<Id, Map<String, SLA__c>> slasByAccountId = new Map<Id, Map<String, SLA__c>>();
        List<SLA__c> accountSLAs = new SLASelector()
            .selectSLAsForAccounts(new List<Object>{
                accountIds
            })
            .executeQuery();

        for (SLA__c sla : accountSLAs) {
            if (!slasByAccountId.containsKey(sla.Account__c)) {
                slasByAccountId.put(sla.Account__c, new Map<String, SLA__c>());
            }
            slasByAccountId.get(sla.Account__c).put(sla.ServiceType__c, sla);
        }

        return slasByAccountId;
    }

    public static List<SLA__c> saveMultipleSLAs(List<SLAController.ServiceLevelAgreement> slaList) {
        Set<Id> slaIds = new Set<Id>();
        List<SLA__c> slaToCreate = new List<SLA__c>();

        if (slaList == null || slaList.size() == 0) {
            return new List<SLA__c>();
        }

        for (SLAController.ServiceLevelAgreement slaWrapper : slaList) {
            SLA__c sla = slaWrapper.getSLA();

            if (sla.Id != null) {
                slaIds.add(sla.Id);
            }

            slaToCreate.add(sla);
        }

        upsert slaToCreate;

        List<SLACreditChart__c> ccToDelete = new SLACreditChartSelector()
            .selectSLACreditChartsForMultipleSLA(new List<Object>{ slaIds })
            .executeQuery();

        delete ccToDelete;

        List<SLACreditChart__c> ccToCreate = new List<SLACreditChart__c>();

        for (SLAController.ServiceLevelAgreement slaWrapper : slaList) {
            SLA__c sla = slaWrapper.sla;

            for (SLAController.ServiceLevelAgreementCreditChart ccWrapper : slaWrapper.creditCharts) {
                SLACreditChart__c cc = ccWrapper.getCreditChart(sla);
                ccToCreate.add(cc);
            }

            slaIds.add(sla.Id);
        }

        insert ccToCreate;

        return loadMultipleSLAsById(slaIds);
    }
}
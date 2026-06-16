public without sharing class SLAController {
    public class MalformedSLACreditChartSettingsException extends Exception {
    }

    public class ServiceLevelAgreementCreditChart {
        @AuraEnabled public Decimal minAvailability;
        @AuraEnabled public Decimal maxAvailability;
        @AuraEnabled public Decimal credit;

        public SLACreditChart__c getCreditChart(SLA__c sla) {
            SLACreditChart__c slaCC = new SLACreditChart__c(
                SLA__c = sla.Id,
                MinAvailability__c = this.minAvailability,
                MaxAvailability__c = this.maxAvailability,
                SLACredit__c = this.credit
            );
            return slaCC;
        }
    }
    public class ServiceLevelAgreement {
        @AuraEnabled public Id id;
        @AuraEnabled public Id account;
        @AuraEnabled public Id engageLegal;
        @AuraEnabled public Boolean isStandard;
        @AuraEnabled public Integer minDowntime;
        @AuraEnabled public Integer unitSize;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public Boolean dollarToDollarCalculation;
        @AuraEnabled public Decimal maxCredit;
        @AuraEnabled public Decimal availability;
        @AuraEnabled public String availabilityUnit;
        @AuraEnabled public String serviceType;
        @AuraEnabled public String triggerType;
        @AuraEnabled public String triggerRelation;
        @AuraEnabled public Decimal triggerValue;
        @AuraEnabled public Integer strikeCount;
        @AuraEnabled public Integer strikePeriod;
        @AuraEnabled public Decimal strikeValue;
        @AuraEnabled public Integer sbStrikeCount;
        @AuraEnabled public Integer sbStrikePeriod;
        @AuraEnabled public Decimal sbStrikeValue;
        @AuraEnabled public String triggerFormula;
        @AuraEnabled public String calculationFormula;
        @AuraEnabled public List<ServiceLevelAgreementCreditChart> creditCharts;

        public SLA__c sla;

        public ServiceLevelAgreement(SLASettings__c standardSLA) {
            this.isStandard = true;
            this.serviceType = standardSLA.Name;
            this.minDowntime = Integer.valueOf(standardSLA.MinDowntime__c);
            this.unitSize = Integer.valueOf(standardSLA.UnitSize__c);
            this.sortOrder = Integer.valueOf(standardSLA.SortOrder__c);
            this.maxCredit = standardSLA.MaxCredit__c;
            this.availabilityUnit = standardSLA.AvailabilityUnits__c;
            this.dollarToDollarCalculation = false;
            this.calculationFormula = standardSLA.CalculationFormula__c;
            this.triggerType = standardSLA.Trigger__c;
            this.triggerRelation = standardSLA.TriggerRelation__c;
            this.triggerValue = standardSLA.TriggerValue__c;
            this.triggerFormula = standardSLA.TriggerFormula__c;
            this.strikeCount = Integer.valueOf(standardSLA.StrikeCount__c);
            this.strikePeriod = Integer.valueOf(standardSLA.StrikePeriod__c);
            this.strikeValue = standardSLA.StrikeValue__c;
            this.sbStrikeCount = 0;
            this.sbStrikePeriod = 0;
            this.sbStrikeValue = 0.0;
            this.creditCharts = this.getCreditCharts(standardSLA);
        }

        public ServiceLevelAgreement(SLASettings__c standardSLA, Account acc) {
            this(standardSLA);
            this.account = acc.Id;
        }

        public List<ServiceLevelAgreementCreditChart> getCreditCharts(SLASettings__c standardSLA) {
            List<ServiceLevelAgreementCreditChart> listCC = new List<ServiceLevelAgreementCreditChart>();

            if(standardSLA.CreditCharts__c == null) {
                return listCC;
            }

            List<String> creditChartRows = standardSLA.CreditCharts__c.split('\\r?\\n');
            for (String creditChartRow : creditChartRows) {
                List<String> creditChartValues = creditChartRow.split('[,;]\\s*');

                if(creditChartValues.size() == 3 &&
                    (creditChartValues.get(0) != null && creditChartValues.get(1) != null && creditChartValues.get(2) != null)) {
                    Decimal minAvailability = Decimal.valueOf(creditChartValues.get(0));
                    Decimal maxAvailability = Decimal.valueOf(creditChartValues.get(1));
                    Decimal credit = Decimal.valueOf(creditChartValues.get(2));

                    ServiceLevelAgreementCreditChart cc = new ServiceLevelAgreementCreditChart();
                    cc.minAvailability = minAvailability;
                    cc.maxAvailability = maxAvailability;
                    cc.credit = credit;

                    listCC.add(cc);
                } else {
                    throw new MalformedSLACreditChartSettingsException('Malformed Credit Chart value: ' + creditChartRow);
                }
            }

            return listCC;
        }

        public SLA__c getSLA() {
            this.sla = new SLA__c(
                Id = this.id,
                IsStandardSLA__c = this.isStandard,
                EngageLegal__c = this.engageLegal,
                Account__c = this.account,
                UnitSize__c = this.unitSize,
                DollarToDollarCalculation__c = this.dollarToDollarCalculation,
                MaxCredit__c = this.maxCredit,
                MinDowntime__c = this.minDowntime,
                AvailabilityUnits__c = this.availabilityUnit,
                ServiceType__c = this.serviceType,
                Trigger__c = this.triggerType,
                TriggerFormula__c = this.triggerFormula,
                CalculationFormula__c = this.calculationFormula,
                TriggerRelation__c = this.triggerRelation,
                TriggerValue__c = this.triggerValue,
                StrikeCount__c = this.strikeCount,
                StrikePeriod__c = this.strikePeriod,
                StrikeValue__c = this.strikeValue,
                SilverBulletStrikeCount__c = this.sbStrikeCount,
                SilverBulletStrikePeriod__c = this.sbStrikePeriod,
                SilverBulletStrikeValue__c = this.sbStrikeValue
            );

            return this.sla;
        }
    }

    @AuraEnabled
    public static Response getSLAById(Id slaId) {
        SLA__c sla = SLAHelper.loadSLAById(slaId);

        Response res = new Response();

        if(sla == null) {
            res.setData('record', null);

            return res;
        }

        Map<String, ServiceLevelAgreement> slaDefaultsByServiceType = SLAHelper.getStandardSLAsByServiceType();
        Map<String, SLA__c> accountSLAsByServiceType = SLAHelper.loadSLAByServiceTypeForAccount(sla.Account__c);

        res.setData('record', sla);
        res.setData('account', sla.Account__r);
        res.setData('existingSLAs', accountSLAsByServiceType);
        res.setData('standardSLAs', slaDefaultsByServiceType);

        return res;
    }

    @AuraEnabled
    public static Response getApprovalInfo(Id approvalId) {
        Approval__c approval = SLAHelper.loadApproval(approvalId);
        Map<String, SLA__c> mapSLAByServiceType = SLAHelper.loadSLAByServiceTypeForAccount(approval.Account__r.Id);
        Map<String, ServiceLevelAgreement> slaDefaultsByServiceType = SLAHelper.getStandardSLAsByServiceType();

        Response r = new Response();

        r.setData('approval', approval);
        r.setData('account', approval.Account__r);
        r.setData('existingSLAs', mapSLAByServiceType);
        r.setData('standardSLAs', slaDefaultsByServiceType);

        return r;
    }

    @AuraEnabled
    public static Response saveSLA(String data) {
        ServiceLevelAgreement req = (ServiceLevelAgreement) JSON.deserialize(data, ServiceLevelAgreement.class);

        SLA__c sla = SLAHelper.saveSLA(req);

        Response r = new Response();
        r.setData('record', sla);

        return r;
    }
}
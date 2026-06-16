public with sharing class PurchaseRestrictionPeriodSettings {
    public final String terminatedServiceName;
    public final String targetServiceName;
    public final Integer cooldownPeriodInMonths;

    public PurchaseRestrictionPeriodSettings(ServicePurchaseRestrictionPeriod__c settings) {
        this.terminatedServiceName = settings.TerminatedService__c;
        this.targetServiceName = settings.TargetService__c;
        this.cooldownPeriodInMonths = getPeriodValue(settings.MonthsPassed__c);
    }

    public static List<PurchaseRestrictionPeriodSettings> getSettings() {
        List<PurchaseRestrictionPeriodSettings> settings = new List<PurchaseRestrictionPeriodSettings>();
        for (ServicePurchaseRestrictionPeriod__c setting : ServicePurchaseRestrictionPeriod__c.getAll().values()) {
            settings.add(new PurchaseRestrictionPeriodSettings(setting));
        }
        return settings;
    }

    private Integer getPeriodValue(Decimal value) {
        Decimal safeNum = NumberHelper.toNumber(value);
        return safeNum < 0 ? 0 : safeNum.intValue();
    }
}
public class PackageTotalsSvc {
    private static final Integer MONTHS_IN_YEAR = 12;

    public static TotalsCalculator getCalculationStrategy(Package__c pckg, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
        if (pckg.Service_Type__c == QuoteHelper.NGBS_RCCC_PRODUCT) {
            return new RCCCCalculator(pckg, relatedOrders, accountsMap);
        } else if (pckg.Service_Type__c == QuoteHelper.NGBS_ENGAGE_DIGITAL_PRODUCT) {
            return new EngageDigitalCalculator(pckg, relatedOrders, accountsMap);
        } else if (pckg.Service_Type__c == QuoteHelper.NGBS_ENGAGE_VOICE_PRODUCT) {
            return new EngageVoiceCalculator(pckg, relatedOrders, accountsMap);
        } else if (pckg.Service_Type__c == QuoteHelper.NGBS_RCEVENTS_PRODUCT) {
            return new EventsCalculator(pckg, relatedOrders, accountsMap);
        } else {
            return new OfficeCalculator(pckg, relatedOrders, accountsMap);
        }
    }

    public abstract class TotalsCalculator {
        @TestVisible
        protected final Package__c record;
        @TestVisible
        protected final List<Order> relatedOrders;
        @TestVisible
        private final SObjectField serviceMRRField;
        @TestVisible
        private final Map<Id, Account> accountsMap;

        public TotalsCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap, SObjectField serviceMRRField) {
            this.record = record;
            this.relatedOrders = relatedOrders;
            this.accountsMap = accountsMap;
            this.serviceMRRField = serviceMRRField;
        }

        protected abstract void calculateServiceFields();

        public void calculateTotals() {
            calculateCommonTotals();
            calculateServiceFields();
        }

        private void calculateCommonTotals() {
            Decimal salesOrderMRS = 0;
            Decimal transportMRR = 0;
            Decimal acquisitionMRR = 0;
            Decimal serviceMRR = 0;
            record.MinuteBundle__c = 0;
            record.NumberOfMainLicenses__c = 0;

            for (Order relatedOrder : relatedOrders) {
                Boolean isAnnual = QuoteHelper.isAnnual(relatedOrder.Quote);

                record.MinuteBundle__c += NumberHelper.toNumber(relatedOrder.MinuteBundle__c);
                record.NumberOfMainLicenses__c += NumberHelper.toNumber(relatedOrder.NumberOfMainLicenses__c);
                salesOrderMRS += getMonthlyValue(relatedOrder.Recurring_total__c, isAnnual);
                transportMRR += getMonthlyValue(relatedOrder.TransportMRR__c, isAnnual);
                serviceMRR += getMonthlyValue(relatedOrder.SeatMRR__c, isAnnual);
                if (isNewBusiness(relatedOrder)) {
                    acquisitionMRR += getMonthlyValue(relatedOrder.Recurring_total__c, isAnnual);
                }
            }

            record.Sales_Order_MRS__c = salesOrderMRS;
            record.TransportMRR__c = transportMRR;
            record.AcquisitionMRR__c = NumberHelper.toNumber(record.AcquisitionMRR__c) + acquisitionMRR;
            setServiceMRRField(serviceMRR);
        }

        private Decimal getMonthlyValue(Decimal value, Boolean isAnnual) {
            value = NumberHelper.toNumber(value);
            return isAnnual ? value / MONTHS_IN_YEAR : value;
        }

        private Boolean isNewBusiness(Order relatedOrder) {
            // TODO: abstract this MPUB checks out, so that TotalsCalculator is not aware of Multiproduct flows
            Account acc = accountsMap.get(relatedOrder.AccountId);

            return AccountHelper.isMPUBAccount(acc.Id, acc.Master_Accounts__r)
                ? QuoteHelper.STATUS_NEW_CUSTOMER.equalsIgnoreCase(relatedOrder.Quote?.Upsell_Status__c)
                : !AccountHelper.isExistingBusiness(acc);
        }

        private void setServiceMRRField(Decimal serviceMRR) {
            if (serviceMRRField != null) {
                record.put(serviceMRRField, serviceMRR);
            }
        }
    }

    @TestVisible
    private class OfficeCalculator extends TotalsCalculator {
        public OfficeCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            super(record, relatedOrders, accountsMap, null);
        }

        protected override void calculateServiceFields() {
            // Office doesn't have any specific fields to calculate
        }
    }

    @TestVisible
    private class RCCCCalculator extends TotalsCalculator {
        public RCCCCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            super(record, relatedOrders, accountsMap, Package__c.SeatMRR__c);
        }

        protected override void calculateServiceFields() {
            record.No_of_InContact_Seats__c = record.NumberOfMainLicenses__c;
            record.AdditionalProductsMRR__c = record.Sales_Order_MRS__c - record.SeatMRR__c;
            record.Price_per_Seat__c = record.No_of_InContact_Seats__c > 0
               ? record.SeatMRR__c / record.No_of_InContact_Seats__c
               : 0;
        }
    }

    @TestVisible
    private class EngageDigitalCalculator extends TotalsCalculator {
        public EngageDigitalCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            super(record, relatedOrders, accountsMap, Package__c.EngageDigitalUserMRR__c);
        }

        protected override void calculateServiceFields() {
            record.NumberOfEngageDigitalUsers__c = record.NumberOfMainLicenses__c;
            record.EDAdditionalProductsMRR__c = record.Sales_Order_MRS__c - record.EngageDigitalUserMRR__c;
        }
    }

    @TestVisible
    private class EngageVoiceCalculator extends TotalsCalculator {
        public EngageVoiceCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            super(record, relatedOrders, accountsMap, Package__c.EngageVoiceUserMRR__c);
        }

        protected override void calculateServiceFields() {
            record.NumberOfEngageVoiceSeats__c = record.NumberOfMainLicenses__c;
            record.EVAdditionalProductsMRR__c = record.Sales_Order_MRS__c - record.EngageVoiceUserMRR__c;
        }
    }

    @TestVisible
    private class EventsCalculator extends TotalsCalculator {
        public EventsCalculator(Package__c record, List<Order> relatedOrders, Map<Id, Account> accountsMap) {
            super(record, relatedOrders, accountsMap, Package__c.Events_User_MRR__c);
        }

        protected override void calculateServiceFields() {
            record.Number_of_Events_Users__c = record.NumberOfMainLicenses__c;
            record.Events_Additional_Products_MRR__c = record.Sales_Order_MRS__c - record.Events_User_MRR__c;
        }
    }
}
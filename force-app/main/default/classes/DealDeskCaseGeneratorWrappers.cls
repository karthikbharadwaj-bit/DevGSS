public class DealDeskCaseGeneratorWrappers {

    public class CaseSourceWrapper {
        public Id accountId;
        public Id opportunityId;
        public String ownerEmail;

        public CaseSourceWrapper(Quote quote) {
            this.accountId = quote.MasterQuote__c != null ? quote.MasterQuote__r.AccountId : quote.AccountId;
            this.opportunityId = quote.OpportunityId;
            this.opportunityId = quote.MasterQuote__c != null ? quote.MasterQuote__r.OpportunityId : quote.OpportunityId;
        }

        public CaseSourceWrapper(Order order) {
            this.accountId = order.AccountId;
            this.opportunityId = order.OpportunityId;
            this.ownerEmail = order.Opportunity.Owner.Email;
        }
    }

    public interface LineItem {
        String getType();
        String getLicenseId();
        String getCategoryCode();
        String getName();
        String getPaymentPlan();
        Decimal getUnitPrice();
        Integer getQuantity();
        Decimal getDiscount();
        String getDiscountType();
        String getChargeTerm();
    }

    public class QuoteLineItemWrapper implements LineItem {
        private QuoteLineItem qli;
        public String type;

        public QuoteLineItemWrapper(QuoteLineItem qli) {
            this.qli = qli;
        }
        public QuoteLineItemWrapper(QuoteLineItem qli, String type) {
            this.qli = qli;
            this.type = type;
        }

        public String getType() {
            return type;
        }
        public String getLicenseId() {
            return qli.Product2.ExtID__c;
        }
        public String getCategoryCode() {
            return qli.Product2.CategoryCode__c;
        }
        public String getName() {
            return String.isBlank(qli.Product2.Description) ? qli.Product2.Name : qli.Product2.Description;
        }
        public String getPaymentPlan() {
            return qli.Quote.Account.Payment_Plan__c;
        }
        public Decimal getUnitPrice() {
            return qli.UnitPrice;
        }
        public Integer getQuantity() {
            return (Integer) qli.Quantity;
        }
        public Decimal getDiscount() {
            return qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY ? qli.Discount_number__c.setScale(2) : qli.Discount.setScale(2);
        }
        public String getDiscountType() {
            return qli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY ? qli.CurrencyIsoCode : '%';
        }
        public String getChargeTerm() {
            return qli.ChargeTerm__c;
        }
    }

    public class OrderLineItemWrapper implements LineItem {
        private OrderItem oli;
        public String type;

        public OrderLineItemWrapper(OrderItem oli) {
            this.oli = oli;
        }
        public OrderLineItemWrapper(OrderItem oli, String type) {
            this.oli = oli;
            this.type = type;
        }

        public String getType() {
            return type;
        }
        public String getLicenseId() {
            return oli.Product2.ExtID__c;
        }
        public String getCategoryCode() {
            return oli.Product2.CategoryCode__c;
        }
        public String getName() {
            return String.isBlank(oli.Product2.Description) ? oli.Product2.Name : oli.Product2.Description;
        }
        public String getPaymentPlan() {
            return oli.Order.Account.Payment_Plan__c;
        }
        public Decimal getUnitPrice() {
            return oli.UnitPrice;
        }
        public Integer getQuantity() {
            return (Integer) oli.Quantity;
        }
        public Decimal getDiscount() {
            return oli.Discount_Number__c == null ? 0 : oli.Discount_Number__c.setScale(2);
        }
        public String getDiscountType() {
            return oli.Discount_Type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY ? oli.CurrencyIsoCode : '%';
        }
        public String getChargeTerm() {
            return oli.ChargeTerm__c;
        }
    }
}
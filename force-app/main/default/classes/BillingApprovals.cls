public with sharing class BillingApprovals {

    public static Quote approveDiscounts(List<QuoteLineItem> qlis, Quote q, List<Contract_Discount__c> discounts, Map<Id, QuoteLineItem> proservQlis) {
        Quote quoteToUpdate = new Quote(
            id = q.id,
            RecordTypeId = q.RecordTypeId,
            Approved_Status__c = q.Approved_Status__c
        );

        for(QuoteLineItem qli : qlis) {
            if (qli.Product_Family__c == Product2Helper.FAMILY_TAXES) {
                continue;
            }
            if(String.isNotBlank(qli.PackageInfo__c)) { // TODO remove

                Double qliDiscount = qli.Discount_type__c == QuoteLineItemHelper.DISCOUNT_TYPE_CURRENCY
                                        ? qli.Discount_number__c
                                        : qli.Discount;

                if(qli.Entitlement__r != null) {
                    Double billingDiscount = q.Upsell_Status__c == 'Upgrade' ? 0 : qli.Entitlement__r.Discount__c;
                    Boolean isNotSameType = qli.Discount_type__c != qli.Entitlement__r.Discount_Type__c;
                    Boolean isQliApprovedWoDiscounts =
                        qliDiscount == 0
                        && QuoteHelper.APPROVAL_STATUS_APPROVED.equalsIgnoreCase(q.Approved_Status__c);

                    if(isNotSameType
                        || qliDiscount > billingDiscount
                        || isQliApprovedWoDiscounts) {
                        quoteToUpdate.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        break;
                    }
                } else if (qli.ServiceName__c == QuoteLineItemHelper.SUBCATEGORY_PROSERV && !proservQlis.isEmpty()) {
                    QuoteLineItem oldQli = proservQlis.get(qli.Id);
                    Boolean isNotSameType = qli?.Discount_type__c != oldQli?.Discount_type__c;
                    Boolean isDiscountIncreased = qli?.Discount > oldQli?.Discount;
                    if (isNotSameType || isDiscountIncreased) {
                        quoteToUpdate.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        break;
                    }
                } else {
                    if(qliDiscount > 0) {
                        quoteToUpdate.Approved_Status__c = QuoteHelper.APPROVAL_STATUS_REQUIRED;
                        break;
                    }
                }
            }
        }

        return quoteToUpdate;
    }
}
public class PhaseHelper {

    // Phase Describe Object
    public static final Schema.describeSObjectResult DESCRIBE = Phase__c.SObjectType.getDescribe();

    // Record Types
    public static final String RT_NAME_PROSERV_PHASE = 'ProServ Phase';
    public static final String RT_NAME_RINGCENTRAL_HARDWARE_PHASE = 'RingCentral Hardware Phase';

    public static final Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
    public static final Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();

    public static final Id RT_ID_PROSERV_PHASE = RT_INFO_BY_NAME.get(RT_NAME_PROSERV_PHASE).getRecordTypeId();
    public static final Id RT_ID_RINGCENTRAL_HARDWARE_PHASE = RT_INFO_BY_NAME.get(RT_NAME_RINGCENTRAL_HARDWARE_PHASE).getRecordTypeId();
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_PENDING_APPROVAL = 'Pending Approval';
    public static final String STATUS_DELETED = 'Deleted';
    public static final String STATUS_LOCKED = 'Locked';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String BILLING_STATUS_MANUAL = 'Manual';
    public static final String BILLING_STATUS_SUBMITTED = 'Submitted';
    public static final String BILLING_STATUS_REPLACED = 'Replaced';
    public static final String BILLING_STATUS_CANCELLED = 'Cancelled';
    public static final String BILLING_STATUS_ACTIVE = 'Active';

    public static final String CANNOT_DELETE_COMPLETED_PHASE = 'You can not delete a Completed Phase';

    /**
     * Check if all Quote Line Items on quote are assigned to phases
     *
     * Taking into account only One - Time Quote Line Items
     *
     * @param quoteLineItems    QLIs from quote
     *                          Required fields:
     *                          Id, Quantity
     * @param phases            Phases with Phase Line Items from quote
     *                          Required fields:
     *                          Hardware_Line_Items__r, Hardware_Line_Item__c.Quote_Line_Item__c,
     *                          Hardware_Line_Item__c.Quantity__c,
     *
     * @return
     */
    public static Boolean isAllQLIAssigned(List<QuoteLineItem> quoteLineItems, List<Phase__c> phases){
        Map<Id, Decimal> qliIdToQuantityMap = new Map<Id, Decimal>();
        Boolean isAllQliAssigned = true;

        // Get Quantity of each Phase LineItem
        for (Phase__c phase : phases) {
            for (Hardware_Line_Item__c hli : phase.Hardware_Line_Items__r) {
                Decimal assignedQLIQuantity = qliIdToQuantityMap.get(hli.Quote_Line_Item__c) == null ?
                        0 :
                        qliIdToQuantityMap.get(hli.Quote_Line_Item__c);
                assignedQLIQuantity = assignedQLIQuantity + hli.Quantity__c;
                qliIdToQuantityMap.put(hli.Quote_Line_Item__c, assignedQLIQuantity);
            }
        }

        for (QuoteLineItem qli : quoteLineItems){
            // Skip Quote Line Items that shouldn't be assigned
            if (qli.Product2.Charge_Term__c != Product2Helper.CHARGE_TERM_ONE_TIME) {
                continue;
            }
            Decimal assignedQLIQuantity = qliIdToQuantityMap.get(qli.Id) == null ? 0 : qliIdToQuantityMap.get(qli.Id);

            if (QuoteLineItemHelper.getQuantity(qli) > assignedQLIQuantity) {
                isAllQliAssigned = false;
            }
        }

        return isAllQliAssigned;
    }

    /**
     * Check if there is at least one Phase without phase line items
     *
     * @param phases
     *
     * @return
     */
    public static Boolean isHasEmptyPhases(List<Phase__c> phases){
        Boolean isHasEmptyPhases = false;
        for (Phase__c phase: phases) {
            if (phase.Hardware_Line_Items__r.isEmpty() && phase.Status__c != PhaseHelper.STATUS_DELETED) {
                isHasEmptyPhases = true;
                break;
            }
        }
        return isHasEmptyPhases;
    }
}
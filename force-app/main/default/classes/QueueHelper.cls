public class QueueHelper {
    public static final Id SHARED_LEADS_ID = HardcodedIdsMapper.getMatchedObjectId('00G80000003GNXy');

    public static final String DEAL_DESK_ENGAGE_QUEUE = 'Deal_Desk_Engage';
    public static final String SALES_ORDER_EXCEPT_DESK_QUEUE = 'Sales_Order_Except_Desk_Queue';
    public static final String CLOSED_LOOP_TEAM = 'Closed_Loop_Team';

    public static final String QUEUE_PS_INTERNATIONAL = 'PS International';
    public static final String QUEUE_PS_NA_ENTERPRISE = 'PS NA Enterprise';
    public static final String QUEUE_PS_NA_MAJORS = 'PS NA Majors';
    public static final String QUEUE_PS_NA_MIDMARKET = 'PS NA MidMarket';
    public static final String QUEUE_PS_SMB = 'PS SMB';
    public static final String QUEUE_PS_MRR_SERVICES = 'PS MRR Services';
    public static final String QUEUE_PS_VIDEO = 'PS Video';
    public static final String QUEUE_PS_AFTERMARKET = 'PS Aftermarket';
    public static final String QUEUE_PS_CONTACT_CENTER = 'PS Contact Center';
    public static final String QUEUE_PROFESSIONAL_SERVICES = 'Professional Services Queue';

    public static final Set<String> PROSERV_QUEUES = new Set<String> {
        QUEUE_PS_INTERNATIONAL,
        QUEUE_PS_NA_ENTERPRISE,
        QUEUE_PS_NA_MAJORS,
        QUEUE_PS_NA_MIDMARKET,
        QUEUE_PS_SMB,
        QUEUE_PS_MRR_SERVICES,
        QUEUE_PS_VIDEO,
        QUEUE_PS_AFTERMARKET,
        QUEUE_PS_CONTACT_CENTER,
        QUEUE_PROFESSIONAL_SERVICES
    };

    public static Map<String, Id> getPSQueuesMap() {
        List<QueueSObject> psQueues = (List<QueueSObject>) new QueueSelector()
            .selectQueuesByNames(PROSERV_QUEUES)
            .executeQuery();

        Map<String, Id> psQueuesMap = new Map<String, Id>();
        for (QueueSObject psQueue: psQueues) {
            psQueuesMap.put(psQueue.Queue.Name, psQueue.QueueId);
        }
        return psQueuesMap;
    }
}
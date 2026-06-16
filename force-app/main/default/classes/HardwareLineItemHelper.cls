/**
 * Helper class for Hardware_Line_Item__c also known as Phase Line Item
 */
public class HardwareLineItemHelper {

    // Phase Describe Object
    public static Schema.describeSObjectResult DESCRIBE {
        get {
            if(DESCRIBE == null) {
                DESCRIBE = Hardware_Line_Item__c.SObjectType.getDescribe();
            }
            return DESCRIBE;
        }
        set;
    }

    // Record Types
    public static final String RT_NAME_HARDWARE_LINE_ITEM = 'Hardware Line Item';
    public static final String RT_NAME_PROSERV_LINE_ITEM = 'ProServ Line Item';
    public static Map<String, Schema.RecordTypeInfo> RT_INFO_BY_NAME {
        get {
            if(RT_INFO_BY_NAME == null) {
                RT_INFO_BY_NAME = DESCRIBE.getRecordTypeInfosByName();
            }
            return RT_INFO_BY_NAME;
        }
        set;
    }
    public static Map<Id, Schema.RecordTypeInfo> RT_INFO_BY_ID {
        get {
            if(RT_INFO_BY_ID == null) {
                RT_INFO_BY_ID = DESCRIBE.getRecordTypeInfosById();
            }
            return RT_INFO_BY_ID;
        }
        set;
    }

    public static final Id RT_ID_HARDWARE_LINE_ITEM = RT_INFO_BY_NAME.get(RT_NAME_HARDWARE_LINE_ITEM).getRecordTypeId();
    public static final Id RT_ID_PROSERV_LINE_ITEM = RT_INFO_BY_NAME.get(RT_NAME_PROSERV_LINE_ITEM).getRecordTypeId();

}
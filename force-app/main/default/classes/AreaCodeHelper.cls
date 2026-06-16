public class AreaCodeHelper {
    public static final String TYPE_LOCAL = 'Local';
    public static final String TYPE_TOLL_FREE = 'Toll-Free';

    public static final Set<String> CATEGORY_CODES_LOCAL_AREA_CODES;

    public static final Set<String> CATEGORY_CODES_TOLL_FREE_AREA_CODES;

    public static final Set<String> CATEGORY_CODES_MAIN_AREA_CODES;

    public static final Set<String> CATEGORY_CODES_FAX_AREA_CODES;

    static {

        Map<String, Category_Codes__c> codesMap = Category_Codes__c.getAll();

        if(codesMap == null || codesMap.isEmpty()) {
            CATEGORY_CODES_FAX_AREA_CODES = new Set<String>();
            CATEGORY_CODES_LOCAL_AREA_CODES = new Set<String>();
            CATEGORY_CODES_MAIN_AREA_CODES = new Set<String>();
            CATEGORY_CODES_TOLL_FREE_AREA_CODES = new Set<String>();
        }

        for(String codeName : codesMap.keySet()) {

            String codesStr = codesMap.get(codeName).Codes__c;

            if(String.isBlank(codesStr)) {
                continue;
            }

            codesStr = codesStr.containsWhitespace() ? codesStr.deleteWhitespace() : codesStr;

            if (codeName.equalsIgnoreCase('FAX_AREA_CODES')) {
                CATEGORY_CODES_FAX_AREA_CODES = new Set<String>(codesStr.split(','));
            }else if (codeName.equalsIgnoreCase('LOCAL_AREA_CODES')) {
                CATEGORY_CODES_LOCAL_AREA_CODES = new Set<String>(codesStr.split(','));
            }else if (codeName.equalsIgnoreCase('MAIN_AREA_CODES')) {
                CATEGORY_CODES_MAIN_AREA_CODES = new Set<String>(codesStr.split(','));
            }else if (codeName.equalsIgnoreCase('TOLL_FREE_AREA_CODES')) {
                CATEGORY_CODES_TOLL_FREE_AREA_CODES = new Set<String>(codesStr.split(','));
            }
        }
    }


    public static Area_Code_Line_Item__c preCreateAreaCode(QuoteLineItem qli, Quote qt) {

        Id areaCodeId = null;
        Area_Code_Line_Item__c result = null;
        BillingWrappers.QLIPackageInfo pInfo = new BillingWrappers.QLIPackageInfo(qli.PackageInfo__c);
        String category = pInfo.CategoryCode;

        Boolean canApplyMain = CATEGORY_CODES_MAIN_AREA_CODES.contains(category);
        Boolean canApplyFax = CATEGORY_CODES_FAX_AREA_CODES.contains(pInfo.categoryCode);

        if (canApplyMain && canApplyType(category, qt.AreaCode__r)) {
            areaCodeId = qt.AreaCode__c;

        } else if (canApplyFax && canApplyType(category, qt.FaxAreaCode__r)) {
            areaCodeId = qt.FaxAreaCode__c;

        }

        if (areaCodeId != null) {
            result = new Area_Code_Line_Item__c (
                Area_Code__c = areaCodeId,
                Quote_Line_Item__c = qli.Id,
                Quantity__c = QuoteLineItemHelper.getQuantity(qli)
            );
        }
        return result;
    }

    private static Boolean canApplyType(String qliCategoryCode, Area_Codes__c areaCode) {
        Boolean canApplyLocal = CATEGORY_CODES_LOCAL_AREA_CODES.contains(qliCategoryCode);
        Boolean canApplyTollFree = CATEGORY_CODES_TOLL_FREE_AREA_CODES.contains(qliCategoryCode);

        return areaCode != null &&
            ((canApplyLocal && areaCode.Type__c == TYPE_LOCAL) ||
            (canApplyTollFree && areaCode.Type__c == TYPE_TOLL_FREE));
    }
}
public class HelperCaseDispatch {

    public static final String PRODUCT_ASSISTANCE_GDPR = 'GDPR Request';
    public static final String PRODUCT_ASSISTANCE_BILLING = 'Billing';
    public static final String GDPR_QUEUE_NAME = 'GDPR_Request';
    public static final String BILLING_QUEUE_NAME = 'Billing Inquiries';
    public static final String MANILA_QUEUE_NAME = 'Manila Contact Center Queue';
    public static final String ENGAGE_VOICE_PROD_ASSISTANCE = 'Engage Voice'; 
    public static final String ENGAGE_VOICE_QUEUE_NAME = 'RC Engage Voice Support';
    public static final String UNIFY_OFFICE_CASE_DISPATCH_NAME = 'Unify Office Support';
    public static final String CSS_QUEUE_NAME = 'CSS';
    public static final String OTC_QUEUE_NAME = 'OTC Credit Check';
    public static final Set<String> BILLING_CATEGORY_VALUES = new Set<String> {
        'Downgrade',
        'Cancellation',
        'Early Termination Request',
        'Payment Plan Update',
        'Rental Charge Removal'
    };

    //Constructor
    static String caseOwnerId;
    static List<Case_Dispatch__c> caseDispatchObjList;
    static Id GdprQueueId { get; private set; }
    static
    {
        caseDispatchObjList = Case_Dispatch__c.getall().values();

        Group[] gdprQueue =
        [
            SELECT Id
            FROM Group
            WHERE DeveloperName = :GDPR_QUEUE_NAME
            LIMIT 1
        ];

        if (gdprQueue.size() > 0)
        {
            GdprQueueId = gdprQueue[0].Id;
        }
    }
    public HelperCaseDispatch(){}

    public static Id getGdprQueue() {
        return GdprQueueId;
    }
    
    //Function to assign Queue on basis of Tier, Total Account DLs and Brand
    public static Case assignQueue(Case caseObj,User loginUser){    
        try{    
                caseOwnerId='';
                String accountTier;
                String productAssistance = caseObj.Product_Assistance__c != null ? caseObj.Product_Assistance__c.trim() : '';
                Double accountDLS;
                String accountBrand;
                String accountVIP;
                String accountServiceStatus;
                Boolean accountEESupport;
                Double accountNumberOfDLs;

                if(caseObj.Account != null){
                    accountTier = caseObj.Account.RC_Tier__c;
                    accountDLS = caseObj.Account.Total_Account_DL_s__c;
                    accountBrand = caseObj.Account.RC_Brand__c;
                    accountVIP = caseObj.Account.VIP_Account_Indicator__c;
                    accountNumberOfDLs = caseObj.Account.Number_of_DL_s__c;
                    accountServiceStatus = caseObj.Account.Service_Status__c;
                    accountEESupport = caseObj.Account.Extended_Enterprise_Support_Customer__c;
                }else{
                    accountTier = loginUser.Contact.Account.RC_Tier__c;
                    accountDLS = loginUser.Contact.Account.Total_Account_DL_s__c;
                    accountBrand = loginUser.Contact.Account.RC_Brand__c;
                    accountVIP = loginUser.Contact.Account.VIP_Account_Indicator__c;
                    accountNumberOfDLs = loginUser.Contact.Account.Number_of_DL_s__c;
                    accountServiceStatus = loginUser.Contact.Account.Service_Status__c;
                    accountEESupport = loginUser.Contact.Account.Extended_Enterprise_Support_Customer__c;
                }
            
                if (caseObj.Product_Assistance__c == PRODUCT_ASSISTANCE_GDPR) {
                    if (GdprQueueId != null) {
                        caseObj.OwnerId = GdprQueueId;
                        return caseObj;
                    }
                } 
                
                if (caseObj.Product_Assistance__c == PRODUCT_ASSISTANCE_BILLING) {                                        
                    String queueName = '';
                	if (BILLING_CATEGORY_VALUES.contains(caseObj.Product_Assistance_Lvl2__c)) {
						queueName = CSS_QUEUE_NAME;
                    } else if (caseObj.Product_Assistance_Lvl2__c.equalsIgnoreCase('Monthly Credit Limit Increase')) {
                        queueName = OTC_QUEUE_NAME;
                    } else {
                       queueName = BILLING_QUEUE_NAME;
                    }
                    QueueSObject billingQueue = (QueueSObject) new QueueSelector()
						.selectQueueByName(new List<Object> {queueName})
						.executeQuery()
						.get(0);
                    caseObj.OwnerId = billingQueue?.QueueId;
                    return caseObj;
                }
                                
                accountTier = String.isBlank(accountTier) ? '':accountTier.trim();
                accountDLS = accountDLS == null ? 0.0:accountDLS;
                accountBrand = String.isBlank(accountBrand) ? '' : accountBrand;
                Case_Dispatch__c manilaCaseDispatch = Case_Dispatch__c.getInstance(MANILA_QUEUE_NAME);
                List<String> csServiceStatuses = manilaCaseDispatch != null && String.isNotBlank(manilaCaseDispatch.Service_Status__c) 
                                ? manilaCaseDispatch.Service_Status__c.split(',') 
                                : new List<String>();
                
                Map<String, String> groupIdMap = getAllGroups(caseDispatchObjList);

                if(csServiceStatuses.contains(accountServiceStatus) 
                    && accountNumberOfDLs < 1000
                    && accountEESupport == manilaCaseDispatch.Extended_Enterprise_Support__c
                    && (manilaCaseDispatch.VIP__c == !String.isBlank(accountVIP))) {

                    String manilaCCQueueId = groupIdMap.get(MANILA_QUEUE_NAME);

                    if(manilaCCQueueId != null) {
                        caseObj.OwnerId = manilaCCQueueId;
                        return caseObj;
                    }
                }

                Case_Dispatch__c unifyOfficeCaseDispatch = Case_Dispatch__c.getInstance(UNIFY_OFFICE_CASE_DISPATCH_NAME);
                if (String.isNotBlank(accountBrand) 
                    && accountBrand.containsIgnoreCase(OpportunityHelper.BRAND_ATOS) 
                    && unifyOfficeCaseDispatch != null
                    && String.isNotBlank(groupIdMap.get(unifyOfficeCaseDispatch.Queue__c))) {

                    caseObj.OwnerId = groupIdMap.get(unifyOfficeCaseDispatch.Queue__c);
                    return caseObj;
                }

                if(accountTier != '') {
                        // Added by Virendra                    
                        for(Case_Dispatch__c caseSettingobj : caseDispatchObjList){
                            String customSettingTier = String.isNotBlank(caseSettingobj.Tier__c) ? caseSettingobj.Tier__c.trim() : '';
                            String customSettingBrands = String.isNotBlank(caseSettingobj.Brand__c) ? caseSettingobj.Brand__c.trim() : '';
                            List<String> csTiers = spiltTiers(customSettingTier);
                            Boolean checkResult = checkTierValueInAccTier(csTiers,accountTier);
                            Boolean isVIP = caseSettingobj.VIP__c && String.isNotBlank(accountVIP) ? true : false;
                            List<String> csBrands = spiltTiers(customSettingBrands);
                            Set<String> csBrandsSet = new Set<String>();

                            for(String str : csBrands){
                                If(String.isNotBlank(str)){
                                    csBrandsSet.add(str.trim().toLowerCase());
                                }
                            }
                            csBrandsSet.addAll(csBrands);
                            Boolean checkForBrand = csBrandsSet.contains(accountBrand.trim().toLowerCase()) ? true : false;
                            String productAssistanceCS = String.isBlank(caseSettingobj.Product_Assistance__c) ? '' : caseSettingobj.Product_Assistance__c.trim();

                            if (productAssistanceCS.containsIgnoreCase(productAssistance) && checkResult && checkForBrand){
                                if(customSettingTier.containsIgnoreCase('Fax') || customSettingTier.containsIgnoreCase('Pro')){
                                    if(isVIP){
                                        caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                    }else{
                                        caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                    }
                                    break;
                                }else if(customSettingTier.containsIgnoreCase('Office')){
                                    String strOperator= String.isNotBlank(caseSettingobj.Operator__c) ? caseSettingobj.Operator__c.trim() : '';
                                    if((strOperator).equals('<=')){
                                        if(accountDLS <= caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }else if((strOperator).equals('<')){
                                        if(accountDLS < caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }else if((strOperator).equals('>=')){
                                        if(accountDLS >= caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }else if((strOperator).equals('>')){
                                        if(accountDLS > caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }else if((strOperator).equals('==')){
                                        if(accountDLS == caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }else if((strOperator).equals('!=')){
                                        if(accountDLS != caseSettingobj.Total_Account_DL_s__c){
                                            if(isVIP){
                                                caseOwnerId = getGroupId_VIP(caseSettingobj,groupIdMap);
                                            }else{
                                                caseOwnerId = getGroupId(caseSettingobj,groupIdMap);
                                            }
                                            break;
                                        }
                                    }
                                }else{
                                    caseOwnerId = getDefaultQueue(groupIdMap,caseDispatchObjList);
                                    break;
                                }
                            }
                        }
            } else {
                caseOwnerId = getDefaultQueue(groupIdMap,caseDispatchObjList);
            }
            if(String.isBlank(caseOwnerId)) {
                caseOwnerId = getDefaultQueue(groupIdMap,caseDispatchObjList);
            }
            
            //START Engage Voice Case Routing
            String engageVoiceQueueId = groupIdMap.get(ENGAGE_VOICE_QUEUE_NAME);
            if(engageVoiceQueueId != null && productAssistance == ENGAGE_VOICE_PROD_ASSISTANCE) {
                caseOwnerId = engageVoiceQueueId;
            }
            //END Engage Voice Case Routing
            
            if(caseOwnerId.trim()!=''){
                caseObj.OwnerId = caseOwnerId;
            }
            return caseObj;
        }catch(Exception ex){
            System.debug('Exception============'+ex.getMessage());
            System.debug('Exception============'+ex.getStackTraceString());
            return caseObj;
        }
    }
    
    public static String[] spiltTiers(String tier){
        List<String> tierArray = null;
        tier = (tier==null) ? '' : tier;
        if(tier.containsIgnoreCase(',')){
            tierArray = tier.split(',');
        }else{
            tierArray = new List<String>();
            tierArray.add(tier);
        }
        return tierArray;
    }
    
    public static boolean checkTierValueInAccTier(List<String> csTiers,String accTier){
        for(String tier : csTiers){
            if(accTier.containsIgnoreCase(tier)){
                return true;
            }
        }
        return false;
    }
        
    private static String getGroupId(Case_Dispatch__c csObject, Map<String, String> groupIdMap) {
        return (groupIdMap.size() != 0 && groupIdMap.get((csObject.Queue__c).trim()) != null ?  groupIdMap.get((csObject.Queue__c).trim()) : '');
    }
    
    private static String getGroupId_VIP(Case_Dispatch__c csObject, Map<String, String> groupIdMap) {
        return (groupIdMap.size() != 0 && groupIdMap.get((csObject.VIP_Queue__c).trim()) != null ?  groupIdMap.get((csObject.VIP_Queue__c).trim()) : '');
    }

    private static Map<String, String> getAllGroups(List<Case_Dispatch__c> displatchList) {
        Map<String, String> groupIdMap = new Map<String, String>();
        Set<String> groups = new Set<String>();
        for(Case_Dispatch__c dispatchObj : displatchList) {
            groups.add(dispatchObj.Queue__c);
            groups.add(dispatchObj.VIP_Queue__c);
        }
        for(Group groupObj : [SELECT Id,Name FROM Group WHERE Name IN:groups]) {
            groupIdMap.put(groupObj.name,groupObj.id);  
        }
        return groupIdMap;
    }
    private static String getDefaultQueue(Map<String, String> groupIdMap, List<Case_Dispatch__c> displatchList) {
        for(Case_Dispatch__c dispatchObj : displatchList) {
            if((dispatchObj.Name).equalsIgnoreCase('DEFAULT_QUEUE')) {
                return groupIdMap.get(dispatchObj.Queue__c);
            }
        }
        return '';
    }
}
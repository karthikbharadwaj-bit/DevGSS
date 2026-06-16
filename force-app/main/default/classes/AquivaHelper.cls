public class AquivaHelper {

    public class AquivaException extends Exception {

    }

    public static void throwAquivaException(String exMessage, Exception ex) {
        throw new AquivaHelper.AquivaException(exMessage, ex);
    }

    public static void throwAquivaException(Exception ex) {
        System.debug(ex.getStackTraceString());
        throwAquivaException(ex.getMessage());
    }

    public static void throwAquivaException(String exMessage) {
        AquivaHelper.AquivaException properEx = new AquivaHelper.AquivaException(exMessage);
        properEx.setMessage(exMessage);
        throw properEx;
    }

    public static void throwAuraException(Exception ex){
        System.debug(ex.getStackTraceString());
        throwAuraException(ex.getMessage());
    }

    public static void throwAuraException(String exMessage) {
        AuraHandledException properEx = new AuraHandledException(exMessage);
        properEx.setMessage(exMessage);
        throw properEx;
    }

    // Checks if current user is admin
    public static Boolean isAdmin(){
        return isAdmin(UserInfo.getProfileId());
    }

    // Checks if profile is admin
    public static Boolean isAdmin(Id profileId) {
        return Id.valueOf(HardcodedIdsMapper.getMatchedObjectId('00e80000000l1hKAAQ')) == profileId;
    }


    public static Boolean isCurrentUserSuitableForRecallingEL() {
         //Start of EU Phase 3 IT Profile Changes
        Id userProfileid = UserInfo.getProfileId();
        List<String> profLstForRecallingEL = new List<String>();
		List<EU_Component_reference__mdt> profileList = [Select DeveloperName, Values__c from EU_Component_reference__mdt where Apex_Classes__c like '%AquivaHelper%' and DeveloperName = 'Profiles_For_Recalling_EL'];
		for(EU_Component_reference__mdt profRec:profileList){
            profLstForRecallingEL.addall(profRec.Values__c.split(','));
		}
        return profLstForRecallingEL.size() > 0? profLstForRecallingEL.contains(userProfileid):false;

    }

    // To get all sub roles.
    public static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {

        Set<ID> currentRoleIds = new Set<ID>();

        List<UserRole> userRole = [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleId != null];
        for(UserRole uRole : userRole) {
            currentRoleIds.add(uRole.Id);
        }

        // go fetch some more rolls!
        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }

        return currentRoleIds;
    }

    private static UserRole currentUserRole;
    public static UserRole getCurrentUserRole(){
        if(null == currentUserRole && null != UserInfo.getUserRoleId()){
            List<UserRole> roles = [SELECT Name FROM UserRole WHERE Id =: UserInfo.getUserRoleId() LIMIT 1];
            currentUserRole = roles.isEmpty() ? null : roles[0];
        }
        return currentUserRole;
    }

    private static Map<Id, Opportunity> opportunitiesByQuotes;
    private static Map<Id, Opportunity> queriedOpptys;

    public static Map<Id, Opportunity> getOpportunitiesByQuotes(){
        return getOpportunitiesByQuotes(Trigger.isDelete ? Trigger.old : Trigger.new);
    }

    // Test for this method is in Test_DocuSignStatusTriggerHandler
    public static Map<Id, Opportunity> getOpportunitiesByQuotes(List<Quote> quoteList) {
        if (null == opportunitiesByQuotes) {
            opportunitiesByQuotes = new Map<Id, Opportunity>();
        }
        if (null == queriedOpptys) {
            queriedOpptys = new Map<Id, Opportunity>();
        }
        Map<Id, Id> quotesWoOpptys = new Map<Id, Id>();
        for(Quote q: quoteList) {
            if (!opportunitiesByQuotes.containsKey(q.Id) && !queriedOpptys.containsKey(q.OpportunityId)) {
                quotesWoOpptys.put(q.Id, q.OpportunityId);
            } else if (!opportunitiesByQuotes.containsKey(q.Id) && queriedOpptys.containsKey(q.OpportunityId)) {
                opportunitiesByQuotes.put(q.Id, queriedOpptys.get(q.OpportunityId));
            }
        }
        if(!quotesWoOpptys.keySet().isEmpty()){
            opportunitiesByQuotes.putAll(queryOpptys(quotesWoOpptys));
        }
        return retrieveOpptysByQuotes(quoteList);
    }

    private static Map<Id, Opportunity> queryOpptys(Map<Id, Id> quotesWoOpptys) {
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        Map<Id, Opportunity> opptys = new Map<Id, Opportunity>(
        [SELECT Id, Special_TOS_Approval__c
        FROM Opportunity WHERE Id IN: quotesWoOpptys.values()]);
        for(Id qId: quotesWoOpptys.keySet()) {
            result.put(qId, opptys.get(quotesWoOpptys.get(qId)));
        }
        return result;
    }

    private static Map<Id, Opportunity> retrieveOpptysByQuotes(List<Quote> quotes) {
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();
        for(Quote q: quotes) {
            result.put(q.Id, opportunitiesByQuotes.get(q.Id));
        }
        return result;
    }

    /**
     *  Get Object Name by Id
     */
    public static String getObjectNameById(String objId) {
        return ((Id) objId)?.getSObjectType().getDescribe().getName();
    }

    /**
     * Get Object Field Names
     *
     * param: objName - Name of the object. Standard objects should be called without __c
     * like Quote or QuoteLineItem, but custom objects should use __c, like CustomAddress__c
     */
    public static List<Schema.SObjectField> getAllFieldsForObject(String objName) {
        Schema.SObjectType sobjType = ((SObject) Type.forName(objName).newInstance()).getSObjectType();
        if (sobjType == null) {
            throwAquivaException('Object ' + objName + ' does not exist on this environment');
        }
        Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
        Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
        return fieldsMap.values();
    }

    public static String getObjectLabelById(String objId) {
        return ((Id) objId)?.getSObjectType().getDescribe().getLabel();
    }

    public static String getFieldLabel(String obj, String fieldName) {
        Schema.SObjectType objSchema = ((SObject) Type.forName(obj).newInstance()).getSObjectType();
        Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();

        return fieldMap.get(fieldName).getDescribe().getLabel();
    }

    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> values = new List<string>();
        List<Schema.PicklistEntry> picklistValues = ((SObject) Type.forName(objectName).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();
        for (Schema.PicklistEntry picklistValue : picklistValues){
            values.add(string.valueof(picklistValue.getLabel()));
        }

        return values;
    }

    public static Set<Id> getFieldList(List<SObject> objects, String fieldName) {
        Set<Id> result = new Set<Id>();
        for (SObject o : objects) {
            result.add((Id) o.get(fieldName));
        }
        return result;
    }

    public static List<Object> collectFieldValues(
        Type resultListType,
        List<SObject> sObjectList,
        String fieldName,
        Boolean isUnique
    ) {
        return collectFieldValues(resultListType, sObjectList, fieldName, isUnique, false);
    }

    public static List<Object> collectFieldValues(
        Type resultListType,
        List<SObject> sObjectList,
        String fieldName,
        Boolean isUnique,
        Boolean allowNulls
    ) {
        List<Object> result = (List<Object>) resultListType.newInstance();
        Set<Object> duplicates = new Set<Object>(result);

        for (SObject o: sObjectList) {
            Object fieldValue = o.get(fieldName);

            if (fieldValue == null && !allowNulls) {
                continue;
            }

            if(!isUnique) {
                result.add(fieldValue);
            } else {
                if(!duplicates.contains(fieldValue)) {
                    result.add(fieldValue);
                }
            }

            duplicates.add(fieldValue);
        }

        return result;
    }

    public static Map<Object, SObject[]> groupByField(
        Type listType,
        List<SObject> sObjectList,
        String fieldName
    ) {
        Map<Object, List<SObject>> result = new Map<Object, List<SObject>>();

        for (SObject o: sObjectList) {
            Object fieldValue = getFieldValueByPath(o, fieldName);

            if (!result.containsKey(fieldValue)) {
                result.put(fieldValue, (List<SObject>) listType.newInstance());
            }

            result.get(fieldValue).add(o);
        }

        return result;
    }

    public static Map<String, SObject[]> groupByStringField(
        Type listType,
        List<SObject> sObjectList,
        String fieldName
    ) {
        Map<Object, SObject[]> sObjectMap = groupByField(listType, sObjectList, fieldName);
        Map<String, SObject[]> resultMap = new Map<String, SObject[]>();

        for(Object k: sObjectMap.keySet()) {
            resultMap.put((String) k, sObjectMap.get(k));
        }

        return resultMap;
    }

    public static Map<Id, SObject[]> groupByIdField(
        Type listType,
        List<SObject> sObjectList,
        String fieldName
    ) {
        Map<Object, SObject[]> sObjectMap = groupByField(listType, sObjectList, fieldName);
        Map<Id, SObject[]> resultMap = new Map<Id, SObject[]>();

        for(Object k: sObjectMap.keySet()) {
            resultMap.put((Id) k, sObjectMap.get(k));
        }

        return resultMap;
    }

    public static Object getFieldValueByPath(SObject rec, String fieldPath) {
        SObject lastParent = rec;
        SObjectType lastType = rec.getSObjectType();
        Object result = null;

        Iterator<String> it = fieldPath.split('\\.').iterator();
        while (it.hasNext()) {
            String field = it.next();
            SObjectField token = SObjectDescribeHelper.getDescribe(lastType).getField(field.toLowerCase());

            if (token != null) {
                DescribeFieldResult tokenDescribe = token.getDescribe();
                if (it.hasNext()) {
                    if (tokenDescribe.getSoapType() == Schema.SoapType.ID) {
                        List<Schema.SObjectType> references = tokenDescribe.getReferenceTo();
                        if (!references.isEmpty()) {
                            lastType = references.get(0);
                            lastParent = lastParent.getSObject(tokenDescribe.getRelationshipName());
                        }
                    }
                } else {
                    result = lastParent.get(field);
                }
            } else {
                throw new AquivaException('Invalid field');
            }
        }
        return result;
    }

    public static Map<String, Decimal> getCurrencyToConversionRateMap() {
        Map<String, Decimal> isoCodeToConversionRateMap = new Map<String, Decimal>();

        List<CurrencyType> currencyTypes = (List<CurrencyType>) new CurrencyTypeSelector()
                .selectActiveCurrencyTypes()
                .executeQuery();

        for (CurrencyType c : currencyTypes) {
            isoCodeToConversionRateMap.put(c.IsoCode, c.ConversionRate);
        }
        return isoCodeToConversionRateMap;
    }


}
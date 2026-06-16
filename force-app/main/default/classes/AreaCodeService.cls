@RestResource(urlMapping='/AreaCodeService/*')
global with sharing class AreaCodeService {

    public static final String ERROR_ACTION = 'Cannot find action';

    @HttpPost
    global static void handleRequest() {
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.Params paramsData = (BillingWrappers.Params) JSON.deserialize(
            body,
            BillingWrappers.Params.class
        );

        RestResponse res = RestContext.response;
        Response r = new Response();
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            switch on paramsData.action {
                when 'getAreaCodeLineItems' {
                    r.setData(getAreaCodeItems(paramsData.opportunityId));
                }
                when 'syncAreaCodeLineItems' {
                    r.setData(syncAreaCodeItems(paramsData));
                }
                when else {
                    r.setData('error', ERROR_ACTION);
                }
            }
            res.responseBody = Blob.valueOf(JSON.serialize(r));
        } catch (Exception e) {
            Map<String, String> errMsg = new Map<String, String>();
            errMsg.put('error', e.getMessage());
            errMsg.put('stackTrace', e.getStackTraceString());
            res.responseBody = Blob.valueOf(JSON.serialize(errMsg));

            return;
        }
    }

    public static Response getAreaCodeItems(Id opportunityId) {
        Response r = new Response();

        List<Area_Code_Line_Item__c> areaCodeLineItems = [
            SELECT Id, Name, Quantity__c, Quote_Line_Item__c, Area_Code__r.Area_Code__c,
                   Area_Code__r.Country__c, Area_Code__r.City__c, Area_Code__r.Type__c,
                   Area_Code__r.State__c
            FROM Area_Code_Line_Item__c
            WHERE Quote_Line_Item__c IN (SELECT Id FROM QuoteLineItem WHERE Quote.OpportunityId = :opportunityId)
            ORDER BY CreatedDate ASC
        ];

        r.setData('areaCodeLineItems', areaCodeLineItems);

        return r;
    }

    public static Response syncAreaCodeItems(BillingWrappers.Params paramsData) {
        List<BillingWrappers.AreaCodeLineItem> areaCodeLineItems = paramsData.areaCodeLineItems;
        Map<String, String> qliMap = paramsData.qliMap;
        Response resp = new Response();
        String quoteId = paramsData.quoteId;

        if (
            areaCodeLineItems == null || areaCodeLineItems.isEmpty() ||
            qliMap == null || qliMap.isEmpty() ||
            quoteId == null
        ) {
            return resp;
        }

        Map<String, List<Area_Code_Line_Item__c>> aclisForSync = getAreaCodeItemsForSync(
            areaCodeLineItems, qliMap, quoteId
        );

        if (!aclisForSync.isEmpty()) {
            upsert aclisForSync.get('upsert');
            delete aclisForSync.get('delete');
        }

        resp.setData('upsertedRecords', aclisForSync.get('upsert').size());
        resp.setData('deletedRecords', aclisForSync.get('delete').size());

        return resp;
    }

    private static Map<String, List<Area_Code_Line_Item__c>> getAreaCodeItemsForSync(
        List<BillingWrappers.AreaCodeLineItem> areaCodeLineItems,
        Map<String, String> cartItemToQLIMap,
        String quoteId
    ) {
        Map<String, Object> areaCodeData = getAreaCodeData(areaCodeLineItems);
        Map<String, Area_Codes__c> areaCodeByAreaId = getAreaCodeWithAreaId(areaCodeData, quoteId);
        List<Area_Codes__c> areaCodesForInsert = getAreaCodesForInsert(
            areaCodeLineItems, areaCodeByAreaId
        );
        insert areaCodesForInsert;

        enrichAreaCodes(areaCodeByAreaId, areaCodesForInsert);

        return getSyncedAreaCodeLineItems(
            areaCodeLineItems, areaCodeByAreaId, cartItemToQLIMap, quoteId
        );
    }

    private static Map<String, Object> getAreaCodeData(
        List<BillingWrappers.AreaCodeLineItem> areaCodeItems
    ) {

        List<BillingWrappers.AreaCodeData> areaCodeDataList = new List<BillingWrappers.AreaCodeData>();
        for (BillingWrappers.AreaCodeLineItem areaCodeItem : areaCodeItems) {
            areaCodeDataList.add(areaCodeItem.areaCodeInfo);
        }

        return getAreaCodeData(areaCodeDataList);
    }

    public static Map<String, Object> getAreaCodeData(List<BillingWrappers.AreaCodeData> items) {
        Map<String, Object> result = new Map<String, Object>{
            'countries' => new Set<String>(),
            'states' => new Set<String>(),
            'cities' => new Set<String>(),
            'areaCodes' => new Set<Integer>()
        };

        for (BillingWrappers.AreaCodeData item : items) {
            if (item != null && String.isNotBlank(item.country) && item.areaCode != null) {
                ((Set<String>) result.get('countries')).add(item.country);
                ((Set<String>) result.get('states')).add(item.state);
                ((Set<String>) result.get('cities')).add(item.city);
                ((Set<Integer>) result.get('areaCodes')).add(item.areaCode);
            }
        }
        return result;
    }

    public static Map<String, Area_Codes__c> getAreaCodeWithAreaId(
        Map<String, Object> areaCodeData,
        String quoteId
    ) {
        Map<String, Area_Codes__c> areaCodeByAreaId = new Map<String, Area_Codes__c>();

        for (
            Area_Codes__c areaCode : (List<Area_Codes__c>) new AreaCodesSelector()
                .selectAreaCodesForMatchedSync(
                    new List<Object>{
                        (Set<String>) areaCodeData.get('countries'),
                        (Set<String>) areaCodeData.get('states'),
                        (Set<String>) areaCodeData.get('cities'),
                        (Set<Integer>) areaCodeData.get('areaCodes')
                    },
                    new List<Object>{
                        (String) quoteId
                    }
                )
                .executeQuery()
        ) {
            areaCodeByAreaId.put(
                getAreaId(areaCode),
                areaCode
            );
        }

        return areaCodeByAreaId;
    }

    private static List<Area_Codes__c> getAreaCodesForInsert(
        List<BillingWrappers.AreaCodeLineItem> areaCodeLineItems,
        Map<String, Area_Codes__c> areaCodeByAreaId
    ) {
        Map<String, BillingWrappers.AreaCodeData> uniqueAreaCodes = new Map<String, BillingWrappers.AreaCodeData>();
        List<Area_Codes__c> areaCodes = new List<Area_Codes__c>();

        for (BillingWrappers.AreaCodeLineItem areaCodeItem : areaCodeLineItems) {
            String areaId = getAreaId(areaCodeItem.areaCodeInfo);
            if (!uniqueAreaCodes.containsKey(areaId)) {
                uniqueAreaCodes.put(areaId, areaCodeItem.areaCodeInfo);
            }
        }

        for (String areaCodeKey: uniqueAreaCodes.keySet()) {
            Area_Codes__c existingAreaCode = areaCodeByAreaId.get(areaCodeKey);
            Area_Codes__c newAreaCode = buildAreaCode(uniqueAreaCodes.get(areaCodeKey));

            if (existingAreaCode == null && newAreaCode != null) {
                areaCodes.add(newAreaCode);
            }
        }

        return areaCodes;
    }

    public static Area_Codes__c buildAreaCode(BillingWrappers.AreaCodeData areaCodeItem) {
        return areaCodeItem != null && areaCodeItem.areaCode != null
            ? (Area_Codes__c) new SObjectBuilder(Area_Codes__c.SObjectType)
                .setFields(
                    new Map<SObjectField, Object> {
                        Area_Codes__c.Name         => String.valueOf(areaCodeItem.areaCode),
                        Area_Codes__c.Country__c   => areaCodeItem.country,
                        Area_Codes__c.State__c     => areaCodeItem.state,
                        Area_Codes__c.City__c      => areaCodeItem.city,
                        Area_Codes__c.Area_Code__c => areaCodeItem.areaCode,
                        Area_Codes__c.Type__c      => areaCodeItem.type
                    }
                )
                .build()
                .getRecord()
            : null;
    }

    private static Area_Code_Line_Item__c buildAreaCodeLineItem(
        BillingWrappers.AreaCodeLineItem areaCodeItem,
        Id relatedQLIId,
        Id relatedAreaCodeId
    ) {
        return (Area_Code_Line_Item__c) new SObjectBuilder(Area_Code_Line_Item__c.SObjectType)
            .setFields(
                new Map<SObjectField, Object> {
                    Area_Code_Line_Item__c.Id                 => areaCodeItem.id,
                    Area_Code_Line_Item__c.Quantity__c        => areaCodeItem.quantity,
                    Area_Code_Line_Item__c.Quote_Line_Item__c => relatedQLIId,
                    Area_Code_Line_Item__c.Area_Code__c       => relatedAreaCodeId
                }
            )
            .build()
            .getRecord();
    }

    public static void enrichAreaCodes(
        Map<String, Area_Codes__c> areaCodeByAreaId,
        List<Area_Codes__c> areaCodes
    ) {
        for (Area_Codes__c areaCode : areaCodes) {
            String areaId = getAreaId(areaCode);

            if (areaCodeByAreaId.get(areaId) == null) {
                areaCodeByAreaId.put(
                    getAreaId(areaCode),
                    areaCode
                );
            }
        }
    }

    private static Map<String, List<Area_Code_Line_Item__c>> getSyncedAreaCodeLineItems(
        List<BillingWrappers.AreaCodeLineItem> areaCodeItems,
        Map<String, Area_Codes__c> areaCodeByAreaId,
        Map<String, String> qliByCatalogId,
        String quoteId
    ) {
        Map<String, List<Area_Code_Line_Item__c>> processedAclis = new Map<String, List<Area_Code_Line_Item__c>> {
            'upsert' => new List<Area_Code_Line_Item__c>(),
            'delete' => new List<Area_Code_Line_Item__c>()
        };
        
        Map<Id, Area_Code_Line_Item__c> aclisMap = new Map<Id, Area_Code_Line_Item__c>();
        List<Area_Code_Line_Item__c> aclis = new AreaCodeLineItemSelector()
            .selectACLIForMasterQuotes(new List<Object>{ new List<String>{quoteId} })
            .executeQuery();
        
        for (Area_Code_Line_Item__c acli: aclis) {
            aclisMap.put(acli.Id, acli);
        }
        
        for (BillingWrappers.AreaCodeLineItem areaCodeItem : areaCodeItems) {
            String areaId = getAreaId(areaCodeItem.areaCodeInfo);
            String processedKey = areaCodeItem.isDeleted ? 'delete' : 'upsert';
            Area_Codes__c areaCode = areaCodeByAreaId.get(areaId);
            Id relatedAreaCodeId = areaCode != null ? areaCode.Id : null;
            Id relatedQLIId;

            try {
                relatedQLIId = Id.valueOf(qliByCatalogId.get(areaCodeItem.cartItemCatalogId));
            } catch (Exception ex) {
                continue;
            }

            if (relatedQLIId == null || aclisMap.get(areaCodeItem.id) == null && processedKey == 'delete') {
                continue;
            }

            processedAclis.get(processedKey).add(
                buildAreaCodeLineItem(areaCodeItem, relatedQLIId, relatedAreaCodeId)
            );
        }

        return processedAclis;
    }

    public static String getAreaId(BillingWrappers.AreaCodeData areaCodeItem) {
        return areaCodeItem != null
            ? areaCodeItem.country + ':' +
                (String.isNotBlank(areaCodeItem.state) ? areaCodeItem.state + ':' : '') +
                (String.isNotBlank(areaCodeItem.city) ? areaCodeItem.city + ':' : '') +
                areaCodeItem.areaCode
            : null;
    }

    public static String getAreaId(Area_Codes__c areaCode) {
        return areaCode != null
            ? areaCode.Country__c + ':' +
               (String.isNotBlank(areaCode.State__c) ? areaCode.State__c + ':' : '') +
               (String.isNotBlank(areaCode.City__c) ? areaCode.City__c + ':' : '') +
               areaCode.Area_Code__c
            : null;
    }

    public static Map<String, Area_Codes__c> syncAreaCodesForAssignmentLineItem(List<BillingWrappers.AssignmentLineItem> alis, String quoteId) {

        Map<String, BillingWrappers.AreaCodeData> areaIdToAreaCodeMap = new Map<String, BillingWrappers.AreaCodeData>();
        for (BillingWrappers.AssignmentLineItem ali : alis) {
            Boolean isNotValidAreaCodeData = ali.areaCodeInfo == null || (ali.areaCodeInfo.country == null && ali.areaCodeInfo.areaCode == null);
            if (isNotValidAreaCodeData) {
                continue;
            }
            String areaId = getAreaId(ali.areaCodeInfo);

            areaIdToAreaCodeMap.put(
                areaId,
                ali.areaCodeInfo
            );
        }

        Map<String, Area_Codes__c> existingAreaCodes = getExistingAreaCodesByAreaCodeData(areaIdToAreaCodeMap.values(), quoteId);

        Map<String, Area_Codes__c> areaCodesToInsertMap = new Map<String, Area_Codes__c>();
        for (String areaId : areaIdToAreaCodeMap.keySet()) {
            if (!existingAreaCodes.containsKey(areaId)) {
                Area_Codes__c newAreaCode = buildAreaCode(
                    areaIdToAreaCodeMap.get(areaId)
                );
                areaCodesToInsertMap.put(
                    getAreaId(newAreaCode),
                    newAreaCode
                );
            }
        }

        insert areaCodesToInsertMap.values();

        Map<String, Area_Codes__c> mergedAreaCodesMap = new Map<String, Area_Codes__c>(existingAreaCodes);
        mergedAreaCodesMap.putAll(areaCodesToInsertMap);

        return mergedAreaCodesMap;
    }

    private static Map<String, Area_Codes__c> getExistingAreaCodesByAreaCodeData(List<BillingWrappers.AreaCodeData> areaCodeDataItems, String quoteId) {

        Map<String, Object> areaCodeData = getAreaCodeData(areaCodeDataItems);

        Map<String, Area_Codes__c> areaIdToAreaCodeMap = getAreaCodeWithAreaId(areaCodeData, quoteId);

        return areaIdToAreaCodeMap;
    }
}
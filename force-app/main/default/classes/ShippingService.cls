@RestResource(UrlMapping='/ShippingService/*')
global with sharing class ShippingService {

    @HttpPost
    global static void shipping() {
        String result = '';
        String body = RestContext.request.requestBody.toString();
        BillingWrappers.ParamsShipping paramsDataShipping = (BillingWrappers.ParamsShipping)JSON.deserialize(body, BillingWrappers.ParamsShipping.class);
        RestResponse res = RestContext.response;
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }

        try {
            if (paramsDataShipping.action == 'getShippingInfo') {
                Map<String,List<BillingWrappers.ShippingItemsInfo>> shippingData = getShippingInfo(paramsDataShipping.selectedQuoteId);
                result = JSON.serializePretty(shippingData);
            }
            if (paramsDataShipping.action == 'saveShippingInfo') {
                Map<String,List<BillingWrappers.ShippingItemsInfo>> shippingData = processShippingData(paramsDataShipping);
                result = JSON.serializePretty(shippingData);
            }
            else if (paramsDataShipping.action == 'deleteCustomAddressAssignments') {
                Map<String,List<BillingWrappers.ShippingItemsInfo>> shippingData = deleteCustomAddressAssignments(paramsDataShipping);
                result = JSON.serializePretty(shippingData);
            }
            res.responseBody = Blob.valueOf(result);
        } catch(Exception e) {
            PlatformLog.logException('Shipping error: ', e);
        }
    }

    @TestVisible
    private static Map<String,List<BillingWrappers.ShippingItemsInfo>> getShippingInfo(String quoteId) {
        Map <String,List<BillingWrappers.ShippingItemsInfo>> shippingData = new Map <String,List<BillingWrappers.ShippingItemsInfo>>();
        Map<Id, QuoteLineItem> qlisMap = getQuoteLineItems(new Map<String,List<BillingWrappers.ShippingItemsInfo>>(), quoteId);

        List<CustomAddressAssignments__c> customAddressAssignments = (List<CustomAddressAssignments__c>) new CustomAddressAssignmentsSelector()
            .selectCAAForShipping(new List<Object> { qlisMap.keySet() })
            .executeQuery();

        if (!customAddressAssignments.isEmpty()) {
            for (CustomAddressAssignments__c caa : customAddressAssignments) {
                BillingWrappers.ShippingItemsInfo shippingItem = getShippingItem(caa);
                if (shippingData.containsKey(shippingItem.deviceUniqId)) {
                    shippingData.get(shippingItem.deviceUniqId).add(shippingItem);
                } else {
                    shippingData.put(shippingItem.deviceUniqId, new List<BillingWrappers.ShippingItemsInfo>{ shippingItem });
                }
            }
        }
        return shippingData;
    }

    @TestVisible
    private static Map<String,List<BillingWrappers.ShippingItemsInfo>> processShippingData(BillingWrappers.ParamsShipping paramsDataShipping) {

        Map<Id, QuoteLineItem> qlisMap = new Map<Id, QuoteLineItem>();
        String keyAssignments = CustomAddressAssignments__c.getSObjectType().getDescribe().getKeyPrefix();
        Map<Id,CustomAddressAssignments__c> caaDelete = new Map<Id, CustomAddressAssignments__c>();
        Set<Id> masterDevicesId = new Set<Id>();
        Map<BillingWrappers.ShippingItemsInfo, CustomAddress__c> getCustomAddressMap = new Map<BillingWrappers.ShippingItemsInfo, CustomAddress__c>();
        Map<String, QuoteLineItem> uniqIdsToQliMap = new Map<String,QuoteLineItem>();
        Map<Id, List<String>> qliIdToUniqIds = new Map<Id, List<String>>();

        if (paramsDataShipping != null) {
            qlisMap = getQuoteLineItems(paramsDataShipping.shippingItemsMap, null);
            qliIdToUniqIds = populateMapQliIdToListUniqId(paramsDataShipping);

            for (QuoteLineItem qli : qlisMap.values()) {
                uniqIdsToQliMap.put(qli.Product_Lic_Id__c, qli);
                if (qliIdToUniqIds.containsKey(qli.Id)) {
                    for (String uniqId : qliIdToUniqIds.get(qli.Id)) {
                        uniqIdsToQliMap.put(uniqId, qli);
                    }
                }
            }

            for (String uniqId : uniqIdsToQliMap.keySet()) {
                if (paramsDataShipping.shippingItemsMap.get(uniqId) != null) {
                    for (BillingWrappers.ShippingItemsInfo si : paramsDataShipping.shippingItemsMap.get(uniqId)) {
                        if (si.isDeleted && si.junctionID != null) {
                            caaDelete.put(si.junctionID, new CustomAddressAssignments__c(Id = si.junctionID, CustomAddress__c = si.location?.address?.id, QuoteLineItem__c = si.quoteLineItemId, DeviceId__c = si.deviceUniqId));
                            masterDevicesId.add(si.quoteLineItemId);
                            paramsDataShipping.shippingItemsMap.remove(uniqId);
                            continue;
                        }
                        if (si.location !=null &&
                            si.location.address != null && !si.isDeleted) {
                            getCustomAddressMap.put(si, null);
                        }
                    }
                }
            }
            if (caaDelete.size() > 0) {
                List<CustomAddressAssignments__c> techCAAs = new CustomAddressAssignmentsSelector()
                    .selectTechnicalCAA(masterDevicesId)
                    .executeQuery();
                if (!techCAAs.isEmpty()) {
                    for (CustomAddressAssignments__c caa : caaDelete.values()) {
                        for (CustomAddressAssignments__c techCaa : techCAAs) {
                            if (caa.CustomAddress__c == techCaa.CustomAddress__c && 
                                caa.QuoteLineItem__c == techCaa.QuoteLineItem__r.MasterQLI__c &&
                                caa.DeviceId__c == techCaa.DeviceId__c
                            ) {
                                caaDelete.put(techCaa.Id, techCaa);
                                break;
                            }
                        }
                    }
                }
                delete caaDelete.values();
            }
        }
        if (getCustomAddressMap.size() > 0) {
            getCustomAddressMap = getCustomAddresses(getCustomAddressMap);
        }

        Map<String, List<BillingWrappers.ShippingItemsInfo>> res = getCustomAddresseAssignments(getCustomAddressMap, keyAssignments, uniqIdsToQliMap);

        // info: recall approvals if any ShippingItemsInfo.location.shippingMethod != QuoteHelper.SHIPPING_OPTION_GROUND
        Boolean hasNonGroundShippingMethod = false;
        for(List<BillingWrappers.ShippingItemsInfo> shipList: res.values()) {
            for (BillingWrappers.ShippingItemsInfo shippingInfo : shipList) {
                if (shippingInfo.location.shippingMethod != QuoteHelper.SHIPPING_OPTION_GROUND) {
                    hasNonGroundShippingMethod = true;
                    break;
                }
            }
        }

        // info: start approval process for free shipping in needed
        Quote qt = (Quote) new QuoteSelector()
            .selectQuoteById(new List<Object>{paramsDataShipping.selectedQuoteId})
            .executeQuery()
            .get(0);

        Boolean freeShippingNotRequiredApproval = !hasNonGroundShippingMethod
            && qt.Approved_Status__c == QuoteHelper.APPROVAL_STATUS_APPROVED;

        if (qt.FreeShippingTerms__c == QuoteHelper.FREESHIPPING && !freeShippingNotRequiredApproval) {
            QuoteApprovals.IS_NEED_RECALCULATE_MAIN_QUOTE_APPROVALS = true;
            update new Quote(Id = qt.Id);
            QuoteApprovals.IS_NEED_RECALCULATE_MAIN_QUOTE_APPROVALS = false;
        }

        return res;
    }

    private static Map<String, List<BillingWrappers.ShippingItemsInfo>> getCustomAddresseAssignments(
        Map<BillingWrappers.ShippingItemsInfo, CustomAddress__c> getCustomAddressMap,
        String keyAssignments,
        Map<String,QuoteLineItem> uniqIdsToQliMap
    ) {
        List<CustomAddressAssignments__c> insertCustomAddressAssignments = new List<CustomAddressAssignments__c>();
        List<CustomAddressAssignments__c> updateCustomAddressAssignments = new List<CustomAddressAssignments__c>();
        List<CustomAddressAssignments__c> upsertTechCustomAddressAssignments = new List<CustomAddressAssignments__c>();
        Map<String, List<BillingWrappers.ShippingItemsInfo>> shippingItemsMap = new Map<String, List<BillingWrappers.ShippingItemsInfo>>();
        Map<Id, Id> masterToTechQuoteId = new Map<Id, Id>();
        Set<Id> quoteLineItemIds = new Set<Id>();
        List<CustomAddressAssignments__c> techCaaList = new List<CustomAddressAssignments__c>();
        Set<BillingWrappers.ShippingItemsInfo> shippingInfoSet = getCustomAddressMap.keySet();

        for (BillingWrappers.ShippingItemsInfo si : shippingInfoSet) {
            quoteLineItemIds.add(si.quoteLineItemId);
        }

        if (!quoteLineItemIds.isEmpty()) {
            for (QuoteLineItem techQLI : (List<QuoteLineItem>) new QuoteLineItemSelector().selectTechQuoteLineItemsByMasterQuoteIdsForShipping(quoteLineItemIds).executeQuery()) {
                masterToTechQuoteId.put(techQLI.MasterQLI__c, techQLI.Id);
                for (CustomAddressAssignments__c techCAA : techQLI.Custom_Address_QLI__r) {
                    techCaaList.add(techCAA);
                }
            }
        }

        for (BillingWrappers.ShippingItemsInfo si : shippingInfoSet) {
            CustomAddressAssignments__c caa = new CustomAddressAssignments__c();
            caa.Quantity__c = si.quantity;
            caa.QuoteLineItem__c = si.quoteLineItemId;
            caa.AttentionTo__c = si.location.attentionTo;
            caa.CustomAddress__c = getCustomAddressMap?.get(si)?.Id;
            caa.Type__c = si.location.shippingMethod;
            caa.ShippingLicenseTree__c = si.location.shippingLicensesTree;
            caa.ShippingBillingCodeId__c = si.location.shippingBillingCodeId;
            caa.AssignmentLineItem__c = si.assignmentLineItemId;
            caa.DeviceId__c = si.deviceUniqId;

            if (si.junctionID != null && si.junctionID.startsWith(keyAssignments)) {
                caa.Id = si.junctionID;
                si.location.id = caa.CustomAddress__c + '-' + caa.Type__c + '-' + caa.AttentionTo__c;
                updateCustomAddressAssignments.add(caa);
            } else {
                insertCustomAddressAssignments.add(caa);
            }

            if (masterToTechQuoteId.get(caa.QuoteLineItem__c) != null) {
                CustomAddressAssignments__c newTechCaa = caa.clone(false, false, false, false);
                CustomAddressAssignments__c oldTechCaa; 
                for (CustomAddressAssignments__c techCaa: techCaaList) {
                    if (
                        techCaa.QuoteLineItem__c == masterToTechQuoteId.get(caa.QuoteLineItem__c) &&
                        techCaa.deviceId__c == caa.deviceId__c
                    ) {
                        oldTechCaa = techCaa;
                        break;
                    }
                }
                newTechCaa.QuoteLineItem__c = masterToTechQuoteId.get(caa.QuoteLineItem__c);
                if (oldTechCaa != null) {
                    newTechCaa.Id = oldTechCaa.Id;
                }
                upsertTechCustomAddressAssignments.add(newTechCaa);
            }
        }

        if (updateCustomAddressAssignments.size() > 0) {
            update updateCustomAddressAssignments;
        }

        if (insertCustomAddressAssignments.size() > 0) {
            insert insertCustomAddressAssignments;
        }

        if (!upsertTechCustomAddressAssignments.isEmpty()) {
            upsert upsertTechCustomAddressAssignments;
        }

        for (BillingWrappers.ShippingItemsInfo si : shippingInfoSet) {
            if (si.junctionID == null) {
                for (CustomAddressAssignments__c caa : insertCustomAddressAssignments) {
                    if (si.deviceUniqId == caa.DeviceId__c && getCustomAddressMap.get(si)?.Id == caa.CustomAddress__c) {
                        si.junctionID = caa.Id;
                        si.location.id = caa.CustomAddress__c + '-' + caa.Type__c + '-' + caa.AttentionTo__c;
                        si.location.address.id = caa.CustomAddress__c;
                    }
                }
            } else {
                for (CustomAddressAssignments__c caa : updateCustomAddressAssignments) {
                    if (si.junctionID == caa.Id) {
                        si.location.address.id = caa.CustomAddress__c;
                    }
                }
            }
        }

        for (BillingWrappers.ShippingItemsInfo si : shippingInfoSet) {
            if (uniqIdsToQliMap.containsKey(si.deviceUniqId)) {
                if (shippingItemsMap.get(si.deviceUniqId) == null) {
                    shippingItemsMap.put(si.deviceUniqId, new List<BillingWrappers.ShippingItemsInfo>());
                }
                shippingItemsMap.get(si.deviceUniqId).add(si);
            }
        }

        return shippingItemsMap;
    }

    private static Map<BillingWrappers.ShippingItemsInfo, CustomAddress__c> getCustomAddresses(Map<BillingWrappers.ShippingItemsInfo, CustomAddress__c> getCustomAddressMap) {
        List<CustomAddress__c> cAddressesFound = new List<CustomAddress__c>();
        List<CustomAddress__c> cAddressesToInsert = new List<CustomAddress__c>();
        Set<CustomAddress__c> cAddressesToInsertUnique = new Set<CustomAddress__c>();
        Set<String> countries = new Set<String>();
        Set<String> cities = new Set<String>();
        Set<String> zipCodes = new Set<String>();
        Set<String> addressLines = new Set<String>();
        Set<String> states = new Set<String>();

        for (BillingWrappers.ShippingItemsInfo si: getCustomAddressMap.keySet()) {
            countries.add(si.location.address.country);
            cities.add(si.location.address.city);
            zipCodes.add(si.location.address.zipCode);
            addressLines.add(si.location.address.addressLine);
            if (si.location.address.state != null) {
                states.add(si.location.address.state);
            }
        }

        cAddressesFound = (List<CustomAddress__c>) new CustomAddressSelector()
            .selectCustomAddressesNew(
                new List<Object> {countries, cities, zipCodes, addressLines, states}
            )
            .executeQuery();

        for (CustomAddress__c caFound : cAddressesFound) {
            for (BillingWrappers.ShippingItemsInfo si: getCustomAddressMap.keySet()) {
                if (compareCustomAddress(caFound, si.location.address)) {
                    getCustomAddressMap.put(si, caFound);
                }
            }
        }

        for (BillingWrappers.ShippingItemsInfo si: getCustomAddressMap.keySet()) {
            if (getCustomAddressMap.get(si) == null) {
                CustomAddress__c caAdd = new CustomAddress__c();
                String fullAddress = si.location.address.country + ', ' + si.location.address.state + ', ' + si.location.address.zipCode + ', ' + si.location.address.city + ', ' + si.location.address.addressLine;
                if (fullAddress.length() > 80) {
                    fullAddress = fullAddress.left(80);
                }
                caAdd.Name = fullAddress;
                caAdd.Country__c = si.location.address.country;
                caAdd.City__c = si.location.address.city;
                if (si.location.address.state != null) {
                    caAdd.State__c = si.location.address.state;
                }
                caAdd.PostalCode__c = si.location.address.zipCode;
                caAdd.Street__c = si.location.address.addressLine;
                caAdd.AddressLine__c = si.location.address.addressLine;
                caAdd.AdditionalAddressLine__c = si.location.address.additionalAddressLine;

                cAddressesToInsertUnique.add(caAdd);
                getCustomAddressMap.put(si, caAdd);
            }
        }

        if (cAddressesToInsertUnique.size() > 0) {
            cAddressesToInsert.addAll(cAddressesToInsertUnique);
            insert cAddressesToInsert;
        }
        for (BillingWrappers.ShippingItemsInfo si: getCustomAddressMap.keySet()) {
            CustomAddress__c caAssign = getCustomAddressMap.get(si);
            for(CustomAddress__c caCreated : cAddressesToInsert) {
                if(
                    caAssign.AddressLine__c == caCreated.AddressLine__c &&
                        caAssign.Name == caCreated.Name &&
                        caAssign.Country__c == caCreated.Country__c &&
                        caAssign.City__c == caCreated.City__c &&
                        caAssign.State__c == caCreated.State__c &&
                        caAssign.PostalCode__c == caCreated.PostalCode__c &&
                        caAssign.Street__c == caCreated.Street__c &&
                        caAssign.AddressLine__c == caCreated.AddressLine__c &&
                        caAssign.AdditionalAddressLine__c == caCreated.AdditionalAddressLine__c) {

                    getCustomAddressMap.put(si, caCreated);
                }
            }
        }

        return getCustomAddressMap;
    }

    private static Map<Id, QuoteLineItem> getQuoteLineItems(Map<String, List<BillingWrappers.ShippingItemsInfo>> shippingItemsMap, String quoteId) {

        Set<Id> qliIds = new Set<Id>();
        Map<Id, QuoteLineItem> qlis = new Map<Id, QuoteLineItem>();

        if (shippingItemsMap.size() > 0) {
            for (List<BillingWrappers.ShippingItemsInfo> silist : shippingItemsMap.values()) {
                for (BillingWrappers.ShippingItemsInfo si : silist) {
                    if (si.quoteLineItemId != null) {
                        qliIds.add(si.quoteLineItemId);
                    }
                }
            }
        }

        if (quoteId != null) {
            qliIds.add(quoteId);
        }
        qlis = new Map<Id, QuoteLineItem>((List<QuoteLineItem>)  new QuoteLineItemSelector()
            .selectQuoteLineItemsByQuoteIdsForShipping(
                new List<Object> {qliIds}
            )
            .executeQuery());

        return qlis;
    }

    public static Boolean hasShippingOptions(List<QuoteLineItem> qlis, Set<String> options) {
        for (QuoteLineItem shql: qlis) {
            if (!shql.Zero_Quantity__c && shql.Quantity > 0 && !shql.Custom_Address_QLI__r.isEmpty()) {
                for (CustomAddressAssignments__c caa : shql.Custom_Address_QLI__r) {
                    if (options.contains(caa.Type__c)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    @TestVisible
    private static Map<String,List<BillingWrappers.ShippingItemsInfo>> deleteCustomAddressAssignments(BillingWrappers.ParamsShipping shippingData) {
        List<CustomAddressAssignments__c> customAddresses = new CustomAddressAssignmentsSelector()
            .selectCustomAddressAssignmentsByOppIds(new List<Id>{ shippingData.opportunityId })
            .executeQuery();

        delete customAddresses;

        return null;
    }

    public static BillingWrappers.ShippingItemsInfo getShippingItem(CustomAddressAssignments__c caa) {
        BillingWrappers.ShippingItemsInfo shippingItem = new BillingWrappers.ShippingItemsInfo();
        shippingItem.location = getShippingLocation(caa);
        shippingItem.quoteLineItemId = caa.QuoteLineItem__c;
        shippingItem.junctionID = caa.Id;
        shippingItem.isDeleted = false;
        shippingItem.quantity = Integer.valueOf(String.valueOf(caa.Quantity__c));
        shippingItem.assignmentLineItemId = caa.AssignmentLineItem__c;
        shippingItem.deviceUniqId = getUniqIdForShippingItem(caa);
        shippingItem.qliProductId = caa.QuoteLineItem__r.Product_Lic_Id__c;

        return shippingItem;
    }

    public static BillingWrappers.ShippingLocation getShippingLocation(CustomAddressAssignments__c caa) {
        BillingWrappers.ShippingLocation shippingLocation = new BillingWrappers.ShippingLocation();
        shippingLocation.id = caa.CustomAddress__c + '-' + caa.Type__c + '-' + caa.AttentionTo__c;
        shippingLocation.shippingMethod = caa.Type__c;
        shippingLocation.attentionTo = caa.AttentionTo__c;
        shippingLocation.address = getShippingAddress(caa);
        shippingLocation.shippingLicensesTree = caa.ShippingLicenseTree__c;
        shippingLocation.shippingBillingCodeId = caa.ShippingBillingCodeId__c;

        return shippingLocation;
    }

    public static BillingWrappers.ShippingAddress getShippingAddress(CustomAddressAssignments__c caa) {
        BillingWrappers.ShippingAddress shippingAddress = new BillingWrappers.ShippingAddress();
        shippingAddress.id = caa.CustomAddress__c;
        shippingAddress.state = caa.CustomAddress__r.State__c;
        shippingAddress.additionalAddressLine = caa.CustomAddress__r.AdditionalAddressLine__c;
        shippingAddress.addressLine = caa.CustomAddress__r.AddressLine__c;
        shippingAddress.city = caa.CustomAddress__r.City__c;
        shippingAddress.country = caa.CustomAddress__r.Country__c;
        shippingAddress.zipCode = caa.CustomAddress__r.PostalCode__c;

        return shippingAddress;
    }

    private static String getUniqIdForShippingItem(CustomAddressAssignments__c caa) {
        String uniqId = caa.QuoteLineItem__r.Product_Lic_Id__c;
        if (caa.AssignmentLineItem__c != null) {
            uniqId = caa.QuoteLineItem__r.Product_Lic_Id__c
                + caa.AssignmentLineItem__r.AreaCode__r.Name
                + caa.AssignmentLineItem__r.Parent__r.Product_Lic_Id__c;
        }

        return uniqId;
    }

    private static Map<Id, List<String>> populateMapQliIdToListUniqId(BillingWrappers.ParamsShipping paramsDataShipping) {
        Map<Id, List<String>> qliIdToUniqIds = new Map<Id, List<String>>();

        for(List<BillingWrappers.ShippingItemsInfo> listShpItemsInfo : paramsDataShipping.shippingItemsMap.values()) {
            for (BillingWrappers.ShippingItemsInfo info : listShpItemsInfo) {
                if (qliIdToUniqIds.containsKey(info.quoteLineItemId)) {
                    qliIdToUniqIds.get(info.quoteLineItemId).add(info.deviceUniqId);
                } else {
                    qliIdToUniqIds.put(info.quoteLineItemId, new List<String>{ info.deviceUniqId });
                }
            }
        }

        return qliIdToUniqIds;
    }

    @TestVisible
    private static Boolean compareCustomAddress(CustomAddress__c foundCustomAddress, BillingWrappers.ShippingAddress shippingInfoCustomAddress) {
        return compareCustomAddressProperty(foundCustomAddress.AddressLine__c, shippingInfoCustomAddress.addressLine)
            && compareCustomAddressProperty(foundCustomAddress.AdditionalAddressLine__c, shippingInfoCustomAddress.additionalAddressLine)
            && compareCustomAddressProperty(foundCustomAddress.Country__c, shippingInfoCustomAddress.country)
            && compareCustomAddressProperty(foundCustomAddress.City__c, shippingInfoCustomAddress.city)
            && compareCustomAddressProperty(foundCustomAddress.PostalCode__c, shippingInfoCustomAddress.zipCode)
            && compareCustomAddressProperty(foundCustomAddress.State__c, shippingInfoCustomAddress.state);
    }

    private static Boolean compareCustomAddressProperty(String foundCustomAddressProperty, String shippingInfoCustomAddressProperty) {
        return (foundCustomAddressProperty == shippingInfoCustomAddressProperty || String.isBlank(foundCustomAddressProperty) && String.isBlank(shippingInfoCustomAddressProperty));
    }
}
public class AssetAssignmentHelper {

  public static Map<Id, String> assetIdToType = new Map<Id, String>();
  public static Map<Id, String> assetIdToName = new Map<Id, String>();
  public static Boolean assetTypePopulatedForDFR = false;
  public static Map<Id,Demand_Funnel__c> recordIdToActiveDFR = new Map<Id,Demand_Funnel__c>();
  public static Map<Id,Account> recordIdToAccount = new Map<Id,Account>();
  public static Marketing_Asset__c brokenAsset;
  public static Map<String,Marketing_Asset__c> assetStringToAsset = new Map<String,Marketing_Asset__c>();

  public static Id getAssetTouchRecordId(SObject sobj, String objectType) {
    Id recordId;
    switch on objectType {
      when 'Lead' {
        recordId = (Id) sobj.get('Lead__c');
      }
      when 'Contact' {
        recordId = (Id) sobj.get('Contact__c');
      }
    }
    return recordId;
  }

  public static void processAndUpsertAssetTouchesForInsertion(List<Asset_Touch__c> assetTouches, String objectType, Map<Id,Account> parentAccountMap) {
    recordIdToAccount = parentAccountMap;
    try {
      processAndUpsertAssetTouchesForInsertion(assetTouches, objectType);
    } catch(Exception e) {
      ExceptionHelper.createExceptionAndNotificacionHistory(e, assetTouches, 'Contact Exception');
    }
  }

  public static List<Asset_Touch__c> getAssetTouchesForRecord(SObject sobj) {
    List<Asset_Touch__c> newAssetTouches = new List<Asset_Touch__c>();
    List<String> concatenatedAssetStrings = new List<String>();
    String assetString = (String) sobj.get('Asset_Id__c');
    if (!String.isEmpty(assetString)) {
      concatenatedAssetStrings = assetString.split(';');
    }
    for (String concatenatedAssetString : concatenatedAssetStrings) {
      if (String.isEmpty(concatenatedAssetString)){
        continue;
      }
      String assetId = AssetAssignmentHelper.extractAssetFromConcatenatedId(concatenatedAssetString);
      String assetStatus = AssetAssignmentHelper.extractAssetStatusFromConcatenatedId(concatenatedAssetString);
      System.assert(!assetStringToAsset.isEmpty());
      if (assetId != null && assetStringToAsset.get(assetId) != null) {
        Asset_Touch__c newAssetTouch = new Asset_Touch__c();
        newAssetTouch.Marketing_Asset__c = assetStringToAsset.get(assetId).Id;
        newAssetTouch.Name = assetIdToName.get(assetStringToAsset.get(assetId).Id);
        newAssetTouch.Status__c = assetStatus;
        if (sobj.Id.getSObjectType() == Lead.SObjectType) {
          newAssetTouch.Lead__c = sobj.Id;
          newAssetTouch.Object_Type__c = 'Lead';
        } else if (sobj.Id.getSObjectType() == Contact.SObjectType) {
          newAssetTouch.Account__c = (Id) sobj.get('AccountId');
          newAssetTouch.Contact__c = sobj.Id;
          newAssetTouch.Object_Type__c = 'Contact';
        }
        newAssetTouch.Asset_Touch_DateTime__c = Datetime.now();
        newAssetTouch.Campaign__c = (Id) sobj.get('Most_Recent_Campaign__c');
        newAssetTouch.Unique_Name__c = String.valueOf(newAssetTouch.Marketing_Asset__c) + '.' + String.valueOf(sobj.Id);
        newAssetTouches.add(newAssetTouch);
      }
    }
    return newAssetTouches;
  }

  public static void processAndUpsertAssetTouchesForInsertion(List<Asset_Touch__c> assetTouches, String objectType) {
    Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
    if (ft != null && ft.Bypass_Asset_Logic__c == true){
      return;
    }
    Set<Id> recordIdsToFetchDFR = new Set<Id>();
    for (Asset_Touch__c at : assetTouches) {
      Id recordId = getAssetTouchRecordId(at, objectType);

      if (!AssetAssignmentHelper.recordIdToActiveDFR.containsKey(recordId)) {
        recordIdsToFetchDFR.add(recordId);
      }

      if (recordIdToAccount.containsKey(at.Account__c)){
      
          recordIdsToFetchDFR.add(at.Account__c);
      }
    }

    for (Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector().selectDFRForMarketingAssetProcessing(new List<Object>{recordIdsToFetchDFR, recordIdsToFetchDFR, recordIdsToFetchDFR,recordIdsToFetchDFR}).executeQuery()) {
      Id recordId = getAssetTouchRecordId(dfr, objectType);
      if (!AssetAssignmentHelper.recordIdToActiveDFR.containsKey(recordId)) {
        AssetAssignmentHelper.recordIdToActiveDFR.put(recordId, dfr);
      }
      if (dfr.Account__c != null && !AssetAssignmentHelper.recordIdToActiveDFR.containsKey(dfr.Account__c)){
          AssetAssignmentHelper.recordIdToActiveDFR.put(dfr.Account__c, dfr);
      }
    }


    for (Asset_Touch__c at : assetTouches) {
      Demand_Funnel__c dfr;
      if (AssetAssignmentHelper.recordIdToActiveDFR.containsKey(at.Account__c)) {
          dfr = AssetAssignmentHelper.recordIdToActiveDFR.get(at.Account__c);
      } else {
          dfr = AssetAssignmentHelper.recordIdToActiveDFR.get(getAssetTouchRecordId(at, objectType));
      }
            
      if (dfr != null) {
        at.DFR__c = dfr.Id;
        at.DFR_Status__c = dfr.DET_Current_Funnel_Status__c;
      }
      
      if (at.Account__c != null && recordIdToAccount.containsKey(at.Account__c)) {
        at.Account_Status__c = recordIdToAccount.get(at.Account__c).RC_Account_Status__c;
        at.Opportunity_Stage__c = recordIdToAccount.get(at.Account__c).Most_Recent_Opportunity_Stage__c;
      }
    }

    //processAndUpsertAssetTouchesForInsertion is only called in cases
    //where we've already updated Most_Recent_Asset__c,
    //so the trigger is unnecessary
    AssetTouchHandler.SKIP_TRIGGER = true;
    Database.upsert(assetTouches, Asset_Touch__c.Unique_Name__c, false);
    AssetTouchHandler.SKIP_TRIGGER = false;
  }

  public static Boolean assetChanged(SObject sobj, SObject oldSObject) {
    return (sobj.get('Asset_ID__c') != oldSObject.get('Asset_ID__c') && sobj.get('Asset_ID__c') != null);
  }

  public static String getMostRecentAssetId(String fullAssetString) {
    if (!String.isempty(fullAssetString)) {
      List<String> assets = fullAssetString.split(';');
      return assets[assets.size() - 1];
    }
    return null;
  }

  public static String extractAssetFromConcatenatedId(String concatenatedId) {
    String sobjAssetId = concatenatedId != null ? concatenatedId.split('\\.')[0] : null;
    return sobjAssetId;
  }

  public static String extractAssetStatusFromConcatenatedId(String assetString) {
    List<String> assetParts = assetString.split('\\.');
    return assetParts.size() < 2 ? '' : assetParts[1];
  }

  public static String extractAssetStatusFromConcatenatedId(SObject newSObject) {
    return extractAssetStatusFromConcatenatedId((String) newSObject.get('Asset_ID__c'));
  }

  public static void reassignAssets(List<SObject> sobjectList, Map<Id,SObject> oldMap) {
    Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
    if (ft != null && ft.Bypass_Asset_Logic__c == true){
      return;
    }
    // Filter out Opportunities since Asset_ID__c field has been removed
    List<SObject> touchedSObjects = new List<SObject>();
    for (SObject sobj : sobjectList) {
      if (sobj.getSObjectType() != Opportunity.SObjectType) {
        SObject oldSObject = oldMap.get(sobj.Id);
        if (assetChanged(sobj, oldSObject)) {
          touchedSObjects.add(sobj);
        }
      }
    }
    assignAssets(touchedSObjects);
  }

  public static void assignAssets(List<SObject> sobjectList) {
    Feature_Toggle__c ft = Feature_Toggle__c.getInstance();
    if (ft != null && ft.Bypass_Asset_Logic__c == true){
      return;
    }
    // Filter out Opportunities since Asset_ID__c field has been removed
    List<SObject> filteredList = new List<SObject>();
    for (SObject sobj : sobjectList) {
    if (sobj.getSObjectType() != Opportunity.SObjectType) {
        filteredList.add(sobj);
      }
    }
    
    for (SObject sobj : filteredList) {
      String fullAssetString = (String) sobj.get('Asset_ID__c');
      if (!String.isEmpty(fullAssetString)) {
        for (String concatenatedPartial : fullAssetString.split(';')) {
          assetStringToAsset.put(extractAssetFromConcatenatedId(concatenatedPartial), null);
        }
      }
    }

    if (!assetStringToAsset.isEmpty()) {
      for (Marketing_Asset__c mA : (List<Marketing_Asset__c>) new MarketingAssetSelector().selectActiveMarketingAssetsByAssetIds(new List<Object>{assetStringToAsset.keySet()}).executeQuery()) {
        if (ma.Asset_ID__c != null) {
          assetStringToAsset.put(ma.Asset_ID__c, ma);
        }
        assetIdToType.put(mA.Id, mA.Type__c);
        assetIdToName.put(ma.Id, ma.Name);
      }

      if (brokenAsset == null) {
        List<Marketing_Asset__c> brokenAssets = (List<Marketing_Asset__c>) new MarketingAssetSelector().selectMarketingAssetByName(new List<Object>{'Broken Asset'}).executeQuery();
        if (!brokenAssets.isEmpty()){
          brokenAsset = brokenAssets[0];
        }
      }

      for (SObject sobj : filteredList) {
        String mostRecentAssetId = getMostRecentAssetId((String) sobj.get('Asset_Id__c'));
        if (assetStringToAsset.get(extractAssetFromConcatenatedId(mostRecentAssetId)) != null) {
          Marketing_Asset__c ma = assetStringToAsset.get(extractAssetFromConcatenatedId(mostRecentAssetId));
          sobj.put('Most_Recent_Asset__c', ma.Id);
        } else if (brokenAsset != null && assetStringToAsset.containsKey(extractAssetFromConcatenatedId(mostRecentAssetId))) {
          sobj.put('Most_Recent_Asset__c', brokenAsset.Id);
        }
      }
    }
  }

}
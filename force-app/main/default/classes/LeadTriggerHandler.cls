public with sharing class LeadTriggerHandler {
    public static Map<Id, User> userDetailMap = new Map<Id, User>();
    public static Map<String, Account> userAccMap = new Map<String, Account>();
    public static Map<String, Campaign> campaignMap = new Map<String, Campaign>();
    public static Set<String> campaignIdSet = new Set<String>();
    public static Map<ID,Schema.RecordTypeInfo> rtMapByName = Lead.SObjectType
        .getDescribe()
        .getRecordTypeInfosById();
    public class PerformWorkFlowActions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.PerformWorkFlowActions(trigger.new);
        }
    }
    
    public class RemoveDowngradeValuesForNonDowngradedLeads extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.removeDowngradeValuesForNonDowngradedLeads((List<Lead>) Trigger.new);
        }
    }
    
    public class MarketoSync extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.MarketoSync((List<Lead>) Trigger.new);
        }
    }

    public class SetLeadCreationDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.SetLeadCreationDate(trigger.new); 
        }
    }
    
    public class PerformLeadCreateUpdateWorkflows extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.PerformLeadCreateUpdateWorkflows((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
        
    }
    
    public class CreateDFR extends Triggers.TriggerHandlerBase {
        override public void handle() {
            try {
                if (Trigger.new.size() > 25) {
                    List<DFR_CreateLead__e> eventList = new List<DFR_CreateLead__e>();
                    for (Lead ld : (List<Lead>) Trigger.new) {
                        if(ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                           && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
                        {
                            continue;
                            
                        }
                        String assetTouch;
                        if(ld.Most_Recent_Asset__c != null && ld.Asset_Id__c != null) {
                            assetTouch = JSON.serialize(AssetAssignmentHelper.getAssetTouchesForRecord(ld));
                        }
                        eventList.add(
                            new DFR_CreateLead__e(
                                Leads__c = ld.Id,
                                Asset_Touchs__c = assetTouch,
                                Is_Test__c = System.isBatch()
                            )
                        );
                    }
                    PlatformEvents.publishPlatformEvent(eventList, 'LeadTriggerHandler');
                } else {
                    List<Asset_Touch__c> assetTouchList = new List<Asset_Touch__c>();
                    for (Lead ld : (List<Lead>) Trigger.new) {
                        if (ld.Most_Recent_Asset__c != null && ld.Asset_Id__c != null) {
                            assetTouchList.addAll(AssetAssignmentHelper.getAssetTouchesForRecord(ld));
                        }
                    }
                    DG_DFR_Class.CreateLeadDFR((List<Lead>) Trigger.new);
                    if (!assetTouchList.isEmpty()) {
                        AssetAssignmentHelper.processAndUpsertAssetTouchesForInsertion(assetTouchList, 'Lead');
                    }
                }
                DG_DFR_Class.isLeadInsert = false;
            } catch (exception e) {
                DG_DFR_Class.dfrSaveException(e, null, (List<Lead>) Trigger.new, null, null);
            }
        }
    }
    
    public class ProcessDFRAfterUpdate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.ProcessDFRAfterUpdate((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class generateCampaignMember extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelperExt.generateCampaignMember((List<Lead>) Trigger.new);
        }
    }
    public class setLeadFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            userDetailMap = LeadTriggerHelperExt.setLeadFields((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class populateSystemProcessStageCreated extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSystemProcessStageCreated((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    
    public class populateSystemProcessStageBypassed extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSystemProcessStageBypassed((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class populateSystemProcessStageEnriched extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSystemProcessStageEnriched((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class stampedAsSLED extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c cs = Gating_Process_Stage__c.getInstance();
            if (cs != null && !cs.IsClayEnabled__c) { // To check if clay migration is disabled therefore ZI can continue to run
            LeadTriggerHelper.stampedAsSLED((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    }
    public class populateSystemProcessStageUpdated extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSystemProcessStageUpdated((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class populateLeadEnrichmentExclusion extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateLeadEnrichmentExclusion((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    
    public class PopulateLSEnrichmentDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateLSEnrichmentDate((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class populateZICDPMatch extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateZICDPMatch((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class PopulateSegmentName extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSegmentName((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class PopulateUltimateSMCountryEmp extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateUltimateSMCountryEmp((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class populateZipCustomFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateZipCustomFields((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        }
    }
    public class PopulateDateStatusChanged extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.PopulateDateStatusChanged((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);	
        }
    }
    public class GetLeadUltimatePartnerId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.getLeadUltimatePartnerId((List<Lead>)trigger.new, (Trigger.isInsert ? null : (Map<Id, Lead>)trigger.oldMap), rtMapByName);
        }
    }
    public class CheckPartnerLeadPermittedByBrand extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.checkPartnerLeadPermittedByBrand((List<Lead>)trigger.new, (Trigger.isInsert ? null : (Map<Id, Lead>)trigger.oldMap),LeadTriggerHelper.getApprovedBrandList((List<Lead>)trigger.new),rtMapByName);
        }
    }
    public class UpdatePartnerLeadCurrentOwnerEmail extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.updatePartnerLeadCurrentOwnerEmail((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.newMap, (Trigger.isInsert ? null : (Map<Id, Lead>)trigger.oldMap),rtMapByName);
        }
    }
    public class populateSaaSquatchReferralEmailIdOnLead extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSaaSquatchReferralEmailIdOnLead((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.oldMap);
        }
    }
    public class populateSaaSquatchAdvocateFieldsOnlead extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateSaaSquatchAdvocateFieldsOnlead((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.oldMap);
        }
    }
    public class populateBMIDBasedOnLeadSource extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateBMIDBasedOnLeadSource((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.oldMap);
        }
    }
    public class assignCampaigns extends Triggers.TriggerHandlerBase {
        override public void handle() {
            campaignMap = LeadTriggerHelperExt.assignCampaigns((List<Lead>)Trigger.New);
        }
    }
    public class assignAssets extends Triggers.TriggerHandlerBase {
        override public void handle() {
            AssetAssignmentHelper.assignAssets((List<Lead>)Trigger.new);
        }
    }
    public class reassignAssets extends Triggers.TriggerHandlerBase {
        override public void handle() {
            AssetAssignmentHelper.reassignAssets((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.oldMap);
        }
    }
    public class findAccountMap extends Triggers.TriggerHandlerBase {
        override public void handle() {
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            if(!byPassTrigger.Bypass_Lead_Before__c){
                userAccMap = LeadTriggerHelper.findAccountMap((List<Lead>)Trigger.new);
            }
        }
    }
    public class updateLeadActiveDate extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.updateLeadActiveDate((List<Lead>)Trigger.New, null);
        }
    }
    public class getLeadOwnerManager extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.getLeadOwnerManager((List<Lead>)trigger.new);
        }
    }    
    public class assignBrand extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.assignBrand((List<Lead>)trigger.new);
        }
    }
    public class updateMostRecentCampaign extends Triggers.TriggerHandlerBase {
        override public void handle() {
            campaignIdSet = LeadTriggerHelper.updateMostRecentCampaign((List<Lead>)trigger.new, (Map<Id, Lead>)trigger.oldMap, rtMapByName);
        }
    }
    public class campaignAtrributionLogic extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.campaignAtrributionLogic((List<Lead>)Trigger.New, (Map<Id, Lead>)Trigger.oldMap);
        }
    }
    public class updateRecruitedByField extends Triggers.TriggerHandlerBase {
        override public void handle() {
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            if(!byPassTrigger.Bypass_Lead_Before__c){
                LeadTriggerHelper.updateRecruitedByField((List<Lead>)Trigger.New);
            } 
        }
    }
    public class populateAssignedCSS extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.populateAssignedCSS((List<Lead>)Trigger.New);
        }
    }
    public class LeadQualificationRecordsProcessing extends Triggers.TriggerHandlerBase {
        override public void handle() {
            new LeadTriggerHelper.LeadQualificationRecordsProcessing().process((Map<Id, Lead>)Trigger.oldMap, (Map<Id, Lead>) Trigger.newMap);
            
        }
    }
    public class createCCIOForLeanDataRouting extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Boolean useLeanDataCCIOCreationOnTrigger = LeadRoutingSettings__c.getOrgDefaults().LeanDataCreateCCIOToggle__c;
            if (useLeanDataCCIOCreationOnTrigger){
                LeadTriggerHelper.createCCIOForLeanDataRouting((Map<Id, Lead>)Trigger.newMap, (Map<Id, Lead>)Trigger.oldMap);
            }
        }
    }
    public class createCompanyPersons extends Triggers.TriggerHandlerBase {
        override public void handle() {
            ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
            if(!byPassTrigger.Bypass_Company_Process_Logic__c){
                LeadTriggerHelper.createCompanyPersons((Map<Id, Lead>)Trigger.newMap, (Map<Id, Lead>)Trigger.oldMap);
            }            
        }
    }
    
    public class DFR_UpdateRelatedDFR extends Triggers.TriggerHandlerBase {
        
        override public void handle() {
            List<DFR_Update_Field__e> eventList = new List<DFR_Update_Field__e>();
            
            for (Lead ld : (List<Lead>) Trigger.new) {
                if(ld.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null 
                   && System.Label.BizMerge_Brand_Exclusion_List.contains(ld.Lead_Brand_Name__c))//BizMerge-Added Brand Name check to exclude DFR logic for ATT Leads
                {
                    continue;
                }
                
                
                DFR_Update_Field__e event = new DFR_Update_Field__e();
                
                if (isChangedField(ld, Lead.SM_Employees__c)) {
                    event.Id__c = ld.Id;
                    event.Fields__c = DemandFunnelPlatEvents.SM_EMPLOYEES_FIELD;
                }
                
                if (isChangedField(ld, Lead.ZI_CDP_Account_Id__c)) {
                    event.Id__c = ld.Id;
                    event.Fields__c = String.isBlank(event.Fields__c) 
                        ? DemandFunnelPlatEvents.ACCOUNT_FIELD
                        : event.Fields__c + ';' + DemandFunnelPlatEvents.ACCOUNT_FIELD;
                }
                
                if (isChangedField(ld, Lead.Lead_Brand_Name__c) || isChangedField(ld, Lead.SM_Country__c)) {
                    event.Id__c = ld.Id;
                    event.Fields__c = String.isBlank(event.Fields__c)
                        ? DemandFunnelPlatEvents.INTENDED_BRAND_FIELD
                        : event.Fields__c + ';' + DemandFunnelPlatEvents.INTENDED_BRAND_FIELD;
                }
                
                if (event.Id__c != null) {
                    eventList.add(event);
                }
            }
            
            if (eventList.size() > 0) {
                PlatformEvents.publishPlatformEvent(eventList, 'LeadTriggerHandler');
            }
        }
    }
    
    //Create Lead Extensions
    //Commenting as Lead_Ext__c is no longer Used
    /*public class CreateLeadExtensions extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.CreateLeadExtensions((List<Lead>)Trigger.new);
        }
    }*/
    
    public class SaasquatchSendEmailsForUnmatchedId extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.SaasquatchSendEmailsForUnmatchedId((List<Lead>)Trigger.new);
        }
    }
    public class LeadWebsiteValidation extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Map<Id,Lead> oldMap=(Map<Id, Lead>)trigger.oldMap;
            for (Lead lead : (List<Lead>)TriggerRecords) {
                if (String.isNotBlank(lead.Website) && lead.Website != oldMap.get(lead.Id).Website && !lead.Portal_Lead__c && !lead.Avaya_Partnership_Lead__c) {
                    Boolean isValid = LeadHelper.isValidWebsite(lead.Website);
                    if (!isValid) {
                        lead.addError(System.Label.Invalid_Website_Error);
                    }
                }
            }
        }
    }
    //Sharing recalculate for Access Controls
    public class accessControls extends Triggers.TriggerHandlerBase {
        List<LeadShare> listLeadShareInsert = new List<LeadShare>();
        List<LeadShare> listExistingShare = new List<LeadShare>();
        List<LeadShare> listSharingToDelete = new List<LeadShare>();
        Map<Id, Id> mapLeadToGroup = new Map<Id, Id>();
        Set<Id> leadIdsShareDelete = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> nonGSPLeadIds = new Set<Id>();
        SettingsService.AccessControlSettingsWrapper accessSettings = new SettingsService.AccessControlSettingsWrapper();
        Map<String, AccessControlSettings__c> mapBrandSetting = new Map<String, AccessControlSettings__c>();
        Map<String, AccessControlSettings__c> mapBISetting = new Map<String, AccessControlSettings__c>();
        Map<String, AccessControlSettings__c> mapPIDSetting = new Map<String, AccessControlSettings__c>();
        Set<String> allBrands = new Set<String>();
        Map<String, Id> mapGroups = new Map<String, Id>();
        Set<String> OtherBrands = new Set<String>();
        Set<String> OtherBIs = new Set<String>();
        Set<String> parentBrands = new Set<String>();
        String nonGSPGroup = '';
        String directGroup = '';
        Set<String> allPartnerIds = new Set<String>();
        public Map<String, AccessControlSettings__c> mapBIdentifierSetting {get; set;}
        public Set<String> allIdentifiers {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBrandSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBIToSetting {get; set;}
        public Map<String, AccessControlSettings__c> mapDirectBrandToSettingForLead {get; set;}
        
        override public void handle() {
            if (accessSettings.allGroups != null) {
                mapGroups = accessSettings.getMapOfGroups(accessSettings.allGroups); 
            }
            
            Map<Id, Segment_Master__c> segmentMasterById = new Map<Id, Segment_Master__c>([SELECT Id, Name FROM Segment_Master__c]);
            
            for (Lead ld : (List<Lead>) Trigger.new) {
                String groupName = '';
                if (isChangedField(ld, Lead.Sub_Brand__c) || isChangedField(ld, Lead.BusinessIdentity__c) || isChangedField(ld, Lead.Lead_Brand_Name__c) || isChangedField(ld, Lead.OwnerId) || isChangedField(ld, Lead.LeadPartnerID__c) || isChangedField(ld, Lead.SegmentName__c)) {
                    if (accessSettings.mapBrandSetting != null && accessSettings.mapBISetting != null && accessSettings.mapBISetting != null && accessSettings.mapPIDSetting != null) {
                        mapBrandSetting = accessSettings.mapBrandSetting;
                        mapBISetting = accessSettings.mapBISetting;
                        allBrands = accessSettings.allBrands;
                        OtherBrands = accessSettings.OtherBrands;
                        OtherBIs = accessSettings.OtherBIs;
                        nonGSPGroup = accessSettings.nonGSPGroup;
                        directGroup = accessSettings.directGroup;
                        allPartnerIds = accessSettings.allPartnerIds;
                        parentBrands = accessSettings.parentFromSetting;
                        mapBIdentifierSetting = accessSettings.mapBIdentifierSetting;
                        allIdentifiers = accessSettings.allIdentifiers;
                        mapDirectBIToSetting = accessSettings.mapDirectBIToSetting;
                        mapDirectBrandSetting = accessSettings.mapDirectBrandSetting;
                        mapDirectBrandToSettingForLead = accessSettings.mapDirectBrandToSettingForLead;
                    }                    
                    if((ld.Sub_Brand__c == null || !OtherBrands.contains(ld.Sub_Brand__c)) 
                       && (ld.BusinessIdentity__c == null || !OtherBIs.contains(ld.BusinessIdentity__c)) 
                       && (ld.Lead_Brand_Name__c == null || !OtherBrands.contains(ld.Lead_Brand_Name__c))
                       && !allPartnerIds.contains(ld.LeadPartnerID__c)){
                           system.debug('Inside Non GSP loop++');
                           leadIdsShareDelete.add(ld.Id);
                           String segmentName = segmentMasterById.containsKey(ld.SegmentName__c) ? segmentMasterById.get(ld.SegmentName__c).Name : null;
                           
                           if (mapDirectBrandSetting != null && ((mapDirectBrandSetting.containsKey(ld.Sub_Brand__c)
                                                                  && mapDirectBrandSetting.get(ld.Sub_Brand__c).ParentBrand__c == ld.Lead_Brand_Name__c)
                                                                 || (mapDirectBrandSetting.containsKey(ld.Sub_Brand__c)
                                                                     && mapDirectBrandSetting.get(ld.Sub_Brand__c).BusinessIdentity__c == ld.BusinessIdentity__c))                        
                               && ((mapDirectBrandSetting.get(ld.Sub_Brand__c).IsSegment__c
                                    && mapDirectBrandSetting.get(ld.Sub_Brand__c).Segment__c == segmentName)
                                   || !mapDirectBrandSetting.get(ld.Sub_Brand__c).IsSegment__c)) {
                                       system.debug('Inside Wholesale with segment++');
                                       groupName = mapDirectBrandSetting.get(ld.Sub_Brand__c).Public_Group_Name__c;
                                       mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                                       system.debug('groupName++ '+groupName);
                                       continue;
                           } else if (mapDirectBIToSetting != null && ((mapDirectBIToSetting.containsKey(ld.BusinessIdentity__c)
								&&  mapDirectBIToSetting.get(ld.BusinessIdentity__c).BusinessIdentity__c == ld.BusinessIdentity__c
                                && ((mapDirectBIToSetting.get(ld.BusinessIdentity__c).IsSegment__c
                                && mapDirectBIToSetting.get(ld.BusinessIdentity__c).Segment__c == segmentName)
                                || !mapDirectBIToSetting.get(ld.BusinessIdentity__c).IsSegment__c)) 
                                || (mapDirectBrandToSettingForLead.containsKey(ld.Lead_Brand_Name__c)
                                &&  mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).Brand__c == ld.Lead_Brand_Name__c
                                && ((mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).IsSegment__c
                                && mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).Segment__c == segmentName)
                                || !mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).IsSegment__c)))) {
                                 
                                    if(mapDirectBIToSetting.containsKey(ld.BusinessIdentity__c)
                                       &&  mapDirectBIToSetting.get(ld.BusinessIdentity__c).BusinessIdentity__c == ld.BusinessIdentity__c
                                       && ((mapDirectBIToSetting.get(ld.BusinessIdentity__c).IsSegment__c
                                       && mapDirectBIToSetting.get(ld.BusinessIdentity__c).Segment__c == segmentName)
                                       || !mapDirectBIToSetting.get(ld.BusinessIdentity__c).IsSegment__c)) {
                                           system.debug('Inside Direct with segment Business Identity');
                                           groupName = mapDirectBIToSetting.get(ld.BusinessIdentity__c).Public_Group_Name__c;
                                           mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                                           system.debug('groupName++ '+groupName);
                                           continue;                                            
                                    }
                                    if(mapDirectBrandToSettingForLead.containsKey(ld.Lead_Brand_Name__c)
                                       &&  mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).Brand__c == ld.Lead_Brand_Name__c
                                       && ((mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).IsSegment__c
                                       && mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).Segment__c == segmentName)
                                       || !mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).IsSegment__c)) {
                                               system.debug('Inside Direct with segment Brand');
                                               groupName = mapDirectBrandToSettingForLead.get(ld.Lead_Brand_Name__c).Public_Group_Name__c;
                                               mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                                               system.debug('groupName++ '+groupName);
                                               continue;                                            
                                    }
                            } else {
                                system.debug('Non GSP group++');
                                mapLeadToGroup.put(ld.id, mapGroups.get(nonGSPGroup));
                                nonGSPLeadIds.add(ld.Id);
                                continue;                                   
                            }
                       }
                    
                    if (mapBrandSetting != null && mapBISetting != null && mapGroups != null) {
                        if((ld.Lead_Brand_Name__c == null && !mapBrandSetting.containskey(ld.Lead_Brand_Name__c)) 
                           || (ld.BusinessIdentity__c == null && !mapBrandSetting.containskey(ld.BusinessIdentity__c))
                           || (ld.Sub_Brand__c == null && !mapBrandSetting.containskey(ld.Sub_Brand__c))) {
                               if(Trigger.isUpdate) {
                                   leadIdsShareDelete.add(ld.Id); 
                               }
                    	}
                        if (ld.Sub_Brand__c != null && mapBrandSetting.containsKey(ld.Sub_Brand__c)
                            && !parentBrands.contains(ld.Sub_Brand__c)) {                            
                                groupName = mapBrandSetting.get(ld.Sub_Brand__c).Public_Group_Name__c;
                                mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                                leadIdsShareDelete.add(ld.Id);
                                continue;
                        } else if (ld.BusinessIdentity__c != null && mapBISetting.containsKey(ld.BusinessIdentity__c)) {
                            groupName = mapBISetting.get(ld.BusinessIdentity__c).Public_Group_Name__c;
                            mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                            leadIdsShareDelete.add(ld.Id);
                            continue;
                        } else if (ld.Lead_Brand_Name__c != null && allBrands.contains(ld.Lead_Brand_Name__c) 
                            && mapBrandSetting.containsKey(ld.Lead_Brand_Name__c)) {
                                groupName = mapBrandSetting.get(ld.Lead_Brand_Name__c).Public_Group_Name__c;
                                mapLeadToGroup.put(ld.Id, mapGroups.get(groupName));
                                leadIdsShareDelete.add(ld.Id);
                                continue;
                        }
                    }
                }
            }
            if (!leadIdsShareDelete.isEmpty() && mapGroups.isEmpty() && accessSettings.allGroups != null) {
                mapGroups = accessSettings.getMapOfGroups(accessSettings.allGroups);
            }
            if (!leadIdsShareDelete.isEmpty() && mapGroups != null) {
                listExistingShare = [SELECT Id, LeadId, UserOrGroupId, LeadAccessLevel
                                     FROM LeadShare
                                     WHERE LeadId IN: leadIdsShareDelete
                                     AND UserOrGroupId IN: mapGroups.values()
                                     AND RowCause = 'Manual'];
                if (!listExistingShare.isEmpty() && !mapLeadToGroup.isEmpty()) {
                    recalculateSharing(listExistingShare, mapLeadToGroup);
                } else if (listExistingShare.isEmpty() && !mapLeadToGroup.isEmpty()) {
                    addNewLeadSharing(mapLeadToGroup);
                } else if (!listExistingShare.isEmpty() && mapLeadToGroup.isEmpty()) {
                    deleteExistingSharing(listExistingShare);
                }
            }
        }
        
        private void directSharingRecalculate(Map<Id, Id> mapLeadToGroup, Id ldId){
            if(mapLeadToGroup.get(ldId) == mapGroups.get(nonGSPGroup) && mapGroups.get(directGroup) != null) {
                listLeadShareInsert.add(new LeadShare(LeadId = ldId, UserOrGroupId = mapGroups.get(directGroup),
                                                  		LeadAccessLevel='Edit', RowCause='Manual'));
            }
        }
        
        private void recalculateSharing(List<LeadShare> listExistingShare, Map<Id, Id> mapLeadToGroup) {
            for (LeadShare ldShare : listExistingShare) {
                if (mapLeadToGroup.containsKey(ldShare.LeadId) && mapLeadToGroup.get(ldShare.LeadId) == ldShare.UserOrGroupId) {
                    mapLeadToGroup.remove(ldShare.LeadId);
                } else {
                	if (nonGSPLeadIds.contains(ldShare.LeadId) && ldShare.UserOrGroupId == mapGroups.get(directGroup)) {
        				continue;
    				}
                    listSharingToDelete.add(ldShare);
                }
            }
            if (!listSharingToDelete.isEmpty()) {
                deleteExistingSharing(listSharingToDelete);
            }
            if (!mapLeadToGroup.isEmpty()) {
                addNewLeadSharing(mapLeadToGroup);
            }
        }
        
        private void deleteExistingSharing(List<LeadShare> listSharingToDelete) {
            if (!listSharingToDelete.isEmpty()) {
                delete listSharingToDelete;
            }
        }
        
        private void addNewLeadSharing(Map<Id, Id> mapLeadToGroup) {
            if (!mapLeadToGroup.isEmpty()) {
                for (Id ldId : mapLeadToGroup.keySet()) {
                    if (mapLeadToGroup.get(ldId) != null) {
                        listLeadShareInsert.add(new LeadShare(LeadId = ldId, UserOrGroupId = mapLeadToGroup.get(ldId),
                                                              LeadAccessLevel='Edit', RowCause='Manual'));
                    }
                    directSharingRecalculate(mapLeadToGroup, ldId);
                }
            }
            
            if (!listLeadShareInsert.isEmpty()) {
                insert listLeadShareInsert;
            }
        }
    }
    public class PopulateIntentFlow extends Triggers.TriggerHandlerBase {
        override public void handle() {
            LeadTriggerHelper.PopulateIntentFlow((List<Lead>)Trigger.New);
        }
    }

    public class SendDatatoClayforEnrichment extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Gating_Process_Stage__c cs = Gating_Process_Stage__c.getInstance();
            if (cs != null && cs.IsClayEnabled__c) {
                LeadTriggerHelper.SendDatatoClayforEnrichment((List<Lead>)Trigger.New);
            }
        }
    }
}
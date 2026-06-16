public without sharing class DealSupportTriggerHandler {

    public class InsertAttachmentsOnContracts extends Triggers.TriggerHandlerBase {
        override public void handle() {
            createAttachmentsOnContracts(this.triggerRecords, (Map<Id,Deal_Support__c>) Trigger.oldMap);
        }

        private void createAttachmentsOnContracts(List<Deal_Support__c> newDealSupportList, Map<Id,Deal_Support__c> oldMap){
            Set<Id> dealSupportIds=new Set<Id>();
            Set<Id> accountIds=new Set<Id>();
            List<ContentDocumentLink> contentDocumentLst=new List<ContentDocumentLink>();
            for(Deal_Support__c dealsupport:newDealSupportList){
                if(dealsupport.Status__c=='Signature Complete' && oldMap.get(dealsupport.Id).Status__c != 'Signature Complete'){
                    dealSupportIds.add(dealsupport.Id);
                    if(dealsupport.Customer_Account__c!=null){
                        accountIds.add(dealsupport.Customer_Account__c);
                    }
                }
            }
            if((!dealSupportIds.isEmpty()&&dealSupportIds.size()>0)&&(!accountIds.isEmpty()&&accountIds.size()>0)){
                List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId 
                                               FROM ContentDocumentLink
                                               WHERE LinkedEntityId IN:dealSupportIds];  
                if(null!=cdl && !cdl.isEmpty() && cdl.size()>0){
                    String contractID = null;
                    List<Contract> contractList = [Select Id,AccountId from Contract where Account.Id IN :accountIds order by CreatedDate desc limit 1];
                    if(null!=contractList && contractList.size()>0){
                       contractID = contractList.get(0).Id;
                    }                
                    if(contractID!=null){
                        for(ContentDocumentLink cdLink:cdl){
                            ContentDocumentLink contentLink=new ContentDocumentLink();
                            contentLink.ContentDocumentId=cdLink.ContentDocumentId;
                            contentLink.LinkedEntityId=contractID;
                            contentDocumentLst.add(contentLink);
                        }
                        if(!contentDocumentLst.isEmpty()&&contentDocumentLst!=null){
                            Savepoint sp = Database.setSavepoint();
                            try
                            {
                                insert contentDocumentLst;
                                delete cdl;
                            }
                            catch(Exception e)
                            {
                                Database.rollback(sp);
                            }
                        }
                    }
                }
            }
        }
    }

    public class PopulateDealSupportCountry extends Triggers.TriggerHandlerBase {
        override public void handle() {
            List<Deal_Support__c> newList = (List<Deal_Support__c>) this.triggerRecords;
            Map<Id,Account> partnerAccountMap = new Map<Id, Account>();
            Map<Id,Lead> leadMap = new Map<Id, Lead>();
            Map<Id,Opportunity> oppMap = new Map<Id, Opportunity>();
            Set<Id> accountIdSet = new Set<Id>();
            Set<Id> leadIdSet = new Set<Id>();
            Set<Id> oppIdSet = new Set<Id>();
            try{
                for(Deal_Support__c ds : newList){                
                    if(ds.Customer_Account__c != null){
                        accountIdSet.add(ds.Customer_Account__c);
                    }
                    else if(ds.Lead__c != null){
                        leadIdSet.add(ds.Lead__c);
                    }
                    else if(ds.Partner_Account__c != null){
                        accountIdSet.add(ds.Partner_Account__c);
                    }
                    if(ds.Opportunity__c != null){
                        oppIdSet.add(ds.Opportunity__c);
                    }
                } 
                if(null!=accountIdSet && accountIdSet.size()>0){
                    partnerAccountMap = new Map<Id,Account>([Select Id,Partner_Country__c, CurrencyIsoCode, Current_Owner__c, OwnerId  
                                                            From Account 
                                                            Where Id In:accountIdSet]);                 
                }
                if(null!=leadIdSet && leadIdSet.size()>0){
                    leadMap = new Map<Id,Lead>([Select Id, Country__c, CurrencyIsoCode,OwnerId  
                                            From Lead
                                            Where Id In:leadIdSet]);
                }
                if(null!=oppIdSet && oppIdSet.size()>0){
                    oppMap = new Map<Id,Opportunity>([Select Id,Name, CurrencyIsoCode,OwnerId,Strategic_Partner_RC_Owner__c 
                                            From Opportunity
                                            Where Id In:oppIdSet]);
                }
                system.debug('LeadMap>>'+leadMap);
                if((partnerAccountMap!=null && !partnerAccountMap.isEmpty()) || (leadMap!=null && !leadMap.isEmpty())){
                    for(Deal_Support__c ds : newList){
                        if(ds.Country__c == null){
                            if(ds.Customer_Account__c!= null && partnerAccountMap.get(ds.Customer_Account__c) != null){                        
                                if(partnerAccountMap.get(ds.Customer_Account__c).CurrencyIsoCode != null){                                
                                    if(partnerAccountMap.get(ds.Customer_Account__c).CurrencyIsoCode == 'CAD'){
                                        ds.Country__c = 'Canada';
                                    }
                                    else if(partnerAccountMap.get(ds.Customer_Account__c).CurrencyIsoCode == 'GBP'){
                                        ds.Country__c = 'United Kingdom';
                                    }
                                    else if(partnerAccountMap.get(ds.Customer_Account__c).CurrencyIsoCode == 'AUD'){
                                        ds.Country__c = 'Australia';
                                    }
                                }                            
                            }
                            else if(ds.Lead__c != null && leadMap.get(ds.Lead__c) != null){
                                if(leadMap.get(ds.Lead__c).Country__c != null){
                                    ds.Country__c = leadMap.get(ds.Lead__c).Country__c;
                                }
                                else{
                                    if(leadMap.get(ds.Lead__c).CurrencyIsoCode == 'CAD'){
                                        ds.Country__c = 'Canada';
                                    }
                                    else if(leadMap.get(ds.Lead__c).CurrencyIsoCode == 'GBP'){
                                        ds.Country__c = 'United Kingdom';
                                    }
                                    else if(leadMap.get(ds.Lead__c).CurrencyIsoCode == 'AUD'){
                                        ds.Country__c = 'Australia';
                                    }
                                }
                            }
                            else if(ds.Partner_Account__c!= null && partnerAccountMap.get(ds.Partner_Account__c) != null){
                                ds.Country__c = partnerAccountMap.get(ds.Partner_Account__c).Partner_Country__c;
                            }                          
                        }
                        if(ds.Lead__c !=null){
                            if(leadMap.get(ds.Lead__c) != null){
                                if(leadMap.get(ds.Lead__c).OwnerId !=null){
                                    ds.Assigned_To_Owner__c=leadMap.get(ds.Lead__c).OwnerId;
                                }
                            }
                        }
                        else if(ds.Opportunity__c != null){
                            if(oppMap.get(ds.Opportunity__c) != null){
                                if(oppMap.get(ds.Opportunity__c).OwnerId != null){
                                    ds.Assigned_To_Owner__c=oppMap.get(ds.Opportunity__c).OwnerId;
                                    if(oppMap.get(ds.Opportunity__c).Strategic_Partner_RC_Owner__c !=null) {
                                        ds.Strategic_Partner_RC_Owner_User__c=oppMap.get(ds.Opportunity__c).Strategic_Partner_RC_Owner__c;
                                    }
                                }
                            }
                        }
                        else if(ds.Customer_Account__c != null){
                            Account acc = partnerAccountMap.get(ds.Customer_Account__c);
                            if( acc != null){
                                if(acc.Current_Owner__c != null){
                                    ds.Assigned_To_Owner__c = acc.Current_Owner__c;
                                }
                                else if(acc.OwnerId != null )
                                {
                                    ds.Assigned_To_Owner__c = acc.OwnerId;
                                }
                            }
                        }
                    }
                }
            }catch(exception ex){
                system.debug(ex.getMessage());
            }          
        }
    }

    public class PopulateApprovedDiscountField extends Triggers.TriggerHandlerBase {
        override public void handle() {
            for(Deal_Support__c dealSupport: (List<Deal_Support__c>) this.triggerRecords){
                if(dealSupport.Type__c == 'Discount Request'){
                    dealSupport.Approved_Discount__c = null;
                }
            }            
        }
    }

    public class UpdateApprovedQuantityOnQuoteLines extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<String> setofQuoteId = new Set<String>();
            Map<Id,Deal_Support__c> oldMap = (Map<Id,Deal_Support__c>) Trigger.oldMap;
            List<Partner_Quote_Line__c> listOfQuoteLineToUpdate = new List<Partner_Quote_Line__c>();
            for(Deal_Support__c objDealSupport : (List<Deal_Support__c>) this.triggerRecords) {
                if(objDealSupport.Status__c != oldMap.get(objDealSupport.Id).Status__c 
                && objDealSupport.Status__c == Quote_PartnerQuoteUtil.QUOTE_STATUS_CLOSED_APPROVED 
                && objDealSupport.Type__c == Quote_PartnerQuoteUtil.DEAL_SUPPORT_TYPE_DISCOUNT_REQUEST) {
                    setofQuoteId.add(objDealSupport.Partner_Quote__c);
                }
            }
            if(!setofQuoteId.isEmpty()) {
                for(Partner_Quote_Line__c objQuoteLine : [SELECT Id,Approved_Quantity__c,Quantity__c 
                                                        FROM Partner_Quote_Line__c
                                                        WHERE Partner_Quote__c IN :setofQuoteId]) {
                    objQuoteLine.Approved_Quantity__c = objQuoteLine.Quantity__c;                                         
                    listOfQuoteLineToUpdate.add(objQuoteLine);
                }
            }
            
            if(!listOfQuoteLineToUpdate.isEmpty()) {
                update listOfQuoteLineToUpdate;
            }                
        }
    }   

    public class HandleDealSupportShare extends Triggers.TriggerHandlerBase {
        override public void handle() {            
            if (!Test.isRunningTest()){
                Quote_SharingHandler.handleDealSupportShare(trigger.newMap.keyset());
            } 
        }
    }

    public class PopulateDealSupportFieldsWithPackageFields extends Triggers.TriggerHandlerBase {
        override public void handle() {
            Set<Id> accIds = new Set<Id>();
			List<Deal_Support__c> dealSupportsToProcess = (List<Deal_Support__c>) this.triggerRecords;

            for (Deal_Support__c ds : dealSupportsToProcess) {
                if (ds.Customer_Account__c != null) {
                    accIds.add(ds.Customer_Account__c);
                }
            }

            if (accIds.isEmpty()) {
                return;
            }

            List<Package__c> packages = new PackageSelector()
                .selectPackagesForNewReferences(new List<Object> {accIds})
                .executeQuery();

			if (packages.isEmpty()) {
                return;
            }

            for (Deal_Support__c ds : dealSupportsToProcess) {
                Map<Id, Package__c> packageToProcessMap = PackageHelper.filterPackagesByService(packages, QuoteHelper.NGBS_OFFICE_PRODUCT);
                Package__c packageToProcess = packageToProcessMap.get(ds.Customer_Account__c);
                ds.User_ID__c = packageToProcess?.RC_Tier_ID__c;
            }
        }
    }
}
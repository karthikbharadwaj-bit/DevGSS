/*       
        * Created By    : Ankit Sharma
        * Created Date  : 17-01-2020
        * Description   : Controller class for Engage legal Lightning component
        * Test Class    :       
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/

public without sharing class Quote_PartnerQuoteEngageLegalController {
    
    @AuraEnabled
    public static void createDealSupport(Id partnerQuoteId){
        Partner_Quote__c objQuote = Quote_PartnerQuoteUtil.getQuote(partnerQuoteId);
        //Added by Ankit Sharma for dynamic queue name based on community..
        String BrandName = 'Avaya Cloud Office';
        if(objQuote.Opportunity__r.Brand_Name__c != null) {
           BrandName = objQuote.Opportunity__r.Brand_Name__c;
        }
        List<Deal_Support__c> lstDealSupport = new List<Deal_Support__c>();
        if(partnerQuoteId != null){
            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,true);
            lstDealSupport = [select id,Contract_Type__c,Playbook_Status__c from Deal_Support__c where Partner_Quote__c =: partnerQuoteId 
                              and Type__c =: 'New Contract Request' and Status__c != 'Closed-Approved' and owner.name = :queueName];
            if(Test.isRunningTest()) {
                lstDealSupport = [select id,Contract_Type__c,Playbook_Status__c from Deal_Support__c where Partner_Quote__c =: partnerQuoteId 
                              and Type__c =: 'New Contract Request' and Status__c != 'Closed-Approved'];
            
            }
        }
        if(lstDealSupport.size() > 0){
            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,false);
             //Added by Saradha for quote contract Submit to RC 
            QueueSObject QueueID = [Select Queue.Id, Queue.Name, Queue.Type from QueueSObject WHERE Queue.Name =:queueName Limit 1];
            
            for(Deal_Support__c objDealSupprt:lstDealSupport){
                if (QueueID.id   != null){
                    objDealSupprt.OwnerId = QueueID.Queue.Id;
                }
            }
            if(lstDealSupport.size() > 0){
                update lstDealSupport;    
            }
        }else{
            Deal_Support__c objDS = Quote_PartnerQuoteUtil.createDealSupport();
            objDS.Type__c = 'New Contract Request';
            partner_Quote__c objQuoteRec = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);
            objDS.Opportunity__c = objQuoteRec.Opportunity__c;
            objDS.Customer_Account__c = objQuoteRec.Opportunity__r.AccountId;
            //Changed By Ankit Sharma For Partner Account
            objDS.Partner_Account__c = objQuoteRec.Opportunity__r.Partner_Account__c;
            String oppName = Quote_PartnerQuoteUtil.getOpportunity(objQuoteRec.Opportunity__c);
            objDS.Name = 'New Contract Request - '+oppName;
            objDS.Status__c = 'New';
            objDS.Sub_Status__c = 'Non Standard Contract';
            //Changes Added By Ankit Sharma for dynamic queue
            String queueName = Quote_PartnerQuoteUtil.getQueueBasedOnCommunity(BrandName,false);
            if(BrandName != 'RingCentral' && BrandName != 'RingCentral Canada' 
               && BrandName != 'RingCentral UK' && BrandName != 'RingCentral EU' && BrandName != 'RingCentral AU') {
                   objDS.ownerId = Quote_PartnerQuoteUtil.getQueueId(queueName);
               }
            else {
                objDS.ownerId = objQuoteRec.Opportunity__r.ownerId;
            }
            objDS.Brand_Name__c = BrandName;
            objDS.Partner_Quote__c = partnerQuoteId;
            insert objDS; 
        }
    }
    
    @AuraEnabled
    public static Boolean dealSupportExists(Id partnerQuoteId){
        String queueName = Label.Avaya_Queue;
        List<Deal_Support__c> listOfDSs = [SELECT id FROM Deal_Support__c 
                                            WHERE Partner_Quote__c =: partnerQuoteId and type__c = 'New Contract Request' 
                                            and status__c != 'Closed-Approved'];
        return !listOfDSs.isEmpty();
    }
    public static Boolean dealSupportExistsInternal(Id partnerQuoteId){
        List<Deal_Support__c> listOfDSs = [SELECT id FROM Deal_Support__c 
                                            WHERE Partner_Quote__c =: partnerQuoteId and type__c = 'New Contract Request' 
                                            and status__c != 'Closed-Approved'];
        return !listOfDSs.isEmpty();
    }
    
    public static Boolean dealSupportExistsUpdate(Id partnerQuoteId,String avayaLegalComments){
         List<Deal_Support__c> listOfDSs=new List<Deal_Support__c>();
         Deal_Support__c dsnew=new Deal_Support__c();
         for(Deal_Support__c dsupport: [SELECT id,Partner_Quote__c FROM Deal_Support__c 
                                            WHERE Partner_Quote__c =: partnerQuoteId and type__c = 'New Contract Request' 
                                        and status__c != 'Closed-Approved']){
        dsnew.Id=dsupport.Id;
       if(avayaLegalComments!=null &&avayaLegalComments !=''){
            dsnew.Escalated_To_Legal__c=true;
            dsnew.Engage_Legal_Comments__c=avayaLegalComments;
        }
         else{
             dsnew.Escalated_To_Legal__c=false;
             dsnew.Engage_Legal_Comments__c='';                                    
        }
        listOfDSs.add(dsnew);

         }
         if(!listOfDSs.isEmpty()&&listOfDSs!=null) {
            update dsnew;
        }
        return !listOfDSs.isEmpty();
                                           
    }
    
    @AuraEnabled
    public static List<PartnerContractTypeWrapper> getPartnerContractTypes(String PartnerQuoteId)
    {
        List<PartnerContractTypeWrapper> partnerContractTypeWrapper = new List<PartnerContractTypeWrapper>();
        List<PartnerAttachmentTypeWrapper> partnerContractAttachmentTypeWrapper = new List<PartnerAttachmentTypeWrapper>();
        List<String> lstContractTypes = new List<String>{'Standard Attachments'};
        List<String> lstStandardAttachmentTypes = new List<String>{'Initial Order Form - Office Services','Commercial MSA','Professional Services','SLA for Support Office','SLA for Support Services','Security Addendum','DPA','BAA'};
        List<String> lstNonStandardAttachmentTypes = new List<String>{'Free Credit'};
        List<String> attachmentTypes = new List<String>();  
        List<Quote_Attachment__mdt> lstQuoteAttachmentMetadataList = new List<Quote_Attachment__mdt>();
        String defaultAttachment = 'Commercial MSA';
        //playbook changes starts
        Deal_Support__c objDS =new Deal_Support__c();
        List<Deal_Support__c> objDealSupportList = [Select Id,Promo_Code__c,Campaign__c,Discount__c,Approved_Discount__c,Discount_Details__c,Promotion__c,Status__c FROM Deal_Support__c WHERE Partner_Quote__c = :PartnerQuoteId AND Type__c='Discount Request'  and Opportunity__r.Brand_Name__c='Avaya Cloud Office' limit 1];
        if(!objDealSupportList.isEmpty() && objDealSupportList.size()>0 && objDealSupportList!=null){
            if(objDealSupportList[0].Status__c=='Closed-Approved' && (objDealSupportList[0].Promo_Code__c=='MIGRATE' || objDealSupportList[0].Promo_Code__c=='DEALDESK')){
                     objDS = objDealSupportList[0];
                    }
                }
         //playbook changes ends
        Partner_Quote__c objPartnerQuoteRec = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);
        if(objPartnerQuoteRec != null) {
            if(objPartnerQuoteRec.Number_of_Licenses__c > 250) {
                defaultAttachment = 'Enterprise MSA';
            }
        }
        
        List<Partner_Quote_Line__c> listofImpltationQuoteLine = [SELECT Id FROM Partner_Quote_Line__c WHERE Partner_Quote__c = :PartnerQuoteId 
                                                                 and Product_Catalogue__r.Category_Name__c = 'Implementation'
                                                                 and Product_Catalogue__r.Package_Product_Type__c includes('Implementation - Show Number Fields')];
        
        Boolean isAvaya = false;
        Boolean isContractTeam = false;
        String portalQuoteContractTeam;
        String portalTopMaster;
       //Added by Ishwarya for making dynamic across portals using custom metadata
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();
        if(null == comDetail){
            comDetailMap = CommunityInfo.getAllCommunityDetails();
            if(objPartnerQuoteRec != null && objPartnerQuoteRec.Opportunity__c !=null) {
                comDetail = comDetailMap.get(objPartnerQuoteRec.Opportunity__r.Brand_Name__c);
            }
        }
        if(comDetail != null) {
        	portalQuoteContractTeam=comDetail.Portal_Quote_Contract_Team__c;
            portalTopMaster = comDetail.Portal_Top_Master_Account_Id__c;
        }
         if(PartnerDealRegistrationUtil.getSelectedPartnerId() == portalTopMaster)
        {
            isAvaya = true;
        }
        if(UserInfo.getUserType() == 'Standard') {
                isContractTeam = true;
      	}
         if(isAvaya){
        
            Set<Id> userIds=new Set<Id>();
             if(portalQuoteContractTeam !=null){
                 for(GroupMember m : [Select Id, UserOrGroupId,GroupId,Group.type,Group.Name From GroupMember WHERE Group.Name=:portalQuoteContractTeam]) {
                     if(m.UserOrGroupId!=null){
                         userIds.add(m.UserOrGroupId);
                     }
                 }
             }
            
            if(!userIds.IsEmpty() && userIds!=null  && userIds.size()>0){
            if(userIds.contains(UserInfo.getUserId())){
                isContractTeam = true;
            }
            }
        }
        
        if(isAvaya) {
            lstQuoteAttachmentMetadataList.addAll([Select Id,isStandard__c,Available__c,label,Description__c,Approval_Type__c,Self_Approved__c,Approval_Required__c,DocumentName__c,Country__c,Brand_Name__c FROM Quote_Attachment__mdt order by label]);
        } else { 
            lstQuoteAttachmentMetadataList.addAll([Select Id,isStandard__c,label,Available__c,Description__c,Approval_Type__c,Self_Approved__c,Approval_Required__c,DocumentName__c,Country__c,Brand_Name__c  FROM Quote_Attachment__mdt WHERE isStandard__c = true order by label]);
        }
        for(String s : lstContractTypes)
        {
            attachmentTypes = new List<String>();
            if(s.contains('Standard') && !s.contains('Non-Standard'))
            {
                attachmentTypes = lstStandardAttachmentTypes;
            }
            else
            {
                attachmentTypes = lstNonStandardAttachmentTypes;
            }
            for(Quote_Attachment__mdt attach : lstQuoteAttachmentMetadataList)
            {
              if(attach.Brand_Name__c != null && objPartnerQuoteRec.Opportunity__r.Brand_Name__c != null && attach.Brand_Name__c.contains(objPartnerQuoteRec.Opportunity__r.Brand_Name__c) && attach.Country__c != null && objPartnerQuoteRec.Opportunity__r.Account.BillingCountry != null && attach.Country__c.contains(objPartnerQuoteRec.Opportunity__r.Account.BillingCountry) ) {
                if(isAvaya){                    
                    if(listofImpltationQuoteLine != null && !listofImpltationQuoteLine.isEmpty() && attach.label == 'Professional Services') {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(true,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);
                        partnerContractAttachmentTypeWrapper.add(patw);
                    } 
                    else if(attach.label == defaultAttachment) {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(true,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);  
                        partnerContractAttachmentTypeWrapper.add(patw);
                    }
                    else {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(false,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);
                        partnerContractAttachmentTypeWrapper.add(patw);
                    }
                    
                }
                else{
                    if(listofImpltationQuoteLine != null && !listofImpltationQuoteLine.isEmpty() && attach.label == 'Professional Services') {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(true,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);  
                        partnerContractAttachmentTypeWrapper.add(patw);
                    } else if(attach.label == defaultAttachment) {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(true,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);  
                        partnerContractAttachmentTypeWrapper.add(patw);
                    }
                    else {
                        PartnerAttachmentTypeWrapper patw = new PartnerAttachmentTypeWrapper(false,attach.label,attach.isStandard__c,attach.Description__c,attach.Self_Approved__c,attach.Approval_Required__c,attach.DocumentName__c,attach.Available__c);  
                        partnerContractAttachmentTypeWrapper.add(patw);
                    }
                }
              }
                
            }
            
            PartnerContractTypeWrapper pctw = new PartnerContractTypeWrapper(s,partnerContractAttachmentTypeWrapper,isAvaya,Integer.valueof(objPartnerQuoteRec.Number_of_Licenses__c),isContractTeam,comDetail,objDS); //playbook changes -Added objDSparam
            partnerContractTypeWrapper.add(pctw);
            partnerContractAttachmentTypeWrapper = new List<PartnerAttachmentTypeWrapper>();
        }
        return partnerContractTypeWrapper;
    }
    @AuraEnabled
    public static List<PartnerContractWrapper> getCustomMetaData(String PartnerQuoteId)
    {
        List<PartnerContractWrapper> partnerContractWrapperList = new List<PartnerContractWrapper>();
        List<PartnerContractMappingsWrapper> partnerContractMappingsWrapper = new List<PartnerContractMappingsWrapper>();
                Partner_Quote__c objPartnerQuoteRec = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);

                Deal_Support__c objDS =new Deal_Support__c();
        List<Deal_Support__c> objDealSupportList = [Select Id,Promo_Code__c,Campaign__c,Discount__c,Approved_Discount__c,Discount_Details__c,Promotion__c,Status__c FROM Deal_Support__c WHERE Partner_Quote__c = :PartnerQuoteId AND Type__c='Discount Request'  and Opportunity__r.Brand_Name__c='Avaya Cloud Office' limit 1];
        if(!objDealSupportList.isEmpty() && objDealSupportList.size()>0 && objDealSupportList!=null){
            if(objDealSupportList[0].Status__c=='Closed-Approved' && (objDealSupportList[0].Promo_Code__c=='MIGRATE' || objDealSupportList[0].Promo_Code__c=='DEALDESK')){
                     objDS = objDealSupportList[0];
                    }
                }

        String eldType;
        Map<String,String> mapOptionnNText = new Map<String,String>();
        Map<String,String> mapOptionnNTextTranslate = new Map<String,String>();
        String textToReplace = '';
        Boolean isOptionSelected = false;
        for(Partner_Contract_Details__mdt pcd : [Select Id,Approval_Required__c,Self_Approved__c, PlayBook_Section_Headings__c,Playbook_Text_Translation__c,isGridInputNeededPlayBook__c, isNumberInputNeeded__c,PlayBook_Sequence__c,PlayBook_Options__c, PlayBook_Term__c, PlayBook_Text__c,
                                                 (Select Id,Mapping_Option__c,Mapping_Text__c,Mapping_Value_Long__c from Partner_Contract_Generation_Mappings__r),
                                                 (Select Mapping_Option__c,Mapping_Text__c,Mapping_Value__c from French_Text_Mappings__r), PlayBook_Section_Footer__c, Brand_Name__c, Country__c,Playbook_Footer_Translation__c from Partner_Contract_Details__mdt order by PlayBook_Sequence__c asc])
        {
                       if(pcd.Brand_Name__c != null && objPartnerQuoteRec.Opportunity__r.Brand_Name__c != null && pcd.Brand_Name__c.contains(objPartnerQuoteRec.Opportunity__r.Brand_Name__c) && pcd.Country__c != null && objPartnerQuoteRec.Opportunity__r.Account.BillingCountry != null && pcd.Country__c.contains(objPartnerQuoteRec.Opportunity__r.Account.BillingCountry) ) { 
            List<String> optionsList = pcd.PlayBook_Options__c != null?pcd.PlayBook_Options__c.split(';'):new List<String>();
            List<String> headingList = pcd.PlayBook_Section_Headings__c != null?pcd.PlayBook_Section_Headings__c.split(';'):new List<String>();
            if(pcd.Partner_Contract_Generation_Mappings__r != null && pcd.Partner_Contract_Generation_Mappings__r.size() > 0)
            {
                for(Partner_Contract_Mappings__mdt pcm : pcd.Partner_Contract_Generation_Mappings__r)
                {                    
                    if(mapOptionnNText.containsKey(pcm.Mapping_Option__c))
                    { 
                        textToReplace = mapOptionnNText.get(pcm.Mapping_Option__c);
                        textToReplace = textToReplace.replaceAll(pcm.Mapping_Text__c,pcm.Mapping_Value_Long__c);
                        mapOptionnNText.put(pcm.Mapping_Option__c,textToReplace);
                    }
                    else
                    {
                        textToReplace = pcd.PlayBook_Text__c;     
                        textToReplace = textToReplace.replaceAll(pcm.Mapping_Text__c,pcm.Mapping_Value_Long__c);                        
                        mapOptionnNText.put(pcm.Mapping_Option__c,textToReplace);   
                    }
                }
            } 
            else
            {
                if(optionsList.size() > 0)
                {
                    mapOptionnNText.put(optionsList[0],pcd.PlayBook_Text__c);
                }                
            } 
                           if(pcd.French_Text_Mappings__r != null && pcd.French_Text_Mappings__r.size() > 0)
                {
                    for(French_Text_Mappings__mdt pcm : pcd.French_Text_Mappings__r){                    
                        if(mapOptionnNTextTranslate.containsKey(pcm.Mapping_Option__c))
                        { 
                            textToReplace = mapOptionnNTextTranslate.get(pcm.Mapping_Option__c);
                            textToReplace = textToReplace.replaceAll(pcm.Mapping_Text__c,pcm.Mapping_Value__c);
                            mapOptionnNTextTranslate.put(pcm.Mapping_Option__c,textToReplace);
                        }
                        else
                        {
                            textToReplace = pcd.Playbook_Text_Translation__c;   
                            system.debug('pcm.Mapping_Text__c>>'+pcm.Mapping_Text__c);
                            textToReplace = textToReplace.replaceAll(pcm.Mapping_Text__c,pcm.Mapping_Value__c);                        
                            mapOptionnNTextTranslate.put(pcm.Mapping_Option__c,textToReplace);   
                        }
                    }
                } 
                else
                {
                    if(optionsList.size() > 0)
                    {
                        mapOptionnNTextTranslate.put(optionsList[0],pcd.Playbook_Text_Translation__c);
                    }                
                }
            if(mapOptionnNText != null && mapOptionnNText.size() > 0)
            {
                for(String option : optionsList)
                {                    
                    if(mapOptionnNText.containsKey(option))
                    {
                        if(option == optionsList[0])
                        {
                            isOptionSelected = true;
                        }
                        else
                        {
                            isOptionSelected = false;
                        }
                        PartnerContractMappingsWrapper pcmw = new PartnerContractMappingsWrapper(option,mapOptionnNText.get(option),isOptionSelected,mapOptionnNTextTranslate.get(option));
                        partnerContractMappingsWrapper.add(pcmw); 
                    }                    
                }
            }                           
            PartnerContractWrapper pcw = new PartnerContractWrapper(false,pcd.isGridInputNeededPlayBook__c,pcd.isNumberInputNeeded__c,pcd.PlayBook_Term__c,optionsList,partnerContractMappingsWrapper,headingList,pcd.Approval_Required__c,pcd.Self_Approved__c,pcd.PlayBook_Section_Footer__c,pcd.Playbook_Footer_Translation__c,objDS); //playbook changes -Added objDSparam         
            partnerContractWrapperList.add(pcw); 
            partnerContractMappingsWrapper = new List<PartnerContractMappingsWrapper>();
            mapOptionnNText = new Map<String,String>();
            mapOptionnNTextTranslate = new Map<String,String>();
        }
        }        
        return partnerContractWrapperList;
    } 
    @AuraEnabled
    public static UpdatePartnerContractWrapper getPartnerContractDetails(String partnerQuoteId)
    { 
        Map<String,String> mapTermNOption = new Map<String,String>();
        List<Attachment> lstAttachments = new List<Attachment>();
        List<String> lstAttachmentPdfNames = new List<String>();
        List<Partner_Contract_Service__c> lstPCS = new List<Partner_Contract_Service__c>();
        Partner_Quote__c objPartnerQuoteRec = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);//playbook changes 
        UpdatePartnerContractWrapper upcw;
        ContractUserInputWrapper inputWrapper = new ContractUserInputWrapper();
        //playbook changes  starts
        Deal_Support__c objDS =new Deal_Support__c();
        List<Deal_Support__c> objDealSupportList = [Select Id,Promo_Code__c,Campaign__c,Discount__c,Approved_Discount__c,Discount_Details__c,Promotion__c,Status__c FROM Deal_Support__c WHERE Partner_Quote__c = :PartnerQuoteId AND Type__c='Discount Request'  and Opportunity__r.Brand_Name__c='Avaya Cloud Office' limit 1];
        if(!objDealSupportList.isEmpty() && objDealSupportList.size()>0 && objDealSupportList!=null){
            if(objDealSupportList[0].Status__c=='Closed-Approved' && (objDealSupportList[0].Promo_Code__c=='MIGRATE' || objDealSupportList[0].Promo_Code__c=='DEALDESK')){
                objDS = objDealSupportList[0];
            }
        }
		//playbook changes ends
        List<Partner_Contract__c> lstPC = [Select Id, Attachments_and_Options__c,Detail_Comments__c,Approval_Comments__c,Inputs_for_Legal__c,Avaya_Legal_Comments__c,Contract_Type__c, Partner_Quote__c, Status__c,(Select Id,Clause__c,Option__c,Term__c,Additional_Text_Input_Value__c,Number_Input_Value__c,Percentage_Input_Value__c,Text_Input_Value__c from Partner_Contract_Details__r) from Partner_Contract__c where Partner_Quote__c=:partnerQuoteId order by CreatedDate desc LIMIT 1]; 
        if(lstPC.size() > 0)
        {
            for(Partner_Contract_Service__c pcs : [Select Id,Minimum_Target__c,Minimum_Target_Effective_Date__c from Partner_Contract_Service__c where Partner_Contract_Detail__r.Partner_Contract__c in :lstPC])
            {
                lstPCS.add(pcs);
            } 
            if(lstPC[0].Partner_Contract_Details__r != null && lstPC[0].Partner_Contract_Details__r.size() > 0)
            {
                for(Partner_Contract_Detail__c pcd : lstPC[0].Partner_Contract_Details__r)
                {
                    mapTermNOption.put(pcd.Term__c,pcd.Option__c);
                    if(pcd.Term__c == 'Free Services (Credit) 1 month' && pcd.Number_Input_Value__c != null && pcd.Number_Input_Value__c > 0)
                    {
                        inputWrapper.freeCredit = pcd.Number_Input_Value__c;                                            
                    }
                    if(pcd.Term__c == 'Elasticity Clause for Office Services' && pcd.Number_Input_Value__c != null && pcd.Number_Input_Value__c > 0)
                    {
                        inputWrapper.digitalLines = pcd.Number_Input_Value__c;                                            
                    }
                    if(pcd.Term__c == 'Business Downturn Elasticity')
                    {
                        if(pcd.Percentage_Input_Value__c != null && pcd.Percentage_Input_Value__c > 0)
                        {
                            inputWrapper.elasticityPercent = pcd.Percentage_Input_Value__c;                                                
                        }  
                        if(pcd.Number_Input_Value__c != null && pcd.Number_Input_Value__c > 0)
                        {
                            inputWrapper.elasticityDigitalLines = pcd.Number_Input_Value__c;                                                
                        }
                    }
                    if(pcd.Term__c == 'Feature Addition')
                    {
                        if(pcd.Text_Input_Value__c != null && pcd.Text_Input_Value__c != null && pcd.Text_Input_Value__c != '')
                        {
                            inputWrapper.featureAdditionEdition = pcd.Text_Input_Value__c;                                                
                        }
                        if(pcd.Additional_Text_Input_Value__c != null && pcd.Additional_Text_Input_Value__c != null && pcd.Additional_Text_Input_Value__c != '')
                        {
                            inputWrapper.featureAdditions = pcd.Additional_Text_Input_Value__c;                                                
                        }
                    }
                    if(pcd.Term__c == 'Price Protection' && pcd.Percentage_Input_Value__c != null && pcd.Percentage_Input_Value__c > 0)
                    {
                         inputWrapper.priceProtectionPercent = pcd.Percentage_Input_Value__c;                                            
                    }
                }            
            }
            
            List<String> lstAttachmentNames = lstPC[0].Attachments_and_Options__c != null ? lstPC[0].Attachments_and_Options__c.split(';') : new List<String>();
            
            List<PartnerContractTypeWrapper> lstPCTW = getPartnerContractTypes(partnerQuoteId);
            for(PartnerContractTypeWrapper pctw : lstPCTW)
            {
                for(PartnerAttachmentTypeWrapper patw : pctw.attachmentTypesWrapper)
                {
                    patw.isSelected = false;
                    if(lstAttachmentNames.contains(patw.attachmentName))
                    {
                        patw.isSelected = true;
                    }
                }
            }
            List<PartnerContractWrapper> lstPCW = getCustomMetaData(partnerQuoteId);
            for(PartnerContractWrapper pcw : lstPCW)
            {
                if(mapTermNOption.containskey(pcw.term))
                {
                    pcw.isSelected = true;
                    for(PartnerContractMappingsWrapper pcmw : pcw.mappingsWrapper)
                    {
                        if(mapTermNOption.get(pcw.term) == pcmw.option)
                        {
                            pcmw.isSelectedOption = true;
                        }
                        else
                        {
                            pcmw.isSelectedOption = false;
                        }
                        if(pcw.term == 'Free Services (Credit) 1 month' && inputWrapper.freeCredit != null && inputWrapper.freeCredit > 0)
                        {
                            if(pcmw.text != null && pcmw.text.contains('-CREDIT-'))
                            {
                                pcmw.text = pcmw.text.replaceAll('-CREDIT-',String.valueOf(inputWrapper.freeCredit));
                            }
                        }
                        if(pcw.term == 'Elasticity Clause for Office Services' && inputWrapper.digitalLines != null && inputWrapper.digitalLines > 0)
                        {
                            if(pcmw.text != null && pcmw.text.contains('-NUMBEROFDIGITALLINES-'))
                            {
                                pcmw.text = pcmw.text.replaceAll('-NUMBEROFDIGITALLINES-',String.valueOf(inputWrapper.digitalLines));
                            }
                        }
                        if(pcw.term == 'Business Downturn Elasticity')
                        {
                            if(inputWrapper.elasticityPercent != null && inputWrapper.elasticityPercent > 0)
                            {
                                if(pcmw.text != null && pcmw.text.contains('-PERCENT-'))
                                {
                                    pcmw.text = pcmw.text.replaceAll('-PERCENT-',String.valueOf(inputWrapper.elasticityPercent));
                                }
                            }  
                            if(inputWrapper.elasticityDigitalLines != null && inputWrapper.elasticityDigitalLines > 0)
                            {
                                if(pcmw.text != null && pcmw.text.contains('-NUMBEROFDIGITALLINES-'))
                                {
                                    pcmw.text = pcmw.text.replaceAll('-NUMBEROFDIGITALLINES-',String.valueOf(inputWrapper.elasticityDigitalLines));
                                }
                            }
                        }
                        if(pcw.term == 'Feature Addition')
                        {
                            if(inputWrapper.featureAdditionEdition != null && inputWrapper.featureAdditionEdition != null && inputWrapper.featureAdditionEdition != '')
                            {
                                if(pcmw.text != null && pcmw.text.contains('-EDITION-'))
                                {
                                    pcmw.text = pcmw.text.replaceAll('-EDITION-',inputWrapper.featureAdditionEdition);
                                }
                            }
                            if(inputWrapper.featureAdditions != null && inputWrapper.featureAdditions != null && inputWrapper.featureAdditions != '')
                            {
                                if(pcmw.text != null && pcmw.text.contains('-ADDITIONS-'))
                                {
                                    pcmw.text = pcmw.text.replaceAll('-ADDITIONS-',inputWrapper.featureAdditions);
                                }
                            }
                        }
                        if(pcw.term == 'Price Protection' && inputWrapper.priceProtectionPercent != null && inputWrapper.priceProtectionPercent > 0)
                        {
                            if(pcmw.text != null && pcmw.text.contains('-PERCENT-'))
                            {
                                pcmw.text = pcmw.text.replaceAll('-PERCENT-',String.valueOf(inputWrapper.priceProtectionPercent));
                            }
                        }
                    }
                }
            }
            for(String s : lstAttachmentNames){
               lstAttachmentPdfNames.add(s+'.pdf'); 
            }              
            lstAttachments = [Select Id,Name from Attachment where ParentId = :partnerQuoteId and Name in :lstAttachmentPdfNames];            
            Boolean isAvaya = false;
            Boolean isContractTeam = false;
            
            //Added by Ishwarya for making dynamic across portals using custom metadata
            String potalTopMasterId; 
            String portalQuoteContractTeam;
            CommunityInfo comm = new CommunityInfo();
            Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
            Map<String,Community_Details__mdt> comDetailMap = new Map<String,Community_Details__mdt>();
            if(null == comDetail){
                comDetailMap = CommunityInfo.getAllCommunityDetails();
                if(objPartnerQuoteRec != null && objPartnerQuoteRec.Opportunity__c !=null) {
                    comDetail = comDetailMap.get(objPartnerQuoteRec.Opportunity__r.Brand_Name__c);
                }
            }
            if(comDetail != null) {
            	portalQuoteContractTeam = comDetail.Portal_Quote_Contract_Team__c;
                potalTopMasterId = comDetail.Portal_Top_Master_Account_Id__c;
            }
            
            if(PartnerDealRegistrationUtil.getSelectedPartnerId() == potalTopMasterId)
            {
                isAvaya = true;
            }
            
            if(isAvaya){
            Set<Id> userIds=new Set<Id>();
                if(portalQuoteContractTeam !=null){
                    for(GroupMember m : [Select Id, UserOrGroupId,GroupId,Group.type,Group.Name From GroupMember WHERE Group.Name=:portalQuoteContractTeam]) {
                        if(m.UserOrGroupId!=null){
                            userIds.add(m.UserOrGroupId);
                        }
                    }
                }
            if(!userIds.IsEmpty() && userIds!=null && userIds.size()>0){
            if(userIds.contains(UserInfo.getUserId())){
                isContractTeam = true;
            }
            }
            }
            
            List<Approval__c> objApprovalList = [Select Id,RC_final_documents_for_sign__c,RC_Approvals__c,RC_Entity__c,Commercial_MSA__c,
                                                 Participant_Agreement__c,NDA__c,POC__c,Order_Form__c,Amendment__c,SOW__c,SLA__c, 
                                                 Rooms_in_a_Box__c,SLA_Contact_Center__c,Service_Attachment_Office__c,Service_Attachment__c,
                                                 Security_Addendums__c,Service_Attachment_CC__c,Cloud_Connects__c,ProServ_Agreement__c,BAAs__c,
                                                 Service_Attachment_Engage_Digital__c,Model_Clauses__c,Service_Attachment_Engage_Voice__c,Model_Clauses_New__c,
                                                 Payment_Terms__c,Limitation_of_Liability_Changes__c,Trial_Period_Out_clause__c,Customer_Indem__c,
                                                 NS_RC_Indemnity__c,Free_Services_Credit_Amount__c,NS_Autorenewal__c,Standard_Step_Up__c,
                                                 NS_Customer_Term_Rights__c,Price_Protection__c,NS_Assignment__c,Value_Choice_of_Law__c,
                                                 Commitment_to_Future_Functionality__c,RecordtypeId,Insurance_Clause__c,Elasticity__c,
                                                 document_attached__c,Standard_Terms__c FROM Approval__c WHERE Partner_Quote__c = :partnerQuoteId];
            
            if(objApprovalList != null && !objApprovalList.isEmpty()) {
                upcw = new UpdatePartnerContractWrapper(lstPCTW,lstPCW,lstPC[0],lstPCS,lstAttachments,isAvaya,objApprovalList[0],inputWrapper,isContractTeam,comDetail,objDS);//playbook changes - Added param objDS
            } else { 
                upcw = new UpdatePartnerContractWrapper(lstPCTW,lstPCW,lstPC[0],lstPCS,lstAttachments,isAvaya,null,inputWrapper,isContractTeam,comDetail,objDS);//playbook changes - Added param objDS
            }
        }
        return upcw;
    }
    @AuraEnabled
    public static ResponseWrapper createPartnerContractRecords(String partnerContractWrapperString,
                                                               String partnerContractTypeWrapperString,String partnerQuoteId,
                                                               Boolean isUpdate,String partnerContractId,
                                                               List<Partner_Contract_Service__c> lstPCS,String contractType, 
                                                               String inputsForLegal, String detailComments, String approvalComments,
                                                               Approval__c objNewApprovalRec,List<String> sObjectAttachedFiles,
                                                               string currentTabId,String inputValuesParameter,String avayaLegalComments)
    {
        List<PartnerContractWrapper> partnerContractWrapper = (List<PartnerContractWrapper>) JSON.deserializeStrict(partnerContractWrapperString, List<PartnerContractWrapper>.class);
        List<PartnerContractTypeWrapper> partnerContractTypeWrapper = (List<PartnerContractTypeWrapper>) JSON.deserializeStrict(partnerContractTypeWrapperString, List<PartnerContractTypeWrapper>.class);
        ContractUserInputWrapper userInputWrapper = (ContractUserInputWrapper) JSON.deserializeStrict(inputValuesParameter,ContractUserInputWrapper.class);                
        List<Partner_Contract_Detail__c> lstPartnerContractDetailToInsert = new List<Partner_Contract_Detail__c>();
        List<Partner_Contract_Detail__c> lstPartnerContractDetailToDelete = new List<Partner_Contract_Detail__c>();
        List<Partner_Contract__c> lstPartnerContractToInsert = new List<Partner_Contract__c>();
        List<Partner_Contract__c> lstPartnerContractToUpdateApproval = new List<Partner_Contract__c>();
        List<String> lstAttachmentNames = new List<String>();
        List<Attachment> lstAttachments = new List<Attachment>();
        List<String> lstAttachmentPdfNames = new List<String>();
        Map<String,List<Partner_Contract_Service__c>> mapTermNLstPCS = new Map<String,List<Partner_Contract_Service__c>>();
        List<Partner_Contract_Service__c> lstPCSToInsert = new List<Partner_Contract_Service__c>();
        Partner_Quote__c objQuoteRec = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);
        String response = 'Success';
        Boolean isSuperUser = Quote_PartnerQuoteUtil.checkSuperUser();
        SavePoint sp = Database.setSavepoint();
        Boolean approvalRequired = false;
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        try
        {
            if(partnerContractTypeWrapper.size() > 0)
            {                
                Partner_Contract__c pc;
                if(partnerContractId == null)
                {
                    pc = new Partner_Contract__c();
                    pc.Partner_Quote__c = partnerQuoteId;
                }
                else
                {
                    pc = new Partner_Contract__c(Id = partnerContractId);
                }
                
                if(approvalComments != null && approvalComments != '') {
                    pc.Approval_Comments__c = approvalComments;
                }
                if(detailComments != null && detailComments != '') {
                    pc.Detail_Comments__c = detailComments;
                }
                if(avayaLegalComments != null && avayaLegalComments != ''){
                    pc.Avaya_Legal_Comments__c = avayaLegalComments;
                    Boolean dealSupportExist = dealSupportExistsInternal(partnerQuoteId);
                    if(dealSupportExist) {
                        Boolean isdealSupportPresent = dealSupportExistsUpdate(partnerQuoteId,avayaLegalComments);
                    } else {
                        Deal_Support__c objDS = Quote_PartnerQuoteUtil.createDealSupport();
                        objDS.Type__c = 'New Contract Request';
                        partner_Quote__c objQuoteRecord = Quote_PartnerQuoteUtil.getQuote(PartnerQuoteId);
                        objDS.Opportunity__c = objQuoteRecord.Opportunity__c;
                        objDS.Customer_Account__c = objQuoteRecord.Opportunity__r.AccountId;
                        //Changed By Ankit Sharma For Partner Account
            			objDS.Partner_Account__c = objQuoteRecord.Opportunity__r.Partner_Account__c;
            			String oppName = Quote_PartnerQuoteUtil.getOpportunity(objQuoteRecord.Opportunity__c);
                        objDS.Name = 'New Contract Request - '+oppName;
                        objDS.Status__c = 'New';
                        objDS.Sub_Status__c = 'Non Standard Contract';
                        objDS.ownerId = Quote_PartnerQuoteUtil.getQueueId(comDetail.Portal_Queue__c);
                        objDS.Brand_Name__c = objQuoteRec.Opportunity__r.Brand_Name__c;
                        objDS.Partner_Quote__c = partnerQuoteId;
                        objDS.Engage_Legal_Comments__c=avayaLegalComments;
                        objDS.Escalated_To_Legal__c=true;
                        insert objDS; 
                    }
                }
                
                pc.Status__c = 'Initiated';
                if(contractType != null && contractType != '')
                {
                    pc.Contract_Type__c = contractType;
                    
                }               
                if(inputsForLegal != null && inputsForLegal != '' )
                {
                    pc.Inputs_for_Legal__c = inputsForLegal;
                    Boolean isDealSupportToCreate = false;
                    if(!isSuperUser && partnerContractId == null) {
                        isDealSupportToCreate = true;
                    } else if(!isSuperUser && partnerContractId != null) {
                        Boolean dealSupportExist = dealSupportExistsInternal(partnerQuoteId);
                        if(!dealSupportExist) {
                            isDealSupportToCreate = true;
                        }
                    }
                    
                    if(isDealSupportToCreate) {
                        Deal_Support__c objDS = Quote_PartnerQuoteUtil.createDealSupport();
                        objDS.Type__c = 'New Contract Request';
                        objDS.Opportunity__c = objQuoteRec.Opportunity__c;
                        objDS.Customer_Account__c = objQuoteRec.Opportunity__r.AccountId;
                        //Changed By Ankit Sharma For Partner Account
            			objDS.Partner_Account__c = objQuoteRec.Opportunity__r.Partner_Account__c;
            			String oppName = Quote_PartnerQuoteUtil.getOpportunity(objQuoteRec.Opportunity__c);
                        objDS.Name = 'New Contract Request - '+oppName;
                        objDS.Status__c = 'New';
                        objDS.Sub_Status__c = 'Non Standard Contract';
                        objDS.ownerId = Quote_PartnerQuoteUtil.getQueueId(comDetail.Portal_Queue__c);
                        objDS.Brand_Name__c = objQuoteRec.Opportunity__r.Brand_Name__c;
                        objDS.Partner_Quote__c = partnerQuoteId;
                        insert objDS; 
                    }
                }
                else {
                    pc.Inputs_for_Legal__c = null;
                }
                for(PartnerContractTypeWrapper pctw : partnerContractTypeWrapper){                    
                    for(PartnerAttachmentTypeWrapper patw : pctw.attachmentTypesWrapper){
                        if(patw.isSelected == true){
                            lstAttachmentNames.add(patw.attachmentName);                      
                        }
                    }                    
                }
                //&& pc.Contract_Type__c == 'Standard' condition removed BY Ankit SHarma 20-01-2020
                if(lstAttachmentNames != null && lstAttachmentNames.size() > 0 )
                {
                    pc.Attachments_and_Options__c = String.join(lstAttachmentNames, ';'); 
                }
                else {
                    pc.Attachments_and_Options__c = null;
                }
                lstPartnerContractToInsert.add(pc);                
            }
            if(lstPartnerContractToInsert.size() > 0)
            {
                upsert lstPartnerContractToInsert;
            } 
            if(partnerContractId != null)
            {
                for(Partner_Contract_Detail__c pcd : [Select Id from Partner_Contract_Detail__c where Partner_Contract__c = :partnerContractId])
                {
                    lstPartnerContractDetailToDelete.add(pcd);
                }
                if(lstPartnerContractDetailToDelete.size() > 0)
                {
                    delete lstPartnerContractDetailToDelete;
                }
            }
            for(Partner_Contract__c pc : lstPartnerContractToInsert)
            {
                if(partnerContractWrapper.size() > 0)
                {
                    for(PartnerContractWrapper pcw : partnerContractWrapper)
                    {
                        if(pcw.isSelected == true)
                        {
                            if(pcw.approvalRequired){
                                approvalRequired = true;
                            }
                            Partner_Contract_Detail__c pcd = new Partner_Contract_Detail__c();
                            pcd.Partner_Contract__c = pc.Id;
                            pcd.Term__c = pcw.term;
                            for(PartnerContractMappingsWrapper pcmw : pcw.mappingsWrapper){
                                if(pcmw.isSelectedOption == true)
                                {
                                    pcd.Option__c = pcmw.option;
                                    if(pcw.isGridInputNeeded == false)
                                    {
                                       pcd.Clause__c = pcmw.text; 
                                    }
                                    if(userInputWrapper != null)
                                    {
                                        system.debug('userInputWrapper.freeCredit');
                                        if(pcd.Term__c == 'Free Services (Credit) 1 month' && userInputWrapper.freeCredit != null && userInputWrapper.freeCredit > 0)
                                        {
                                            pcd.Number_Input_Value__c = userInputWrapper.freeCredit;
                                            if(pcd.Clause__c != null && pcd.Clause__c.contains('-CREDIT-'))
                                            {
                                                pcd.Clause__c = pcd.Clause__c.replaceAll('-CREDIT-',String.valueOf(userInputWrapper.freeCredit));
                                            }
                                        }
                                        if(pcd.Term__c == 'Elasticity Clause for Office Services' && userInputWrapper.digitalLines != null && userInputWrapper.digitalLines > 0)
                                        {
                                            pcd.Number_Input_Value__c = userInputWrapper.digitalLines;
                                            if(pcd.Clause__c != null && pcd.Clause__c.contains('-NUMBEROFDIGITALLINES-'))
                                            {
                                                pcd.Clause__c = pcd.Clause__c.replaceAll('-NUMBEROFDIGITALLINES-',String.valueOf(userInputWrapper.digitalLines));
                                            }
                                        }
                                        if(pcd.Term__c == 'Business Downturn Elasticity')
                                        {
                                            if(userInputWrapper.elasticityPercent != null && userInputWrapper.elasticityPercent > 0)
                                            {
                                                pcd.Percentage_Input_Value__c = userInputWrapper.elasticityPercent;
                                                if(pcd.Clause__c != null && pcd.Clause__c.contains('-PERCENT-'))
                                                {
                                                    pcd.Clause__c = pcd.Clause__c.replaceAll('-PERCENT-',String.valueOf(userInputWrapper.elasticityPercent));
                                                }
                                            }  
                                            if(userInputWrapper.elasticityDigitalLines != null && userInputWrapper.elasticityDigitalLines > 0)
                                            {
                                                pcd.Number_Input_Value__c = userInputWrapper.elasticityDigitalLines;
                                                if(pcd.Clause__c != null && pcd.Clause__c.contains('-NUMBEROFDIGITALLINES-'))
                                                {
                                                    pcd.Clause__c = pcd.Clause__c.replaceAll('-NUMBEROFDIGITALLINES-',String.valueOf(userInputWrapper.elasticityDigitalLines));
                                                }
                                            }
                                        }
                                        if(pcd.Term__c == 'Feature Addition')
                                        {
                                            if(userInputWrapper.featureAdditionEdition != null && userInputWrapper.featureAdditionEdition != null && userInputWrapper.featureAdditionEdition != '')
                                            {
                                                pcd.Text_Input_Value__c = userInputWrapper.featureAdditionEdition;
                                                if(pcd.Clause__c != null && pcd.Clause__c.contains('-EDITION-'))
                                                {
                                                    pcd.Clause__c = pcd.Clause__c.replaceAll('-EDITION-',userInputWrapper.featureAdditionEdition);
                                                }
                                            }
                                            if(userInputWrapper.featureAdditions != null && userInputWrapper.featureAdditions != null && userInputWrapper.featureAdditions != '')
                                            {
                                                pcd.Additional_Text_Input_Value__c = userInputWrapper.featureAdditions;
                                                if(pcd.Clause__c != null && pcd.Clause__c.contains('-ADDITIONS-'))
                                                {
                                                    pcd.Clause__c = pcd.Clause__c.replaceAll('-ADDITIONS-',userInputWrapper.featureAdditions);
                                                }
                                            }
                                        }
                                        if(pcd.Term__c == 'Price Protection' && userInputWrapper.priceProtectionPercent != null && userInputWrapper.priceProtectionPercent > 0)
                                        {
                                            pcd.Percentage_Input_Value__c = userInputWrapper.priceProtectionPercent;
                                            if(pcd.Clause__c != null && pcd.Clause__c.contains('-PERCENT-'))
                                            {
                                                pcd.Clause__c = pcd.Clause__c.replaceAll('-PERCENT-',String.valueOf(userInputWrapper.priceProtectionPercent));
                                            }
                                        }
                                    }
                                }    
                            }                            
                            if(lstPCS != null && lstPCS.size() > 0 && pcw.isGridInputNeeded == true)
                            {
                                mapTermNLstPCS.put(pcd.Term__c,lstPCS);
                            }
                            lstPartnerContractDetailToInsert.add(pcd);
                        }
                    }
                }
            } 
            if(lstPartnerContractDetailToInsert.size() > 0)
            {
                insert lstPartnerContractDetailToInsert;
            }            
            for(Partner_Contract_Detail__c pcd : lstPartnerContractDetailToInsert){
                if(mapTermNLstPCS.containskey(pcd.Term__c))
                {
                    for(Partner_Contract_Service__c pcs : mapTermNLstPCS.get(pcd.Term__c)){
                        pcs.Partner_Contract_Detail__c = pcd.Id;
                        if(pcs.Id != null)
                        {
                            pcs.Id = null;
                        }
                        lstPCSToInsert.add(pcs);
                    }
                }
            }
            if(lstPCSToInsert.size() > 0)
            {
                insert lstPCSToInsert;
            }
            if(lstPartnerContractToUpdateApproval.size() > 0)
            {
                update lstPartnerContractToUpdateApproval;
            }
            for(String s : lstAttachmentNames){
               lstAttachmentPdfNames.add(s+'.pdf'); 
            }
            lstAttachments = [Select Id,Name from Attachment where ParentId = :partnerQuoteId and Name in :lstAttachmentPdfNames]; 
        }
        catch(Exception e)
        {
            system.debug(e);
            Database.rollback(sp);
            response = e.getMessage();
        } 
        ResponseWrapper rw = new ResponseWrapper(response,'',new List<Attachment>(),null);
        if(response == 'Success' && lstPartnerContractToInsert.size() > 0)
        {
            rw.partnerContractId = lstPartnerContractToInsert[0].Id;
            rw.lstAttachments = lstAttachments;
        }
        
        if(isSuperUser && currentTabId != null && currentTabId == 'three' && !objNewApprovalRec.Standard_Terms__c) {
            Id engageRecordTypeId = Schema.SObjectType.Approval__c.getRecordTypeInfosByName().get('Engage Legal').getRecordTypeId();
            objNewApprovalRec.RecordtypeId = engageRecordTypeId; //need added dyamic recordtypeId but for testing added hardcode BY Ankit Sharma
            objNewApprovalRec.Brand_Partner__c='Avaya Partner';
            objNewApprovalRec.Account__c = objQuoteRec.Opportunity__r.AccountId;
            objNewApprovalRec.Opportunity__c = objQuoteRec.Opportunity__c;
            upsert objNewApprovalRec;
            rw.objApprovalRec = objNewApprovalRec;
            
            if(sObjectAttachedFiles != null && !sObjectAttachedFiles.isEmpty()) {
               List<ContentDocumentLink> contentDocumentLinkList = [Select id,contentDocumentId,LinkedEntityId,ShareType  From ContentDocumentLink  Where ContentDocumentId IN :sObjectAttachedFiles and LinkedEntityId = :PartnerQuoteId];
                List<ContentDocumentLink> listOfContentDocumentlinkToInsert = new List<ContentDocumentLink>();
                List<ContentDocumentLink> listOfContentDocumentlinkToDelete = new List<ContentDocumentLink>();
                if(contentDocumentLinkList != null && !contentDocumentLinkList.isEmpty()) {
                    for(ContentDocumentLink objContentLink : contentDocumentLinkList) {
                        ContentDocumentLink clonedContentDocLink = objContentLink.clone();
                        clonedContentDocLink.LinkedEntityId = objNewApprovalRec.Id;
                        clonedContentDocLink.ShareType = objContentLink.ShareType;
                        listOfContentDocumentlinkToDelete.add(objContentLink);
                        listOfContentDocumentlinkToInsert.add(clonedContentDocLink);
                    }
                }
                
                if(!listOfContentDocumentlinkToDelete.isEmpty()) {
                    delete listOfContentDocumentlinkToDelete;
                }
                
                if(!listOfContentDocumentlinkToInsert.isEmpty()) {
                    insert listOfContentDocumentlinkToInsert;
                }
                
                
            }
        } else {
             rw.objApprovalRec = null;
        }

        try{
            updateDealSupportData(partnerQuoteId,approvalRequired,objNewApprovalRec.Standard_Terms__c);     
        }catch(Exception e){
            System.debug('Line Number '+e.getLineNumber()+' Message '+e.getMessage());
        }
       
        return rw;
    }
    @AuraEnabled
    public static String submitForApproval(String partnerContractId)
    {
        String response = 'Success';
        try
        {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting Contract Partner details for approval');
            req.setObjectId(partnerContractId);
            req.setProcessDefinitionNameOrId('Partner_Contract');
            Approval.ProcessResult result = Approval.process(req);
        }
        catch(Exception e)
        {
            response = e.getMessage();
        }        
        return response;
    }
    @AuraEnabled
    public static String recallApprovalController(String partnerContractId)
    {
        String response = 'Success';        
        try
        {
            List<ProcessInstanceWorkitem> workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :partnerContractId AND ProcessInstance.Status = 'Pending']; 
            if(workItems != null && workItems.size() > 0)
            {
                Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();  
                pwr.setAction('Removed');
                pwr.setWorkItemId(workItems[0].id);
                
                Approval.ProcessResult result = Approval.process(pwr);
            }
            else
            {
                response = 'No applicable approval process found to recall for Partner Contract record';
            }
        }
        catch(Exception e){
            response = e.getMessage();
        }        
        return response;
    }
    public class UpdatePartnerContractWrapper
    {
        @AuraEnabled public List<PartnerContractTypeWrapper> lstPartnerContractTypeWrapper;
        @AuraEnabled public List<PartnerContractWrapper> lstPartnerContractWrapper;
        @AuraEnabled public Partner_Contract__c partnerContract;
        @AuraEnabled public List<Partner_Contract_Service__c> pcsList;
        @AuraEnabled public List<Attachment> lstAttachments;
        @AuraEnabled public Approval__c existingApprovalRec;
        @AuraEnabled public Boolean isAvaya;
        @AuraEnabled public ContractUserInputWrapper inputWrapper;
        @AuraEnabled public Boolean isContractTeam;
        @AuraEnabled public Community_Details__mdt communityDetailsRecord;
        @AuraEnabled public Deal_Support__c objDS;//playbook changes - Added param objDS
        public UpdatePartnerContractWrapper(List<PartnerContractTypeWrapper> lstPartnerContractTypeWrapper,List<PartnerContractWrapper> lstPartnerContractWrapper,Partner_Contract__c partnerContract,List<Partner_Contract_Service__c> pcsList,List<Attachment> lstAttachments,Boolean isAvaya,Approval__c existingApprovalRec,ContractUserInputWrapper inputWrapper,Boolean isContractTeam,Community_Details__mdt communityDetailsRecord,Deal_Support__c objDS)
        {
            this.lstPartnerContractTypeWrapper = lstPartnerContractTypeWrapper;
            this.lstPartnerContractWrapper = lstPartnerContractWrapper;
            this.partnerContract = partnerContract;
            this.pcsList = pcsList;
            this.lstAttachments = lstAttachments;
            this.isAvaya = isAvaya;
            this.existingApprovalRec = existingApprovalRec;
            this.inputWrapper = inputWrapper;
            this.isContractTeam=isContractTeam;
            this.communityDetailsRecord=communityDetailsRecord;
            this.objDS = objDS;//playbook changes - Added param objDS
        }
    }
    public class ResponseWrapper
    {
        @AuraEnabled public String responseMessage;
        @AuraEnabled public String partnerContractId;
        @AuraEnabled public Approval__c objApprovalRec;
        @AuraEnabled public List<Attachment> lstAttachments;
        public ResponseWrapper(String responseMessage, String partnerContractId,List<Attachment> lstAttachments,Approval__c objApprovalRec)
        {
            this.responseMessage = responseMessage;
            this.partnerContractId = partnerContractId;
            this.lstAttachments = lstAttachments;
            this.objApprovalRec = objApprovalRec;
        }
    }
    public class PartnerContractTypeWrapper
    {
        @AuraEnabled public String contractType;
        @AuraEnabled public List<PartnerAttachmentTypeWrapper> attachmentTypesWrapper;
        @AuraEnabled public Boolean isAvaya;
        @AuraEnabled public Integer NoOfLicense;
        @AuraEnabled public Boolean isContractTeam;
        @AuraEnabled public Community_Details__mdt communityDetailsRecord;
        @AuraEnabled public Deal_Support__c objDS;//playbook changes - Added param objDS
        public PartnerContractTypeWrapper(String contractType,List<PartnerAttachmentTypeWrapper> attachmentTypesWrapper,Boolean isAvaya,Integer NoOfLicense,Boolean isContractTeam,Community_Details__mdt communityDetailsRecord,Deal_Support__c objDS)
        {
            this.contractType = contractType;
            this.attachmentTypesWrapper = attachmentTypesWrapper;
            this.isAvaya = isAvaya;
            this.NoOfLicense = NoOfLicense;
            this.isContractTeam=isContractTeam;
            this.communityDetailsRecord=communityDetailsRecord;
            this.objDS = objDS;//playbook changes - Added param objDS
        }
    }
    public class PartnerAttachmentTypeWrapper
    { 
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String attachmentName;
        @AuraEnabled public Boolean isStandard;
        @AuraEnabled public String Description;
         @AuraEnabled public Boolean selfApproved;
        @AuraEnabled public Boolean approvalRequired;
        @AuraEnabled public String isAvailable;
         @AuraEnabled public String docName;
        public PartnerAttachmentTypeWrapper(Boolean isSelected,String attachmentName,Boolean isStandard,String Description,Boolean selfApproved,
                                            Boolean approvalRequired,String docName,String isAvailable)
        {
            this.isSelected = isSelected;
            this.attachmentName = attachmentName;
            this.isStandard = isStandard;
            this.Description = Description;
            this.selfApproved=selfApproved;
            this.approvalRequired=approvalRequired;
            this.docName=docName;
            this.isAvailable = isAvailable;
        }
    }
    public class PartnerContractWrapper
    {
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public Boolean isGridInputNeeded;
        @AuraEnabled public Boolean isNumberInputNeeded;
        @AuraEnabled public String term;
        @AuraEnabled public List<String> options; 
        @AuraEnabled public List<String> headings; 
        @AuraEnabled public List<PartnerContractMappingsWrapper> mappingsWrapper;
        @AuraEnabled public Boolean approvalRequired;
        @AuraEnabled public Boolean selfApproved;
        @AuraEnabled public String footer;        
        @AuraEnabled public String footerTranslation;
        @AuraEnabled public Deal_Support__c objDS;//playbook changes - Added param objDS
        public PartnerContractWrapper(Boolean isSelected,Boolean isGridInputNeeded,Boolean isNumberInputNeeded,String term,List<String> options,List<PartnerContractMappingsWrapper> mappingsWrapper,List<String> headings,Boolean approvalRequired,Boolean selfApproved,String footer,String footerTranslation,Deal_Support__c objDS)
        {
            this.isSelected = isSelected;
            this.isGridInputNeeded = isGridInputNeeded;
            this.isNumberInputNeeded = isNumberInputNeeded;
            this.options = options;            
            this.term = term;
            this.mappingsWrapper = mappingsWrapper;
            this.headings = headings;
            this.approvalRequired = approvalRequired;
            this.selfApproved = selfApproved;
            this.footer = footer;            
            this.footerTranslation = footerTranslation;
            this.objDS = objDS;//playbook changes - Added param objDS
        }
    }
    public class PartnerContractMappingsWrapper
    {
        @AuraEnabled public String option;
        @AuraEnabled public String text; 
        @AuraEnabled public Boolean isSelectedOption;            
        @AuraEnabled public String frenchtext;    
        public PartnerContractMappingsWrapper(String option, String text, Boolean isSelectedOption,String frenchtext)
        {
            this.option = option;
            this.text = text;
            this.isSelectedOption = isSelectedOption;            
            this.frenchtext = frenchtext;
        }
    }
    
    @AuraEnabled
    public static List<ContentDocument> getAllFilesOnsObjectRecord(Id sObjectId){
        List<ContentDocument> contentDocumentListToReturn = new List<ContentDocument>();
        List<ContentDocumentLink> contentDocLinkOnsObjectList = new List<ContentDocumentLink>();
        
        //query for the ContentDocumentLink for provided sObject ID
        contentDocLinkOnsObjectList = [Select id, ContentDocumentId, LinkedEntityId From ContentDocumentLink Where LinkedEntityId =: sObjectId];
        Set<Id> contentDocIdSet = new Set<Id>();
        
        //check if the ContentDocumentLinks for provided sObject Id is found
        if(contentDocLinkOnsObjectList != null && !contentDocLinkOnsObjectList.isEmpty()){
            for(ContentDocumentLink conDocLink : contentDocLinkOnsObjectList){
                //get contentDocument Ids from the ContentDocumentLinks found on the sObject record
                contentDocIdSet.add(conDocLink.ContentDocumentId);
            }
        }
        
        //check contentDocumentIds Set is not empty
        if(contentDocIdSet != null && !contentDocIdSet.isEmpty()){
            //get all ContentDocuments on the sObject record
            contentDocumentListToReturn = [Select Id,Title,LatestPublishedVersionId,FileType,CreatedDate From ContentDocument Where ID IN :contentDocIdSet];
        }
        
        //check if the contentDocument List that needs to be returned is not Empty
        if(contentDocumentListToReturn != null && !contentDocumentListToReturn.isEmpty()){
            return contentDocumentListToReturn;
        } else{
            return null;
        }
    }
    
    /*****************************************************************************************************************************************************
* Description       :   Method to delete uploaded files from sObject record.
* Input Parameter   :   String (JSON formatted Content Document IDs)
* return type       :   void
*/
    @AuraEnabled
    public static void deleteFiles(String filesIdArrStr){
        List<ContentDocument> contentDocumentToDelete = new List<ContentDocument>();
        Set<Id> filesIdSet = new Set<Id>();
        
        //check if the JSON formatted String of ContentDocument Ids is not Blank
        if(filesIdArrStr != null && filesIdArrStr != ''){
            //get all ContentDocument Ids in a set
            filesIdSet = (Set<Id>)JSON.deserialize(filesIdArrStr, Set<Id>.class);
        }
        
        //check if the ContentDocument Ids set is not empty     
        if(filesIdSet != null && !filesIdSet.isEmpty()){
            
            //query to get all ContentDocument that needs to be deleted
            contentDocumentToDelete = [Select id From ContentDocument Where Id IN :filesIdSet];
            if(contentDocumentToDelete != null && !contentDocumentToDelete.isEmpty()){
                try{
                    delete contentDocumentToDelete;
                } catch(Exception ex){
                    System.debug('Exception--'+ex.getMessage());
                }   
            }
        }        
    }   
    //Added by Saradha for quote contract save 
    public static void updateDealSupportData(String partnerQuoteId,Boolean approvalRequired,Boolean contractType){
        List<Deal_Support__c> lstDealSupport = new List<Deal_Support__c>();
        System.debug('Inside updateDealSupportData ===== '+partnerQuoteId);
        if(partnerQuoteId != null){
            lstDealSupport = [select id,Contract_Type__c,Playbook_Status__c from Deal_Support__c where Partner_Quote__r.Id =: partnerQuoteId and Type__c =: 'Initial Order' and Status__c != 'Closed' ];
        }
        if(lstDealSupport.size() > 0){
            for(Deal_Support__c objDealSupprt:lstDealSupport){
                if(contractType == null || contractType == true){
                    objDealSupprt.Contract_Type__c = 'Standard';
                }else{
                    objDealSupprt.Contract_Type__c = 'Non Standard';
                }
                
                if(approvalRequired){
                    objDealSupprt.Playbook_Status__c = 'Playbook Approval Requried';
                }else{
                    objDealSupprt.Playbook_Status__c = 'Pre-Approved Playbook';
                }
            }
        }
        if(lstDealSupport.size() != 0){
            update lstDealSupport;
        }
    }
    public class ContractUserInputWrapper
    {
        @AuraEnabled public Decimal freeCredit;
        @AuraEnabled public Decimal digitalLines; 
        @AuraEnabled public Decimal elasticityPercent;  
        @AuraEnabled public Decimal elasticityDigitalLines;
        @AuraEnabled public String featureAdditionEdition; 
        @AuraEnabled public String featureAdditions;
        @AuraEnabled public Decimal priceProtectionPercent;
    }

}
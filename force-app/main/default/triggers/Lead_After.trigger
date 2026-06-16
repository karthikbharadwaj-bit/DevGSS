/*************************************************
Trigger on Event object
After Update: If AID or Five9 DNIS fields are updated try to find matching campaigns to add for membership
After Insert: Set Primary Campaign field.
              Send email notification to owner if owner is RCSF Sync (Means that lead was not distributed)
              Send email notification to owner if owner is not RCSF Sync but created by RCSF (Means that lead was distributed)
              Convert Partner Request leads
/************************************************/

trigger Lead_After on Lead (after insert, after update) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
    if (bypassTrigger != null && bypassTrigger.Bypass_Lead_Trigger__c == true) {
        System.debug('$$$ ByPassTrigger__c Active For Lead $$$');
        return;
    }

    if(Trigger.isInsert) {
        DG_DFR_Class.isLeadInsert = true;
    }



    string strError = '';
    strError = strError  + 'Lead After trigger started On Lead Conversion ' +  +' \r\n';
    strError = strError  + 'Lead After trigger Variable BY_PASS_LEAD_UPDATE: ' + TriggerHandler.BY_PASS_LEAD_UPDATE + ' \r\n';
    strError = strError  + 'Lead After trigger Variable BY_PASS_LEAD_UPDATE_ON_INSERT: ' + TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT + ' \r\n';

    if(Trigger.isUpdate && trigger.isAfter){
        if (Trigger.new.size() == 1) {
            if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true && Trigger.new[0].Avaya_Partnership_lead__c && Trigger.new[0].recordTypeId == LeadHelper.RT_ID_PARTNER_LEADS){
                
                if(System.isBatch()) {
                Sharing_AccountLeadHandler.sharingAOCOnLeadConvertFuture(trigger.new[0].Id);
                }
                else {
                    Sharing_AccountLeadHandlerQueueable updateJob = new Sharing_AccountLeadHandlerQueueable(trigger.new[0].Id);
                	System.enqueueJob(updateJob,3);
                }
                
            }
        }
         if(Trigger.new[0].Avaya_Partnership_lead__c){
            //Naresh Kumar - Calculate sharing if lead owner is changed.
            Sharing_AccountLeadHandler.handleLeadSharingOnOwnerChange(trigger.newMap, trigger.oldMap);
            Partner_LeadTrgHelper.recalculateDealSupportsOfLead(trigger.new, trigger.oldMap);
        }
 //Added for Sharing recalculate.	
        if(!Trigger.new[0].Avaya_Partnership_lead__c && (Trigger.new[0].Avaya_Partnership_lead__c != Trigger.old[0].Avaya_Partnership_lead__c)){	
            Sharing_AccountLeadHandler.handleLeadSharingOnOwnerChange(trigger.newMap, trigger.oldMap);	
        }
    }

    /*********For Desired Behaviour of Campaign Case**************/
    if(TriggerHandler.BY_PASS_LEAD_UPDATE){
        return;
    }
    new Triggers().bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.generateCampaignMember()).manage();

    if(trigger.isInsert){
        User loginUser = null;
        List<User> loginUsers = [SELECT Id,Systems_Integration_Users__c FROM User Where Id=: UserInfo.getUserId()];
        if(loginUsers.size() > 0) {
            loginUser = loginUsers.get(0);
        }
        
        if(loginUser != null && loginUser.Systems_Integration_Users__c && !System.isBatch()){
            try {
                //Future
                LeadUpdationFutureHandler.overrideExistingLead();
            } catch(Exception e) {
                ExceptionHelper.createExceptionAndNotificacionHistory(e, trigger.new, 'Lead Exception');
            }            
        }
    }


    /********************* DFR CODE (DemandGen) - Start ***********************************/
    new Triggers()
        .bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.CreateDFR())
        .bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.DFR_UpdateRelatedDFR())
        .manage();
	
    if(!DG_DFR_Class.isLeadInsert) {
        new Triggers()
            .bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.ProcessDFRAfterUpdate())
            .manage();
    }

    if(Trigger.isUpdate  && trigger.isAfter){
    // no bulk processing; will only run from the UI
        if (Trigger.new.size() == 1) {
            strError = strError  + 'Before DFR lead conversion logic ' + ' \r\n';
            if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true){
                try{
                    strError = StrError + 'Lead Id: ' + Trigger.new[0].Id + ' \r\n';
                    strError = StrError + 'Opportunity Id: ' + Trigger.new[0].ConvertedOpportunityId + ' \r\n';
                    strError = StrError + 'Contact Id: ' + Trigger.new[0].ConvertedContactId + ' \r\n';
                    strError = StrError + 'Account Id: ' + Trigger.new[0].ConvertedAccountId + ' \r\n';
                    strError = StrError + '1000 Lead_After Lead being converted' + ' \r\n';
                    if(DG_DFR_Class.LeadAfterConvert_FirstRun || test.isRunningTest()){
                        strError = StrError + '1100 Lead_After Pass Recursive flag' + ' \r\n' ;
                        DG_DFR_Class.DFR_ConvertLead(Trigger.new[0]);
                        DG_DFR_Class.LeadAfterConvert_FirstRun=false;
                    }
                    strError = StrError + '1200 Lead_After Completed Lead convert trigger' + ' \r\n';
                }catch(exception e){
                    strError = StrError + 'Error Lead_After - '+ e.getMessage() + ' \r\n';
                }
            }
        } else {    //Trigger.size() > 1        code fore debugging bulk Lead convert
            Integer i = 0;
            for (Lead convertedLead : Trigger.new ){
                i++;
                if (Trigger.oldMap.get(convertedLead.Id).isConverted == false && convertedLead.isConverted == true){
                    strError = StrError + 'Lead Id: '+i+' '+convertedLead.Id + ' \r\n';
                    strError = StrError + 'Opportunity Id: ' +i+' '+ convertedLead.ConvertedOpportunityId + ' \r\n';
                    strError = StrError + 'Contact Id: ' +i+' '+ convertedLead.ConvertedContactId + ' \r\n';
                    strError = StrError + 'Account Id: ' +i+' '+ convertedLead.ConvertedAccountId + ' \r\n';
                    strError = StrError + 'Lead being converted' + ' \r\n';
                }
            }
            strError = StrError + 'UserInfo and Id ' + UserInfo.getName()+' '+UserInfo.getUserId() +' \r\n';
        }
    }
	/********************** DFR CODE (DemandGen) - End **********************************/

     /*Shared the lead to partners if partner lead owner field is not blank*/
    try {
        if((UserInfo.getUserType()=='Standard')){
            strError = strError + 'Before Partner sharing logic ' + ' \r\n';
            Map<String,String> mapNewPartnerLead= new Map<String,String>();
            Map<String,String> mapOldPartnerLead= new Map<String,String>();
            if(Trigger.isInsert){
                for(Lead objLead:trigger.new){
                    if(objLead.Partner_Lead_Owner__c!=null){
                        mapNewPartnerLead.put(objLead.id,objLead.Partner_Lead_Owner__c);
                    }
                }
            }
            if(Trigger.isUpdate){
                if(TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT) {
                    return;
                }
                for(Lead objLead:trigger.new){
                    if((trigger.OldMap.get(objLead.id).Partner_Lead_Owner__c != objLead.Partner_Lead_Owner__c) ||
                        (trigger.OldMap.get(objLead.id).ownerId != objLead.ownerId)){
                        if(trigger.OldMap.get(objLead.id).Partner_Lead_Owner__c != null &&
                            trigger.OldMap.get(objLead.id).Partner_Lead_Owner__c != objLead.Partner_Lead_Owner__c){
                            mapOldPartnerLead.put(objLead.id,trigger.OldMap.get(objLead.id).Partner_Lead_Owner__c);
                        }
                        if(objLead.Partner_Lead_Owner__c != null){
                            mapNewPartnerLead.put(objLead.id,objLead.Partner_Lead_Owner__c);
                        }
                    }
                }
            }
            if(mapNewPartnerLead.size()>0 || mapOldPartnerLead.size()>0){
                ShareUtil.shareLeadToPartnerFromLeadTrigger(mapNewPartnerLead,mapOldPartnerLead,Trigger.New);
                //Added for sharing recalculation as per portal logic on lead owner change
                Sharing_AccountLeadHandler.handleLeadSharingOnOwnerChange(trigger.newMap, trigger.oldMap);
            }
            strError = strError  + 'After Partner sharing logic ' + ' \r\n';
        }
    }catch(Exception e){
        strError = strError  + 'Exception Partner sharing logic '+ e.getMessage() + ' \r\n';
    }

    if(Trigger.isUpdate && trigger.isAfter){
        if (Trigger.new.size() == 1) {
            if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true){
                insert new Exception_And_Notification_History__c(
                    Exception__c = 'Lead Conversion Exception - Lead_After Trigger 2 - '+ System.Now().format(),
                    Exception_Desc__c = strError, Object_Type__c = 'Lead',
                    RecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                        .get('Exception History').getRecordTypeId());
            }
        } else {
            if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true){
                insert new Exception_And_Notification_History__c(
                    Exception__c = 'Lead Conversion Exception - Lead_After Trigger 2 - '+ System.Now().format(),
                    Exception_Desc__c = strError, Object_Type__c = 'Lead',
                    RecordTypeId = Schema.SObjectType.Exception_And_Notification_History__c.getRecordTypeInfosByName()
                        .get('Exception History').getRecordTypeId());
            }
        }

        new Triggers()
            .bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.LeadQualificationRecordsProcessing())
            .manage();
    }

    new Triggers()
            .bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.createCCIOForLeanDataRouting())
            .bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.createCCIOForLeanDataRouting())
            .bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.createCompanyPersons())
            .bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.createCompanyPersons())
        	//.bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.CreateLeadExtensions()) //Create lead extensions //Commenting as Lead_Ext__c is no longer Used
            .bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.SaasquatchSendEmailsForUnmatchedId())   
            .bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.SendDatatoClayforEnrichment())
            .manage();

    new Triggers()
        	.bind(Triggers.Evt.afterinsert, new LeadTriggerHandler.accessControls())
        	.bind(Triggers.Evt.afterupdate, new LeadTriggerHandler.accessControls())
            .manage();
}
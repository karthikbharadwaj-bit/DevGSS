global class BatchJob_BmidFix implements Database.Batchable<sObject>, Database.Stateful {
    global String csvContentError = 'Id,ErrorMessage,Object \n';
    global String csvMockUpdateTitle = 'DFR ID,Prospect - Current BMID,Prospect - New BMID,' +
    ' Prospect Current Campaign Id,Prospect Current Campaign Name,Prospect New Campaign Id,Prospect New Campaign Name,Prospect Current Channel'+
    ',Prospect New Channel,Prospect Current Sub-Channel,Prospect New Sub-Channel' +
    ',Update DFR Status MQL?,MQL - Current BMID, MQL - New BMID, MQL_DateTime_Entered__c, Update DFR Status TAL?,TAL - Current BMID' +
    ',TAL - New BMID,Update DFR Status TQL?,TQL - Current BMID,TQL - New BMID,Update DFR Status SAL?,SAL - Current BMID' +
    ',SAL - New BMID,Update DFR Status SQL?,SQL - Current BMID,SQL - New BMID,SQL_DateTime_Entered__c' +
    ',Update DFR Status EOL?,EOL - Current BMID, EOL - New BMID, EOL_DateTime_Entered__c' +
    ',Update Lead BMID?,Adds campaign to Lead campaign history?,Current Lead BMID,New Lead BMID' +
    ',Update Contact BMID?,Adds campaign to Contact campaign history?,Current Contact BMID,New Contact BMID,Update opportunity BMID?' + 
    ',Adds campaign to Opportunity campaign history?,Current Opportunity BMID,New Opportunity,' + 
    'Include_in_RTLM__c,RTLM_Channel__c,RTLM_Country__c,RTLM_CW__c,RTLM_Lead_Source__c,RTLM_MQL__c,RTLM_Prospect__c,RTLM_Segment__c,RTLM_SQL__c \n';
    global Boolean sendEmail = false;
    String runType;
    static List<Lead> leadsForHistoryTrack = new List<Lead>();
    static List<Opportunity> opportunitiesForHistoryTrack = new List<Opportunity>();
    static List<Contact> contactForHistoryTrack = new List<Contact>();
    global Iterable<sObject> start(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            StaticResource sr = (StaticResource) new StaticResourceSelector()
            .selectStaticResourceByNames(new object[]{new String[]{ 'BmidFix' }})
            .executeQuery()[0];
            return ((List<sObject>) LeadCPUMonitorHelper.csvTosObjectList('Demand_Funnel__c', sr));
        } else {
            List<Lead> leads = new LeadSelector()
            .selectLeadByLastName(new object[]{'BmidFix'})
            .executeQuery();

            return (List<sObject>) new DemandFunnelSelector()
            .selectDFRByLeadIds(new object[]{leads})
            .selectFields(new List<String>{'Include_in_RTLM__c', 'RTLM_Channel__c', 'RTLM_Country__c', 'RTLM_CW__c', 'RTLM_Lead_Source__c',
            'RTLM_MQL__c', 'RTLM_Prospect__c', 'RTLM_Segment__c', 'RTLM_SQL__c','MQL_BMID__c', 'MQL_DateTime_Entered__c', 'SAL_BMID__c', 'SAL_DateTime_Entered__c', 'TAL_DateTime_Entered__c',
           'TAL_BMID__c', 'TQL_BMID__c', 'TQL_DateTime_Entered__c', 'SQL_BMID__c', 'SQL_DateTime_Entered__c', 'EOL_DateTime_Entered__c', 'EOL_BMID__c'
           , 'Contact__c', 'Opportunity__c', 'Prospect_Channel__c', 'Prospect_Campaign__c','Prospect_Campaign__r.Name','Prospect_SubChannel__c','SAL_Handoff_Owner__c','Prospect_BMID__c'})
            .executeQuery();
        }
    }

    public BatchJob_BmidFix(String runType) {
        this.runType = runType;
    }

    global void execute(Database.BatchableContext ctx, List<sObject> dfrs) {
        List<Id> leadIds = new List<Id>();
        List<Id> dfrIds = new List<Id>();
        Contact contactToFix = new Contact();
        Opportunity opportunityToFix = new Opportunity();
        Lead leadToFix = new Lead();
        String oldBmidValue = '';
        String newBmidValue = '';
        Demand_Funnel__c dfrToUpdate = new Demand_Funnel__c();
        List<Demand_Funnel__c> dfrsToUpdate = new List<Demand_Funnel__c>();
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Set<Id> dfrOpportunity = new Set<Id>();
        Set<Id> dfrContact = new Set<Id>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
        Map<String,Id> bmidCampaignIdMap = new Map<String,Id>();
        Map<String,Campaign> bmidCampaignMap = new Map<String,Campaign>();
        List<String> bmids = new List<String>();

        for (Demand_Funnel__c fileRow : (List<Demand_Funnel__c>) dfrs) {
            leadIds.add(fileRow.Lead__c);
            dfrIds.add(fileRow.Id);
            if (!bmids.contains(fileRow.SAL_Handoff_Owner__c)) {
                bmids.add(fileRow.SAL_Handoff_Owner__c);
            }
        }

        Map<ID, Demand_Funnel__c> dfrMap = getDfrMap(dfrIds);

        for (Demand_Funnel__c dfr : dfrMap.values()) {
            if (dfr.Opportunity__c != null) {
                dfrOpportunity.add(dfr.Opportunity__c);
            }
            if (dfr.Contact__c != null) {
                dfrContact.add(dfr.Contact__c);
            }
        }

        Map<Id,Lead> mapLead = getLeadMap(leadIds);
        
        if (!dfrContact.isEmpty()) {
            contactMap = getContactMap(dfrContact);
        }

        if (!dfrOpportunity.isEmpty()) {
            opportunityMap = getOpportunityMap(dfrOpportunity);
        }

        bmidCampaignIdMap = getBmidIdMap(bmids);
        bmidCampaignMap = getBmidCampaignMap(bmids);

        for (Demand_Funnel__c fileRow : (List<Demand_Funnel__c>) dfrs) {
            leadToFix = mapLead.get(fileRow.Lead__c);
            dfrToUpdate = dfrMap.get(fileRow.Id);
            dfrToUpdate.Id = fileRow.Id;
            oldBmidValue = fileRow.Prospect_BMID__c;
            /*SAL_Handoff_Owner__c it's a field that we only use to save the new BMID value using a dfr object. 
            This field its not going to change on original dfr its just a value holder.*/
            newBmidValue = fileRow.SAL_Handoff_Owner__c;
            if (runType == 'Export') {
                String recordString = '';
                sendEmail = true;
                recordString = recordString + exportDemandFunnelBMID(dfrToUpdate,oldBmidValue,newBmidValue,bmidCampaignMap);
                recordString = recordString + exportLeadBMID(leadToFix,oldBmidValue,newBmidValue);
                if (dfrToUpdate.Contact__c != null) {
                    contactToFix = contactMap.get(dfrToUpdate.Contact__c);
                    recordString = recordString + exportContactBMID(contactToFix,oldBmidValue,newBmidValue);
                } else {
                    recordString = recordString + exportContactBMIDNull();
                }
                if (dfrToUpdate.Opportunity__c != null) {
                    opportunityToFix = opportunityMap.get(dfrToUpdate.Opportunity__c);
                    recordString = recordString + exportOpportunityBMID(opportunityToFix,oldBmidValue,newBmidValue);
                } else {
                    recordString = recordString + exportOpportunityBMIDNull();
                }
                recordString = recordString + exportRTLMFields(dfrToUpdate) + '\n';
                csvMockUpdateTitle = csvMockUpdateTitle + recordString;
            } else if (runType == 'Fix') {
                if (dfrToUpdate.Contact__c != null) {
                    contactToFix = contactMap.get(dfrToUpdate.Contact__c);
                    contactsToUpdate.add(fixContactBMID(contactToFix,oldBmidValue,newBmidValue));
                }
                if (dfrToUpdate.Opportunity__c != null) {
                    opportunityToFix = opportunityMap.get(dfrToUpdate.Opportunity__c);
                    opportunitiesToUpdate.add(fixOpportunityBMID(opportunityToFix,oldBmidValue,newBmidValue));
                }
                dfrsToUpdate.add(fixDemandFunnelBMID(dfrToUpdate,oldBmidValue,newBmidValue,bmidCampaignIdMap));
                leadsToUpdate.add(fixLeadBMID(leadToFix,oldBmidValue,newBmidValue));
            }
        }

        Database.SaveResult[] srListLeadForTracking = null;
        Database.SaveResult[] srListContactForTracking = null;
        Database.SaveResult[] srListOpportunityForTracking = null;
        Database.SaveResult[] srListLead = null;
        Database.SaveResult[] srListDFR =  null;
        Database.SaveResult[] srListContact = null;
        Database.SaveResult[] srListOpportunity = null;

        if (!leadsForHistoryTrack.isEmpty()) {
            srListLeadForTracking = Database.update(leadsForHistoryTrack, false);
        }
        if (!contactForHistoryTrack.isEmpty() ) {
            srListContactForTracking = Database.update(contactForHistoryTrack, false);
        }
        if(!opportunitiesForHistoryTrack.isEmpty()) {
            srListOpportunityForTracking = Database.update(opportunitiesForHistoryTrack, false);
        }
        if (!dfrsToUpdate.isEmpty()) {
            srListDFR = Database.update(dfrsToUpdate,false);
        }
        if (!dfrsToUpdate.isEmpty()) {
            srListLead = Database.update(leadsToUpdate,false);
        }
        if (!contactsToUpdate.isEmpty()) {
            srListContact = Database.update(contactsToUpdate,false);
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            srListOpportunity  = Database.update(opportunitiesToUpdate,false);
        }

        checkSaveResults(srListDFR,srListLead,srListContact,srListOpportunity);

        if (srListLeadForTracking != null || srListContactForTracking != null || srListOpportunityForTracking != null) {
            checkSaveResults(null,srListLeadForTracking,srListContactForTracking,srListOpportunityForTracking);
        }
    }

    global void finish(Database.BatchableContext BC) {
        List<String> emailsToSend = getMailsForEmailSending();
        if(!emailsToSend.isEmpty() && (sendEmail || Test.isRunningTest())) {
            sendEmailTo(emailsToSend);
        }
    }

    void sendEmailTo(List<String> emails) {
        if (runType == 'Fix') {
            blob csvBlob = Blob.valueOf(csvContentError);
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName('BatchJobBMIDFixesErrors.xls');
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('BatchJob Bmid Fixes Errors');
            email.setToAddresses(emails);
            email.setPlainTextBody('Attached CSV Containing DFRs with issues');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.sendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        } else if (runType == 'Export') { 
            blob csvBlob = Blob.valueOf(csvMockUpdateTitle);
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName('BatchJobBmidFixExport.xls');
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('BatchJob Bmid Fixes');
            email.setToAddresses(emails);
            email.setPlainTextBody('Attached CSV Containing Bmid Fixes');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.sendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }

    List<String> getMailsForEmailSending() {
        BatchJobsConfiguration__c bjc = BatchJobsConfiguration__c.getValues('BatchJob_BmidFix');
        List<String> emailsToSend = new List<String>();
        if (bjc != null && String.isNotBlank(bjc.ErrorEmailDistributionList__c)) {
            emailsToSend = bjc.ErrorEmailDistributionList__c.split(',');
        }
        return emailsToSend;
    }

    void checkSaveResults(Database.SaveResult[] srListDFR, Database.SaveResult[] srListLead,
        Database.SaveResult[] srListContact,Database.SaveResult[] srListOpportunity) {
        
            if (srListDFR != null) {
            for (Database.SaveResult sr : srListDFR) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    String recordString = ''+sr.getId()+','+sr.getErrors()+','+'Demand Funnel'+'\n';
                    csvContentError = csvContentError + recordString;
                    sendEmail = true;
                }
            }
        }

        if(srListLead != null) {
            for (Database.SaveResult sr : srListLead) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    String recordString = ''+sr.getId()+','+sr.getErrors()+','+'Lead'+'\n';
                    csvContentError = csvContentError + recordString;
                    sendEmail = true;
                }
            }
        } 

        if (srListContact != null) {
            for (Database.SaveResult sr : srListContact) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    String recordString = ''+sr.getId()+','+sr.getErrors()+','+'Contact'+'\n';
                    csvContentError = csvContentError + recordString;
                    sendEmail = true;
                }
            }
        }

        if (srListOpportunity != null) {
            for (Database.SaveResult sr : srListOpportunity) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    String recordString = ''+sr.getId()+','+sr.getErrors()+','+'Opportunity'+'\n';
                    csvContentError = csvContentError + recordString;
                    sendEmail = true;
                }
            }
        }
    }

    Demand_Funnel__c fixDemandFunnelBMID(Demand_Funnel__c dfrToUpdate, String oldBmidValue, String newBmidValue, Map<String,Id> bmidCampaignIdMap) {
        String newCampaignId = bmidCampaignIdMap.get(newBmidValue);
        dfrToUpdate.Prospect_BMID__c = newBmidValue;
        dfrToUpdate.Prospect_Campaign__c = newCampaignId;
        if (dfrToUpdate.MQL_DateTime_Entered__c != null && (dfrToUpdate.MQL_BMID__c == null || dfrToUpdate.MQL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            dfrToUpdate.MQL_BMID__c = newBmidValue;
            dfrToUpdate.MQL_Campaign__c = newCampaignId;
        }
        if (dfrToUpdate.SAL_DateTime_Entered__c != null && (dfrToUpdate.SAL_BMID__c == null || dfrToUpdate.SAL_BMID__c.deleteWhitespace() == oldBmidValue)) {
            dfrToUpdate.SAL_BMID__c = newBmidValue;
            dfrToUpdate.SAL_Campaign__c = newCampaignId;
        }
        if (dfrToUpdate.TAL_DateTime_Entered__c != null && (dfrToUpdate.TAL_BMID__c == null || dfrToUpdate.TAL_BMID__c.deleteWhitespace() == oldBmidValue)) {
            dfrToUpdate.TAL_BMID__c = newBmidValue;
            dfrToUpdate.TAL_Campaign__c = newCampaignId;
        }
        if (dfrToUpdate.TQL_DateTime_Entered__c != null && (dfrToUpdate.TQL_BMID__c == null || dfrToUpdate.TQL_BMID__c.deleteWhitespace() == oldBmidValue)) {
            dfrToUpdate.TQL_BMID__c = newBmidValue;
            dfrToUpdate.TQL_Campaign__c = newCampaignId;
        }
        if (dfrToUpdate.SQL_DateTime_Entered__c != null && (dfrToUpdate.SQL_BMID__c == null || dfrToUpdate.SQL_BMID__c.deleteWhitespace() == oldBmidValue)) {
            dfrToUpdate.SQL_BMID__c = newBmidValue;
            dfrToUpdate.SQL_Campaign__c = newCampaignId;
        }
        if (dfrToUpdate.EOL_DateTime_Entered__c != null && (dfrToUpdate.EOL_BMID__c == null || dfrToUpdate.EOL_BMID__c.deleteWhitespace() == oldBmidValue)) {
            dfrToUpdate.EOL_BMID__c = newBmidValue;
            dfrToUpdate.EOL_Campaign__c = newCampaignId;
        }
        return dfrToUpdate;
    }

    String exportDemandFunnelBMID(Demand_Funnel__c dfrToUpdate, String oldBmidValue, String newBmidValue, Map<String,Campaign> bmidCampaignMap) {
        Campaign campaign = bmidCampaignMap.get(newBmidValue);
        String recordString = String.valueOf(dfrToUpdate.Id) + ',' + String.valueOf(oldBmidValue) + ',' + String.valueOf(newBmidValue) + ',' +
        String.valueOf(dfrToUpdate.Prospect_Campaign__c) + ',' + String.valueOf(dfrToUpdate.Prospect_Campaign__r?.Name) + ',' + String.valueOf(campaign?.Id) + ',' + 
        String.valueOf(campaign?.Name) + ',' + String.valueOf(dfrToUpdate.Prospect_Channel__c) + ',' + String.valueOf(campaign?.Channel__c) + ',' + 
        String.valueOf(dfrToUpdate.Prospect_SubChannel__c) + ',' + String.valueOf(campaign?.Sub_Channel__c);

        if (dfrToUpdate.MQL_DateTime_Entered__c != null && (dfrToUpdate.MQL_BMID__c == null || dfrToUpdate.MQL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.MQL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.MQL_BMID__c) + ',' + newBmidValue;
        }
        recordString = recordString + ',' + String.valueOf(dfrToUpdate.MQL_DateTime_Entered__c);
        if (dfrToUpdate.SAL_DateTime_Entered__c != null && (dfrToUpdate.SAL_BMID__c == null || dfrToUpdate.SAL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.SAL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.SAL_BMID__c) + ',' + newBmidValue;
        }
        if (dfrToUpdate.TAL_DateTime_Entered__c != null && (dfrToUpdate.TAL_BMID__c == null || dfrToUpdate.TAL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.TAL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.TAL_BMID__c) + ',' + newBmidValue;
        }
        if (dfrToUpdate.TQL_DateTime_Entered__c != null && (dfrToUpdate.TQL_BMID__c == null || dfrToUpdate.TQL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.TQL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.TQL_BMID__c) + ',' + newBmidValue;
        }
        if (dfrToUpdate.SQL_DateTime_Entered__c != null && (dfrToUpdate.SQL_BMID__c == null || dfrToUpdate.SQL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.SQL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.SQL_BMID__c) + ',' + newBmidValue;
        }
        recordString = recordString + ',' + String.valueOf(dfrToUpdate.SQL_DateTime_Entered__c);
        if (dfrToUpdate.EOL_DateTime_Entered__c != null && (dfrToUpdate.EOL_BMID__c == null || dfrToUpdate.EOL_BMID__c.replaceAll(' ','') == oldBmidValue)) {
            recordString = recordString + ',' + 'Yes' + ',' + String.valueOf(dfrToUpdate.EOL_BMID__c) + ',' + newBmidValue;
        } else {
            recordString = recordString + ',' + 'No' + ',' + String.valueOf(dfrToUpdate.EOL_BMID__c) + ',' + newBmidValue;
        }
        recordString = recordString + ',' + String.valueOf(dfrToUpdate.EOL_DateTime_Entered__c);

        return recordString;
    }

    String exportRTLMFields(Demand_Funnel__c dfrToUpdate) {
        String recordString = ',' +  String.valueOf(dfrToUpdate.Include_in_RTLM__c) + ',' + 
        String.valueOf(dfrToUpdate.RTLM_Channel__c) + ',' +  String.valueOf(dfrToUpdate.RTLM_Country__c) + ',' +  String.valueOf(dfrToUpdate.RTLM_CW__c) + ',' + 
        String.valueOf(dfrToUpdate.RTLM_Lead_Source__c) + ',' +  String.valueOf(dfrToUpdate.RTLM_MQL__c) + ',' +  String.valueOf(dfrToUpdate.RTLM_Prospect__c) + ',' + 
        String.valueOf(dfrToUpdate.RTLM_Segment__c) + ',' +  String.valueOf(dfrToUpdate.RTLM_SQL__c);
        return recordString;
    }

    Map<ID, Demand_Funnel__c> getDfrMap(List<Id> dfrIds) {
        return new Map<ID, Demand_Funnel__c>( (List<Demand_Funnel__c>) new DemandFunnelSelector().selectDFRById(new List<Object>{dfrIds})
            .selectFields(new List<String>{
            'Include_in_RTLM__c', 'RTLM_Channel__c', 'RTLM_Country__c', 'RTLM_CW__c', 'RTLM_Lead_Source__c',
            'RTLM_MQL__c', 'RTLM_Prospect__c', 'RTLM_Segment__c', 'RTLM_SQL__c','MQL_BMID__c', 'MQL_DateTime_Entered__c', 'SAL_BMID__c', 'SAL_DateTime_Entered__c', 'TAL_DateTime_Entered__c',
            'TAL_BMID__c', 'TQL_BMID__c', 'TQL_DateTime_Entered__c', 'SQL_BMID__c', 'SQL_DateTime_Entered__c', 'EOL_DateTime_Entered__c', 'EOL_BMID__c'
            , 'Contact__c', 'Opportunity__c', 'Prospect_Channel__c', 'Prospect_Campaign__c','Prospect_Campaign__r.Name', 'Prospect_SubChannel__c','SAL_Handoff_Owner__c','Prospect_BMID__c'
            }).executeQuery());
    }

    Map<String, Id> getBmidIdMap(List<String> bmids) {
        Map<String, Id> bmidIdMap = new Map<String, Id>();
        for (Campaign c : (List<Campaign>) new CampaignSelector().selectCampaignsByBMID(new List<Object>{bmids}).executeQuery()) {
            bmidIdMap.put(c.BMID__c,c.Id);
        }
        return bmidIdMap;
    }

    Map<String, Campaign> getBmidCampaignMap(List<String> bmids) {
        Map<String, Campaign> bmidCampaignMap = new Map<String, Campaign>();
        for (Campaign c : (List<Campaign>) new CampaignSelector().selectCampaignsByBMID(new List<Object>{bmids}).executeQuery()) {
            bmidCampaignMap.put(c.BMID__c,c);
        }
        return bmidCampaignMap;
    }

    Map<ID, Lead> getLeadMap(List<Id> leadIds){
        return new Map<ID, Lead>((List<Lead>) new LeadSelector().selectLeadsByIds(new List<Object> {leadIds}).executeQuery());
    }

    Map<ID, Opportunity> getOpportunityMap(Set<Id> opportunitiesId) {
        return new Map<ID, Opportunity>((List<Opportunity>) new OpportunitySelector().selectOpportunityForSignUp(opportunitiesId).executeQuery());
    }

    Map<ID, Contact> getContactMap(Set<Id> contactsId) {
        return new Map<ID, Contact>((List<Contact>) new ContactSelector().selectContactsForDFRById(new List<Object> {contactsId}).executeQuery());
    }

    

    Lead fixLeadBMID(Lead leadToFix, String oldBmidValue, String newBmidValue) {
        if (leadToFix.BMID__c == null || leadToFix.BMID__c.deleteWhitespace() == oldBmidValue) {
            leadToFix.BMID__c = newBmidValue;
        } else if (leadToFix.BMID__c != null) {
            String bmid = leadToFix.BMID__c;
            leadsForHistoryTrack.add(new Lead(Id = leadToFix.Id, BMID__c = newBmidValue));
            leadToFix.BMID__c = bmid;
        }
        return leadToFix;
    }

    String exportLeadBMID(Lead leadToFix, String oldBmidValue, String newBmidValue) {
        String recordString = '';
        if (leadToFix.BMID__c == null || leadToFix.BMID__c.replaceAll(' ','') == oldBmidValue) {
            recordString = recordString + ',' + 'Yes' + ',' + 'No' + ',' + String.valueOf(leadToFix.BMID__c) + ',' + newBmidValue;
        } else if (leadToFix.BMID__c != null) {
            recordString = recordString + ',' + 'No' + ',' + 'Yes' + ',' + String.valueOf(leadToFix.BMID__c) + ',' + newBmidValue;
        }
        return recordString;
    }

    Contact fixContactBMID(Contact contactToFix, String oldBmidValue, String newBmidValue) {
        if (contactToFix.BMID__c == null || contactToFix.BMID__c.replaceAll(' ','') == oldBmidValue) {
            contactToFix.BMID__c = newBmidValue;
        } else if (contactToFix.BMID__c != null) {
            String bmid = contactToFix.BMID__c;
            contactForHistoryTrack.add(new Contact(Id = contactToFix.Id, BMID__c = newBmidValue));
            contactToFix.BMID__c = bmid;
        }
        return contactToFix;
    }

    String exportContactBMID(Contact contactToFix, String oldBmidValue, String newBmidValue) {
        String recordString = '';
        if (contactToFix.BMID__c == null || contactToFix.BMID__c.replaceAll(' ','') == oldBmidValue) {
            recordString = recordString + ',' + 'Yes' + ',' + 'No' + ',' + String.valueOf(contactToFix.BMID__c) + ',' + newBmidValue;
        } else if (contactToFix.BMID__c != null) {
            recordString = recordString + ',' + 'No' + ',' + 'Yes' + ',' + String.valueOf(contactToFix.BMID__c) + ',' + newBmidValue;
        }
        return recordString;
    }
    
    String exportContactBMIDNull() {
        return ',' + 'No' + ',' + 'No' + ',' + '' + ',' + '';
    }

    Opportunity fixOpportunityBMID(Opportunity opportunityToFix, String oldBmidValue, String newBmidValue) {
        if (opportunityToFix.BMID__c == null || opportunityToFix.BMID__c.replaceAll(' ','') == oldBmidValue) {
            opportunityToFix.BMID__c = newBmidValue;
        } else if (opportunityToFix.BMID__c != null) {
            String bmid = opportunityToFix.BMID__c;
            opportunitiesForHistoryTrack.add(new Opportunity(Id = opportunityToFix.Id, BMID__c = newBmidValue));
            opportunityToFix.BMID__c = bmid;
        }
        return opportunityToFix;
    }

    String exportOpportunityBMID(Opportunity opportunityToFix, String oldBmidValue, String newBmidValue) {
        String recordString = '';
        if (opportunityToFix.BMID__c == null || opportunityToFix.BMID__c.replaceAll(' ','') == oldBmidValue) {
            recordString = recordString + ',' + 'Yes' + ',' + 'No' + ',' + String.valueOf(opportunityToFix.BMID__c) + ',' + newBmidValue;
        } else if (opportunityToFix.BMID__c != null) {
            recordString = recordString + ',' + 'No' + ',' + 'Yes' + ',' + String.valueOf(opportunityToFix.BMID__c) + ',' + newBmidValue;
        }
        return recordString;
    }

    String exportOpportunityBMIDNull() {
        return ',' + 'No' + ',' + 'No' + ',' + '' + ',' + '';
    }
}
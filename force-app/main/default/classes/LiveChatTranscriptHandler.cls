/*
* Name         : LiveChatTranscriptTrigger.trigger
* Created By   : Crisanto de Llamas (crisanto.dellamas@ringcentral.com)
* Created Date : 03/Oct/2016
* Description  : This trigger will
*                   1) Create a Lead record once a Sales Chat request is abandoned by the guest.
*                       Logic: IF  Status = Missed and
*                              Transcript Body = Empty and
*                              Deployment = UK or US Sales Chat or SnapIn Sales agents
*                       Create a Lead with Lead Source = 'Lead Initial Chat'
*                   2) Save Survey result and assign lead to chat transcript using chat key
* Dependencies : No
*
*/
public class LiveChatTranscriptHandler {
    public class LiveChatTranscriptAfter extends Triggers.TriggerHandlerBase {
        override public void handle() {
            if (Trigger.isUpdate && !Feature_Toggle__c.getInstance().EnableOmniChannelRouting__c) {
                return;
            }
            List<Lead> li = new list <Lead>();
            Set<String> chatKeys = new Set<String>();    
            List<LiveChatTranscript> liveChatTranscriptToProcess = 
                [
                    SELECT Id, Body, Status, PreChat_Number_of_Employees__c, PreChat_Firstname__c,
                        PreChat_Lastname__c, PreChat_Company__c, PreChat_Email__c, PreChat_Phone__c, 
                        AID__c, BMID__c, PID__c, RCKW__c, RCMT__c, SID__c, chatKey, Adobe_Target_Id__c,
                        Adobe_Target_Id_History__c, Transaction_Id__c, BMID_Old__c, RC_Visitor_ID__c,   
                        Disposition__c, LeadId
                    FROM LiveChatTranscript 
                    WHERE Id IN :Trigger.new 
                        AND (LiveChatDeployment.DeveloperName != 'snapins' // not SnapIn deployment
                        OR (LiveChatDeployment.DeveloperName = 'snapins' AND LiveChatButton.DeveloperName Like 'US_%')) // SnapIn Sales agents has button Like 'US_%'
                ];
            
            for ( LiveChatTranscript transcript : liveChatTranscriptToProcess) {
                if ( String.isBlank( transcript.Body ) && transcript.Status == 'Missed' && String.isNotBlank(transcript.PreChat_Number_of_Employees__c) ) {
                    Map<String, String> noePreChatLeadMap = new Map<String, String>();
                    noePreChatLeadMap.put('Just Me', '1-19');
                    noePreChatLeadMap.put('2-4', '1-19');
                    noePreChatLeadMap.put('5-9', '1-19');
                    noePreChatLeadMap.put('10-19', '1-19');
                    noePreChatLeadMap.put('20-49', '20-99');
                    noePreChatLeadMap.put('50-99', '20-99');
                    noePreChatLeadMap.put('100-249', '100-399');
                    noePreChatLeadMap.put('250-499', '400-1999');
                    noePreChatLeadMap.put('500-999', '400-1999');
                    noePreChatLeadMap.put('1000+', '2000+');                  
                    noePreChatLeadMap.put('1-19', '1-19');
                    noePreChatLeadMap.put('20-99', '20-99');
                    noePreChatLeadMap.put('100-399', '100-399');
                    noePreChatLeadMap.put('400-1999', '400-1999');
                    noePreChatLeadMap.put('2000+', '2000+');
                    noePreChatLeadMap.put('400-4999', '400-4999');
                    noePreChatLeadMap.put('5000+', '5000+');                   
                    
                    Lead l = new Lead();
                    
                    l.FirstName = transcript.PreChat_Firstname__c;
                    l.LastName = transcript.PreChat_Lastname__c;
                    l.Company = transcript.PreChat_Company__c;
                    l.Email = transcript.PreChat_Email__c;
                    l.Phone = transcript.PreChat_Phone__c;
                    l.LeadSource = 'Lead Initial Chat';
                    l.NumberOfEmployees__c = noePreChatLeadMap.get(transcript.PreChat_Number_of_Employees__c);
                    l.Industry = 'Other';
                    l.AID__c = transcript.AID__c;
                    l.BMID__c = transcript.BMID__c;
                    l.PID__c = transcript.PID__c;
                    l.RCKW__c = transcript.RCKW__c;
                    l.RCMT__c = transcript.RCMT__c;
                    l.SID__c =  transcript.SID__c;
                    l.Chat_Key__c =  transcript.chatKey;
                    l.Adobe_Target_Id__c = transcript.Adobe_Target_Id__c;
                    l.Adobe_Target_Id_History__c = transcript.Adobe_Target_Id_History__c;
                    l.Transaction_Id__c = transcript.Transaction_Id__c;
                    l.BMID_Old__c = transcript.BMID_Old__c;
                    l.RC_Visitor_ID__c  = transcript.RC_Visitor_ID__c ;                    
                    li.add(l);
                }
                
                if(String.isNotBlank(transcript.chatKey)){
                    chatKeys.add( transcript.chatKey );
                }
            }
        
            if (li.size() > 0) {
                insert li;
            }

            /* 2) Save Survey result and assign lead to chat transcript */
            if ( chatKeys.size() > 0 ) {        
                List<Lead> leadList = [SELECT Id, Chat_Key__c FROM Lead WHERE Chat_Key__c IN :chatKeys];
        
                Map<String, Lead> chatKeyLeadsMap = new Map<String, Lead>();

                for ( Lead l : leadList ) {
                    chatKeyLeadsMap.put( l.Chat_Key__c, l );
                }
         
                List<LiveChatTranscript> transcriptsToUpdate = new List<LiveChatTranscript>();
                for ( LiveChatTranscript transcript : liveChatTranscriptToProcess) {
                    if ( String.isNotBlank( transcript.chatKey ) ) {
                        Lead l = chatKeyLeadsMap.get( transcript.chatKey );
                        LiveChatTranscript newLiveChatTranscript = new LiveChatTranscript(id = transcript.id);
                        Boolean isUpdate = false;
                        if ( l != null && transcript.LeadId == null){
                          newLiveChatTranscript.LeadId = l.Id;
                          isUpdate = true;
                        }
                        if(isUpdate){
                          transcriptsToUpdate.add(newLiveChatTranscript);
                        }
                    }
                }
                if ( transcriptsToUpdate.size() > 0 ) {
                    update transcriptsToUpdate;
                }
            }            
        }
    }
}
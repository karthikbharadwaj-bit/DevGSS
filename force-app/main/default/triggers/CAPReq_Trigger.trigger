/*******************************************************************
Trigger on CAP Request object
Auther: Diganta Sarkar (diganta.sarkar@ringcentral.com) 24-Jan-2022
********************************************************************/
trigger CAPReq_Trigger on CAP_Request__c (before insert, before update, before delete, after insert, after update) {
    
    new Triggers()
            .bind(Triggers.Evt.afterinsert, new CAPReq_TriggerHandler.CreateCapCase())
            .manage();

}
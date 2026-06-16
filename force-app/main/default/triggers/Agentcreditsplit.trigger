/****************************************************************************************************/
/* Class Name  : Agentcreditsplit
/* Date        : 02-Feb-2021
/* Author      : Ranjani.N
/* Description : Trigger to recalculate and create agent credit records based in commission__c
/****************************************************************************************************/
trigger Agentcreditsplit on Account_Split__c ( before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete) {
         new Triggers()
         .bind(Triggers.Evt.afterupdate, new AgentcreditsplitHandler.AgentsplitAfter())
         .bind(Triggers.Evt.afterinsert, new AgentcreditsplitHandler.AgentsplitAfter())
         .manage();
        
        

}
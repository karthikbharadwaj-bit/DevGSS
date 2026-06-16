trigger DSENTPredictionTrigger on DSENT_Prediction__c (before insert,before update,before delete) {
    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            DSENTPredictionTriggerHelper.executeDSENTPredictionTrigger(Trigger.New,true);
        }
        else if(trigger.isUpdate)
        {
            DSENTPredictionTriggerHelper.executeDSENTPredictionTrigger(Trigger.New,false);
        }
        else if(trigger.isDelete)
        {
			DSENTPredictionTriggerHelper.executeDSENTPredictionTrigger(Trigger.Old,false);
        }
    }
}
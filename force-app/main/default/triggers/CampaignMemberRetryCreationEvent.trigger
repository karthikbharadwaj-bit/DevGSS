trigger CampaignMemberRetryCreationEvent on CampaignMemberRetry__e (after insert) {
    Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
    Decimal CampMemberCreationRetriesAttempts = featureToogle.CampMemberCreationRetriesAttempts__c != null ? featureToogle.CampMemberCreationRetriesAttempts__c : 4;
    Try {       
        CampaignMemberPlatEvents.processCampaignMemberRetryCreationEvent(Trigger.new);
    } catch (Exception ex) {
        if (EventBus.TriggerContext.currentContext().retries < CampMemberCreationRetriesAttempts) {
            throw new EventBus.RetryableException(
                'Process Fail, Retry..');
        } else { 
            CampaignMemberPlatEvents.processCampaignMemberRetryCreationEventException(Trigger.new, ex);
        }
    }	
}
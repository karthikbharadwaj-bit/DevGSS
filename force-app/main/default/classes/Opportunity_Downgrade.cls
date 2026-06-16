/*
* Created By    : Madhumita
* Created Date  : 23-03-2020
* Description   : Controller class for Opportunity_Downgrade lightning component
* Test Class    : Test_OpportunityDowngrade

Change History
********************************************************************************************************************
SCRUM/Jira  		ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
public class Opportunity_Downgrade {

    public class DowngradeWrapper {
        @AuraEnabled
        public String responseMessage;
        @AuraEnabled
        public List<String> missingFields;
        @AuraEnabled
        public String validationType;
    }

    @AuraEnabled
    public static DowngradeWrapper downgradeOpp(String optyId) {
        DowngradeWrapper wrapper = new DowngradeWrapper();
        try {
            List<Quote> opp_Quote = [SELECT Id, ProServ_Status__c, RecordType.Name, OpportunityId from Quote
                                 WHERE OpportunityId =: optyId AND (RecordType.Name = 'ProServ Quote' OR RecordType.Name = 'CC ProServ Quote')
                                 AND ProServ_Status__c != 'Cancelled'];
            if(opp_Quote.Size() > 0) {
                wrapper.responseMessage = 'ProServ Quote and CC ProServ Quote status has to be cancelled before attempting to downgrade this opportunity. Please contact your ProServ Client Partner to update the quote status to allow downgrade.';
                return wrapper;
            } else {
                List<String> missingFields = new List<String>();
                Opportunity oppty = (Opportunity) new OpportunitySelector()
                        .selectOpptyFieldsForDowngradeValidationByOpptyID(optyId)
                        .executeQuery()
                        .get(0);
                Map<Id, OpportunityHelper.ValidationCategory> opptyValidationCategoryMap = OpportunityHelper.getOpportunityValidationCategory(new List<Opportunity> { oppty });
                OpportunityHelper.ValidationCategory valCategory = opptyValidationCategoryMap.get(oppty.Id);
                if(valCategory == OpportunityHelper.ValidationCategory.GSP_VALIDATION || OpportunityHelper.doesUserProfileHaveValidationRules()) {
                    oppty.StageName = OpportunityHelper.STAGE_NAME_DOWNGRADED;
                    missingFields = OpportunityStageValidator.getMissingFieldsforGivenStage(oppty,
                        OpportunityHelper.getARRConvertedToCorporateCCY(oppty.ID),
                        valCategory);
                }
                if(missingFields.isEmpty()) {
                    Opportunity opportunityWizardData = OpportunityHelper.getOpportunityCloseWizardValues(optyId);
                    Map<String,String> oppMap = new Map<String,String>();
                    oppMap.put('Id',optyId);
                    oppMap.put('wType', 'Downgrade');
                    oppMap.put('brandName', opportunityWizardData.Brand_Name__c);
                    DowngradeWizardController.submitForm(oppMap);
                    wrapper.responseMessage = 'Success';
                    if (oppty != null && OpportunityHelper.isProServChangeOrderOpportunity(oppty) ) {
                        updateStatusesForOrderAndRelatedSuborders(oppty.Parent_Order__c);
                    }
                } else {
                    wrapper.responseMessage = 'Redirect';
                    wrapper.missingFields = missingFields;
                    wrapper.validationType = valCategory.name();
                }
                return wrapper;
            }
        } catch (Exception ex) {
            wrapper.responseMessage = ex.getMessage();
            return wrapper;
        }
    }

    @TestVisible
    private static void updateStatusesForOrderAndRelatedSuborders(Id orderId) {
        Order parentOrder= (Order) new ListOptional(
            new OrderSelector()
                .selectOrdersByIdsForPhaseManagement(new Set<Id> {orderId})
                .executeQuery()
        ).getFirst();

        parentOrder.Status = OrderHelper.STATUS_NEW;
        for (Suborder__c suborder: parentOrder.Suborders__r) {
            if (suborder.Status__c == SuborderHelper.STATUS_BILLED) {
                parentOrder.Status = OrderHelper.STATUS_IN_PROGRESS;
                break;
            }
        }
        update parentOrder;

        List<Suborder__c> lockedSuborders = new List<Suborder__c>();
        for (Suborder__c suborder: parentOrder.Suborders__r) {
            if (suborder.Status__c == SuborderHelper.STATUS_LOCKED) {
                lockedSuborders.add(suborder);
            }
        }
        if (!lockedSuborders.isEmpty()) {
            for (Suborder__c lockedSuborder : lockedSuborders) {
                lockedSuborder.Status__c = SuborderHelper.STATUS_NEW;
            }
            update lockedSuborders;
        }
    }
}
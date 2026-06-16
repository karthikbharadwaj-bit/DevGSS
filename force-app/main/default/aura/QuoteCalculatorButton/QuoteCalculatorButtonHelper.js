({
    loadOpportunity : function(component) {
        const pageUrlParam = decodeURIComponent(window.location.search.substring(1));
        let oppId = component.get("v.oppId");
        
        if ($A.util.isUndefinedOrNull(oppId)) {
            if (pageUrlParam && !$A.util.isEmpty(pageUrlParam)) {
                const pageStateArr = pageUrlParam.split('=');
                if (pageStateArr[0] === 'id') {
                    oppId = [1];
                }
                
            } 
        }
        
        if (oppId) {
            const action = component.get('c.getOpportunityDetail');
            action.setParams({opportunityId: oppId});
            action.setCallback(this, function (response) {
                if (response.getState() == 'SUCCESS') {
                    const opportunityDetail = response.getReturnValue();
                    if (opportunityDetail) {
                        component.set('v.showCalculator', opportunityDetail.Quote_Calculator_Permission__c);
                    }
                    component.set("v.oppId", oppId);
                }
            });
            $A.enqueueAction(action);
        }
        
        
    }
})
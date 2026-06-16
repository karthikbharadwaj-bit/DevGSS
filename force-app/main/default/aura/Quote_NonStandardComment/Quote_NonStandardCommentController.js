({
	checkStandardTerms : function(component, event, helper) {
		component.set("v.objApprovalRec.document_attached__c", false);
        component.set("v.isStandard",true);
	},
    
    checkWorkDocumentAttached : function(component, event, helper) {
		component.set("v.objApprovalRec.Standard_Terms__c", false);	
        component.set("v.isStandard",false);
	},
    
})
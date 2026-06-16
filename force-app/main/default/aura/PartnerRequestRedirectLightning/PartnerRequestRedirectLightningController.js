({
	redirectToPartnerRequest : function(component, event, helper)
	{
		var LeadId = component.get("v.recordId");
        var action = component.get("c.getLeadDetails");
        action.setParams({ 
            LeadId : component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
				$A.get("e.force:closeQuickAction").fire();
				var state = response.getState();
				if (state == "SUCCESS") {
                    console.log('State value +' + state);
					var LeadObj = response.getReturnValue();
                    console.log('LeadObj.FirstName' + LeadObj.FirstName); 
					var createRecordEvent = $A.get("e.force:createRecord");
                     
					createRecordEvent.setParams({
						"entityApiName": "Partner_Request__c",
						"defaultFieldValues": {
                        "Partner_First_Name__c" : LeadObj.FirstName,
                        "Partner_Last_Name__c" : LeadObj.LastName,
                        "Partner_Email_Address__c": LeadObj.Email,
                        "Partner_Company_Name__c" : LeadObj.Company,
                        "Partner_Phone__c" : LeadObj.Phone,
                        "Partner_Address1__c":LeadObj.Street,
                        "Partner_Address2__c":LeadObj.Partner_Address2__c,
                        "Partner_Zip__c" : LeadObj.PostalCode,
                        "Partner_State__c" : LeadObj.State,
                        "Partner_Country__c" : LeadObj.Country,
                        "Partner_City__c" : LeadObj.City
                        
                        }
                    
					}); 
					createRecordEvent.fire();
                        
                }
				else {
					var toastEvent = $A.get("e.force:showToast");
					toastEvent.setParams({
						"type": "error",
						"title": "Error!",
						"message": "There is some error while processing",
						"mode":'dismissible'
					});
					toastEvent.fire();
				}
        });
        $A.enqueueAction(action);
    }
        
})
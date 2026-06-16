({
    createCoopsJiraTicket : function(component, event, helper) {
        
        component.set("v.spinner", true);
        var recId = component.get("v.recordId");
        var action=component.get("c.createJira");
        action.setParams({
            "CaseId":recId
        });  
        action.setCallback(this, function(response){
            
            var state = response.getReturnValue(); 
            component.set("v.spinner", false);
            var currentUrl = window.location.hostname;
            var jiraUrl;
            if(currentUrl == $A.get("$Label.c.Coops_rcProdUrl")){
            
                jiraUrl = $A.get("$Label.c.Coops_jiraProdUrl"); 
            }
            else{
                jiraUrl = $A.get("$Label.c.Coops_jiraTestUrl"); 
            }

            if(state.includes('Ticket created')){
                var jiraNum = state.slice(state.indexOf('key')+3);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "COOPS Jira created successfully!",
                    "mode":'sticky',
                    "message": "The ticket number is: "+jiraNum,
                    "messageTemplate": "Please refer to this Jira ticket: {0}!",
                    "messageTemplateData": [
                        {
                            url: jiraUrl+jiraNum,
                            label: jiraNum
                        }
                    ]
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();
            }
            
            else if(state.includes('Ticket already exists') ){
                var jiraNum = state.slice(state.indexOf('Key')+3);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "warning",
                    "title": "Ticket already exists!",
                    "mode":'sticky',
                    "message": "Please refer to this Jira ticket: "+jiraNum,
                    "messageTemplate": "Please refer to this Jira ticket: {0}!",
                    "messageTemplateData": [
                        {
                            url: jiraUrl+jiraNum,
                            label: jiraNum
                        }
                    ]
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();
            }
            
                else if(state.includes('Error Occured')){
                    var errorMsg = state.slice(state.indexOf('Message')+7);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title": "Error Occured",
                        "message": errorMsg,
                        "mode":'sticky'
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    $A.get('e.force:refreshView').fire();
                }
            
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title": "Error!COOPS Jira not created!",
                            "message": "Error!COOPS Jira not created!",
                            "mode":'sticky'
                        });
                        toastEvent.fire();
                        var dismissActionPanel = $A.get("e.force:closeQuickAction");
                        dismissActionPanel.fire();
                        $A.get('e.force:refreshView').fire();
                    }
        });
        $A.enqueueAction(action);     
    }
    
})
({
    doInit: function (component, event, helper) {
        component.set("v.Spinner", true);
        helper.CheckIdDQExists(component, event, helper, false);
    },
    saveDQ: function(component, event, helper) {
        
        const detailCmp = component.find("dqDetail"),
            justificationCmp = detailCmp.find('justificationTextArea'),
            justificationTxt = justificationCmp.get("v.value"),
            isValid = detailCmp.get("v.isValid");
        
        /*if ($A.util.isUndefinedOrNull(justificationTxt) || $A.util.isEmpty(justificationTxt)) {
           alert("Please enter Justification for discount and click save!");
            return false;
        }*/

        if (!detailCmp.validateElaFields()) {
            alert ("Please enter required fields!!");
            return false;
        }

        if (!helper.validateELACondition(component, event)) {
            alert("Please add atleast single Product with category Global Office/RC Office to enable ELA.");
            return false;
        } 

        helper.saveDQValidate(component, event, helper,false);
       
    },

    BackToOpportunity: function (component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('oppId');
        window.open('/' + id, '_self');
        //sforce.one.navigateToSObject(id, view);
    },
    handleSubmitForApprovalDQ: function (component, event, helper) {
        const detailCmp = component.find("dqDetail"),
        	justificationCmp = detailCmp.find('justificationTextArea'),
            justificationTxt = justificationCmp.get("v.value");

        if ($A.util.isUndefinedOrNull(justificationTxt) || $A.util.isEmpty(justificationTxt)) {
           alert("Please enter Justification and Description for discount and click save!");
           return false;
        }

        if (!detailCmp.validateElaFields()) {
            alert ("Please enter required fields!!");
            return false;
        }

        if (!helper.validateELACondition(component, event)) {
            alert("Please add atleast single Product with category Global Office/RC Office.")
            return false;
        } 
        
        //component.set("v.Spinner", true);
        helper.saveDQValidate(component, event, helper,true);
    },
    handleRevisedApproval: function (component, event, helper) {
        component.set("v.Spinner", true);
        helper.revisedApproval(component, event);
    },
    handleBackToQuote: function(component, event, helper) {
        helper.backToQuote(component);
    }
})
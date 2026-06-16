({
	doInit : function(component, event, helper) {
        var urlString = window.location.href;
        var baseURL = urlString.substring(0, urlString.indexOf('/s/'));
        component.set("v.baseUrlComm",baseURL);
        helper.loadEditionComponent(component, event, helper);
        helper.loadQuote(component, event, helper);
        helper.loadQuoteLines(component, event, helper);
        //helper.loadCurrentUser(component, event, helper);
        //helper.loadSuperUserFlag(component, event, helper);
        //helper.loadDiscountFlag(component, event, helper);
        //alert(component.get("v.SelectedProductList").length);
        helper.loadOtherInformation(component, event, helper);
        helper.getopportunitycurrency(component,event,helper);//Added for GO Pricing
        helper.getBrandName(component, event, helper);
	},
    
    handleEditionSelection : function(component, event, helper) {
		helper.handleEditionSelection(component, event, helper);	
	},
    
    goToStep1: function(component, event, helper) {
        var objQuote = component.get("v.Quote");
        var isCurrentUserReadOnlyProfile = component.get("v.isCurrentUserReadOnlyProfile");
        if(isCurrentUserReadOnlyProfile) {
            return;
        }
        if(objQuote.Quote_Locked__c && !component.get("v.isSuperUser") && component.get("v.currentUser").UserType != 'Standard'){
    		var errorMessage = $A.get("$Label.c.Quote_Locked_Error_Message");
            helper.showToast('Info', errorMessage, 'error');	    
        }
        else{
        	component.set("v.Step", "1");
        }
	},
    
    goToStep2: function(component, event, helper) {
        var objQuote = component.get("v.Quote");
        var isCurrentUserReadOnlyProfile = component.get("v.isCurrentUserReadOnlyProfile");
        if(isCurrentUserReadOnlyProfile) {
            return;
        }
        if(objQuote.Quote_Locked__c && !component.get("v.isSuperUser") && component.get("v.currentUser").UserType != 'Standard'){
    		var errorMessage = $A.get("$Label.c.Quote_Locked_Error_Message");
            helper.showToast('Info', errorMessage, 'error');	    
        }
        else{
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            if(id) {
                component.set("v.Step", "2");
                component.set("v.selectedCategory", '');
                component.set("v.AutoTabChange", false);
            }
            else {
                helper.showToast('Error', 'Please select a Package first.', 'error');
                component.set("v.Step", "1");
            }
        }
	},
    
    goToStep3: function(component, event, helper) {
        var objQuote = component.get("v.Quote");
        var isCurrentUserReadOnlyProfile = component.get("v.isCurrentUserReadOnlyProfile");
        if(isCurrentUserReadOnlyProfile) {
            return;
        }
        if(objQuote.Quote_Locked__c && !component.get("v.isSuperUser") && component.get("v.currentUser").UserType != 'Standard'){
    		var errorMessage = $A.get("$Label.c.Quote_Locked_Error_Message");
            helper.showToast('Info', errorMessage, 'error');	    
        }
        else{
            var SelectedProductList = component.get("v.SelectedProductList");
            if(!component.get("v.isProductSelectedFROMPYNTab") && component.get("v.Step") == "2") {
                component.set("v.Step","2");
                helper.showToast('Error', 'Please select Main Number.', 'error');
            }
            else {
                var url = new URL(location.href);
                var id = url.searchParams.get('id');
                if(id) {
                    component.set("v.Step", "3");
                    component.set("v.selectedCategory", "Service");
                } else {
                    helper.showToast('Error', 'Please select a Package first.', 'error');
                    component.set("v.Step", "1");
                }
            }
        }
        
	},
    
    goToStep4: function(component, event, helper) {
        var objQuote = component.get("v.Quote");
        var isCurrentUserReadOnlyProfile = component.get("v.isCurrentUserReadOnlyProfile");
        if(isCurrentUserReadOnlyProfile) {
            return;
        }
        if(objQuote.Quote_Locked__c && !component.get("v.isSuperUser") && component.get("v.currentUser").UserType != 'Standard'){
    		var errorMessage = $A.get("$Label.c.Quote_Locked_Error_Message");
            helper.showToast('Info', errorMessage, 'error');	    
        }
        else{
            if(!component.get("v.isProductSelectedFROMPYNTab") && component.get("v.Step") == "2") {
                component.set("v.Step","2");
                helper.showToast('Error', 'Please select Main Number.', 'error');
            }
            else {
                var url = new URL(location.href);
                var id = url.searchParams.get('id');
                if(id){
                    component.set("v.Step", "4");
                } else {
                    helper.showToast('Error', 'Please select a Package first.', 'error');
                    component.set("v.Step", "1");
                }
            }
        }
	},
    
    goToStep5: function(component, event, helper) {
        var objQuote = component.get("v.Quote");
        var isCurrentUserReadOnlyProfile = component.get("v.isCurrentUserReadOnlyProfile");
        if(isCurrentUserReadOnlyProfile) {
            return;
        }
        if(objQuote.Quote_Locked__c && !component.get("v.isSuperUser") && component.get("v.currentUser").UserType != 'Standard'){
    		var errorMessage = $A.get("$Label.c.Quote_Locked_Error_Message");
            helper.showToast('Info', errorMessage, 'error');	    
        }
        else{
            if(!component.get("v.isProductSelectedFROMPYNTab") && component.get("v.Step") == "2") {
                component.set("v.Step","2");
                helper.showToast('Error', 'Please select Main Number.', 'error');
            }
            else {
                var url = new URL(location.href);
                var id = url.searchParams.get('id');
                if(id) {
                    component.set("v.Step", "5");
                } else {
                    helper.showToast('Error', 'Please select a Package first.', 'error');
                    component.set("v.Step", "1");
                }
            }
        }
    },
    
    updateTab4Name: function(component, event, helper) {
        var tabName = 'Cart (';
        if(component.get("v.Quote.Subscription__c") != null)
           tabName = 'CURRENT ENTITLEMENTS (';
        tabName += component.get("v.SelectedProductList").length + ')';
        component.set("v.Step4Name", tabName);
	},
    
})
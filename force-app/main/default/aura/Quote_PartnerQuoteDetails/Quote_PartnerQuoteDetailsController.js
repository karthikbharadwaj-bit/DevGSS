({
	loadData : function(component, event, helper) {
        var today = new Date();
        var currentdate = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
        component.set("v.currentDate",currentdate);
        component.set("v.Spinner", true);
        //alert(component.get("v.Spinner"));
        helper.checkOpenINCommunity(component, event, helper);
        helper.checkIfUserIsAvayaAdmin(component, event, helper);
		helper.loadQuote(component, event, helper);
        helper.loadCurrentUserInfo(component, event, helper);
        helper.validServiceLineOnQuote(component, event, helper);
		helper.getTranslations(component, event, helper);
    },
    
    saveQuote : function(component, event, helper) {
		helper.saveQuote(component, event, helper, false);	
	},
    
    clonePartnerQuote : function(component, event, helper) {
		helper.clonePartnerQuote(component, event, helper);	
	},
    
    addFav : function(component, event, helper) {
        component.set("v.showFavModel",true);
	},
    
    closeModel: function(component, event, helper) {
    	component.set("v.showFavModel", false);
   	},
    
    closePartnerDiscountModel: function(component, event, helper) {
    	component.set("v.showPartnerDiscount", false);
   	},
    
    submitQuote: function(component, event, helper) {
        component.set("v.Spinner",true);
        helper.saveQuote(component, event, helper, true);	
   	},
    
    requestDiscount: function(component, event, helper) {
        var quote = component.get("v.Quote");
        var startDate = Date.parse(quote.Start_Date__c);
        if(!startDate && quote.Contract__c){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Please enter Expected Service Start Date.', 'error'); 
            return
        }
    	component.set("v.showPartnerDiscount", true);
    },
  
  	addToFavourite : function(component, event, helper) {
    	helper.addFav(component, event, helper);
    },
    
    goToAddProducts : function(component, event, helper) {
		component.set("v.Step", '3');		
        component.set("v.selectedCategory", "Service");
	},
    
    generatePDF : function(component, event, helper) {
    	helper.redirectTo('/partner/apex/Quote_PartnerQuotePDF?Id='+ component.get("v.Quote").Id+'&force_download=true');
	},
    
    engageLegal : function(component, event, helper){
        helper.engageLegal(component, event, helper);	
    },
    
    convertQuote : function(component, event, helper) {
        component.set("v.Spinner",true);
    	helper.convertQuote(component, event, helper);
	},
    
    submitOrder : function(component, event, helper) {
        var quote = component.get("v.Quote");
        var startDate = Date.parse(quote.Start_Date__c);
        var isPartnerContractExist = component.get("v.isPartnerContractExist");
        var isOpenContractRequest =  component.get("v.isOpenContractRequest");
        var isDiscountRequestExists = component.get("v.isDiscountRequestExists");
        var isNoContractValidation = component.get("v.hideRCContract");
        
        //alert(startDate);
        //Added for JIRA Issue BZS-6286 Bill On Behalf PRM/CRM start 
        if(component.get("v.accPartnerTypeval")){
            if((component.get("v.accPartnerTypeval").includes("Bill-on-Behalf"))){
                isPartnerContractExist = true;
            }
        }
        //Added for JIRA Issue BZS-6286 Bill On Behalf PRM/CRM end 
        if(!quote.Primary__c) {
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Order can not be submitted on this quote. It is not a primary quote.', 'error'); 
            return
        }
        
        if(!startDate && quote.Contract__c){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Please enter Expected Service Start date.', 'error'); 
            return;
        }
        
        if(!isPartnerContractExist && quote.Contract__c && !isNoContractValidation) {
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Please select contract details.', 'error'); 
            return;
        }
        
        if(isOpenContractRequest && quote.Contract__c) {
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'There is a pending contract request so quote can not be submitted.', 'error'); 
            return;
        }
        
        if(isDiscountRequestExists) {
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'There is a pending Discount request so quote can not be submitted.', 'error'); 
            return;
        }
        
        helper.checkAccountList(component, event, helper);
    },
    createContract : function(component, event, helper) {
        component.set("v.showCreateContractCMP",true);
    },
    showPOCRequest : function(component,event,helper){
        component.set("v.showPOCRequest",true);
    },
    //Method added for Longform Quote for ACO
    showLongformModal : function(component,event,helper){
        component.set("v.showLongFormModal",true);        
    },
    //Method added for Longform Quote for ACO
    closeLongFormModal : function(component,event,helper){
        component.set("v.showLongFormModal",false);        
    },
})
({
    doInit : function(component, event, helper) {      
        component.set('v.playBookDisplay',true); 
       
        var url = new URL(location.href);
        var id = url.searchParams.get('id');        
        if(!id)
        {
            id = url.href.split('/')[6];
        }
        if(id)
        {
            component.set('v.partnerQuoteId',id);
        }
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));        
        component.set('v.baseURL',baseURL);
        if(component.get('v.partnerQuoteId') != '')
        {
        	helper.getExistingPartnerContractDetails(component); 
        }
        else
        {
            component.set('v.hasPrimaryQuote',true);
        }
        component.set('v.isActive',true);
	},
    removeRow: function(component, event, helper) {        
        var pcsList = component.get("v.partnerContractServiceList");        
        var selectedItem = event.currentTarget;        
        var index = selectedItem.dataset.record;
        pcsList.splice(index, 1);
        component.set("v.partnerContractServiceList", pcsList);
    },
	handleClick : function(component, event, helper) {
        component.set('v.standardDisplay',false);
        component.set('v.playBookDisplay',true);
        helper.loadCustomMetaData(component);        
	},
    handleBackClick : function(component, event, helper) {
        component.set('v.standardDisplay',false);
        component.set('v.initialDisplay',true);        
	},
    handlePlayBookBackClick : function(component, event, helper) {
        component.set('v.playBookDisplay',false);
        component.set('v.standardDisplay',true);        
	},
    handleInputLegalBackClick : function(component, event, helper) {
        component.set('v.legalInputsDisplay',false);
        component.set('v.initialDisplay',true);        
	},
    handleClickInitialDisplay : function(component, event, helper) {
        var standardMSAOptionValue = component.get("v.standardMSAOptionValue");		       
        if(standardMSAOptionValue == 'Yes')
        {
            component.set('v.standardDisplay',true);
            component.set('v.initialDisplay',false);
            helper.loadCustomMetaData(component);  
        }
        else if(standardMSAOptionValue == 'No')
        {
            component.set('v.legalInputsDisplay',true);
            component.set('v.initialDisplay',false);
        }
	},
    /*handleClickNonStdDisplay : function(component, event, helper) {        
        component.set('v.legalInputsDisplay',true); 
        component.set('v.nonStandardDisplay',false);
	},*/
	handleApproval : function(component, event, helper) {        
        helper.handleApproval(component);        
	},
	recallApproval : function(component, event, helper) {        
        helper.recallApproval(component);        
	},    
    handleOptionChange : function(component, event, helper) {      
        helper.handleOptionChange(component);
	},
    handleSave : function(component, event, helper) {
        var nonStandardInputValue = component.get("v.nonStandardInputValue");
        var partnerContract = component.get("v.partnerContract");
        var contractType = component.get("v.contractType");
        partnerContract.Contract_Type__c = contractType; 
        if(partnerContract.Contract_Type__c == 'Non-Standard' && !nonStandardInputValue) {
            component.set("v.showSpinner",false);
            helper.showToast('Error', 'Please give input for non standard!', 'Error');
            return;
        }
        helper.createPartnerContractRecords(component, event, helper); 
        helper.checkForDealSupportExist(component, event, helper);          
	},    
    closeModal: function(component, event, helper) {      
      component.set('v.isActive', false);
      component.destroy();
   }, 
   updateDetails : function(component, event, helper) {
        component.set('v.isUpdateDetailClicked',true);
		if(component.get('v.partnerQuoteId') != undefined)
        {
            helper.getExistingPartnerContractDetails(component);
        }        
	},    
    showSpinner: function(component, event, helper) {        
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        /*var footerSpinner = component.find("loadingSpinnerFooter");
        console.log('footerSpinner'+footerSpinner);
        $A.util.removeClass(footerSpinner, "slds-hide");*/
    },   
    hideSpinner : function(component,event,helper){           
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
        //var footerSpinner = component.find("loadingSpinnerFooter");
       //$A.util.addClass(footerSpinner, "slds-hide");
    },
    
    attachmentSelected : function(component,event,helper) {
        event.stopPropagation();
       var index = event.getSource().get("v.class");
       var selectedAttachmentName  = event.getSource().get("v.label");
       var isChecked  = false;
       var isChanged = false;
        var deselectAttachmentName;
        //Changed for ACO 4.0 jira issue
        if(selectedAttachmentName == 'Enterprise MSA' || selectedAttachmentName == 'Enterprise MSA + PSA') {
            isChecked = true;
            deselectAttachmentName = 'Commercial MSA';
        } else if(selectedAttachmentName == 'Commercial MSA') {
            isChecked = true;
            deselectAttachmentName = 'Enterprise MSA + PSA';//ACO 4.0
        }
        if(isChecked && event.getSource().get("v.checked")) {
            var partnerContractTypeWrapperList = component.get("v.partnerContractTypeWrapperList");
            console.log('before>>',partnerContractTypeWrapperList);
            for(var objContractTypeList of partnerContractTypeWrapperList)  {
                //alert(objContractTypeList.contractType);
                if(objContractTypeList.contractType == 'Standard Attachments') {
                    for(var objAttach of objContractTypeList.attachmentTypesWrapper) {
                        //alert(deselectAttachmentName == objAttach.attachmentName);
                        //ACO 4.0
                        if(deselectAttachmentName.includes(objAttach.attachmentName)) {
                            isChanged = true;
                            objAttach.isSelected = false;
                        }
                        //ACO 4.0
                        if(selectedAttachmentName.includes(objAttach.attachmentName)) {
                            isChanged = true;
                            objAttach.isSelected = true;
                        }
                    }
                }
            }
            if(isChanged)
                component.set("v.partnerContractTypeWrapperList",partnerContractTypeWrapperList);
        }
        
    },
})
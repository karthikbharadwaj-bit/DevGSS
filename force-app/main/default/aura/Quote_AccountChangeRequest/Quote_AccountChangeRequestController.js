({
    doInit : function(component, event, helper) {
        console.log("isFromInternal "+component.get("v.isFromInternal"));
        if(component.get("v.isFromInternal"))
        	helper.doInit(component, event, helper);
        else
            helper.getCountryStateValues(component, event, helper);
        //Added for ALE
        var partnerComm = component.get("v.partnerCommunity");
        if(partnerComm == 'Rainbow Office'){
            helper.contractStatusChange(component, event, helper);
        }
        helper.getTranslations(component, event, helper);
    },
    onchangeCountry:function(component,event,helper){
        helper.onchangeCountry(component,event,helper);
    },

	submitDetails : function(component, event, helper) {        
        component.set("v.showSpinner",true);
        //Changes added for ALE - start
        var partnerComm = component.get("v.partnerCommunity");
        var callHelperSubmit = true;
        if(partnerComm == 'Rainbow Office'){            
            var primaryContactPhone = component.get("v.objAccountChecklist.Primary_Contact_Phone__c");
            console.log("primaryContactPhone "+primaryContactPhone);
            var contractStatusChange = component.get("v.objAccountChecklist.Contract_Status_Change_To__c"); 
            if (contractStatusChange != 'N/A'){            
                var contractChangeReason = component.get("v.objAccountChecklist.Contract_Status_Request_Reason__c");
                if(contractChangeReason == undefined || contractChangeReason ==null || contractChangeReason =='' ){
                    component.set("v.showSpinner",false);
                    callHelperSubmit = false;
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "error",
                        "title":  component.get("v.translationsMap.Error")+'!',
                        "message": component.get("v.translationsMap.Please_enter_a_valid_reason_for_Contract")+'!',
                        "mode":'dismissible'
                    });
                    toastEvent.fire();
                    component.set("v.isReadOnly",false);
                }else{
                    callHelperSubmit = true;
                }
            }
            if(callHelperSubmit){            
                if(primaryContactPhone!=undefined && primaryContactPhone !=null && primaryContactPhone !=''){
                    component.set("v.showSpinner",false);
                    var regex1  = new RegExp("^[0-9,+()-]*$");
                    var isValidPhone = regex1.test(primaryContactPhone);
                    console.log('isValidPhone>'+isValidPhone);
                    if(!isValidPhone){
                        callHelperSubmit = false;
                        component.set("v.showSpinner",false);                      
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "error",
                            "title":  component.get("v.translationsMap.Error")+'!',
                            "message":  component.get("v.translationsMap.Please_enter_only_numeric_values_Phone")+'!',
                            "mode":'dismissible'
                        });
                        toastEvent.fire();
                        component.set("v.isReadOnly",false);
                    }else{
                        callHelperSubmit = true;
                        component.set("v.isReadOnly",true);
                    }
                }else{
                    callHelperSubmit = true;                
                    component.set("v.isReadOnly",true);
                }
            }
        }
        if(component.get("v.objAccountChecklist").Payment_Method__c==""||component.get("v.objAccountChecklist").Payment_Method__c==undefined||component.get("v.objAccountChecklist").Payment_Method__c==null||component.get("v.objAccountChecklist").Payment_Method__c=='--None--'){
            helper.showToast('Error', 'Please Select a Payment Method before submitting!', 'error');
            component.set("v.showSpinner",false);
            component.set("v.isReadOnly",false);
            callHelperSubmit = false;  
        }
        if(callHelperSubmit)
            helper.submitDetails(component, event, helper); 
        //Changes added for ALE - end
	},
    closeModel : function(component, event, helper) {
        //alert(component.get("v.isVisible"));
        if(component.get("v.isFromInternal"))
            component.set("v.isVisible", false);
        //Added for ALE - start
        component.set("v.objAccountChecklist.Contract_Status_Change_To__c","N/A");
        component.set("v.ShowContractChangeReason", false);
        component.set("v.objAccountChecklist.Contract_Status_Request_Reason__c", null);
        //Added for ALE - end
        component.set("v.showChangeRequestCMP",false); 
        if(component.get("v.isFromInternal")){
            const retURL = new URL(window.location).searchParams.get("id");
            console.log('retURL>'+retURL);
            if (retURL) {
                //window.open(retURL, '_parent');
                 window.history.back();
            }
        }
    },
    //Added for ALE
    contractStatusChange : function(component, event, helper) {
        helper.contractStatusChange(component, event, helper);//Added for ALE
    },
    paymentMethodChange : function(component, event, helper){
        var objAcctCheckList=component.get('v.objAccountChecklist');
        console.log("objAcctCheckList-->"+JSON.stringify(component.get('v.objAccountChecklist')));
        component.set('v.objAccountCheckList',objAcctCheckList);
    }
})
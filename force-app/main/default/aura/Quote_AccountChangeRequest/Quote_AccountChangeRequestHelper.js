({
    doInit : function(component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        //alert(id);
        var action = component.get("c.getAccountChangeRequest");
        action.setParams({
            AccountChangeRequestId : id
		});
        action.setCallback(this, function(result) {            
            var state = result.getState();
            //alert(state);
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.objAccountChecklist",result.getReturnValue());               
                if(result.getReturnValue().Payment_Method__c == 'Invoice'){
                    component.set("v.paymentMethod",true);
                }
                if(result.getReturnValue().Account__r.RC_Brand__c != null &&result.getReturnValue().Account__r.RC_Brand__c != undefined){
                    console.log('brandname--'+result.getReturnValue().Account__r.RC_Brand__c);
                    component.set("v.partnerCommunity",result.getReturnValue().Account__r.RC_Brand__c);
                }
                if(component.get("v.isFromInternal")){
                var contractStatusChange = component.get("v.objAccountChecklist.Contract_Status_Change_To__c");
                if (contractStatusChange != 'N/A')
                    component.set("v.ShowContractChangeReason", true);
                else{
                    component.set("v.ShowContractChangeReason", false);
                    component.set("v.objAccountChecklist.Contract_Status_Request_Reason__c", null);
                }  
                console.log('contract boolean',component.get("v.ShowContractChangeReason"));
                }
                helper.getCountryStateValues(component, event, helper);
            }
        });
        $A.enqueueAction(action); 
    },
    
    // Translation Start
       getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Account'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.accFieldsMap", resultData.allObjFieldsMap.Account);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    },
    
    // Translation End
	submitDetails : function(component, event, helper) {
        console.log('inside submit');
        //alert(component.get("v.accountId"));
        var action = component.get("c.createAccountChangeRequest");
        //var paymentMethod = component.get("v.paymentMethod");
        var objAccountChecklist = component.get("v.objAccountChecklist");
        /*if(paymentMethod) {
            objAccountChecklist.Payment_Method__c = 'Invoice';
        }
        else {
            objAccountChecklist.Payment_Method__c = 'Credit Card';
        }*/
        action.setParams({
            objChangeRequest : objAccountChecklist,
            accId : component.get("v.accountId")
            
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            console.log('submit state--'+state);
            //alert(state);
            if (component.isValid() && state === "SUCCESS"){
                component.set("v.isReadOnly",false);
                component.set("v.showSpinner",false);
                helper.showToast('success','Successfully Change Request Created','success');
                //var parentCMP = component.get("v.parent");
                component.set("v.showChangeRequestCMP",false);
                //parentCMP.doInit();
                if(component.get("v.isFromInternal")){
                    const retURL = new URL(window.location).searchParams.get("id");
                    console.log('retURL>'+retURL);
                    if (retURL) {
                        //window.open(retURL, '_parent');
                        window.history.back();
                    }
                }
            }
        });    
        
        $A.enqueueAction(action); 
	},
    getCountryStateValues : function(component,event,helper){
        
        var toastEvent = $A.get('e.force:showToast');
        var action = component.get("c.getCountryStateMap");
        component.set('v.ShowSpinnerOpp',true); 
        var communityBrand;
        if(!component.get('v.IsOpenInCommunity')) {
            //Avaya Cloud Office
            communityBrand = 'Avaya Cloud Office';
        }
        //component.get("v.partnerCommunity")
        action.setParams({ 
            "communityBrand": communityBrand,
            "accountId": component.get('v.accountId')
        });        
        action.setCallback(this, function(response) {   
            var state = response.getState();
            console.log('state>>>>',state);
            if (state === "SUCCESS") { 
                var dataResponse = response.getReturnValue();
                console.log('dataResponse>>>>',dataResponse);
                var data = dataResponse.countryStateMap;
                var countries = dataResponse.countriesAvailable;
                console.log(data);
                var partnerType = dataResponse.custAccount.Partner_Type__c;
                console.log("Partner Type:" +partnerType);
                var billingCountry= dataResponse.custAccount.BillingCountry;
                console.log("Billing Country" +billingCountry);
                var arrayMapKeys = [];
                var stateValues = [];
                var i = 0;
                for(var key in data){
                    if(i == 0){
                        if(countries.includes(key)){
                            stateValues = data[key];
                            arrayMapKeys.push({key: key, value: data[key]});
                            i++;
                        }
                    }else{
                        if(countries.includes(key)){
                            arrayMapKeys.push({key: key, value: data[key]});    
                        }
                    }
                    
                }
                
                component.set("v.mapCountryKeys", arrayMapKeys);
                component.set("v.mapData", data);
               console.log('arrayMapKeys>>',arrayMapKeys);
               component.set("v.mapCountryValueKeys",stateValues);
                var objAccountCheckList = component.get("v.objAccountChecklist");
                console.log('objAccountCheckList>>>>',objAccountCheckList);
                if(objAccountCheckList.Payment_Method__c == 'Invoice'){
                    component.set("v.paymentMethod",true);
                    console.log('paymentMethod'+ component.get("v.paymentMethod"));
                }
                if(objAccountCheckList && objAccountCheckList.Legal_Country__c) {
                    var legalStateValues= helper.defaultState(component,event,helper,objAccountCheckList.Legal_Country__c);
                    component.set("v.mapCountryValueKeys",legalStateValues);
            	}
                // Added for JIRA BZS - 7041 PRM BOB start
                 
                var paymentMethods=['--None--','Credit Card','Invoice Billing'];
                console.log("payment methods 1: "+paymentMethods);
                let directDebitCountries = [];
                
                console.log("billingCountry>>>: "+billingCountry);
                for(var i=0;i<countries.length;i++){
                    if(countries[i]!='Canada'&&countries[i]!='United States'&&countries[i]!='Australia'&&countries[i]!='Singapore'&&countries[i]!='Switzerland'){
                        directDebitCountries.push(countries[i]);
                    }
                    console.log("directDebitCountries>>>" +directDebitCountries);
                }
                
                for(var b=0; b<directDebitCountries.length; b++){
                	console.log("inside for directDebitCountries>>>" +directDebitCountries[b]+billingCountry);
                    if(billingCountry==directDebitCountries[b]){
                      paymentMethods=['--None--','Credit Card','Invoice Billing','Direct Debit'];  
                    }
                    console.log("inside for paymentMethods>>>" +paymentMethods);
                }
                //Added for singapore starts
                if(billingCountry=='Singapore'|| billingCountry=='Switzerland'){
                    paymentMethods=['--None--','Invoice Billing'];
                }      
                //Added for singapore ends
               
                console.log("Customer Account's Partner Type is:" +dataResponse.custAccount.Partner_Type__c);
                
                if(partnerType == 'Bill-on-Behalf' || partnerType == 'Alcatel-Lucent - Bill-on-Behalf' || partnerType == 'Atos - Bill-on-Behalf' || partnerType == 'Avaya - Bill-on-Behalf'){
                    paymentMethods = ['--None--','Invoice-on-behalf'];
                }
                
                if(partnerType == 'Wholesale-Reseller' || partnerType == 'Alcatel-Lucent - Wholesale-Reseller' || partnerType == 'Atos - Wholesale-Reseller' || partnerType == 'Avaya - Wholesale-Reseller'){
                    paymentMethods = ['--None--','Invoice-Wholesale'];
                } 
                
                component.set('v.paymentListDisplayed',paymentMethods);
                console.log('Payment List >>>'+component.get('v.paymentListDisplayed'));
                // Added for JIRA BZS - 7041 PRM BOB end
               // component.set('v.ShowSpinnerOpp',false);
            }else{
                component.set('v.ShowSpinnerOpp',false);
            }             
        });        
        $A.enqueueAction(action);
    },
    onchangeCountry:function(component,event,helper){
        var mapCountryStates = component.get("v.mapData");
        var selctedValue = event.getSource().get("v.value");
        
        var stateValues = [];
        var statesForCountry1 = mapCountryStates[selctedValue];
        var statesForCountry = statesForCountry1.toString();
        component.set("v.mapCountryValueKeys",stateValues);
        
        console.log('statesForCountry',statesForCountry);
        if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
            for(var i=0;i<statesForCountry.split(',').length;i++){
                stateValues.push(statesForCountry.split(',')[i]); 
            }
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                selectCmp.set('v.disabled',false);
            }
        }else{
            var selectCmp = component.find("selectedState");
            if(selectCmp != null){
                stateValues.push('-- None --');
                selectCmp.set('v.disabled',true);
            }
            
        }
        
        	component.set("v.mapCountryValueKeys",stateValues);
        	component.find("selectedState").set("v.value",stateValues[0]);
         
        
    },
    
    defaultState : function(component,event,helper,selectedValue) {
        var objAccountCheckList = component.get("v.objAccountChecklist");
        if(selectedValue) {
            var mapCountryStates = (component.get("v.mapData"));
            //console.log('objAccountCheckList.Legal_State__c)',objAccountCheckList.Legal_Country__c);
            var statesForCountry1 = mapCountryStates[selectedValue];
            var statesForCountry = statesForCountry1.toString();
            var stateValues = [];
            console.log('statesForCountry>>',statesForCountry);
            component.set("v.mapCountryValueKeys",stateValues);
            if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
                for(var i=0;i<statesForCountry.split(',').length;i++){
                    stateValues.push(statesForCountry.split(',')[i]); 
                }
            }
            
            return stateValues;
        }
    },
    
    //Added for ALE
    contractStatusChange : function(component, event, helper) {
        console.log('inside contract');
        var contractStatusChange = component.get("v.objAccountChecklist.Contract_Status_Change_To__c");
        if (contractStatusChange != 'N/A' && contractStatusChange != null && contractStatusChange != "" && contractStatusChange != undefined)
            component.set("v.ShowContractChangeReason", true);
        else{
            component.set("v.ShowContractChangeReason", false);
            component.set("v.objAccountChecklist.Contract_Status_Request_Reason__c", null);
        }  
           console.log('contract boolean',component.get("v.ShowContractChangeReason"));
    }
})
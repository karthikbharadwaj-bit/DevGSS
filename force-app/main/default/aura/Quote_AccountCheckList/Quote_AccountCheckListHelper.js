({
    
    addAreaCodeRecord : function(component, event) {
        var areaCodeList = component.get("v.areaCodeList");
        //Added for BZS-4921 starts
        var oppCountry = '';
        var areaCodeListNew = [];
        if (component.get("v.isFromCheckOutPage")) {
            console.log('opp country for ale', component.get("v.Quote").Opportunity__r.Account.BillingCountry);
            oppCountry = component.get("v.Quote").Opportunity__r.Account.BillingCountry;
        } else {
            oppCountry = component.get("v.OpportunityRecord").Account.BillingCountry;
        }
        //Add New Account checklist Record
        areaCodeList.push({
            'sobjectType': 'Area_Codes__c',
            'Area_Code__c': '',
            'Country__c': oppCountry,
            'Is_Area_Code_Declaration_Checked__c': false,
            'Quantity_Requested__c': '',
            'Other_Country__c': ''
        });
        for (var i in areaCodeList) {
            areaCodeListNew.push({
                'Area_Code__c': areaCodeList[i].Area_Code__c,
                'Country__c': areaCodeList[i].Country__c,
                'Is_Area_Code_Declaration_Checked__c': areaCodeList[i].Is_Area_Code_Declaration_Checked__c,
                'Quantity_Requested__c': areaCodeList[i].Quantity_Requested__c,
                'Other_Country__c': areaCodeList[i].Other_Country__c
            });
        }
        //Added for BZS-4921 ends
        component.set("v.areaCodeList", areaCodeListNew);
    },
    
    submitDetails : function(component, event,helper) {
        try
        {
            var partnerQuoteId;
            var objectAccountCheckList = component.get("v.objAccountCheckList");
            var QuoteRec = component.get("v.Quote");
            var communityDetailRec = component.get("v.communityDetailsRecord");
            var addressList = [];
            var shippingAddressList = component.get("v.ShippingAddressList");
            var isFilled=false;
            var validationError = false;
            var isChangeOrder = component.get("v.oppType") == 'Existing Business' ? true : false;
            if(shippingAddressList) {
                for(var wrapRec of shippingAddressList) {
                    addressList.push(wrapRec.acrRec);
                    if(wrapRec.acrRec.Type__c == 'Shipping Address')
                    {
                        if(wrapRec.acrRec.Shipping_Contact_Phone_Number__c!=undefined && wrapRec.acrRec.Shipping_Contact_Phone_Number__c !=null && wrapRec.acrRec.Shipping_Contact_Phone_Number__c !=''){
                            component.set("v.showSpinner",false);
                            var regex1  = new RegExp("^[0-9,+()-]*$");
                            var isValidPhone = regex1.test(wrapRec.acrRec.Shipping_Contact_Phone_Number__c);
                            console.log('isValidPhone>'+isValidPhone);
                            if(!isValidPhone && wrapRec.acrRec.Type__c == 'Shipping Address'){
                                isFilled=false;
                                component.set("v.showSpinner",false); 
                                //shippingContactPhoneNumber.focus();
                                /*
                                 * var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Please enter only numeric values in Phone Number field!",
                                    "mode":'dismissible'
                                });
                                toastEvent.fire(); */
                                helper.showToast('Error', 'Please enter only numeric values in Phone Number field!', 'error');
                                validationError = true;
                                return;
                            }else{
                                isFilled=true;
                            }
                        }
                    }
                }
            }
            if(isFilled){
                component.set("v.showSpinner",true);
                    
                if(component.get("v.fromProcessOrder")){
                    partnerQuoteId = component.get("v.salesQuote").Id;
                }
                if(component.get("v.isFromCheckOutPage") && !component.get("v.fromProcessOrder")) {
                    var url = new URL(location.href);
                    var id = url.searchParams.get('id');
                    partnerQuoteId = id;                 
                } 
            }
            
            var productQuantityMap = component.get("v.productQuantityMap");
            var shippingQuantityMap = {};
            for(var wrapRec of shippingAddressList)
            {
                for(var key in productQuantityMap)
                {
                    if(productQuantityMap[key].key == wrapRec.acrRec.Product_Catalogue__c) 
                    {
                        var keyy = productQuantityMap[key].key;                   
                        if(shippingQuantityMap.hasOwnProperty(keyy))
                        {
                            shippingQuantityMap[keyy] = parseInt(shippingQuantityMap[keyy]) + parseInt(wrapRec.acrRec.Quantity__c);
                        }
                        else
                        {
                            shippingQuantityMap[keyy] = parseInt(wrapRec.acrRec.Quantity__c);
                        }
                        console.log('keyy - ' + keyy); 
                        console.log('productQuantityMap[key]- ' + productQuantityMap[key].value); 
                        console.log('shippingQuantityMap[keyy]- ' + shippingQuantityMap[keyy]); 
                        if(shippingQuantityMap[keyy] > productQuantityMap[key].value)
                        {
                            helper.showToast('Error!','Please make sure Shipping Quantity not greater than selected quantity','error');
                            component.set("v.showSpinner",false);
                            return;
                        }
                    }
                }
            }
            console.log('isFilled>>'+isFilled);
            //BZS-4921 starts
            if (component.get("v.ShowOnlyALE")) {
                var areaCodeList = component.get("v.areaCodeList");
                if (objectAccountCheckList && objectAccountCheckList.Main_Area_Code_Country__c) {
                    if (objectAccountCheckList.Main_Area_Code_Country__c == 'Other') {
                        if (!objectAccountCheckList.Other_Country__c) {
                            helper.showToast('Error!', 'Please input Other Country for Main Number!', 'error');
                            component.set("v.showSpinner", false);
                            return;
                        } else {
                            var regex1 = new RegExp("^[a-zA-Z ]*$");
                            var isValidCountry = regex1.test(objectAccountCheckList.Other_Country__c.trim());
                            console.log('isValidCountry' + isValidCountry)
                            console.log('objectAccountCheckList.Other_Country__c.trim().length' + objectAccountCheckList.Other_Country__c.trim().length)
                            if (!isValidCountry || !objectAccountCheckList.Other_Country__c.trim().length) {
                                helper.showToast('Error!', 'Please input only letters in Other Country!', 'error');
                                component.set("v.showSpinner", false);
                                return;
                            }
                        }
                    }
                }
                var noOfLicenses, sumOfLicenses = 0;
                var isAreaCodeFilled = false;
                console.log('Number_of_Licenses__c' + component.get("v.Quote.Number_of_Licenses__c"));
                noOfLicenses = component.get("v.Quote.Number_of_Licenses__c");
                for (var i in areaCodeList) {
                    console.log('areaRec' + areaCodeList[i]);
                    if (areaCodeList[i].Area_Code__c != undefined && areaCodeList[i].Area_Code__c != '' && areaCodeList[i].Area_Code__c != '') {
                        if (areaCodeList[i].Quantity_Requested__c != undefined && areaCodeList[i].Quantity_Requested__c != '' && areaCodeList[i].Quantity_Requested__c != '') {
                            sumOfLicenses = parseInt(sumOfLicenses) + parseInt(areaCodeList[i].Quantity_Requested__c);
                        } else {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Please input Quantity requested for each Area Code!",
                                "mode": 'dismissible'
                            });
                            toastEvent.fire();
                            component.set("v.showSpinner", false);
                            return;
                        }
                        if (areaCodeList[i].Country__c) {
                            if (areaCodeList[i].Country__c == 'Other') {
                                if (!areaCodeList[i].Other_Country__c) {
                                    helper.showToast('Error!', 'Please input Other Country!', 'error');
                                    component.set("v.showSpinner", false);
                                    return;
                                } else {
                                    var regex1 = new RegExp("^[a-zA-Z ]*$");
                                    var isValidCountry = regex1.test(areaCodeList[i].Other_Country__c.trim());
                                    console.log('isValidCountry' + isValidCountry)
                                    if (!isValidCountry || !areaCodeList[i].Other_Country__c.trim().length) {
                                        helper.showToast('Error!', 'Please input only letters in Other Country!', 'error');
                                        component.set("v.showSpinner", false);
                                        return;
                                    }
                                }
                            }
                        }
                    } else {
                        if (areaCodeList[i].Quantity_Requested__c != undefined && areaCodeList[i].Quantity_Requested__c != '' && areaCodeList[i].Quantity_Requested__c != '') {
                            sumOfLicenses = parseInt(sumOfLicenses) + parseInt(areaCodeList[i].Quantity_Requested__c);
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Please input Area Code!",
                                "mode": 'dismissible'
                            });
                            toastEvent.fire();
                            component.set("v.showSpinner", false);
                            return;
                        }
                    }
                }
                console.log('total sumOfLicenses' + sumOfLicenses);
                for (var i in areaCodeList) {
                    if (areaCodeList[i].Area_Code__c != undefined && areaCodeList[i].Area_Code__c != '' && areaCodeList[i].Area_Code__c != '') {
                        isAreaCodeFilled = true;
                    }
                }
                if (isAreaCodeFilled) {
                    if (sumOfLicenses > noOfLicenses) {
                        helper.showToast('Error!', 'Please ensure that Quantity Requested is not greater than selected no of Licenses ' + noOfLicenses, 'error');
                        component.set("v.showSpinner", false);
                        return;
                    } else if (sumOfLicenses < noOfLicenses) {
                        helper.showToast('Error!', 'Please ensure that Quantity Requested aligns with selected no of Licenses ' + noOfLicenses, 'error');
                        component.set("v.showSpinner", false);
                        return;
                    }
                }
            }//BZS-4921 ends
            if(validationError == false && (component.get("v.isShippingRequired") == false || component.get("v.showProductSection") == false)) {
               if(component.get("v.fromProcessOrder")){
                    partnerQuoteId = component.get("v.salesQuote").Id;
                }
                if(component.get("v.isFromCheckOutPage") && !component.get("v.fromProcessOrder")) {
                    var url = new URL(location.href);
                    var id = url.searchParams.get('id');
                    partnerQuoteId = id;
                }
            }
            if(isChangeOrder && component.get("v.fromProcessOrder")){
            	var action = component.get("c.createChangeOrderRequest");
                action.setParams({
                isChangeOrder : isChangeOrder,
                fromProcessOrder : component.get("v.fromProcessOrder"),
                partnerQuoteId :  partnerQuoteId, 
                accId : component.get("v.accountId")
                });
                action.setCallback(this, function(result) {  
                    var state = result.getState();
                    if (component.isValid() && state === "SUCCESS"){
                        component.set("v.showSpinner",false);
                        component.set("v.showProcessOrder", true);
                        component.set("v.processOrdercontext",'Process order has already been requested. Status: New');
                        helper.showToast('success','Submitted, Change Order Request submitted successfully','success');
                        component.set("v.showChecklistCMP",false);
                    }
                });
                $A.enqueueAction(action); 
                
            }else{
                var action = component.get("c.updateAccountChecklist");
            	action.setParams({
                fromProcessOrder : component.get("v.fromProcessOrder"),
                partnerQuoteId :  partnerQuoteId,  
                objCheckListRec : objectAccountCheckList,
                accId : component.get("v.accountId"),
                areaCodeList : component.get("v.areaCodeList"),
                isStandardMSA : component.get("v.standardMSAOptionValue") ,
                isAvaya : component.get("v.isAvaya"),
                isNoStandardPlayBook :  component.get("v.isNoStandardPlayBook"),
                addressList :  addressList,
                isFromCheckOut : component.get("v.isFromCheckOutPage"),
                Quote : component.get("v.Quote")
                
            });
            action.setCallback(this, function(result) {            
                var state = result.getState();
                //alert(state);
                if (component.isValid() && state === "SUCCESS"){
                    // helper.showToast('success','Successfully updated','success');
                    if(component.get("v.isFromCheckOutPage")) {
                        if(component.get("v.objAccountCheckList.Id") != undefined && 
                           component.get("v.objAccountCheckList.Id") != null &&
                           component.get("v.objAccountCheckList.Id") != ''){
                            helper.showToast('success','Submitted, Order submitted successfully','success');
                            var objAccountCheckListTmp = result.getReturnValue();
                            component.set("v.showSpinner",false);
                            component.set("v.objAccountCheckList",objAccountCheckListTmp);
                            component.set("v.showChecklistCMP",false);
                            helper.redirectTo('/quotetool?id='+ partnerQuoteId + '&step=5');
                            //helper.redirectTo('/partner/s/quotetool?id='+ partnerQuoteId + '&step=5');
                        }else{
                            var objAccountCheckListTmp = result.getReturnValue();
                            component.set("v.objAccountCheckList",objAccountCheckListTmp);
                            component.set("v.showSpinner",false);
                            component.set("v.showProcessOrder", true);
                            component.set("v.processOrdercontext",'Process order has already been requested. Status: New');
                            helper.showToast('success','Submitted, Order submitted successfully','success');
                            component.set("v.showChecklistCMP",false);
                            //alert('test');
                            /*var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type": "success",
                            "title": "Success!",
                            "message": "Successfully Submitted! Please upload any document if needed",
                            "mode":'dismissible'
                        });
                        toastEvent.fire();*/
                        }
                    }else {
                        var objAccountCheckListTmp = result.getReturnValue();
                        component.set("v.objAccountCheckList",objAccountCheckListTmp);
                        component.set("v.showSpinner",false);
                        helper.showToast('Success','Saved, Changes saved successfully','success');
                        component.set("v.showChecklistCMP",false);
                    }
                    
                }
            });    
            
            $A.enqueueAction(action); 
            }
            
        }
            catch(e)
            {
                console.log('exc - '+e);
            }
            
        },
    onCustomValidationClick : function(component, event, helper) {
        helper.submitDetails(component,event,helper);
    },
    
    addAccountChecklistAddress: function(component, event, helper) {
        var currShippingAddressList = component.get("v.ShippingAddressList");  
        console.log('length - '+ currShippingAddressList.length);
        var len = currShippingAddressList.length;
        var action = component.get("c.addAddressRow");
        console.log('stringfy>>.',JSON.stringify(component.get("v.ShippingAddressList")));
        action.setParams({
            addressList :  JSON.stringify(component.get("v.ShippingAddressList"))
        });
        action.setCallback(this, function(response) {   
            var state = response.getState();
            var oppCountry='';
            var oppState='';
            if (state == "SUCCESS"){
                console.log('component.get("v.communityDetailsRecord.Brand_Name__c") -'+component.get("v.communityDetailsRecord.Brand_Name__c"));
                if(component.get("v.communityDetailsRecord.Brand_Name__c")== 'Rainbow Office'){
                    if(component.get("v.isFromCheckOutPage")){
                        console.log('opp country for ale',component.get("v.Quote").Opportunity__r.Account.BillingCountry);
                        oppCountry=component.get("v.Quote").Opportunity__r.Account.BillingCountry;
                        oppState=component.get("v.Quote").Opportunity__r.Account.BillingState;
                    }else{
                        oppCountry=component.get("v.OpportunityRecord").Account.BillingCountry;
                        oppState=component.get("v.OpportunityRecord").Account.BillingState;
                    }
                    
                    var currShippingAddressList = response.getReturnValue();  
                    console.log('length1 - '+ currShippingAddressList.length);
                    var len = currShippingAddressList.length;
                    console.log('response add'+JSON.stringify(currShippingAddressList));
                    console.log('oppCountry'+oppCountry);
                    console.log('oppState'+oppState);
                    if(currShippingAddressList!=undefined && currShippingAddressList!=null && currShippingAddressList!='')
                    {
                        currShippingAddressList[len-1].acrRec.Country__c = oppCountry;
                        currShippingAddressList[len-1].acrRec.State__c = oppState;    
                        var mapCountryStates = component.get("v.mapData");
                        console.log('mapCountryStates'+mapCountryStates);                 
                        var stateValues = [];
                        var statesForCountry1 = mapCountryStates[oppCountry];
                        var statesForCountry = statesForCountry1.toString();
                        console.log('states>>'+statesForCountry);
                        if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
                            for(var i=0;i<statesForCountry.split(',').length;i++){
                                stateValues.push(statesForCountry.split(',')[i]); 
                            }
                        }
                        currShippingAddressList[len-1].shippingStateList=stateValues;
                        component.set("v.ShippingAddressList", currShippingAddressList); 
                        console.log('shiipingadd row>>>',currShippingAddressList);
                    }      
                }else{
                    component.set("v.ShippingAddressList", response.getReturnValue());
                }
            }
        }); 
        $A.enqueueAction(action); 
    },
    
    getuploadedFiles:function(component){
        try
        {
            var parentRecordId = component.get("v.objAccountCheckList.Id");
            var action = component.get("c.getFiles");  
            action.setParams({  
                "recordId":parentRecordId  
            });      
            action.setCallback(this,function(response){  
                var state = response.getState();  
                if(state=='SUCCESS'){ 
                    var result = response.getReturnValue();           
                    component.set("v.files",result);  
                    for (var i = 0; i < result.length; i++) {
                        var row = result[i]; 
                        if(row.Title==undefined ||row.Title=='')
                            row.Title='';
                        else
                            row.Title=row.Title+'.'+row.FileType;
                    }
                    if(result == undefined || result =='' ||result ==null)
                        component.set("v.FilesMessage", true);
                    else{
                        component.set("v.FilesMessage", false);
                    }
                } 
                else{
                    component.set("v.FilesMessage", true);
                }
            }); 
            
            $A.enqueueAction(action);  
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
    },
    getPhoneProducts : function(component) {
        try
        {
            var partnerQuoteId;
            if(component.get("v.isFromCheckOutPage")) {
                var url = new URL(location.href);
                var id = url.searchParams.get('id');
                partnerQuoteId = id;
            } 
            var action = component.get("c.getPhoneProductFROMQuoteLine");  
            action.setParams({  
                "recordId": partnerQuoteId  
            });      
            action.setCallback(this,function(response){  
                var state = response.getState();
                if(state=='SUCCESS'){ 
                    var productMap = [];
                    var productQuantityMap = [];
                    var result = response.getReturnValue();
                    if(result) {
                        var productNameMap = result.mapOfProductIdToProductName;
                        for(var key in productNameMap){
                            productMap.push({key: key, value: productNameMap[key]});
                        }
                        
                        //Quantity Part
                        var productQuantiyMapTemp = result.mapOfProductIdToProductQuantity;
                        for(var key in productQuantiyMapTemp){
                            productQuantityMap.push({key: key, value: productQuantiyMapTemp[key]});
                        }
                    }
                    
                    if(productMap.length > 0 ){
                        component.set("v.showProductSection",true);
                    }
                    else
                    {
                        if(component.get("v.isFromCheckOutPage")) {
                            component.set("v.isShippingRequired", false);
                        }
                        
                    }
                    console.log("showProductSection - " + component.get("v.showProductSection"));
                    console.log("isShippingRequired - " + component.get("v.isShippingRequired"));
                    component.set("v.productMap",productMap);
                    component.set("v.productQuantityMap",productQuantityMap);
                    
                    var addressList = component.get("v.ShippingAddressList");
                    for(var i=0; i < addressList.length; i++)
                    {
                        for(var key in productQuantityMap)
                        {
                            if(productQuantityMap[key].key == addressList[i].acrRec.Product_Catalogue__c) {
                                addressList[i].acrRec.Selected_Quantity__c = productQuantityMap[key].value;
                            }
                        }
                    }
                    component.set("v.ShippingAddressList",addressList);
                }
            });  
            $A.enqueueAction(action);  
        }
        catch(e)
        {
            console.log('error - '+ e);
        }
    },
    getCountryStateValues : function(component,event,helper){
        try
        {
            var communityBrand='';
            console.log('v.Quote.Opportunity__r.Brand_Name__c - '+ component.get('v.Quote.Opportunity__r.Brand_Name__c'));
            console.log('v.communityDetailsRecord - ' + component.get("v.communityDetailsRecord"));
            if(component.get("v.communityDetailsRecord")!=undefined && component.get("v.communityDetailsRecord") !='' && component.get("v.communityDetailsRecord") !=null)
                communityBrand = component.get("v.communityDetailsRecord").Brand_Name__c;
            else
                communityBrand = component.get('v.Quote.Opportunity__r.Brand_Name__c');
            console.log('communityBrand'+communityBrand);
            var action = component.get("c.getCountryStateMap");
            action.setParams({ 
                "communityBrand": communityBrand
            });
            
            action.setCallback(this, function(response) {   
                var state = response.getState();
                console.log('state - ' + state);
                if (state === "SUCCESS") { 
                    var dataResponse = response.getReturnValue();
                    console.log('dataResponse - ' + dataResponse);
                    var data = dataResponse.countryStateMap;
                    console.log('data - '+ data);
                    var countries = dataResponse.countriesAvailable;
                    console.log('countries - '+ countries);
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
                    //Added for BZS-4921 starts
                    component.set("v.mapLegalCountryKeys", arrayMapKeys);
                    if (communityBrand == 'Rainbow Office') {
                        var mainCountryKeys = arrayMapKeys;
                        mainCountryKeys.push({ key: 'Other', value: '' });
                        component.set("v.mapCountryKeys", mainCountryKeys);
                        component.set("v.removesingaporelist", mainCountryKeys);
                    } else
                        component.set("v.mapCountryKeys", arrayMapKeys);
                    	component.set("v.removesingaporelist", arrayMapKeys);
                    //Added for BZS-4921 ends
                    component.set("v.mapData", data);
                    console.log('arrayMapKeys>>',arrayMapKeys);
                    component.set("v.mapCountryValueKeys",stateValues);
                    var objAccountCheckList = component.get("v.objAccountCheckList");
                    if(objAccountCheckList && objAccountCheckList.Legal_Country__c) {
                        var legalStateValues= helper.defaultState(component,event,helper,objAccountCheckList.Legal_Country__c);
                        component.set("v.mapCountryValueKeys",legalStateValues);    
                    }
                    
                    // component.set('v.ShowSpinnerOpp',false);
                }else{
                    component.set('v.ShowSpinnerOpp',false);
                    console.log('elseee');
                }             
            });        
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('error - '+e);
        }
    },
    onchangeCountry:function(component,event,helper,isLegal,index){
        //alert('test');
        console.log('Country '+ event.getSource().get("v.value"))
        var mapCountryStates = (component.get("v.mapData"));
        var selctedValue = event.getSource().get("v.value");
        
        var stateValues = [];
        var statesForCountry1 = mapCountryStates[selctedValue];
        var statesForCountry = statesForCountry1.toString();
        if(isLegal) {
            component.set("v.mapCountryValueKeys",stateValues);
        }
        else {
            component.set("v.mapShappingCountryValueKeys",stateValues);
        }
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
        if(isLegal) {
            component.set("v.mapCountryValueKeys",stateValues);
            component.find("selectedState").set("v.value",stateValues[0]);
        } else {
            var shippingAddressList = component.get("v.ShippingAddressList");
            //alert(shippingAddressList);
            //alert(index);
            console.log(stateValues);
            console.log(shippingAddressList[index].shippingStateList);
            shippingAddressList[index].shippingStateList = stateValues;
            //shippingAddressList[index].shippingStateList.push(stateValues);
            component.set("v.ShippingAddressList",shippingAddressList);
            //component.set("v.mapShappingCountryValueKeys",stateValues);
            //component.find("shippingState").set("v.value",stateValues[0]);
        }
        
    },
    
    defaultState : function(component,event,helper,selectedValue) {
        try
        {
            var objAccountCheckList = component.get("v.objAccountCheckList");
            console.log('objAccountCheckList - ' + JSON.stringify(objAccountCheckList));
            if(objAccountCheckList.Id == undefined)
                console.log('object undefined..');
            var oppState='';
            console.log('component.get("v.communityDetailsRecord") - ' + component.get("v.communityDetailsRecord"));
            
            var currShippingAddressList = component.get("v.ShippingAddressList"); 
            console.log('currShippingAddressList - ' + JSON.stringify(currShippingAddressList));
            //if(component.get("v.communityDetailsRecord")!=null){
            
            var communityBrand='';
            if(component.get("v.communityDetailsRecord")!=undefined && component.get("v.communityDetailsRecord") !='' && component.get("v.communityDetailsRecord") !=null)
                communityBrand = component.get("v.communityDetailsRecord").Brand_Name__c;
            else
            {
                if(component.get("v.isFromCheckOutPage")){
                    communityBrand = component.get('v.Quote.Opportunity__r.Brand_Name__c');
                }
                else
                {
                    communityBrand = component.get('v.OpportunityRecord.Brand_Name__c');
                }
            }
            
            if(communityBrand == 'Rainbow Office')
            {
                if(objAccountCheckList.Id == undefined)
                {
                    if(component.get("v.isFromCheckOutPage")){
                        console.log('opp country for ale',component.get("v.Quote").Opportunity__r.Account.BillingCountry);
                        selectedValue=component.get("v.Quote").Opportunity__r.Account.BillingCountry;
                        oppState=component.get("v.Quote").Opportunity__r.Account.BillingState;
                    }else{
                        selectedValue=component.get("v.OpportunityRecord").Account.BillingCountry;
                        oppState=component.get("v.OpportunityRecord").Account.BillingState;
                    }
                    component.set("v.objAccountCheckList.Legal_Country__c",selectedValue);
                    component.set("v.objAccountCheckList.Legal_State__c",oppState);
                    //var countryUndefined;
                    if(currShippingAddressList!=undefined && currShippingAddressList!=null)
                    {
                        //countryUndefined = true;
                        currShippingAddressList[0].acrRec.Country__c = selectedValue;
                        currShippingAddressList[0].acrRec.State__c = oppState;   
                        component.set("v.ShippingAddressList", currShippingAddressList); 
                    }
                }
            }
            //}
            console.log('selectedValue>',selectedValue);
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
                if(communityBrand == 'Rainbow Office'){
                    if(objAccountCheckList.Id == undefined)
                    {
                        currShippingAddressList[0].shippingStateList=stateValues;
                    }
                    component.set("v.ShippingAddressList", currShippingAddressList); 
                    component.set("v.shippingStateList",stateValues);
                    console.log('stateValues'+component.get("v.shippingStateList"));
                }
                return stateValues;
            }
        }
        catch(e)
        {
            console.log('exception - ' + e);
        }
    },
    
    copyAccountChecklistAddress: function(component, event, helper) {
        var currShippingAddressList = component.get("v.ShippingAddressList");  
        console.log('length - '+ currShippingAddressList.length);
        var len = currShippingAddressList.length;
        var selectedItem = event.currentTarget;        
        var index = selectedItem.dataset.record;
        console.log('street  - ' + currShippingAddressList[index].acrRec.Shipping_Address__c);
        currShippingAddressList[len - 1].acrRec.Shipping_Address__c = currShippingAddressList[index].acrRec.Shipping_Address__c;
        currShippingAddressList[len - 1].acrRec.City__c = currShippingAddressList[index].acrRec.City__c;
        currShippingAddressList[len - 1].shippingStateList = currShippingAddressList[index].shippingStateList;
        currShippingAddressList[len - 1].acrRec.State__c = currShippingAddressList[index].acrRec.State__c;
        currShippingAddressList[len - 1].acrRec.Country__c = currShippingAddressList[index].acrRec.Country__c;    
        currShippingAddressList[len - 1].acrRec.Zip_Code__c = currShippingAddressList[index].acrRec.Zip_Code__c; 
        component.set("v.ShippingAddressList", currShippingAddressList);         
    },
    
    //Added for ACO 3.0 - starts        
    handleShowVAR : function(component,event,helper) {
        try
        {
            var action = component.get("c.getCountryAndCommunityForCustAcct");
            var accountId = component.get("v.accountId");
            var oppId = component.get("v.recordID");//BZS-4921
            action.setParams({ 
                "accountId": accountId, "opportunityId": component.get("v.recordID")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('handleShowVAR state>>>>',state);
                if (state === "SUCCESS") { 
                    var dataResponse = response.getReturnValue();                
                    var communityRecord = dataResponse.comDetail;
                    var partnerCommunity = '';
                    if(communityRecord != null){
                        partnerCommunity = communityRecord.Brand_Name__c;                    
                    }else{
                        partnerCommunity = dataResponse.RCBrand;
                    }
                    component.set("v.showSpinner",false);
                    console.log("partnerCommunityName "+partnerCommunity); 
                    component.set("v.customerAccount", dataResponse.custAccount);
                    if(partnerCommunity == 'Rainbow Office')
                    {
                        component.set("v.ShowOnlyALE",true);
                    }
                         var oppCountry = '';
                var isFromCheckOutPage = component.get("v.isFromCheckOutPage");   
                if(isFromCheckOutPage){
                    oppCountry = dataResponse.custAccount.BillingCountry;
                }else{
                    oppCountry = component.get("v.oppCountry");
                }
                console.log("oppCountry "+oppCountry);
                component.set("v.oppCountry",oppCountry);
                var countryMap=component.get('v.mapCountryKeys');
                var itr=countryMap.keys();
                let countries = [...countryMap.values()];
                let directDebitCountries = [];
                for(var i=0;i<countries.length;i++){
                    if(countries[i].key!='Canada'&&countries[i].key!='United States'&&countries[i].key!='Australia'&&countries[i].key!='Switzerland'&&countries[i].key!='Singapore'){
                        directDebitCountries.push(countries[i].key);
                    }
                }
                var paymentMethods=['Credit Card','Invoice Billing'];
                for(var b=0; b<directDebitCountries.length; b++){
                    if(oppCountry==directDebitCountries[b]){
                      paymentMethods=['Credit Card','Invoice Billing','Direct Debit'];  
                    }
                }
                //Added for singapore starts
                if(oppCountry=='Singapore'|| oppCountry =='Switzerland'){
                    paymentMethods=['Invoice Billing'];
                }      
                //Added for singapore ends
                var partnerType = dataResponse.custAccount.Partner_Account__r.Partner_Type__c;
                console.log("Partner Type:" +partnerType);
                
                if(partnerType == 'Bill-on-Behalf' || partnerType == 'Alcatel-Lucent - Bill-on-Behalf' || partnerType == 'Atos - Bill-on-Behalf' || partnerType == 'Avaya - Bill-on-Behalf'){
                    paymentMethods = ['Invoice-on-behalf'];
                }
                if(partnerType == 'Wholesale-Reseller' || partnerType == 'Alcatel-Lucent - Wholesale-Reseller' || partnerType == 'Atos - Wholesale-Reseller' || partnerType == 'Avaya - Wholesale-Reseller'){
                    paymentMethods = ['Invoice-Wholesale'];
                }  
                component.set("v.paymentListDisplayed",paymentMethods);
                console.log("objAcctCheckList payment->"+JSON.stringify(component.get('v.objAccountCheckList').Payment_Method__c));
                console.log("paymentMethods list>"+JSON.stringify(paymentMethods));
                    if(partnerCommunity == 'Avaya Cloud Office' || partnerCommunity == 'Rainbow Office'){
                        //var EUCountries = ['France','Ireland','Netherlands','Italy','Germany','Belgium','Austria','Spain','United Kingdom','Australia'];//ACO 4.0
                        //Added for BZS-4921 starts 
                        if (!component.get("v.isFromCheckOutPage")) {
                            console.log('dataResponse.objQuote' + dataResponse.objQuote);
                            if (dataResponse.objQuote != undefined && dataResponse.objQuote != '' && dataResponse.objQuote != null)
                                component.set("v.Quote", dataResponse.objQuote);
                            console.log('quote details>' + JSON.stringify(component.get("v.Quote")));
                        } //Added for BZS-4921 ends
                        var EUCountries = [];
                        if(partnerCommunity == 'Avaya Cloud Office')
                        {
                            //Added Portugal for ACO 5.0
                            EUCountries = ['France','Ireland','Netherlands','Italy','Germany','Belgium','Austria','Spain','United Kingdom','Australia','Portugal','Switzerland'];//ACO 4.0
                        }
                        if(partnerCommunity == 'Rainbow Office')
                        {
                            EUCountries = ['Austria','Belgium','France','Germany','Ireland','Italy','Netherlands','Spain','United Kingdom', 'Australia'];
                            component.set("v.ShowOnlyALE", true);
                        }                        
                        //Added for BZS-4921 starts
                        if (partnerCommunity == 'Rainbow Office') {
                            var objAccountCheckList = component.get("v.objAccountCheckList");
                            console.log('ac country' + objAccountCheckList.Main_Area_Code_Country__c);
                            if (objAccountCheckList.Main_Area_Code_Country__c == undefined || objAccountCheckList.Main_Area_Code_Country__c == null || objAccountCheckList.Main_Area_Code_Country__c == '')
                                component.set("v.objAccountCheckList.Main_Area_Code_Country__c", oppCountry);
                        } //Added for BZS-4921 ends
                        for(var b=0; b<EUCountries.length; b++){
                            if(oppCountry == (EUCountries[b])){
                                component.set("v.showVAR",true);
                                break;
                            }else{
                                component.set("v.showVAR",false);
                            }
                        }
                    }
                    else if(partnerCommunity == 'Unify Office'){
                        component.set("v.ShowOnlyAtos",true);
                        console.log('VATNumber>>'+dataResponse.custAccount.VATNumber__c);
                        component.set("v.objAccountCheckList.VAT_Number__c",dataResponse.custAccount.VATNumber__c);
                        console.log('appro>'+dataResponse.custAccount.Approvals__r);
                        console.log('Opportunities>'+dataResponse.custAccount.Opportunities);
                        var listOfApprovals=[];
                        if(dataResponse.custAccount.Approvals__r != undefined && dataResponse.custAccount.Approvals__r!= null && dataResponse.custAccount.Approvals__r !=''){
                            listOfApprovals=dataResponse.custAccount.Approvals__r;
                            //console.log('listOfApprovals>'+JSON.stringify(listOfApprovals));
                            if(listOfApprovals.length>0){
                                for(var i = 0; i < listOfApprovals.length; i++){
                                    if(listOfApprovals[i].VATExemption__c !=null || listOfApprovals[i].VATExemption__c != undefined){
                                        if(listOfApprovals[i].VATExemption__c == 'Approved'){
                                            component.set("v.isVATReadOnly",true);
                                            console.log('is vatreadonly>'+ component.get("v.isVATReadOnly"));
                                        }
                                    }
                                }
                            }
                        }else{
                            component.set("v.isVATReadOnly",false);
                        }
                        
                        /*if(dataResponse.custAccount.Opportunities != undefined && dataResponse.custAccount.Opportunities!= null && dataResponse.custAccount.Opportunities !=''){
                        var listOfOpps=[];
                        listOfOpps=dataResponse.custAccount.Opportunities;
                        console.log('listOfOpps'+JSON.stringify(listOfOpps))
                        if(listOfOpps.length>0){
                            for(var i = 0; i < listOfOpps.length; i++){
                                if(listOfOpps[i].Tier_Name__c !=null && listOfOpps[i].Tier_Name__c != undefined){
                                    if(listOfOpps[i].Tier_Name__c == 'RC Meetings'){
                                        component.set("v.isShippingRequired",false);
                                        console.log('is isShippingRequired>'+ component.get("v.isShippingRequired"));
                                    }else{
                                          component.set("v.isShippingRequired",true);
                                        console.log('is isShippingRequired>'+ component.get("v.isShippingRequired"));
                                    }
                                }
                            }
                        }
                    }*/
                    console.log('is vatreadonly>', component.get("v.isVATReadOnly"));

                    //ATOS 21.2 - Added Finland
                    var VATCountriesAtos = ['France', 'Ireland', 'Netherlands', 'Italy', 'Denmark', 'Norway', 'Switzerland', 'Portugal', 'Sweden', 'Germany', 'Belgium',
                        'Austria', 'Spain', 'United Kingdom', 'Australia', 'Finland'];
                    var vatRequiredCountries = ['France', 'Ireland', 'Netherlands', 'Italy', 'Denmark', 'Norway', 'Switzerland', 'Portugal', 'Sweden', 'Germany', 'Belgium', 'Austria', 'Spain'];
                    var isFromCheckOutPage = component.get("v.isFromCheckOutPage");            
                    var oppCountry = '';
                    if(isFromCheckOutPage){
                        oppCountry = dataResponse.billingCountry;
                    }else{
                        oppCountry = component.get("v.oppCountry");
                    }
                    console.log("oppCountry "+oppCountry);
                    component.set("v.oppCountry", oppCountry);//Added for BZS-4921
                    for(var b=0; b<VATCountriesAtos.length; b++){
                        if(oppCountry == (VATCountriesAtos[b])){
                            component.set("v.showVAR",true);
                            /*if(oppCountry == (vatRequiredCountries[b])){
                                component.set("v.isVATRequired",true);
                                console.log('isVATRequired>'+ component.get("v.isVATRequired"))
                            }*/
                            break;
                        }else{
                            component.set("v.showVAR",false);
                        }
                    }
                    console.log('showvar>'+component.get("v.showVAR"));
                }
                    else{
                        
                        component.set("v.showVAR",false);
                        if(!component.get("v.fromProcessOrder")){
                            component.set("v.oppCountry", component.get("v.Quote").Opportunity__r.Account.BillingCountry);
                        }
                    }                
            }else{
                component.set("v.showVAR",false);
            }
        });        
            $A.enqueueAction(action); 
        }
        catch(e)
        {
            console.log('error - '+ e);
        } 
    },
    //Added for ACO 3.0 - ends
    //Added for BZS-4921 starts
    getAreaCodeLists: function (component, event, helper) {
        try {
            var action = component.get("c.getAreaCodeListsForAccountChecklists");
            action.setParams({
                "accountChecklistId": component.get("v.objAccountCheckList.Id")
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                console.log('state' + state);
                if (state == 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log('area code list--' + JSON.stringify(result));
                    component.set("v.areaCodeList", result);
                    if (result == undefined || result == '' || result == null) {
                        var areaCodeList = [];
                        areaCodeList.push({
                            'sobjectType': 'Area_Codes__c',
                            'Area_Code__c': '',
                            'Country__c': component.get("v.oppCountry"),
                            'Is_Area_Code_Declaration_Checked__c': false
                        });
                        console.log('area code list--' + JSON.stringify(areaCodeList));
                        component.set("v.areaCodeList", areaCodeList);
                    }
                }
            });
            
            $A.enqueueAction(action);
        }
        catch (e) {
            console.log('err ' + e);
        }
    },  //Added for BZS-4921 ends
	 //Translation Start
    getTranslations: function (component, event, helper) {
        try {
            function setTranslations(result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if (resultData != undefined && resultData != null && resultData != '') {
                        if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
                            resultData.allObjFieldsMap != '') {
                            component.set("v.DealRegFieldsMap", resultData.allObjFieldsMap.Deal_Registration__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            };
            var getTranslations = component.get("c.getTranslations");
            getTranslations.setParams({
                "objNames": 'Deal_Registration__c'
            });
            getTranslations.setCallback(this, setTranslations);
            $A.enqueueAction(getTranslations);
        }
        catch (e) {
            console.log('err - ' + e);
        }
    }
    //Translation End
})
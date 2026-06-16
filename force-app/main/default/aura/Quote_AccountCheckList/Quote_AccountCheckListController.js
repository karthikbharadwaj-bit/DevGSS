({
    doInit : function(component, event, helper) {
        component.set("v.showSpinner",true);
        /*console.log('isFromCheckOutPage - ' + component.get("v.isFromCheckOutPage"));
        var brandName = '';
        if(component.get("v.isFromCheckOutPage")){
            console.log('Quote Brand Name - ' + component.get("v.Quote").Opportunity__r.Brand_Name__c);
            brandName = component.get("v.Quote").Opportunity__r.Brand_Name__c;
        }
        else {
            console.log('Opp Brand Name - ' + component.get("v.OpportunityRecord").Brand_Name__c);
            brandName = component.get("v.OpportunityRecord").Brand_Name__c;
        }
        
        if(brandName == 'Rainbow Office')
            component.set("v.ShowOnlyALE",true); */
        helper.getTranslations(component, event, helper);
        helper.getCountryStateValues(component, event, helper);
        helper.getuploadedFiles(component); 
        if(component.get("v.fromProcessOrder")){
               component.set("v.showProductSection",false);
               component.set("v.isShippingRequired", false);
        }else{
             helper.getPhoneProducts(component);
        }
        var url = new URL(location.href);            
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));
        component.set("v.baseURL",baseURL);
        //Added for ACO 3.0
        helper.handleShowVAR(component, event, helper);
        helper.getAreaCodeLists(component, event, helper);//Added for BZS-4921
        
    },
    submitDetails : function(component, event, helper) {
        try
        {
            if(!component.get("v.dealSupportExists")) {
                var addressList = [];
                var shippingAddressList = component.get("v.ShippingAddressList");//Added for BZS-4921 starts
                var communityBrand = '';
                var areaCodeList = component.get("v.areaCodeList");
                var objectAccountCheckList = component.get("v.objAccountCheckList");
                if (component.get("v.communityDetailsRecord") != undefined && component.get("v.communityDetailsRecord") != '' && component.get("v.communityDetailsRecord") != null)
                    communityBrand = component.get("v.communityDetailsRecord").Brand_Name__c;
                else {
                    if (component.get("v.isFromCheckOutPage"))
                        communityBrand = component.get('v.Quote.Opportunity__r.Brand_Name__c');
                    else
                        communityBrand = component.get('v.OpportunityRecord.Brand_Name__c');
                }
                /* var paymentDropdown=component.get('v.showPaymentDropDown');
        	var objAcctCheckList=component.get('v.objAccountCheckList');
            if(!paymentDropdown){
            var invoiceCreditCard=objAcctCheckList.Invoice_Credit_Card__c;
            if(invoiceCreditCard){
                objAcctCheckList.Payment_Method__c="Invoice Billing";
            }else{
                objAcctCheckList.Payment_Method__c="Credit Card";
            }
            }*/
            console.log("Payment Method Selected-->"+component.get("v.objAccountCheckList").Payment_Method__c);
            
            if(component.get("v.objAccountCheckList").Payment_Method__c==""||component.get("v.objAccountCheckList").Payment_Method__c==undefined||component.get("v.objAccountCheckList").Payment_Method__c==null){
                            helper.showToast('Error', 'Please Select a Payment Method before submitting!', 'error');
                			component.set("v.showSpinner",false);
                			return;
                			
            }
                //Added for BZS-4921 starts ends
                if(component.get("v.showProductSection")== true){
                    if(component.get("v.isShippingRequired")== true){
                        //alert(shippingAddressList);
                        if(shippingAddressList) {
                            for(var wrapRec of shippingAddressList) {
                                addressList.push(wrapRec.acrRec);
                                var shippingMethod=wrapRec.acrRec.Shipping_Method__c;
                                var shippingContactName=wrapRec.acrRec.Shipping_Contact__c;
                                var shippingContactPhoneNumber=wrapRec.acrRec.Shipping_Contact_Phone_Number__c; 
                                console.log('shippingMethod for>'+shippingMethod);
                                console.log('shippingContactName for>'+shippingContactName);
                                console.log('shippingContactPhoneNumber for>'+shippingContactPhoneNumber);
                                if(wrapRec.acrRec.Type__c == 'Shipping Address' && (shippingContactName==undefined || shippingContactName=='' || shippingContactName==null)){
                                    component.set("v.showSpinner",false);
                                    //wrapRec.acrRec.Shipping_Contact__c.showHelpMessageIfInvalid();
                                    
                                    //console.log(' shippingContactName.focus()>'+acrRec.Shipping_Contact__c);
                                    /* var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Please enter Shipping Contact before submitting!",
                                    "mode":'dismissible'
                                });
                                toastEvent.fire(); */
                                helper.showToast('Error', 'Please enter Shipping Contact before submitting!', 'error');
                                
                            }
                            if(wrapRec.acrRec.Type__c == 'Shipping Address' && (shippingContactPhoneNumber==undefined  || shippingContactPhoneNumber ==null || shippingContactPhoneNumber=='')){
                                component.set("v.showSpinner",false);
                                /*var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Please enter Shipping Contact Phone Number before submitting!",
                                    "mode":'dismissible'
                                });
                                toastEvent.fire();*/
                                helper.showToast('Error', 'Please enter Shipping Contact Phone Number before submitting!', 'error');
                            } 
                        }
                    }
                    //Added for BZS-4921 starts
                    if (communityBrand == 'Rainbow Office') {
                        if (objectAccountCheckList && objectAccountCheckList.Main_Number_Area_Code__c) {
                            if (objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == undefined || objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == null || objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == '') {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "Please check the confirmation checkbox of Area Code!",
                                    "mode": 'dismissible'
                                });
                                toastEvent.fire();
                                component.set("v.showSpinner", false);
                                return;
                            }
                        }
                        if (areaCodeList) {
                            for (var i in areaCodeList) {
                                console.log('areaRec' + areaCodeList[i]);
                                if (areaCodeList[i].Area_Code__c != undefined && areaCodeList[i].Area_Code__c != '' && areaCodeList[i].Area_Code__c != '') {
                                    if (areaCodeList[i].Is_Area_Code_Declaration_Checked__c == false) {
                                        var toastEvent = $A.get("e.force:showToast");
                                        toastEvent.setParams({
                                            "type": "error",
                                            "title": "Error!",
                                            "message": "Please check the confirmation checkbox of Area Code!",
                                            "mode": 'dismissible'
                                        });
                                        toastEvent.fire();
                                        component.set("v.showSpinner", false);
                                        return;
                                    }
                                }
                            }
                        }
                    } //Added for BZS-4921 ends
                    var isFilled=false;
                    for(var i=0;i<addressList.length;i++){
                        
                        var row = addressList[i]; 
                        if(row.Type__c == 'Shipping Address') {
                            if(row.Shipping_Contact__c == undefined || row.Shipping_Method__c ==undefined  || row.Shipping_Contact_Phone_Number__c ==undefined
                               || row.Shipping_Contact__c == '' || row.Shipping_Method__c ==''  || row.Shipping_Contact_Phone_Number__c ==''
                               || row.Shipping_Contact__c == null || row.Shipping_Method__c ==null  || row.Shipping_Contact_Phone_Number__c ==null){
                                isFilled=false;
                                break;
                            }else{
                                isFilled=true;
                            } 
                        }
                        else if(row.Type__c == 'Billing Address') {
                            isFilled=true;
                        }
                    }
                    if(isFilled){
                        if(component.get("v.isFromCheckOutPage"))
                            helper.onCustomValidationClick(component, event, helper); 
                        else
                            helper.submitDetails(component,event,helper);
                    }
                }
            }
            else if(component.get("v.isShippingRequired")== false || component.get("v.showProductSection") == false || component.get("v.fromProcessOrder")) {
                //Added for BZS-4921 starts
                var isAreaCodeCheckboxFilled = false;
                if (communityBrand == 'Rainbow Office') {
                    if (objectAccountCheckList && objectAccountCheckList.Main_Number_Area_Code__c) {
                        if (objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == undefined || objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == null || objectAccountCheckList.Is_Area_Code_Declaration_Checked__c == '') {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "error",
                                "title": "Error!",
                                "message": "Please check the confirmation checkbox of Area Code!",
                                "mode": 'dismissible'
                            });
                            toastEvent.fire();
                            component.set("v.showSpinner", false);
                            return;
                        } else {
                            if (areaCodeList) {
                                for (var i in areaCodeList) {
                                    console.log('areaRec' + areaCodeList[i]);
                                    if (areaCodeList[i].Area_Code__c != undefined && areaCodeList[i].Area_Code__c != '' && areaCodeList[i].Area_Code__c != '') {
                                        if (areaCodeList[i].Is_Area_Code_Declaration_Checked__c == false) {
                                            var toastEvent = $A.get("e.force:showToast");
                                            toastEvent.setParams({
                                                "type": "error",
                                                "title": "Error!",
                                                "message": "Please check the confirmation checkbox of Area Code!",
                                                "mode": 'dismissible'
                                            });
                                            toastEvent.fire();
                                            component.set("v.showSpinner", false);
                                            isAreaCodeCheckboxFilled = false;
                                            break;
                                        } else
                                            isAreaCodeCheckboxFilled = true;
                                    } else
                                        isAreaCodeCheckboxFilled = true;
                                }
                            } else
                                isAreaCodeCheckboxFilled = true;
                        }
                    } else
                        isAreaCodeCheckboxFilled = true;
                } else {
                    isAreaCodeCheckboxFilled = true;
                }
                console.log('isAreaCodeCheckboxFilled--' + isAreaCodeCheckboxFilled);
                if (isAreaCodeCheckboxFilled) //Added for BZS-4921 ends
                    helper.submitDetails(component,event,helper);
            }
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "Information",
                "message": "There is a pending contract approval request. Order can not be submitted.",
                "mode":'dismissible'
            });
            toastEvent.fire();
        }
               }
               catch(e)
               {
                   console.log('exceptionn - ' + e);
               }
           },
    closeModel : function(component, event, helper) {
        component.set("v.showChecklistCMP",false);
    },
    addRow: function(component, event, helper) {
        helper.addAreaCodeRecord(component, event);
    },
    removeRow: function(component, event, helper) {
        //Get the account list
        var areaCodeList = component.get("v.areaCodeList");
        //Get the target object
        var selectedItem = event.currentTarget;
        //Get the selected item index
        var index = selectedItem.dataset.record;
        areaCodeList.splice(index, 1);
        component.set("v.areaCodeList", areaCodeList);
    },
    removeAddressRow: function(component, event, helper) {        
        var addressList = component.get("v.ShippingAddressList");        
        var selectedItem = event.currentTarget;        
        var index = selectedItem.dataset.record;
        addressList.splice(index, 1);
        component.set("v.ShippingAddressList", addressList);
    },
    addAddressRow1 : function(component, event, helper) {
        helper.addAccountChecklistAddress(component, event, helper);
    },
    countryChange : function(component, event, helper) {
        var currentTarget = event.getSource();
        var index = currentTarget.get("v.name");
        var isLegal = false;
        helper.onchangeCountry(component,event,helper,isLegal,index);
    },
     //PRM-247
     //Commented for BZS-10931
    /*typeChange : function(component, event, helper) {
        var currentTarget = event.getSource();
        var index = currentTarget.get("v.name");
        var isLegal = false;
        var selectedType = event.getSource().get("v.value");
        var countryvalue=component.get('v.mapCountryKeys');
        var singaporeremove = [];
        for(var i=0;i<countryvalue.length;i++){
            if(countryvalue[i].key!='Singapore'){
                singaporeremove.push({ key: countryvalue[i].key, value: countryvalue[i].value });
            }
        }
        if(selectedType == 'Shipping Address')
        {
            component.set("v.removesingaporelist", singaporeremove);
        }
        else
        {
            component.set("v.removesingaporelist", countryvalue);
        }
        
        console.log('singaporeremove>>>>>>',singaporeremove); 
        console.log('Selectedtype '+ event.getSource().get("v.value"));
    },*/
    onLegalCountryChange : function(component, event, helper) {
        console.log('....test change');
        var objAccountCheckList = component.get("v.objAccountCheckList");
        objAccountCheckList.Legal_State__c = '';
        component.set("v.objAccountCheckList",objAccountCheckList);
    },
    productChange : function(component, event, helper) {
        var currentTarget = event.getSource();
        var productId = currentTarget.get("v.name");
        var index = currentTarget.get("v.class");
        var addressList = component.get("v.ShippingAddressList");
        var productQuantityMap = component.get("v.productQuantityMap");
        if(productQuantityMap && productId) {
            for(var key in productQuantityMap){
                if(productQuantityMap[key].key == productId) {
                    addressList[index].acrRec.Selected_Quantity__c = productQuantityMap[key].value;
                    addressList[index].acrRec.Quantity__c = '';
                    component.set("v.ShippingAddressList",addressList);
                }
            }
        }
        
        if(!productId) {
            addressList[index].acrRec.Selected_Quantity__c = '0';
            addressList[index].acrRec.Quantity__c = '';
            component.set("v.ShippingAddressList",addressList);
        }
        //component.set("v.addressList",addressList);
    },
    handleUploadFinished:function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var documentId = uploadedFiles[0].documentId;
        component.set("v.documentId",documentId);
        var fileName = uploadedFiles[0].name;
        component.set("v.Attachments",fileName);
        helper.getuploadedFiles(component); 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "success",
            "title": "Success!",
            "message": "The file has been uploaded successfully.",
            "mode":'dismissible'
        });
        toastEvent.fire();
        
    }, 
    previewFile :function(component,event,helper){  
        var rec_id = event.currentTarget.id;  
        $A.get('e.lightning:openFiles').fire({ 
            recordIds: [rec_id]
        });  
    },
    onchangeCountry:function(component,event,helper){
        //alert('onchange');
        var index = 0;
        var isLegal = true;
        helper.onchangeCountry(component,event,helper,isLegal,index);
    },
    getAddressfromAccount:function(component,event,helper){
        console.log('inside address toggle');
        var target = event.getSource();
        console.log('checked - '+target.get("v.checked"));
        var customerAccount = component.get("v.customerAccount");
        console.log('customerAccount--'+JSON.stringify(customerAccount));
        var currShippingAddressList = component.get("v.ShippingAddressList");       
        if(customerAccount!=undefined && customerAccount!=null && target.get("v.checked") == true)
        {
            currShippingAddressList[0].acrRec.Shipping_Address__c = customerAccount.BillingStreet;
            currShippingAddressList[0].acrRec.City__c = customerAccount.BillingCity;
            currShippingAddressList[0].acrRec.Country__c = customerAccount.BillingCountry;   
            if(customerAccount.BillingCountry!= null && customerAccount.BillingCountry!= undefined) 
            {
                var mapCountryStates = (component.get("v.mapData"));
                var statesForCountry1 = mapCountryStates[customerAccount.BillingCountry];
                var statesForCountry = statesForCountry1.toString();
                var stateValues = [];
                if(statesForCountry != '' && statesForCountry != undefined && statesForCountry != null){
                    for(var i=0;i<statesForCountry.split(',').length;i++){
                        stateValues.push(statesForCountry.split(',')[i]); 
                    }
                }
                currShippingAddressList[0].shippingStateList = stateValues; 
            }

            currShippingAddressList[0].acrRec.Zip_Code__c = customerAccount.BillingPostalCode; 
            component.set("v.ShippingAddressList", currShippingAddressList); 
        }
        
    },
    
    copyAddressRow : function(component, event, helper) {
        helper.copyAccountChecklistAddress(component, event, helper);
    },
    paymentMethodChange : function(component, event, helper){
        var paymentMethod = event.getSource().get("v.value");
        var objAcctCheckList=component.get('v.objAccountCheckList');
         if (paymentMethod == 'Invoice Billing') {
            objAcctCheckList.Invoice_Credit_Card__c=true;
        }
        else{
            objAcctCheckList.Invoice_Credit_Card__c=false;
        }
        console.log("objAcctCheckList-->"+JSON.stringify(objAcctCheckList));
        //component.set('v.objAccountCheckList',objAcctCheckList);
    }
})
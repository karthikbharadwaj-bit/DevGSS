({
    
    saveQuote : function(component, event, helper, doSubmitQuote){
        var url = new URL(location.href);
        var saveQuoteAction = component.get("c.updateQuote");
        var quote = component.get("v.Quote");
        if(doSubmitQuote){
            var discount = component.get("v.discount");
            var discountType = component.get("v.discountType");
            if(discount > 100 && discountType == '%'){
                component.set("v.Spinner",false);
                helper.showToast('Error !', 'Discount can not be more than 100%.', 'error'); 
                return;
            }
            else if(discount <= 0 && discountType == '%'){
                component.set("v.Spinner",false);
                helper.showToast('Error !', 'Discount must be greater than 0%.', 'error'); 
                return;
            }
            else if(discount <= 0 && discountType == 'Amt'){
                component.set("v.Spinner",false);
                helper.showToast('Error !', 'Discount must be greater than 0.', 'error'); 
                return;
            }
            if(component.get("v.discountDetails") == null || component.get("v.discountDetails") == ''){
                component.set("v.Spinner",false);
                helper.showToast('Error !', 'Please enter Non Standard Request Justification.', 'error'); 
                return;
            }
        }
        
        if(component.get("v.showPartnerDiscount")) {
            if(!this.validatePromoCode(component, event, helper)) {
                component.set("v.Spinner", false);
                return;
            }
        }
        
        
        var expirationDate = Date.parse(quote.Expiration_Date__c);
        var startDate = Date.parse(quote.Start_Date__c);
        var dateAfter30Days = new Date();
		dateAfter30Days.setDate(dateAfter30Days.getDate() + 30);
        if(!expirationDate){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Please enter Quote Expiration Date.', 'error'); 
            return
        }
        if(!startDate && quote.Contract__c){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Please enter Expected Service Start Date.', 'error'); 
            return
        }
        if(expirationDate < new Date()){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Quote Expiration date must be a future date.', 'error');    
        }
        else if(expirationDate > dateAfter30Days){
            component.set("v.Spinner",false);
        	helper.showToast('Error !', 'Quote Expiration date can not be more than 30 days.', 'error');  
        } 
        else{
            saveQuoteAction.setParams({  
                objQuote : quote,
                doSubmit : doSubmitQuote,
                discount : component.get("v.discount"),
                discountDetails : component.get("v.discountDetails"),
                promotion : component.get("v.promotion"),
                campaign : component.get("v.campaign"),
                promoCode : component.get("v.promoCode"),
                discountType : component.get("v.discountType")
            });
            saveQuoteAction.setCallback(this, function(response){
                console.log('response.getState()=', response.getState());
                if(response.getState() == "SUCCESS"){
                    component.set("v.Spinner",false);
                    var result = response.getReturnValue();
                    console.log('result', result);
                    
                    if(result == 'Success'){
                        if(doSubmitQuote){
                            component.set("v.showPartnerDiscount", false);
                            helper.showToast('Success !', 'Quote submitted successfully.', 'Success'); 
                            $A.get('e.force:refreshView').fire();
                        }	 
                        else{
                            helper.loadQuote(component, event, helper);
                            helper.showToast('Success !', 'Quote saved successfully.', 'Success');    
                        }
                    }
                    else
                        helper.showToast('Error !', result, 'error');
                }
                else{
                    component.set("v.Spinner",false);
                    helper.showToast('Error !', 'There is some error in saving the Quote.', 'error');
                }
            });
            $A.enqueueAction(saveQuoteAction);
        }
    },
    
    clonePartnerQuote : function(component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        console.log('id==' + id);
        if(id){
            var getQuoteAction = component.get("c.cloneQuote");
            getQuoteAction.setParams({  quoteId : id  });
            getQuoteAction.setCallback(this, function(response){
                console.log('response.getState()=', response.getState());
                if(response.getState() == "SUCCESS"){
                    var varQuoteId = response.getReturnValue();
                    helper.showToast('Success', 'Quote cloned successfully !', 'Success');
                    helper.redirectTo('/quotetool?id='+ varQuoteId + '&step=5');
                }
                else{
                    helper.showToast('Error', 'There is some error in cloing Quote.', 'error');
                }
            });
            $A.enqueueAction(getQuoteAction);	
        }
	},
    
    addFav : function(component, event, helper) {
       console.log('add fav helper'); 
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        console.log('add fav id==' + id);
        if(id){
            var getQuoteAction = component.get("c.addQuoteASFav");
            getQuoteAction.setParams({  "quoteId" : id,
                                        "quoteName" : component.get("v.cloneQuoteName")
                                     });
            getQuoteAction.setCallback(this, function(response){
                console.log('response.getState()=', response.getState());
                if(response.getState() == "SUCCESS"){
                    helper.showToast('Success', 'Quote added to favorites successfully !', 'Success');
                    component.set("v.isModalOpen", false);
                }
                else{
                    helper.showToast('Error', 'There is some error in cloing Quote.', 'error');
                    component.set("v.isModalOpen", false);
                }
            });
            $A.enqueueAction(getQuoteAction);	
        }
	},
   	
    //<T1>***************
    engageLegal : function(component, event, helper){    	   	
		$A.createComponent("c:Partner_QuoteEngageLegal",{},
        function(createPartnerComponent, status, errorMessage){
                if (status === "SUCCESS") {                	
                    var pcDiv = component.find('partnerContractDiv').get('v.body');
                    pcDiv.push(createPartnerComponent);
                    component.find('partnerContractDiv').set('v.body', pcDiv);                    
                }
            }
        );       
    },
    //</T1>***************  
    convertQuote : function(component, event, helper){
        var action = component.get("c.createQuote");
                action.setParams({  partnerQuoteRec : component.get("v.Quote") });
                action.setCallback(this, function(response){
                    console.log('response.getState()=', response.getState());
                    if(response.getState() == "SUCCESS"){
                       helper.showToast('Success', 'Quote Converted Successfully', 'success');
                       component.set("v.Spinner",false);
                    }
                    else{
                        component.set("v.isConverting",false);
                        helper.showToast('Error', 'There is some error in convertin the Quote.', 'error');
                    }
                });
                $A.enqueueAction(action);
    },
    
    checkAccountList : function(component, event, helper) {
        var action = component.get("c.CheckAccountListExist");
        action.setParams({  accountId : component.get("v.Quote").Opportunity__r.AccountId });
        action.setCallback(this, function(response){
            console.log('response.getState()=', response.getState());
            if(response.getState() == "SUCCESS"){
                component.set("v.showChecklistCMP",true);
                if(response.getReturnValue() != null) {
                   	var objCheckList = response.getReturnValue();
                   // alert(objCheckList.listOfACR.length);
                	component.set("v.objAccountCheckList", objCheckList.objACR);
                    if(objCheckList.listOfACR != null){
                		component.set("v.addressList", objCheckList.listOfACR);
                        component.set("v.ShippingAddressList",objCheckList.listOfACRWrapp);
                        console.log('ShippingAddressListtest>>',objCheckList.listOfACRWrapp);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    checkIfUserIsAvayaAdmin : function(component, event, helper) {
        //alert('I am here');
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
    	var action = component.get("c.checkSuperUser");
        //alert(component.get("v.Quote").Id);
         action.setParams({quoteId : id });
         action.setCallback(this, function(response){
            console.log('response.getState()=', response.getState());
            if(response.getState() == "SUCCESS"){
                //alert(response.getReturnValue());
                component.set("v.isSuperUser",response.getReturnValue().isSuperUser);
                component.set("v.isPartnerContractExist",response.getReturnValue().isPartnerContractExist);
                component.set("v.isOpenContractRequest",response.getReturnValue().isOpenContractRequest);
                component.set("v.isPOCRequestExists",response.getReturnValue().isPOCRequestExists);
                component.set("v.isDiscountRequestExists",response.getReturnValue().isDiscountRequestExists);
                var objDealSupport = response.getReturnValue().objDealSupport;
                //alert(objDealSupport);
                if(objDealSupport) {
                    console.log('objDealSupport>>',objDealSupport);
                    component.set("v.discountDetails",objDealSupport.Discount_Details__c);
                    component.set("v.promotion",objDealSupport.Promotion__c);
                    component.set("v.campaign",objDealSupport.Campaign__c);
                    component.set("v.promoCode",objDealSupport.Promo_Code__c);
                    if (objDealSupport.Discount__c > 0) {
                        component.set("v.discount",objDealSupport.Discount__c);
                        component.set("v.discountType","%");
                    }else if(objDealSupport.Discount_Amount__c > 0){
                        component.set("v.discount",objDealSupport.Discount_Amount__c);
                        component.set("v.discountType","Amt");
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
     addAccountChecklistAddress: function(component) {       
        var addressList = component.get("v.addressList");        
        addressList.push({
            'sobjectType': 'Account_Checklist_Address__c',
            'Shipping_Address__c': null,
            'State__c': null            
        });
        component.set("v.addressList", addressList);
    },
    
    addExistingAccountChecklistAddress: function(component, existAddressList) {
        alert(existAddressList);
       	var addressList = component.get("v.addressList");
        for(var objaddress of existAddressList) {       
            addressList.push({
                'sobjectType': 'Account_Checklist_Address__c',
                'Shipping_Address__c': null,
                'State__c': null            
            });
        }
        component.set("v.addressList", addressList);
    },
    
    checkOpenINCommunity: function(component, event, helper) {
        var action = component.get("c.isCommunity");
        action.setCallback(this, function(response) {
            var isCommunity = response.getReturnValue(); // do any operation needed here
            //alert(isCommunity);
            component.set("v.IsOpenInCommunity",isCommunity);
        });
        $A.enqueueAction(action);
    },
    
    validServiceLineOnQuote: function(component, event, helper) {
        const url = new URL(location.href);
        const id = url.searchParams.get('id');
        const action = component.get("c.isValidServiceLineOnQuote");
        action.setParams({quoteId : id });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                if (!response.getReturnValue()) {
                    component.set("v.invalidQuote", "Phone quantities can not be more than Service quantities. Please adjust the quantities to submit the order.");
                } else {
                    component.set("v.invalidQuote", '');
                }
                
            }
        });
        $A.enqueueAction(action);
    },
    
    validatePromoCode: function (component, event, helper) {
        console.log('mapOfPromoToListAssociatedDetail>>',component.get("v.mapOfPromoToListAssociatedDetail"));
        var mapOfPromoToListAssociatedDetail = component.get("v.mapOfPromoToListAssociatedDetail");
        var mapOfPackageToPromoDetail = component.get("v.mapOfPackageToPromoDetail");
        let quoteLineRecord;
        var availableRequiredProductCount = 0;
        var availableOptionalProductCount = 0;
        //let promoDetailRec;
        const quote = component.get("v.Quote"),
            quoteLines = quote.Partner_Quote_Products__r,
            inputPromoCode = component.get("v.promoCode");
        if (!$A.util.isEmpty(inputPromoCode)) {
            if(mapOfPromoToListAssociatedDetail) {
                for(var key in  mapOfPromoToListAssociatedDetail) {
                    console.log('mapOfPackageToPromoDetail[key].value>>',mapOfPromoToListAssociatedDetail[key].value);
                    if(mapOfPromoToListAssociatedDetail[key].key == inputPromoCode) {
                    	var totalRequireProductCount = 0;//mapOfPromoToListAssociatedDetail[key].value.length;
                        var totalOptionalProductCount = 0;
                        for(var promoDetailRec of mapOfPromoToListAssociatedDetail[key].value) {
                            console.log('promoDetailRec>>',promoDetailRec);
                            if(promoDetailRec.isRequired__c == 'Required')
                            totalRequireProductCount++;
                            else
                            	totalOptionalProductCount++;
                            
                            var promoCodeProductId = promoDetailRec.Product_Catalogue__r.Product__c.substring(0, 15);
                            //promoDetailRec = mapOfPackageToPromoDetail[key].value;
                        	if (parseInt(quote.Initial_Term__c) < parseInt(promoDetailRec.Term__c)) {
                    			console.log('term not match');
                    			helper.showToast('Error', 'Applying promo code is not valid for selected term.', 'error');
                    			return false;
                			}
                            if (!$A.util.isEmpty(quoteLines)) {
                                var tempquoteLineRecord = quoteLines.filter(function (quoteLine){
                                    console.log('quoteLine.Product__c.substring(0, 15)>>',quoteLine.Product__c.substring(0, 15)+'--'+promoCodeProductId);
                                    console.log(inputPromoCode);
                                    console.log(promoDetailRec.Name);
                                    console.log('inputPromoCode === promoDetailRec.Name',inputPromoCode == promoDetailRec.Name);
                                    console.log('inputPromoCode === promoDetailRec.Name',inputPromoCode === promoDetailRec.Name+inputPromoCode+'-'+promoDetailRec.Name);
                                    return quoteLine.Product__c.substring(0, 15) === promoCodeProductId && inputPromoCode == promoDetailRec.Name;
                                });
                            	console.log('tempquoteLineRecord>>',tempquoteLineRecord);
                                console.log('promoDetailRec>>',promoDetailRec);
                                if(!$A.util.isEmpty(tempquoteLineRecord) && promoDetailRec.isRequired__c == 'Required') {
                                    availableRequiredProductCount++;
                                    quoteLineRecord = tempquoteLineRecord;
                                    console.log('tempquoteLineRecord>>',tempquoteLineRecord);
                                } 
                                if(!$A.util.isEmpty(tempquoteLineRecord) && promoDetailRec.isRequired__c == 'Optional'){
                                    availableOptionalProductCount++;
                                }
                            
                            }
                        }
                    }
                }
                console.log('availableRequiredProductCount>>',availableRequiredProductCount);
                console.log('totalRequireProductCount>>',totalRequireProductCount);
                console.log('totalOptionalProductCount>>',totalOptionalProductCount);
                console.log('availableOptionalProductCount>>',availableOptionalProductCount);
                //|| (totalOptionalProductCount > 0 && availableOptionalProductCount == 0)
                if (availableRequiredProductCount != totalRequireProductCount) {
                    helper.showToast('Error', 'Applying promo code is not valid for selected product.', 'error');
                    return false;
                }
            }
        }
        
        /*if (!$A.util.isEmpty(inputPromoCode)) {
            
            if (inputPromoCode !== promoCode) {
                helper.showToast('Error', 'Applying promo code is not valid.', 'error');
                return false;
            }
            
            if (!$A.util.isEmpty(quoteLines)) {
                let quoteLineRecord = quoteLines.filter(function (quoteLine){
                    return quoteLine.Product__c.substring(0, 15) === productCode;
                });
                
                if ($A.util.isEmpty(quoteLineRecord)) {
                    helper.showToast('Error', 'Applying promo code is not valid for selected product.', 'error');
                    return false;
                }
                if (parseInt(quote.Initial_Term__c) < parseInt(term)) {
                    helper.showToast('Error', 'Applying promo code is not valid for selected term.', 'error');
                    return false;
                }
                
                //if (quoteLineRecord[0].Quantity__c > quantity) {
                  //  helper.showToast('Error', 'Applying promo code is not valid for applied quantity.', 'error');
                   // return false;
                //}
            }
        }*/
        
        return true;
    },
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
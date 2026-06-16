({
    showToast: function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                duration: ' 5000',
                key: 'info_alt',
                type: type,
                mode: 'dismissible'
            });
            toastEvent.fire();
        }
        else {
            alert(message);
        }
    },

    redirectTo: function (url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },
    //Added for GO Pricing - start
    getopportunitycurrency : function(component,event,helper){

        var url = new URL(location.href);
        var id;
        if(url.searchParams.get('id')){
            id = url.searchParams.get('id');
        }else{
            id = url.searchParams.get('oppId');
        }
        console.log('::::::Id:::::'+id);
        if(id){
            var action = component.get("c.getOpportunityCurrency");
            action.setParams({
                OppIdOrQuoteId : id
            });
            action.setCallback(this,function(response){

                console.log(':::response::'+response.getState());
                if(response.getState() == "SUCCESS"){
                    component.set("v.Currencycode",response.getReturnValue());
                    console.log(':::::::::::'+response.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        }
    },
    //Added for GO Pricing - end
    createUpdateQuote: function (component, event, helper, redirectTo, goToStep, oppId, doReload,
                                 doUpdateLines, isPackageChanged, isPricingChanged, doNotSendProducts) {
        try {
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            component.set("v.Spinner", true);
            var productList = component.get("v.SelectedProductList");
            var productListJSON;
            var listOfTiers = [];
            if (productList) {
                productList.forEach(function (eachProduct) {
                    if (eachProduct.objCatalogue) {
                        listOfTiers.push(eachProduct.objCatalogue.Product_Tier_Prices__r);
                        eachProduct.objCatalogue.Product_Tier_Prices__r = null;
                    }
                });
                if (!doNotSendProducts)
                    productListJSON = JSON.stringify(productList);

                for (var i = 0; i < productList.length; i++) {
                    if (productList[i].objCatalogue) {
                        productList[i].objCatalogue.Product_Tier_Prices__r = listOfTiers[i];
                    }
                }
            }
            console.log('v.SelectedProductList===', productList);
            var createPQAction = component.get("c.createUpdatePartnerQuote");
            var paymentTermJS;
            paymentTermJS = component.get("v.PricingYearly") == true ? 'Yearly' : 'Monthly';
            console.log('paymentTermJS=', paymentTermJS);
            var editionIdJS;
            var objQuote = component.get("v.Quote");
            //added method to calculate total for partner quote
            if (productList && productList.length > 0)
                helper.doTotal(component, event, helper, objQuote);

            if (component.get("v.ProductEdition")) {
                //Added for wholesale
                var parentOrSubPackage = component.get('v.ParentOrSubPackage');
                editionIdJS = component.get("v.ProductEdition").Id;
                if(parentOrSubPackage == 'Sub Package'){
                    editionIdJS = component.get("v.parentPackageId");
                    objQuote.Sub_Package__c = component.get("v.ProductEdition").Id;
                }
                objQuote.Product_Edition__c = editionIdJS;
            }
            else
                editionIdJS = objQuote.Product_Edition__c;
            if (paymentTermJS && !objQuote.Id)
                objQuote.Payment_Term__c = paymentTermJS;
            //alert(objQuote.Opportunity__r.Brand_Name__c);
            if (objQuote.Payment_Term__c == 'Monthly' && objQuote.Id && objQuote.Opportunity__r.Brand_Name__c
                && objQuote.Opportunity__r.Brand_Name__c != 'RingCentral' &&
                objQuote.Opportunity__r.Brand_Name__c != 'RingCentral Canada' &&
                objQuote.Opportunity__r.Brand_Name__c != 'RingCentral UK' &&
                objQuote.Opportunity__r.Brand_Name__c != 'RingCentral EU' &&
                objQuote.Opportunity__r.Brand_Name__c != 'RingCentral AU' &&
                objQuote.Opportunity__r.Brand_Name__c != 'Unify Office') {
                objQuote.Contract__c = true;
            }
            createPQAction.setParams({
                objPartnerQuote: objQuote,
                quoteLines: productListJSON,
                opportunityId: oppId,
                doUpdateLines: doUpdateLines,
                isPackageChanged: isPackageChanged,
                isPricingChanged: isPricingChanged
            });
            createPQAction.setCallback(this, function (response) {
                console.log('Quote created=', response.getState());
                if (response.getState() == "SUCCESS") {
                    var objQuote = response.getReturnValue();
                    console.log('Quote: ', objQuote);
                    if (redirectTo) {
                        helper.redirectTo(redirectTo + '?id=' + objQuote.Id);
                    }
                    else {
                        component.set("v.Quote", objQuote);
                        if (goToStep)
                            component.set("v.Step", goToStep);
                    }
                    if (doReload)
                        helper.setReloadFlag(component, event, helper);
                    helper.loadQuoteLines(component, event, helper);
                }
                else {
                    helper.showToast('Error', 'There is some error in creating/updating quote. Please contact your system admin.', 'error');
                }
                if (!doReload)
                    component.set("v.Spinner", false);
                helper.addErrorToConsoleIfAny(response);
            });
            $A.enqueueAction(createPQAction);
        }
        catch (e) {
            console.log('Error = ', e);
            component.set("v.Spinner", true);
        }
        //component.set("v.Spinner", false);
    },

    addErrorToConsoleIfAny: function (response) {
        if (response.getState() == "ERROR") {
            var errors = response.getError();
            var message = 'Unknown error'; // Default error message
            if (errors && Array.isArray(errors) && errors.length > 0) {
                message = errors[0].message;
            }
            console.error(message);
        }
    },

    loadQuote: function (component, event, helper) {
        try {
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            console.log('Base loadQuote id==' + id);
            if (!id) {
                id = url.href.split('/')[6];
            }
            if (id) {
                var getQuoteAction = component.get("c.getQuote");
                getQuoteAction.setParams({
                    quoteId: id
                });
                getQuoteAction.setCallback(this, function (response) {
                    console.log('response.getState()=', response.getState());
                    if (response.getState() == "SUCCESS") {
                        //component.set("v.Spinner", false);
                        var objQuote = response.getReturnValue();
                        component.set("v.Quote", objQuote);
                        component.set("v.Spinner", false);
                        var yearlyPricing = false;
                        if (objQuote.Payment_Term__c == 'Yearly')
                            yearlyPricing = true;
                        component.set("v.PricingYearly", yearlyPricing);

                        if(objQuote != undefined &&
                            objQuote.Opportunity__r != undefined &&
                            objQuote.Opportunity__r.Partner_Account__r != undefined) {
                                // added above check for bzs-10386
                        if(objQuote.Opportunity__r.Partner_Account__r.Partner_Type__c!=null || objQuote.Opportunity__r.Partner_Account__r.Partner_Type__c !='' || objQuote.Opportunity__r.Partner_Account__r.Partner_Type__c != undefined){
                            component.set("v.accPartnerTypeval", objQuote.Opportunity__r.Partner_Account__r.Partner_Type__c);
                        }
                            }
                        if(component.get("v.accPartnerTypeval") != undefined && component.get("v.accPartnerTypeval") !=null && component.get("v.accPartnerTypeval") != ''){
                            if(component.get("v.accPartnerTypeval").includes("Bill-on-Behalf")){
                                component.set("v.isAccountPartnerTypeBOB",true);
                            }
                        }
                        if(objQuote.Opportunity__r.Brand_Name__c){
                            var brand = component.set("v.quoteBrandName",objQuote.Opportunity__r.Brand_Name__c);
                            helper.checkisAvaya(component,event,helper,brand);
                        }
                        //Quote Details Component
                        if (component.get("v.cName") && component.get("v.cName") == 'Partner_QuoteDetails') {
                            if (objQuote.Status__c != 'Draft' && objQuote.Status__c != 'Approved'
                                && objQuote.Status__c != 'L1 Discount Approved' && objQuote.Status__c != 'L2 Discount Approved')
                                component.set("v.isQuoteLocked", true);
                        }
                        else {
                            if (objQuote.Payment_Term__c == 'Yearly')
                                component.set("v.PricingYearly", true);
                            if (objQuote.Subscription__c && component.get("v.AutoTabChange") && component.get("v.Step")) {
                                component.set("v.Step", "4");
                            }
                        }
                        if (objQuote.Quote_Locked__c) {
                            component.set("v.Step", "5");
                        }
                        if (objQuote.Product_Edition__r.Skip_Pick_Your_Number__c && component.get("v.Step") == "2") {
                            component.set("v.Step", "3");
                            component.set("v.selectedCategory", "Service");
                        }


                    }
                    else {
                        helper.showToast('Error', 'There is some error in loading Quote.', 'error');
                    }
                });
                $A.enqueueAction(getQuoteAction);
            }
        }
        catch (e) {
            console.log('Error = ', e);
        }
    },

    loadDiscountFlag: function (component, event, helper) {
        //Getting Current user Discount field access
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        if (id) {
            var getDiscountInfoAction = component.get("c.loadHideDiscountFlag");
            getDiscountInfoAction.setParams({
                quoteId: id
            });
            getDiscountInfoAction.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    var discountAccess = response.getReturnValue();
                    //alert('discountAccess'+discountAccess);
                    component.set("v.hideDiscount", discountAccess);
                }
            });
            $A.enqueueAction(getDiscountInfoAction);
        }

    },


    loadCurrentUser: function (component, event, helper) {
        try {
            var getQuoteAction = component.get("c.getCurrentUser");
            getQuoteAction.setCallback(this, function (response) {
                console.log('response.getState()=', response.getState());
                if (response.getState() == "SUCCESS") {
                    var objUser = response.getReturnValue();
                    component.set("v.currentUser", objUser);
                }
                else {
                    helper.showToast('Error', 'There is some error in loading current user details.', 'error');
                }
            });
            $A.enqueueAction(getQuoteAction);
        }
        catch (e) {
            console.log('Error = ', e);
        }
    },

    deleteQuoteProductUsingProductId: function (component, event, helper, productId) {
        try {
            var url = new URL(location.href);
            var quoteId = url.searchParams.get('id');
            var deleteQuoteLinesAction = component.get("c.deleteQuoteLineFromProductId");
            //Checking if record exists in database
            deleteQuoteLinesAction.setParams({
                quoteId: quoteId,
                productId: productId
            });
            console.log('productId =', productId);
            console.log('quoteId =', quoteId);
            component.set("v.Spinner", true);
            deleteQuoteLinesAction.setCallback(this, function (response) {
                console.log('response.getState()=', response.getState());
                if (response.getState() == "SUCCESS") {
                    helper.setReloadFlag(component, event, helper);
                    helper.loadQuoteLines(component, event, helper);
                    /*
                    var selectedProducts = component.get("v.SelectedProductList");
                    console.log('selectedProducts=', selectedProducts);
                    var selectedProductsFresh = [];
                    selectedProducts.forEach(function(eachProduct){
                        if(eachProduct.objProduct.Id != productId){
                            selectedProductsFresh.push(eachProduct);
                        }
                    });
                    component.set("v.SelectedProductList", selectedProductsFresh);
                    */
                    component.set("v.Spinner", false);
                }
                else {
                    helper.showToast('Error', 'There is some error in removing Quote Line Items. Please contact your Admin.', 'error');
                    component.set("v.Spinner", false);
                }
            });
            $A.enqueueAction(deleteQuoteLinesAction);
        }
        catch (e) {
            console.log('Error = ', e);
            component.set("v.Spinner", false);
        }
    },

    updatePrice: function (component, event, helper, listOfProducts, updateSelectedProducts) {
        try {
            var isSpeciaPermissionAvail = component.get("v.isSpeciaPermissionAvail");
            var isPromoCodeAppliedApproved = component.get("v.isPromoCodeAppliedApproved");
            var mapOfPackageToPromoDetail = component.get("v.mapOfPackageToPromoDetail");
            var productList;
            if (listOfProducts)
                productList = listOfProducts;
            else
                productList = component.get("v.ProductList");
            var objQuote = component.get("v.Quote");
            var quantity = objQuote.Number_of_Licenses__c;
            var paymentTerm = objQuote.Payment_Term__c;
            var isContract = objQuote.Contract__c;

            console.log('quantity=', quantity);
            console.log('paymentTerm=', paymentTerm);
            console.log('productList=', productList);
			var domesticAndUnlimitedLicense = 0;
            var quantityError=false;
            var objCurrentUser = component.get("v.currentUser");
			for (var eachitem of productList){
                if (eachitem.objCatalogue){
                    if(eachitem.objCatalogue.Display_Name__c.includes('DigitalLine Unlimited')){
                        domesticAndUnlimitedLicense=domesticAndUnlimitedLicense+Number(eachitem.quantity);//PBC-12338
                    }
                    if(eachitem.objCatalogue.Display_Name__c.includes('MS Teams CloudPBX - Domestic')){
                        domesticAndUnlimitedLicense=domesticAndUnlimitedLicense+Number(eachitem.quantity);//PBC-12338
                    }
                    //PBC-12338: Adding null and undefined check for DigitalLine BYOC
					if (eachitem.objCatalogue.Display_Name__c.includes('DigitalLine BYOC') && eachitem.quantity != null && eachitem.quantity != undefined) {
						domesticAndUnlimitedLicense = domesticAndUnlimitedLicense + Number(eachitem.quantity);//PBC-12338
					}
                }
            }
			console.log('domesticAndUnlimitedLicense '+domesticAndUnlimitedLicense);
            // AS Start
            var lboxCriteriaMap = [];
            for (var eachProduct of productList) {
                if (eachProduct.objCatalogue && eachProduct.objCatalogue.LBOX_Rule_Lookup__c && eachProduct.objCatalogue.LBOX_Rule_Lookup__r && eachProduct.objCatalogue.LBOX_Rule_Lookup__r.Rule_Type__c == 'LB') {
                    var tempQuantity = lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c];
                    if (tempQuantity > 0) {
                        lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c] = parseInt(lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c]) + parseInt(eachProduct.quantity);
                    }
                    else {
                        lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c] = eachProduct.quantity;
                    }
                }
            }

            var mapOfIdVsCatalogue = new Map();
            var consolidatedProductList = component.get("v.SelectedProductList");
            consolidatedProductList = consolidatedProductList.concat(productList);
            for (var eachProduct of consolidatedProductList) {
                if (eachProduct.objCatalogue)
                    mapOfIdVsCatalogue.set(eachProduct.objCatalogue.Id, parseInt(eachProduct.quantity));
            }
            console.log('mapOfIdVsCatalogue ===', mapOfIdVsCatalogue);
            //End AS
            for(var eachProduct of productList){
                var promoError = null;
                var promoErrorQtyDiscount = 0;

                if(!eachProduct.objProduct)
                    continue;
                if (eachProduct.partnerDiscount) {
                    if (eachProduct.partnerDiscount < 0) {
                        helper.showToast('Error', 'Discount can not be a negative number.', 'error');
                        eachProduct.partnerDiscount = 0;
                    }
                    else if(eachProduct.partnerDiscount > 100 && eachProduct.discountType == '%'){
                        helper.showToast('Error', 'Discount can not be greater than 100%.', 'error');
                        eachProduct.partnerDiscount = 0;
                    }
                }
                if (objCurrentUser && objCurrentUser.Partner_Discount_Approval__c === 'L1 Approval') {
                    console.log('eachProduct>ecah>', objCurrentUser.Partner_Discount_Approval__c);
                    var discountLimit;
                    var isPromoValid = false;
                    //BZS-4987
                    if (objQuote.Opportunity__r.Brand_Name__c === 'Avaya Cloud Office') {
                        discountLimit = 30;
                    }
                    else {
                        discountLimit = 15;
                    }
                    if (objQuote.Opportunity__r.Brand_Name__c !== 'Avaya Cloud Office' && eachProduct.objCatalogue && eachProduct.objCatalogue.Discount_Limit__c)
                        discountLimit = eachProduct.objCatalogue.Discount_Limit__c;
                    var promoCodeProduct = $A.get("$Label.c.Quote_PromoCodeDetail").split(';');
                    var promoCodeProductId = promoCodeProduct[1].substring(0, 15);
                    var quantity = promoCodeProduct[3];
                    var productId;
                    if (eachProduct.objProduct != null)
                        productId = eachProduct.objProduct.Id.substring(0, 15);
                    console.log('mapOfPackageToPromoDetail>>', mapOfPackageToPromoDetail);
                    if (mapOfPackageToPromoDetail) {
                        for (var key in mapOfPackageToPromoDetail) {
                            //console.log('key>>',key);
                            //console.log('mapOfPackageToPromoDetailKey>>',mapOfPackageToPromoDetail[key].key);
                            var promoCodeProductId = mapOfPackageToPromoDetail[key].value.Product_Catalogue__r.Product__c.substring(0, 15);
                            var promoDetailRec = mapOfPackageToPromoDetail[key].value;

                            if (isPromoCodeAppliedApproved && promoCodeProductId != null && eachProduct.objProduct != null && productId == promoCodeProductId &&  eachProduct.partnerDiscount > discountLimit && !promoDetailRec.Specail_Permission__c) {
                                if(eachProduct.quantity > promoDetailRec.Quantity__c){
                                    promoError = 'Qty';
                                    promoErrorQtyDiscount = promoDetailRec.Quantity__c;
                                }else if(eachProduct.partnerDiscount > promoDetailRec.Discount__c && eachProduct.discountType == '%'){
                                    promoError = 'DiscountPercentage';
                                    promoErrorQtyDiscount = promoDetailRec.Discount__c;
                                }else if(eachProduct.partnerDiscount > promoDetailRec.Discount_Amount__c && eachProduct.discountType == 'Amt'){
                                    promoError = 'DiscountCurrency';
                                    promoErrorQtyDiscount = promoDetailRec.Discount_Amount__c;
                                }else{
                                    console.log('condition matched');
                                    console.log('productId == promoCodeProductId', productId + '--' + promoCodeProductId);
                                    isPromoValid = true;
                                    break;
                                }
                            } else if (isPromoCodeAppliedApproved && promoCodeProductId != null && eachProduct.objProduct != null && productId == promoCodeProductId && eachProduct.partnerDiscount > discountLimit && promoDetailRec.Specail_Permission__c && isSpeciaPermissionAvail) {
                                if(eachProduct.quantity > promoDetailRec.Quantity__c){
                                    promoError = 'Qty';
                                    promoErrorQtyDiscount = promoDetailRec.Quantity__c;
                                }else if(eachProduct.partnerDiscount > promoDetailRec.Discount__c && eachProduct.discountType == '%'){
                                    promoError = 'DiscountPercentage';
                                    promoErrorQtyDiscount = promoDetailRec.Discount__c;
                                }else if(eachProduct.partnerDiscount > promoDetailRec.Discount_Amount__c && eachProduct.discountType == 'Amt'){
                                    promoError = 'DiscountCurrency';
                                    promoErrorQtyDiscount = promoDetailRec.Discount_Amount__c;
                                }else{
                                    console.log('condition matched else if');
                                    isPromoValid = true;
                                    break;
                                }
                            }
                        }
                    }
                    console.log('isPromoValid>>>', isPromoValid);
                    console.log('eachProduct>>>', eachProduct);
                    /*if(isPromoCodeAppliedApproved && promoCodeProductId != null && eachProduct.objProduct != null && productId == promoCodeProductId && eachProduct.quantity <= quantity && eachProduct.partnerDiscount > discountLimit)*/

                    /*if(objQuote.Payment_Term__c == 'Monthly' && !objQuote.Contract__c && objQuote.Id
                       && objQuote.Opportunity__r.Brand_Name__c != null && eachProduct.partnerDiscount > 0
                       && (objQuote.Opportunity__r.Brand_Name__c == 'RingCentral' ||
                       objQuote.Opportunity__r.Brand_Name__c == 'RingCentral Canada' ||
                       objQuote.Opportunity__r.Brand_Name__c == 'RingCentral UK'  ||
                       objQuote.Opportunity__r.Brand_Name__c == 'RingCentral EU' ||
                       objQuote.Opportunity__r.Brand_Name__c == 'RingCentral AU')) {
                        helper.showToast('Error', 'You cannot give discount for montly and is not on contract', 'error');
                        eachProduct.partnerDiscount = 0;
                    }*/

                    if (isPromoValid) {
                        eachProduct.showAddButton = true;
                    }else if(promoError && promoError == 'Qty'){
                        helper.showToast('Error', 'The quantity can not be more than ' + promoErrorQtyDiscount, 'error');
                        eachProduct.showAddButton = false;
						quantityError = true;
                    }else if(promoError && promoError == 'DiscountPercentage'){
                        helper.showToast('Error', 'The discount can not be more than ' + promoErrorQtyDiscount + '%', 'error');
                        eachProduct.partnerDiscount = 0;
                    }else if(promoError && promoError == 'DiscountCurrency'){
                        helper.showToast('Error', 'The discount can not be more than ' + promoErrorQtyDiscount+ objQuote.CurrencyIsoCode, 'error');
                        eachProduct.partnerDiscount = 0;
                    }else if (eachProduct.partnerDiscount > discountLimit && eachProduct.discountType == '%') {
                        console.log('eachProduct.partnerDiscounterror>>>', eachProduct.partnerDiscount);
                        helper.showToast('Error', 'The discount can not be more than ' + discountLimit + '%', 'error');
                        eachProduct.partnerDiscount = 0;
                    }
                    console.log('each')
                }

                //console.log('eachProduct =', eachProduct);
                var tierList;
                if (eachProduct.objCatalogue && eachProduct.objCatalogue.Product_Tier_Prices__r)
                    tierList = eachProduct.objCatalogue.Product_Tier_Prices__r;
                else
                    tierList = [];
                console.log('tierList=', tierList);

                var listPriceMonthly = -1;
                var listPriceYearly = -1;
                var contractDiscount = null;
                var unitPrice = 0;
                //AS START
                if (eachProduct.objCatalogue && lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c]) {
                    var selProdPackName = eachProduct.objCatalogue.Product_Package__r.Name;
                    console.log('selProdPackName>>>>'+eachProduct.objCatalogue.Product_Package__r.Name);
                    var tempQuantity = parseInt(lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c]);
                    if(tempQuantity > eachProduct.lboxRule.Max_Range__c) {
                        helper.showToast('Error','Quantity can not be more than '+eachProduct.lboxRule.Max_Range__c,'Error');
                        if(eachProduct.objQuoteLine)
                            eachProduct.quantity = eachProduct.objQuoteLine.Quantity__c;
                        else
                            eachProduct.quantity = 0;
						quantityError = true;
                    }
                    else if (tempQuantity < eachProduct.lboxRule.Min_Range__c){
                        helper.showToast('Error','Quantity can not be less than '+eachProduct.lboxRule.Min_Range__c,'Error');
                        if(eachProduct.objQuoteLine)
                            eachProduct.quantity = eachProduct.objQuoteLine.Quantity__c;
                        else
                            eachProduct.quantity = 0;
						quantityError = true;
                    }
                    else {
                        quantity = parseInt(lboxCriteriaMap[eachProduct.objCatalogue.LBOX_Rule_Lookup__c]);
                    }
                }
                else if (eachProduct.quantity) {
                    quantity = eachProduct.quantity;
                }
                    else
                        quantity = 0;

				if (quantityError && eachProduct.quantity) quantity = eachProduct.quantity;

                if (eachProduct.objCatalogue && eachProduct.objCatalogue.Quantity_Dependent_Product_1__c) {
                    quantity = 0;
                    var dependentProductId = eachProduct.objCatalogue.Quantity_Dependent_Product_1__c;
                    var dependentProduct1Quantity = mapOfIdVsCatalogue.get(dependentProductId);
                    if (dependentProduct1Quantity)
                        quantity = parseInt(quantity) + parseInt(dependentProduct1Quantity);


                }
                if (eachProduct.objCatalogue && eachProduct.objCatalogue.Quantity_Dependent_Product_2__c) {
                    var dependentProductId = eachProduct.objCatalogue.Quantity_Dependent_Product_2__c;
                    var dependentProduct2Quantity = mapOfIdVsCatalogue.get(dependentProductId);
                    if (dependentProduct2Quantity)
                        quantity = parseInt(quantity) + parseInt(dependentProduct2Quantity);
                }
				if(!quantityError && eachProduct.objCatalogue && (eachProduct.objCatalogue.Category_Name__c == 'Service'||eachProduct.objCatalogue.Category_Name__c == 'International'||eachProduct.objCatalogue.Category_Name__c == 'Conferencing') && (eachProduct.objCatalogue.Sub_Category_Name__c == 'Service'||eachProduct.objCatalogue.Sub_Category_Name__c == 'MS Teams'||eachProduct.objCatalogue.Sub_Category_Name__c == 'Global Office'||eachProduct.objCatalogue.Sub_Category_Name__c == 'Global MVP'||eachProduct.objCatalogue.Sub_Category_Name__c == 'Mobile') && eachProduct.objCatalogue.Package_Product_Type__c.indexOf('Header') === -1 && eachProduct.objCatalogue.Package_Product_Type__c.indexOf('Service Fee') === -1){
                    //quantity = objQuote.Number_of_Licenses__c;
                         quantity=domesticAndUnlimitedLicense;
                }
                console.log('eachProduct ===', eachProduct);
                console.log('quantity ===', quantity);

                var netPriceBeforeUpdate = eachProduct.netPrice;
                // AS END
                if (tierList && tierList.length > 0) {
                    for (var eachTier of tierList) {
                        if (eachTier.CurrencyIsoCode == objQuote.CurrencyIsoCode && quantity <= eachTier.No_of_Licenses__c) {
                            listPriceMonthly = eachTier.Monthly_Price__c;
                            listPriceYearly = eachTier.Yearly_Price__c;
                            contractDiscount = eachTier.Contract_Discount__c;
                            console.log('eachTier.Contract_Discount__c>>', eachTier.Contract_Discount__c);
                            break;
                        }
                    }
                    if (listPriceMonthly == -1)
                        listPriceMonthly = tierList[tierList.length - 1].Monthly_Price__c;
                    if (listPriceYearly == -1)
                        listPriceYearly = tierList[tierList.length - 1].Yearly_Price__c;

                }
                if (listPriceMonthly == -1)
                    listPriceMonthly = 0;
                if (listPriceYearly == -1)
                    listPriceYearly = 0;
                console.log('listPriceMonthly=', listPriceMonthly);
                console.log('listPriceYearly=', listPriceYearly);
                console.log('contractDiscount=', contractDiscount);
                if(objQuote.Payment_Term__c == 'Monthly'){
                    eachProduct.listPrice = listPriceMonthly;
                    unitPrice = listPriceMonthly;
                    if(isContract && eachProduct.objCatalogue ){
                        if(contractDiscount != null) {
                            eachProduct.listPrice -= contractDiscount;
                            unitPrice = eachProduct.listPrice;
                        }
                        else if(eachProduct.objCatalogue.Contract_Discount__c != null){
                            eachProduct.listPrice -= eachProduct.objCatalogue.Contract_Discount__c;
                            unitPrice = eachProduct.listPrice;
                        }
                    }
                }
                else{
                    eachProduct.listPrice = listPriceYearly;
                    unitPrice = eachProduct.listPrice;
                }
                console.log('eachProduct.listPrice=', eachProduct.listPrice);
                var listPrice = eachProduct.listPrice;
                var discount = eachProduct.partnerDiscount;
                var discountType = eachProduct.discountType;
                var quantity1 = eachProduct.quantity;
                var netPrice = 0;

                if (listPrice != null && quantity1 != null) {
                    if (discount == 100)
                        listPrice = 0;
                    else if( discount > 0 && discountType == '%'){
                        listPrice -= ((listPrice * discount) / 100);
                    }else if(discount && discount > 0 && discountType == 'Amt'){
                        listPrice -= discount;
                    }
                    netPrice = listPrice * quantity1;
                }

                if (netPrice != null) {
                    var discountAmount = Math.round(((unitPrice * discountLimit) / 100) * 100) /100;
                    if(listPrice < 0){
                        eachProduct.partnerDiscount = 0;
                        helper.showToast('Error', 'The discount can not be more than unit price', 'error');
                    }else if(eachProduct.partnerDiscount > 0 && !isPromoValid && !promoError && eachProduct.discountType == 'Amt' && discountAmount < eachProduct.partnerDiscount){
                        helper.showToast('Error', 'The discount can not be more than ' + discountLimit + '%(' + discountAmount + objQuote.CurrencyIsoCode + ')', 'error');
                        eachProduct.partnerDiscount = 0;
                    }
                        else{
                            eachProduct.netPrice = netPrice;
                            eachProduct.listPrice = listPrice;
                        }
                }
                if (!updateSelectedProducts && netPriceBeforeUpdate.toFixed(2) != netPrice.toFixed(2))
                    eachProduct.doUpdate = true;
            }

            console.log('productList ===', productList);
            if (updateSelectedProducts)
                component.set("v.SelectedProductList", productList);
            else
                component.set("v.ProductList", productList);


        }
        catch (e) {
            console.log('Error = ' + e);
        }
    },

    loadQuoteLines: function (component, event, helper) {
        try {
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            if (id) {
                component.set("v.Spinner", true);
                //Getting Quote Products
                var getQPAction = component.get("c.getProductsFromQuote");
                getQPAction.setParams({
                    quoteId: id
                });
                getQPAction.setCallback(this, function (response) {
                    console.log('response.getState()', response.getState());
                    if (response.getState() == "SUCCESS") {
                        var listOfQuoteLines = response.getReturnValue();
                        component.set("v.SelectedProductList", listOfQuoteLines);
                        console.log("listOfQuoteLines = ", listOfQuoteLines);
                        helper.updatePrice(component, event, helper, component.get("v.SelectedProductList"), true);
                    }
                    else {
                        helper.showToast('Error', 'There is some error in loading quoe lines. Please contact your system admin.', 'error');
                    }
                });
                $A.enqueueAction(getQPAction);
            }
        }
        catch (e) {
            console.log('Error = ', e);
            //component.set("v.Spinner", false);
        }
    },

    setReloadFlag: function (component, event, helper) {
        component.set("v.ReloadDataOnLineDelete", false);
        component.set("v.ReloadDataOnLineDelete", true);
    },

    loadSuperUserFlag: function (component, event, helper) {
        //Getting Current User Info
        var getUserInfoAction = component.get("c.checkSuperUser");
        getUserInfoAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var isSuperUser = response.getReturnValue();
                component.set("v.isSuperUser", isSuperUser);
            }
        });
        $A.enqueueAction(getUserInfoAction);
    },

    loadCurrentUserInfo: function (component, event, helper) {
        //Getting Current User Info
        var getUserInfoAction = component.get("c.getCurrentUserInfo");
        getUserInfoAction.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var objUser = response.getReturnValue();
                component.set("v.currentUser", objUser);
            }
        });
        $A.enqueueAction(getUserInfoAction);
    },

    switchProgressBar: function (component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        if (id)
            helper.redirectTo('/quotetool' + '?id=' + id);
    },
    loadOtherInformation: function (component, event, helper) {
        var url = new URL(location.href);
        var id = url.searchParams.get('id');
        if (id) {
            var serverAction = component.get("c.getOtherDetails");
            serverAction.setParams({
                quoteId: id
            });

            serverAction.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    var objWrapper = response.getReturnValue();
                    console.log("objWrapper>>", objWrapper);
                    component.set("v.currentUser", objWrapper.currentUserDetails);
                    component.set("v.isSuperUser", objWrapper.isSuperUser);
                    component.set("v.hideDiscount", objWrapper.discountAccess);
                    console.log('****>>>', objWrapper.discountAccess);
                    component.set("v.isSpeciaPermissionAvail", objWrapper.isSpecialPermissionPromoAvail);
                    component.set("v.isPromoCodeAppliedApproved", objWrapper.isPromoCodeAppliedApproved);
                    component.set("v.isCurrentUserReadOnlyProfile", objWrapper.isCustomPermissionAvailable);
                    console.log('objWrapper.isCustomPermissionAvailable>>', objWrapper.isCustomPermissionAvailable);
                    var mapOfPackageToPromoRec = this.setMapData(component, event, helper, objWrapper.mapOfPackageToPromoRec);
                    var mapOfPromoToListAssociatedDetail = this.setMapData(component, event, helper, objWrapper.mapOfPromoToListAssociatedDetail);

                    component.set("v.mapOfPackageToPromoDetail", mapOfPackageToPromoRec);
                    component.set("v.mapOfPromoToListAssociatedDetail", mapOfPromoToListAssociatedDetail);
                    //Skip code added by AS
                    component.set("v.skipPYN", objWrapper.skipPYN);
                }
            });
            $A.enqueueAction(serverAction);
        }
    },
    setMapData: function (component, event, helper, result) {
        var tempMap = [];
        for (var key in result) {
            tempMap.push({ key: key, value: result[key] });
        }
        return tempMap;
    },

    getBrandName: function (component, event, helper, objQuote) {
        var url = new URL(location.href);
        var id;
        if (url.searchParams.get('id'))
            id = url.searchParams.get('id');
        else
            id = url.searchParams.get('oppId');

        if (id) {
            var serverAction = component.get("c.getBrandNameFromOppOrQuote");
            serverAction.setParams({
                OppIdOrQuoteId: id
            });

            serverAction.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    //var objWrapper = response.getReturnValue();
                    component.set("v.BrandName", response.getReturnValue());
                    //Added for GO Pricing - start
                    var brandname = response.getReturnValue();
                    if(brandname.includes('RingCentral')){
                        component.set("v.showOnlyRc",true);
                    }else{
                        component.set("v.showOnlyRc",false);
                    }
                    //Added for GO Pricing - end
                    // alert(component.get("v.BrandName"));
                }
            });
            $A.enqueueAction(serverAction);
        }
    },
    doTotal: function (component, event, helper, objQuote) {
        var listOfSelectedRecords = component.get("v.SelectedProductList");
        var totalPrice = 0;
        var oneTimeTotal = 0;
        var reccuringTotal = 0;
        listOfSelectedRecords.forEach(function (eachLine) {
            if (eachLine.netPrice && eachLine.rowType != 'Header') {
                //alert(eachLine.netPrice);
                if (eachLine.rowType == 'Record') {
                    totalPrice += eachLine.netPrice;
                }
                if (eachLine.objCatalogue.Plan__c == 'One - Time') {
                    oneTimeTotal += eachLine.netPrice;
                }
                else {
                    reccuringTotal += eachLine.netPrice;
                }
            }
        });
        objQuote.One_Time_Payment__c = oneTimeTotal;
        objQuote.Total_Recurring_Payment__c = reccuringTotal;
        return objQuote;
    },
    checkisAvaya: function(component,event,helper,brand){
        var action = component.get("c.checkIsTopMaster");
        action.setParams({
            quoteBrandName:brand
        });
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
                var topMasterDetail = response.getReturnValue();
                component.set("v.isAvaya",topMasterDetail.isAvaya);
                component.set("v.isContractTeam",topMasterDetail.isContractTeam);
                var com = topMasterDetail.partnerCommunityName;
                var isTopMaster = topMasterDetail.isAvaya;
                if(com && (com.includes("RingCentral")||com.includes("Unify Office")) && isTopMaster == false){
                    component.set("v.hideRCContract",true);
                }
            }
        });
        $A.enqueueAction(action);
    },
})
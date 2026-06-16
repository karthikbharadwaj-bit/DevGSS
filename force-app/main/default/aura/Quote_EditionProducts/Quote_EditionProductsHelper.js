({
    doCalculation : function(component, event, helper, calculateAll){
        try{
            if(calculateAll){
                var listOfProducts = component.get("v.ProductList");
                for(var i = 0; i < listOfProducts.length; i++){
                    helper.doCalculationOnEachLine(component, event, helper, i);
                }
            }
            else{
                var index = event.target.name.split('-')[1];
                helper.doCalculationOnEachLine(component, event, helper, index);
            }
        }
        catch(e){
            console.log('Error', e);
        }
    },
    
    doCalculationOnEachLine : function(component, event, helper, index){
        try{
            var listOfProducts = component.get("v.ProductList");
            var currentRow = listOfProducts[index];
            if(currentRow.rowType == 'Record'){
                var listPrice = currentRow.listPrice;
                var discount = currentRow.partnerDiscount;
                var discountType = currentRow.discountType;
                var quantity = currentRow.quantity;
                var netPrice = 0;
                /*
                if(quantity == 0 || quantity == null){
                    helper.showToast('Error', 'Quantity can not be 0 for ' + currentRow.objCatalogue.Display_Name__c, 'error');
                	quantity = 1;
                }
                */
                if(listPrice != null && quantity != null){
                    if(discount == 100)
                        listPrice = 0;
                    else if( discount > 0 && discountType == '%'){
                        listPrice -= ((listPrice * discount) / 100);  
                    }else if(discount > 0 && discountType == 'Amt'){
                        listprice -= discount;
                    }
                    netPrice = listPrice * quantity;
                }    
                
                if(netPrice){
                    currentRow.netPrice = netPrice;
                }
                listOfProducts[index] = currentRow;
                component.set("v.ProductList", listOfProducts);
            }
        }
        catch(e){
            console.log('Error', e);
        }
    },
    
    updateCart : function(component, event, helper, index, doDelete) {
        try{
            var listOfProducts = component.get("v.ProductList");
            var selectedRecord = listOfProducts[index];
            var doReload = true;
            if(selectedRecord.objRule && selectedRecord.objRule.Rule_Type__c != '')
                doReload = true;
            var mapOfIdVsProduct = new Map();
            for(var i = 0; i < listOfProducts.length; i++){
                var eachProduct = listOfProducts[i];
            	mapOfIdVsProduct.set(eachProduct.objProduct.Id, eachProduct);	
            }
            
            if(selectedRecord.buttonText == 'Update'){
                if(doDelete){
                    selectedRecord.quantity = 0;
                    doReload = true;	
                }
                
                var selectedProducts = component.get("v.SelectedProductList");
                for(var i = 0; i < selectedProducts.length; i++){
                    if(selectedProducts[i].objProduct && selectedRecord.objProduct.Id == selectedProducts[i].objProduct.Id){
                        selectedProducts[i] = selectedRecord;
                    }
                    //Delete child lines
                    if(doDelete){
                        if(selectedProducts[i].objCatalogue && selectedProducts[i].objCatalogue.Parent__c == selectedRecord.objCatalogue.Id){
                            selectedProducts[i].quantity = 0;
                            doReload = true;
                        }
                    }
                    //Auto updating children records quantities
                    if(selectedProducts[i].objRule && selectedProducts[i].objCatalogue.Parent__c == selectedRecord.objCatalogue.Id && selectedProducts[i].objRule.Rule_Type__c == 'AA- Auto Add Child'){
                        selectedProducts[i].quantity = selectedRecord.quantity;
                        doReload = true;
                    }
                    //Updating products for which pricing is changed
                    var eachSelectedProduct = selectedProducts[i];
                    if(eachSelectedProduct.objProduct){
                        var eachProduct = mapOfIdVsProduct.get(eachSelectedProduct.objProduct.Id);
                        if(eachProduct && eachProduct.doUpdate){
                            eachSelectedProduct.quantity = eachProduct.quantity;
                            eachSelectedProduct.listPrice = eachProduct.listPrice;
                            eachSelectedProduct.netPrice = eachProduct.netPrice;
                        }
                    }
                }
                component.set("v.SelectedProductList", selectedProducts);
                helper.createUpdateQuote(component, event, helper, null, null, null, doReload, true, false);
            }
            else{
                var selectedCategory = component.get("v.selectedCategory");
                if(selectedCategory == 'Implementation')
                    selectedRecord.quantity = 1;
                var selectedRecords = [];
                if(!selectedRecord.quantity){
                    helper.showToast('Error', 'Please enter quantity first.', 'error');
                }
                else{
                    selectedRecord.buttonText = 'Update';
                    selectedRecord.doUpdate = false;
                    selectedRecords.push(selectedRecord);
                    
                    for(var i = 0; i < listOfProducts.length; i++){
                        var eachRecord = listOfProducts[i];
                        //Auto selecting parent and dependent products - Auto Add Parent
                        if(selectedRecord.objRule 
                           && selectedRecord.objRule.Rule_Type__c == 'EU - Parent dependent quantity - AAP'){
                            if(selectedRecord.objCatalogue.Parent__c == eachRecord.objCatalogue.Id 
                               || (selectedRecord.objCatalogue.Parent__c == eachRecord.objCatalogue.Parent__c
                                   && eachRecord.objCatalogue.Package_Product_Type__c.indexOf('Quantity same as parent') != -1)){
                                if(eachRecord.buttonText != 'Update')
                                {
                                    eachRecord.buttonText = 'Update';
                                    eachRecord.quantity = selectedRecord.quantity;
                                    selectedRecords.push(eachRecord);   
                                }
                            }
                        }
                        
                        //Auto selecting children records
                        if(selectedRecord.objRule && selectedRecord.objRule.Rule_Type__c == 'EU - Parent dependent quantity'){
                            if(eachRecord.objRule 
                               && selectedRecord.objRule.Id == eachRecord.objRule.Id && eachRecord.isAutoSelect){
                                eachRecord.buttonText = 'Update';
                                selectedRecords.push(eachRecord);    
                            }
                        }
                        else{
                            //Enabling children
                            if(selectedRecord.objCatalogue && eachRecord.objCatalogue && selectedRecord.objCatalogue.Id == eachRecord.objCatalogue.Parent__c){
                                if(eachRecord.isAutoSelect){
                                    eachRecord.buttonText = 'Update';
                                    if(eachRecord.quantity == null)
                                        eachRecord.quantity = selectedRecord.quantity;
                                    selectedRecords.push(eachRecord);   
                                    eachRecord.isDisabled = true;
                                }
                                else{
                                    eachRecord.isDisabled = false;
                                }
                            }
                        }
                    }
                    //Updating products for which pricing is changed
                  	var selectedProducts = component.get("v.SelectedProductList");
                    for(var i = 0; i < selectedProducts.length; i++){
                    	var eachSelectedProduct = selectedProducts[i];
                        if(eachSelectedProduct.objProduct){
                            var eachProduct = mapOfIdVsProduct.get(eachSelectedProduct.objProduct.Id);
                            if(eachProduct && eachProduct.doUpdate){
                                eachSelectedProduct.quantity = eachProduct.quantity;
                                eachSelectedProduct.netPrice = eachProduct.netPrice;
                            }
                        }
                    }
                    component.set("v.SelectedProductList", selectedProducts);
                    var selectProductEvent = component.getEvent("evtSelectProduct");
                    selectProductEvent.setParams({
                        "evtParam_Product" : selectedRecords
                    });
                    selectProductEvent.fire();
                    listOfProducts[index] = selectedRecord;
                    component.set("v.ProductList", listOfProducts);
                }
            }
        }
        catch(e){
            console.log('Error =', e);
        }
    },
    
    validateRules : function(component, event, helper, index){
        try{
            var listOfProducts = component.get("v.ProductList");
            var selectedRecord = listOfProducts[index];
            if(!selectedRecord.quantity){
                helper.showToast('Error', 'Please enter quantity.', 'error');
                return;
            }
            var productsListTiers = [];
            if(selectedRecord.objRule && (selectedRecord.objRule.Rule_Type__c == 'EU - Parent dependent quantity'
                                          || selectedRecord.objRule.Rule_Type__c == 'EU - Parent dependent quantity cannot exceed parent'
                                          || selectedRecord.objRule.Rule_Type__c == 'EU - Parent dependent quantity cannot exceed parent, EU - Select only one')){
                
                for(var i = 0; i < listOfProducts.length; i++){
                    if(listOfProducts[i].objCatalogue){
                        console.log('counter>>>listOfProducts[i].partnerDiscount>>>',listOfProducts[i].partnerDiscount);
                        console.log('counter>>>listOfProducts[i].partnerDiscount>>>',listOfProducts[i].partnerDiscount=='');
                        if(listOfProducts[i].partnerDiscount == ''){
                            listOfProducts[i].partnerDiscount = 0;
                        }
                    	productsListTiers.push(listOfProducts[i].objCatalogue.Product_Tier_Prices__r);
                    	listOfProducts[i].objCatalogue.Product_Tier_Prices__r = null;
                    }
                    listOfProducts[i].listOfTiers = null;
                    console.log('Setting tiers as null');
                }
                
                var url = new URL(location.href);
                var id = url.searchParams.get('id');
                component.set("v.Spinner", true);
                console.log('listOfProducts=', listOfProducts);
                var productListJSON = JSON.stringify(listOfProducts);
                console.log('productListJSON=', productListJSON);
                var validateRulesAction = component.get("c.validateRules");
                validateRulesAction.setParams({  
                    quoteId : id,
                    productList : productListJSON  
                });
                validateRulesAction.setCallback(this, function(response){
                    if(response.getState() == "SUCCESS"){
                        var listOfProducts1 = response.getReturnValue();
                        console.log('listOfProducts1=', listOfProducts1);
                        var isErrorMessage = false;
                        var eachProduct;
                        for(var i = 0; i < listOfProducts1.length; i++){
                            console.log('productsListTiers[i]',productsListTiers[i]);
                            if(listOfProducts1[i].errorMsg != null){
                                isErrorMessage = true;
                           	}
                            if(listOfProducts1[i].objCatalogue)
                        		listOfProducts1[i].objCatalogue.Product_Tier_Prices__r = productsListTiers[i];
                        }
                        component.set("v.ProductList", listOfProducts1);
                        if(isErrorMessage){
                            
                            component.set("v.Spinner", false);
                            helper.showToast('Error', 'There is some validation error. Please check product quantities.', 'error');
                        }
                        else{
                            component.set("v.Spinner", false);
                           	helper.updateCart(component, event, helper, index);  
                        }
                    }
                    else{
                        helper.showToast('Error', 'There is some error while validating the products. Please contact your admin.', 'error');
                        component.set("v.Spinner", false);
                    }
                });
                $A.enqueueAction(validateRulesAction);
            }
            else{
                helper.updateCart(component, event, helper, index);  
            }
        }
        catch(e){
            console.log('Error = ', e);
        }
    }
})
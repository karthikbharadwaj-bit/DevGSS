({
	addToCart : function(component, event, helper) {
        try{
    		var index = event.currentTarget.id;
            var listOfProducts = component.get("v.ProductList");
            var selectedRecord = listOfProducts[index];
            console.log('selectedRecord>>>',selectedRecord);
            if(selectedRecord.buttonText == 'Remove'){
                helper.deleteQuoteProductUsingProductId(component, event, helper, selectedRecord.objProduct.Id);
            }
            else{
                component.set("v.isProductSelectedFROMPYNTab",true);
                selectedRecord.quantity = 1;
                selectedRecord.isSelected = true;
                selectedRecord.buttonText = 'Remove';
                selectedRecord.netPrice = selectedRecord.listPrice;
                listOfProducts[index] = selectedRecord;
                var disabledRecordIds = [];
                for(var i = 0; i < listOfProducts.length; i++){
                    var eachRecord = listOfProducts[i];
                    //If selected product is current then skip it
                    if(i == index)
                        continue;    
                    
                    if(selectedRecord.objRule){ //&& selectedRecord.objRule.Rule_Type__c == 'MU - Pick none or one'){
                        if(eachRecord.objRule && selectedRecord.objRule.Id == eachRecord.objRule.Id){
                            eachRecord.isDisabled = true;
                            disabledRecordIds.push(eachRecord.objProduct.Id);
                        }
                    }
                }
                //Disabling child records
                for(var i = 0; i < listOfProducts.length; i++){
                    var eachRecord = listOfProducts[i];
                    //If selected product is current then skip it
                    if(i == index)
                        continue;    
                    
                    if(disabledRecordIds.indexOf(eachRecord.parentId) > -1){
                        eachRecord.isDisabled = true;    
                    }
                }
                var selectProductEvent = component.getEvent("evtSelectProduct");
                console.log("selectedRecord=", selectedRecord);
                selectProductEvent.setParams({
                    "evtParam_Product" : selectedRecord
                });
                selectProductEvent.fire();
                console.log('Product Selection Event Fired !');
                component.set("v.ProductList", listOfProducts);
            }
            
            for(var objProd of listOfProducts) {
                if(objProd.objCatalogue && objProd.objCatalogue.Package_Product_Type__c.includes('Pick Your Numbers - Mandatory') && objProd.isSelected) {
                    component.set("v.isProductSelectedFROMPYNTab",true);
                    break;
                }
            }
        }
        catch(e){
            console.log('Error =', e);
        }
	},
})
({
	calculateAll : function(component, event, helper){
        console.log('Calcualting all rows');
        helper.updatePrice(component, event, helper);
    },
    
    doCalculation : function(component, event, helper){
        var index = event.currentTarget.id;
        helper.updatePrice(component, event, helper, index);
   	},
    
	updateCart : function(component, event, helper){
        //alert('add');
        var isSuperUser = component.get("v.isSuperUser");
        var currentUser = component.get("v.currentUser");
        var index = event.currentTarget.id;
        const targetIndex = index;
        var ProductList = component.get("v.ProductList");
        var objProductRec = ProductList[index];
        console.log('objProductRec>>',objProductRec);
        
        try {
            let brandName;
            const igniteBrands = ['RingCentral', 'RingCentral AU', 'RingCentral UK', 'RingCentral Canada', 'RingCentral EU'];
            const quote = component.get("v.Quote");
            if (quote && quote.Opportunity__r)
                brandName = quote.Opportunity__r.Brand_Name__c;
            if (igniteBrands.includes(brandName)) {
                let maxLicense = 399;
                if (['RingCentral UK', 'RingCentral EU'].includes(brandName))
                    maxLicense = 499;
                let totalLicenses = quote.Number_of_Licenses__c;
                ProductList.forEach(function (item, index) {
                    const objCatalogue = item.objCatalogue;
                    let previousQuantity = 0;
                    if (item.buttonText === 'Update' &&
                        index !== Number(targetIndex) &&
                        objCatalogue &&
                        (objCatalogue.Category_Name__c === 'Service' ||
                         objCatalogue.Sub_Category_Name__c === 'Global MVP') &&
                        objCatalogue.Package_Product_Type__c &&
                        (!objCatalogue.Package_Product_Type__c.includes('Header')) &&
                        (!objCatalogue.Package_Product_Type__c.includes('Service Fee'))) {
                        if (item.objQuoteLine) {
                            previousQuantity = item.objQuoteLine.Quantity__c;
                        }
                        totalLicenses += Number(item.quantity) - previousQuantity;
                    }
                });
                
                let objCatalogue;
                if (objProductRec)
                    objCatalogue = objProductRec.objCatalogue;
                
                if (objCatalogue &&
                    (objCatalogue.Category_Name__c === 'Service' ||
                     objCatalogue.Sub_Category_Name__c === 'Global MVP') &&
                    objCatalogue.Package_Product_Type__c &&
                    (!objCatalogue.Package_Product_Type__c.includes('Header')) &&
                    (!objCatalogue.Package_Product_Type__c.includes('Service Fee'))) {
                    let previousQuantity = 0;
                    if (objProductRec.objQuoteLine)
                        previousQuantity = objProductRec.objQuoteLine.Quantity__c;
                    totalLicenses += Number(objProductRec.quantity) - previousQuantity;
                    if (totalLicenses > maxLicense) {
                        helper.showToast('Error', `Please make sure total number of licenses not exceeds ${maxLicense}`, 'Error');
                        return;
                    }
                }
            }
        }
        catch (error) {
            console.log('7130', error);
        }

        if(currentUser.UserType != 'Standard' && !isSuperUser && objProductRec.buttonText != 'Add' && objProductRec.objQuoteLine.Discount__c != null && objProductRec.objQuoteLine.Discount__c > 0 && objProductRec.objQuoteLine.Approved_Quantity__c != null && objProductRec.quantity < objProductRec.objQuoteLine.Approved_Quantity__c) {
            helper.showToast('Error','Quantity cannot be less than approved qantity','Error');
        }
        else {
            //alert('else');
        	helper.validateRules(component, event, helper, index);  
        }    
    },    
    
    deleteQuoteLine : function(component, event, helper){
        var index = event.currentTarget.id;
        helper.updateCart(component, event, helper, index, true);  
    },
    
})
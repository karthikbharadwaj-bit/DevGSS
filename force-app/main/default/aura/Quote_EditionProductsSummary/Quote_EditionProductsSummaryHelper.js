({
	quoteLoadActions: function(component, event, helper){
    	var objQuote = component.get("v.Quote");
        if(objQuote && objQuote.Payment_Term__c == 'Yearly')
            component.set("v.PricingYearly", true);
	},
    
    doTotal : function(component, event, helper) {
        var listOfSelectedRecords = component.get("v.SelectedProductList");
        var totalPrice = 0;
        var oneTimeTotal = 0;
        var reccuringTotal = 0;
        listOfSelectedRecords.forEach(function(eachLine){
            if(eachLine.netPrice && eachLine.rowType != 'Header' ){
                //alert(eachLine.netPrice);
                if(eachLine.rowType == 'Record'){
                    totalPrice += eachLine.netPrice;
                }
                if(eachLine.objCatalogue.Plan__c == 'One - Time') {
                    oneTimeTotal += eachLine.netPrice;
                }
                else {
                    reccuringTotal += eachLine.netPrice;
                }
            }
        });
        //alert(oneTimeTotal);
    	component.set("v.oneTimeTotal", oneTimeTotal);
        component.set("v.reccuringTotal", reccuringTotal);
        component.set("v.Total", totalPrice);
	},
})
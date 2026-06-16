({
	loadData : function(component, event, helper) {
		helper.loadQuoteLines(component, event, helper);	
        //var callDoCalculation = component.get('c.doCalculation');
        //$A.enqueueAction(callDoCalculation);
		helper.getTranslations(component, event, helper);
	},
    
    saveQuoteLines : function(component, event, helper) {
		//helper.saveQuoteLines(component, event, helper);	
	},
    
    doCalculation : function(component, event, helper) {
        console.log('doing calculations');
		helper.doCalculation(component, event, helper);
	},
    
    deleteQuoteProduct : function(component, event, helper) {
        //helper.deleteQuoteProduct(component, event, helper);
	},
})
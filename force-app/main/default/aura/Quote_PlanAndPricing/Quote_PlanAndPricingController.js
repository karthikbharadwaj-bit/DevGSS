({
	loadPlansAndPricing : function(component, event, helper) {
		helper.getTranslations(component, event, helper);
        var url = new URL(location.href);
        var alreaySelectedEdition = component.get("v.Quote").Product_Edition__c;
        component.set("v.selectedEditionId", alreaySelectedEdition);

        try {
            const selectedEditionRec = component.get("v.Quote").Product_Edition__r;
            if(selectedEditionRec != undefined && selectedEditionRec.Name != undefined) {
                const packageName = selectedEditionRec.Name.toLowerCase();
                if(packageName != undefined && (packageName.includes('classroom') || packageName.includes('education')))
                component.set("v.isEDUOptionEnabled",true);
            }
        }catch(e) {
            console.error('error: ', e);
        }

        //Added for GO Pricing - start
        var noofseats = component.get("v.Quote").Number_of_Licenses__c;
        console.log(':::::Opportunity:::::'+JSON.stringify(component.get("v.Quote")));
        if(noofseats >= 20){
            component.set("v.activateGlobal",true);
        }else{
            component.set("v.activateGlobal",false);
        }
        console.log("PricingYearly in planpricing>>"+component.get("v.PricingYearly"));
        //Added for GO Pricing - end

        helper.getInfo(component, event, helper);//EDU Package
		helper.loadPlansAndPricing(component, event, helper);	
	},
    
    NoOfSeatsChange : function(component, event, helper) {
        helper.NoOfSeatsChange(component, event, helper);
	},
    //Added for GO Pricing - start
    addorremoveglobal : function(component,event,helper){
         helper.addorremoveglobal(component,event,helper);
    },
    //Added for GO Pricing - end
    //EDU Package
    onEDUOptionChange : function(cmp, event, helper) {
        helper.NoOfSeatsChange(cmp, event, helper);
    }
})
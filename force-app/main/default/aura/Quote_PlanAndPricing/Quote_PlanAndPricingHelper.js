({
    getInfo: function (component, event, helper) {
        //EDU Package
        try {
            const url = new URL(location.href);
            let opporquoteid;
            opporquoteid = url.searchParams.get('oppId');
            if (!opporquoteid) {
                opporquoteid = url.searchParams.get('id');
            }
            function setInfo(response) {
                if (response.getState() == "SUCCESS") {
                    const wrapper = response.getReturnValue();
                    if (wrapper) {
                        console.log('accountSector: ' + wrapper.accountSector);
                        component.set("v.accountSector", wrapper.accountSector);
                        component.set("v.Currencycode", wrapper.currencyISOCode);
                    }
                }
            }
            const getInfo = component.get("c.getInfo");
            getInfo.setParams({ OpporQuoteId: opporquoteid });
            getInfo.setCallback(this, setInfo);
            $A.enqueueAction(getInfo);
        }
        catch (e) {
            console.error('error: ' + e);
        }
    },

    loadPlansAndPricing : function(component, event, helper) {
        var url = new URL(location.href);
        var Id = url.searchParams.get('oppId');
        var opportunityId;
        if(Id) {
            opportunityId = Id;
        } else {
            opportunityId = url.searchParams.get('id');
        }
        //alert(opportunityId);
        //console.log('component.get("v.Quote")>>>',component.get("v.Quote"));
        //alert(component.get("v.Quote"));
        if(opportunityId) {
            var getEditionsAction = component.get("c.getProductEditions");
            getEditionsAction.setParams({
                oppId : opportunityId,
                 parentPackageId : ''
            });
            
            getEditionsAction.setCallback(this, function(response){
                if(response.getState() == "SUCCESS"){
                    var editionWrapper = response.getReturnValue();
                    var normaledition = [];
                    var globaledition = [];
                    let EDUPackages = [], packageName;//EDU Package
                    console.log('::::::editionWrapper::::::::'+JSON.stringify(editionWrapper));
                    //Added for GO Pricing - start
                    for(var thisRecord of editionWrapper){
                        console.log('::::::::isGlobal:::::::'+thisRecord.isGlobal+':::::'+JSON.stringify(thisRecord));
                        if(thisRecord.editionRec != undefined && thisRecord.editionRec.Name != undefined)
                        packageName = thisRecord.editionRec.Name.toLowerCase();//EDU Package
                        if(thisRecord.isGlobal == true){
                            globaledition.push(thisRecord);
                        }else{
                            if(packageName != undefined && (packageName.includes('classroom') || packageName.includes('education')))
                            EDUPackages.push(thisRecord);//EDU Package
                            else
                            normaledition.push(thisRecord);
                        }
                    }
                    component.set("v.NormalEditions", normaledition); 
                    component.set("v.EDUPackages", EDUPackages);//EDU Package
                    component.set("v.GlobalEditions", globaledition);
                    console.log('::::::Global Editions:::::',globaledition);
                    console.log('::::::Normal Editions::::::',normaledition);
                    //Added for GO Pricing - end

                    var quoteRec = component.get("v.Quote");
                    if(editionWrapper != undefined && editionWrapper.length > 0) {
                        quoteRec.CurrencyIsoCode = editionWrapper[0].currencyIsoCode;
                        component.set("v.Quote",quoteRec);
                    }
                    // Added for AU and UK GO Pricing - start
                    var currencyCode = component.get("v.Currencycode");
                    const brand = component.get("v.BrandName");
                    console.log("brand Name: " + brand);
                    if ((currencyCode == 'EUR' || quoteRec.CurrencyIsoCode == 'EUR') ||
                        (currencyCode == 'AUD' || quoteRec.CurrencyIsoCode == 'AUD') ||
                        (currencyCode == 'GBP' || quoteRec.CurrencyIsoCode == 'GBP')) {
                            component.set("v.showUnlimitedPackages", true);
                    } else {
                            component.set("v.showUnlimitedPackages", false);
                    }
                    // Added for AU and UK GO Pricing - end
                    const EDUBrands = ['Avaya Cloud Office','RingCentral','RingCentral UK','RingCentral Canada','RingCentral EU','RingCentral AU'];
                    const EDUCurrencies = ['USD','CAD'];
                    const accountSector = component.get("v.accountSector"); 
                    if (accountSector.toLowerCase() == 'education' && 
                        EDUBrands.includes(brand) && 
                        EDUCurrencies.includes(currencyCode)) {
                        component.set("v.showEDUToggle", true);//EDU Package
                    }
                    this.NoOfSeatsChange(component, event, helper);
                }
                else{
                    helper.showToast('Error', 'There is some error in loading Editions. Please contact your system admin.', 'error');
                }
            });
            $A.enqueueAction(getEditionsAction);
        }
    },
    NoOfSeatsChange : function(component, event, helper) {
        var Editions = [];
        var objQuote = component.get("v.Quote");
        var NoOfSeats = component.get("v.NoOfSeats");
        var pricingYearlyOrMonthly = component.get("v.PricingYearly");
        var isContract = component.get("v.isContract");
        const isEDUEnabled = component.get("v.isEDUOptionEnabled");//EDU Package
        //Added for GO Pricing - start
        if(NoOfSeats >= 20){
            component.set("v.activateGlobal",true);
        }else{
            component.set("v.activateGlobal",false);
            objQuote.is_Global_Unlimited__c = false;
            component.set("v.Quote",objQuote);
        }
        if(objQuote.is_Global_Unlimited__c){
            Editions = component.get("v.GlobalEditions");
        }else{
            if(isEDUEnabled)
                Editions = component.get("v.EDUPackages");//EDU Package
            else
                Editions = component.get("v.NormalEditions");
        }
        //Added for GO Pricing - end
        for(var thisRecord of Editions)
        {
            var listPriceMonthly = 0;
            var listPriceYearly = 0;
            var contractDiscount = null;
            var tierList = thisRecord.editionRec.Product_Tier_Prices__r;
            
            if(tierList && tierList.length > 0){
                for(var eachTier of tierList){
                    if(NoOfSeats <= eachTier.No_of_Licenses__c ){
                        listPriceMonthly = eachTier.Monthly_Price__c;
                        listPriceYearly = eachTier.Yearly_Price__c;
                        contractDiscount = eachTier.Contract_Discount__c;
                        break;
                    }
                }
                if(listPriceMonthly == 0)
                    listPriceMonthly = tierList[tierList.length-1].Monthly_Price__c;  
                if(listPriceYearly == 0)
                    listPriceYearly = tierList[tierList.length-1].Yearly_Price__c;
                //rounding off price to 2 decimal places
                if(pricingYearlyOrMonthly){
                	thisRecord.editionRec.Price__c = Math.round(listPriceYearly * 100) / 100;
                }
                else if(isContract && !pricingYearlyOrMonthly){
                    if(contractDiscount != null){
                        let price = listPriceMonthly - contractDiscount;
						thisRecord.editionRec.Price__c = Math.round(price * 100) / 100;
                    }
                    else if(thisRecord.editionRec.Contract_Discount__c != 0 && thisRecord.editionRec.Contract_Discount__c != null) {
                    	let price = listPriceMonthly - thisRecord.editionRec.Contract_Discount__c;
                        thisRecord.editionRec.Price__c = Math.round(price * 100) / 100;
                    } else {
                        let price = listPriceMonthly;
                        thisRecord.editionRec.Price__c = Math.round(price * 100) / 100;
                    }
                }
                else
                    thisRecord.editionRec.Price__c = Math.round(listPriceMonthly * 100) /100 ;                
            }
        }
        if(objQuote.is_Global_Unlimited__c){
            component.set("v.GlobalEditions",Editions);
        }else{
            if(isEDUEnabled)
            component.set("v.EDUPackages",Editions);//EDU Package
            else
            component.set("v.NormalEditions",Editions);
        }
        //component.set("v.Editions",Editions);commented for GO Pricing
	},
    //Added for GO Pricing - start
    addorremoveglobal : function(component,event,helper){
         var noofseats = component.get("v.Quote").Number_of_Licenses__c;
        console.log(':::::Opportunity:::::'+JSON.stringify(component.get("v.Quote")));
        if(noofseats >= 20){
            component.set("v.activateGlobal",true);
        }else{
            component.set("v.activateGlobal",false);
        }
        this.NoOfSeatsChange(component,event,helper);
    },
    //Added for GO Pricing - end
	    //Translation Start
      getTranslations: function (component, event, helper) {
        try {
			console.log('Inside Quote_PlanAndPricing Translation');
            function setTranslations(result) {
                var state = result.getState();
				console.log('Quote_PlanAndPricing Translation state- ' + state);
				console.log('check component validity- ' + component.isValid());
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
				else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {    
                        console.log("Error message: " +  errors[0].message);
                    }
                }
				else {
                    console.log("Unknown error");
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
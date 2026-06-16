({
    doInit : function(component, event, helper) { 
        try
        {
        var isFromContract = component.get("v.isFromContract");
        if(isFromContract)
            component.set("v.currentTabId",'one');
        else
            component.set("v.currentTabId",'four');            
        var url = new URL(location.href);
        component.set('v.RespectiveTabURL',url);
        var id = url.searchParams.get('id');        
        if(!id)
        {
            id = url.href.split('/')[6];
        }
        if(id)
        {
            component.set('v.partnerQuoteId',id);
        }
        helper.loadCustomMetaData(component);
        helper.loadQuote(component, event, helper);
        component.set('v.playBookDisplay',true);
        var baseURL = url.href.substring(0, url.href.indexOf("/s"));        
        component.set('v.baseURL',baseURL);
        if(component.get('v.partnerQuoteId'))
        {
        	helper.getExistingPartnerContractDetails(component); 
            helper.checkForDealSupport(component);
        }
        else
        {
            component.set('v.hasPrimaryQuote',true);
        }
        component.set('v.isActive',true);
        }
        catch(e)
        {
            console.log('error - '+ e);
        }
		helper.getTranslations(component, event, helper);
    },
	closeModel : function(component, event, helper) {
         var isFromContract = component.get("v.isFromContract");
        if(isFromContract)
        	component.set("v.showCreateContractCMP",false);
        else
           component.set("v.showChecklistCMP",false); 
    },
    handleSave : function(component, event, helper) {
        var addressList = [];
        var shippingAddressList = component.get("v.ShippingAddressList");
        //alert(shippingAddressList);
        if(shippingAddressList) {
            for(var wrapRec of shippingAddressList) {
                addressList.push(wrapRec.acrRec);
            }
        }
        component.set("v.showSpinner",true);
        if(component.get("v.currentTabId") != 'four') {
            console.log('Inside if')
            var childCmp = component.find("PartnerQuoteEngageLegal");
 			childCmp.createContract();
        }
        else {
            console.log('Inside else');
            if(component.get("v.isFromCheckOutPage")) {
                //var addressList = component.get("v.addressList");
                var isShippingExist = false;
                var objQuote = component.get("v.Quote");
                /*if(objQuote.Product_Edition__r.Name == 'Unify Office Video Plus'){
                    isShippingExist = true;
                }*/
                for(var addressRec of addressList) {
                    if(addressRec.Type__c == 'Shipping Address') {
                        isShippingExist = true;
                    }
                }
                console.log('isShippingExist - '+isShippingExist);
                var childCmp = component.find("AccountCheckList");
                var showProductSection = component.get("v.showProductSection");
                var communityBrand='';
                console.log('v.Quote.Opportunity__r.Brand_Name__c - '+ component.get('v.Quote.Opportunity__r.Brand_Name__c'));
                console.log('v.communityDetailsRecord - ' + component.get("v.communityDetailsRecord"));
                if(component.get("v.communityDetailsRecord")!=undefined && component.get("v.communityDetailsRecord") !='' && component.get("v.communityDetailsRecord") !=null)
                    communityBrand = component.get("v.communityDetailsRecord").Brand_Name__c;
                else
                    communityBrand = component.get('v.Quote.Opportunity__r.Brand_Name__c');
                console.log('communityBrand - '+communityBrand);
                console.log('showProductSection - '+ showProductSection);
                //if(communityBrand == 'Rainbow Office')
                //{
                    if(showProductSection)
                    {
                        if(!isShippingExist) 
                        {
                            helper.showToast('Error', 'Please select shipping address before submiting quote.', 'error');
                            component.set("v.showSpinner",false);
                            return;
                        }
                    }
                //}
                /*else
                {
                    if(!isShippingExist) 
                    {
                        helper.showToast('Error', 'Please select shipping address before submiting quote.', 'error');
                        component.set("v.showSpinner",false);
                        return;
                    }
                }*/
                
            }
            childCmp = component.find("AccountCheckList");
            childCmp.submitDetails();
            /* Naresh 02/11/2020	- Commenting below lines as it is causing js exception as v.label is not found.
            var cancelBtn = component.find("cancelBtn");
            cancelBtn.set("v.label","Close");
            var submitBtn = component.find("submitBtn");
            submitBtn.set("v.label","Save");
        	*/
        }
        
    },
    updateDetails : function(component, event, helper) {
        component.set('v.isUpdateDetailClicked',true);
		if(component.get('v.partnerQuoteId') != undefined)
        {
            helper.getExistingPartnerContractDetails(component);
        }        
	}, 
    handleApproval : function(component, event, helper) {        
        helper.handleApproval(component);        
	},
    recallApproval : function(component, event, helper) {        
        helper.recallApproval(component);        
	},
    submitToRC : function(component, event, helper) {
         component.set("v.showSpinner",true);
        var partnerContractId = component.get("v.partnerContractId");
        var isAvaya = component.get("v.isAvaya");
        if(partnerContractId && isAvaya) {
            var childCmp = component.find("PartnerQuoteEngageLegal");
            childCmp.createContract();
        }
        helper.submitToRC(component);        
	},
})
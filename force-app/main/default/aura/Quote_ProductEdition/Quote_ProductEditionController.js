({
	selectEdition : function(component, event, helper) {
        component.set("v.Spinner",true);
        try{
            var url = new URL(location.href);
            var oppId = url.searchParams.get('oppId');
            if(component.get("v.NoOfSeats") > 10000){
                helper.showToast('Error', 'No of Licenses can not be more than 10k.', 'error');
                component.set("v.Spinner",false);
                return;
            }
                
            var url = new URL(location.href);
            var partnerQuoteId = url.searchParams.get('id');
            var selectedTemplateId = component.get("v.selectedTemplateId");
            if(oppId && (selectedTemplateId == null || selectedTemplateId == 'none')){
                helper.createUpdateQuote(component, event, helper, '/quotetool', null, oppId, null, true, false);
                var selectEditionEvent = component.getEvent("evtSelectEdition");
                //Added for wholesale starts
                var parentOrSubPackage = component.get('v.ParentOrSubPackage');
                //console.log('parentOrSubPackage '+parentOrSubPackage+'component.get("v.parentPackageId") '+component.get("v.parentPackageId"));
                if(parentOrSubPackage == 'Sub Package'){
                    console.log('parentOrSubPackage '+parentOrSubPackage+'component.get("v.parentPackageId") '+component.get("v.parentPackageId"));
                    selectEditionEvent.setParams({
                        "evtParam_ProductEdition" : component.get("v.parentPackageId")
                    });
                }else{
                    selectEditionEvent.setParams({
                        "evtParam_ProductEdition" : component.get("v.ProductEdition")
                    });
                }
                //Added for wholesale ends
                selectEditionEvent.fire();
            }
            else if(oppId && selectedTemplateId != null && selectedTemplateId != 'none') {
                helper.createPartnerQuoteFromTemplate(component, event, helper);
            }
            else if(partnerQuoteId) {
                helper.createUpdateQuote(component, event, helper, '/quotetool', null, oppId, null, false, true);
                var selectEditionEvent = component.getEvent("evtSelectEdition");
                selectEditionEvent.setParams({
                    "evtParam_ProductEdition" : component.get("v.ProductEdition")
                });
                selectEditionEvent.fire();
            }
            else {
               helper.showToast('Error', 'Please select an opportunity first.', 'error');
                component.set("v.Spinner",false);
            }
        }
        catch(e){
            console.log('Error = ', e);
        }
	},
    //Added for wholesale
    displaySubPackages :function(component,event,helper){
        helper.displaySubPackages(component,event,helper)
        component.set('v.showSubPackages',true);
    },
    closeModel : function(component,event,helper){
        component.set('v.showSubPackages',false);
    }
})
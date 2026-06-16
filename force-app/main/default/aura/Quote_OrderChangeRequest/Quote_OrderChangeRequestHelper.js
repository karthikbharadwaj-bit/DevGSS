({
    doInit : function(component,event,helper,packageChange) {
       //alert(component.get("v.changeEdition"));
       var action = component.get("c.getProductCategories");
        var changeAddition = component.get("v.changeEdition");
       action.setParams({
            packageName : component.get("v.changeEdition"),
            ExistingChangeOrder : component.get("v.ExistingChangeOrder"),
            changeOrderId : component.get("v.changeOrderId"),
            isPackageChange : packageChange
	   });
        action.setCallback(this, function(result) {            
            var state = result.getState();
          
            if (state === "SUCCESS"){
                console.log('result>>',result.getReturnValue());
                component.set("v.brandName",result.getReturnValue().brandName);
                component.set("v.objCategoryWrap",result.getReturnValue());
                component.set("v.isWholesale",result.getReturnValue().isWholesale);//added for wholesale
                component.set("v.listofEditionWrapper",result.getReturnValue().listofEditionWrapper);
                //Added for GO Pricing - start
                component.set("v.No_Of_DL_Acct",result.getReturnValue().No_Of_DL_Acct);
                component.set("v.initialOrderPkgEdition",result.getReturnValue().initialOrderPkgEdition);
                var brandName=result.getReturnValue().brandName;
                component.set("v.selPackageName",result.getReturnValue().changedPackage);
                var currencycode = result.getReturnValue().currencyCode;
                //var package = result.getReturnValue().listofEditionWrapper;
                console.log('::::package::::'+JSON.stringify(result.getReturnValue().listofEditionWrapper));
                console.log('::::currencycode::::'+currencycode);
                console.log('::::selPackageName::::'+component.get("v.selPackageName"));
                //added for edu
                var accountsector ='';
                if(result.getReturnValue().sector !=null){
                    accountsector = result.getReturnValue().sector.toLowerCase();
                }
                //added for edu
                //Changed for PBC-9537 EDU
                if(currencycode != 'EUR' && currencycode != 'AUD' && accountsector != 'education'){
                    console.log('::::if currencycode::::'+currencycode);
                    var packagelist = [];
                    var fullEditionList = result.getReturnValue().listofEditionWrapper;
                    let editionList = fullEditionList.filter(edition => !edition.pickVal.includes("Video"));
                    for(var thisrec of editionList){
                        console.log('::::inside for::::'+JSON.stringify(thisrec.pickVal));
                        var val = thisrec.pickVal;
                        //Changed condition for PBC-9537 EDU
                        if(!val.includes("Unlimited") && !val.includes("Education") && !val.includes("Classroom")){
                            packagelist.push(thisrec);
                            console.log('::::inside if packagelist::::'+packagelist);
                        }
                    }
                    component.set("v.listofEditionWrapper",packagelist);
                  }//added for edu packages starts
				          else if(accountsector != 'education'){
                    var normalpackagelist = [];
                    var fullEditionList = result.getReturnValue().listofEditionWrapper;
                    let editionList = fullEditionList.filter(edition => !edition.pickVal.includes("Video"));
                    for(var thisrec of editionList){
                      var val = thisrec.pickVal;
                      if(!val.includes("Education") && !val.includes("Classroom")){
                        normalpackagelist.push(thisrec);
                        console.log('::::inside if nonedupackagelist::::'+normalpackagelist);
                      }
                    } 
                    component.set("v.listofEditionWrapper",normalpackagelist);
                    //added for edu packages ends
                  }else{
                    var fullEditionList = result.getReturnValue().listofEditionWrapper;
                    let editionList = fullEditionList.filter(edition => !edition.pickVal.includes("Video"));
                    component.set("v.listofEditionWrapper",editionList);
                    console.log('::::else currencycode::::'+currencycode);
                }
                
                
                //Added for GO Pricing - end
				
				if (component.get("v.OpportunityRecord").Tier_Name__c == "RC Meetings") {
          if (brandName.includes("Unify Office") || brandName.includes("RingCentral") ) {
            var fullEditionList = result.getReturnValue().listofEditionWrapper;
            let editionList = fullEditionList.filter(edition => edition.pickVal.includes("Video"));
            console.log("listofEditionWrapper" + JSON.stringify(editionList));
            component.set("v.listofEditionWrapper", editionList);
          }
        }
        // Added 10591 start
        /*else{
          var fullEditionList = result.getReturnValue().listofEditionWrapper;
          let editionList = fullEditionList.filter(edition => !edition.pickVal.includes("Video"));
          console.log("listofEditionWrapper" + JSON.stringify(editionList));
          component.set("v.listofEditionWrapper", editionList);
        }*/
        // Added 10591 End-commented as handled while setting normal packages.
				
                if(component.get("v.ExistingChangeOrder")) {
                    var objpartnerQuote = result.getReturnValue().objPartnerQuoteRec;
                    if(objpartnerQuote.Payment_Method__c == 'Invoice') {
                       component.set("v.paymentMethod",true); 
                    }
                    
                    if(objpartnerQuote.Payment_Term__c == 'Yearly')
                       component.set("v.PricingYearly",true);
                    
                    if(!packageChange)
                    	component.set("v.changeEdition",objpartnerQuote.Product_Edition__c);
                    
                    	component.set("v.objPartnerQuote",objpartnerQuote);
                    
                    //added for wholesale
                    if(component.get("v.isWholesale")){
                        if(objpartnerQuote.Sub_Package__c)
                            component.set("v.subPackageId",objpartnerQuote.Sub_Package__c);
                        if(!packageChange){
                            //console.log("changeEdition hiii");
                            helper.loadSubPackages(component, event, helper);
                        }
                    }
                }
                else {
                    component.set("v.objPartnerQuote",result.getReturnValue().objPartnerQuoteRec);
                }
                //component.set("v.objPartnerQuote",result.getReturnValue().objPartnerQuoteRec);
                component.set("v.CategoryWrapperList",result.getReturnValue().parentCategoryWrapperList);
            }
        });    
        
        $A.enqueueAction(action); 
    },
    
	helperFun : function(component,event,secId) {
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-show');  
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
       }
	},
    submitDetails : function(component, event, helper,Status) {
        //alert(component.get("v.accountId"));
        console.log('component.get("v.CategoryWrapperList")>>',component.get("v.CategoryWrapperList"));
        var action = component.get("c.createOrderRequest");
        var paymentMethod = component.get("v.paymentMethod");
        var objPartnerQuote = component.get("v.objPartnerQuote");
        objPartnerQuote.Product_Edition__c = component.get("v.changeEdition");
        objPartnerQuote.Opportunity__c = component.get("v.recordID");
        objPartnerQuote.Status__c = Status;
		if(paymentMethod) {
            objPartnerQuote.Payment_Method__c = 'Invoice';
        }
        else {
            objPartnerQuote.Payment_Method__c = 'Credit Card';
        }
        
        if(component.get("v.PricingYearly"))
        	objPartnerQuote.Payment_Term__c = 'Yearly';
        else {
            objPartnerQuote.Payment_Term__c = 'Monthly';
        }
        //added for wholesale
        if(component.get("v.isWholesale")){
            objPartnerQuote.Sub_Package__c = component.get("v.subPackageId");
        }
        
        action.setParams({
            categoryWrapperStr : JSON.stringify(component.get("v.CategoryWrapperList")),
            objPartnerQuoteRec : objPartnerQuote,
            ExistingChangeOrder : component.get("v.ExistingChangeOrder"),
            changeOrderId : component.get("v.changeOrderId"),
            accountId : component.get("v.accountId")
        });
        action.setCallback(this, function(result) {            
            var state = result.getState();
            //alert(state);
            if (component.isValid() && state === "SUCCESS"){
                if(Status == 'Pending Order') {
                    component.set("v.isChangeOrderSubmitted", true);
                    helper.showToast('Success','Change requested submitted successfully.','success');
                }
                else{
                	helper.showToast('Success','Change requested saved successfully.','success');
                }
                component.set("v.showChangeRequestCMP",false);
            }
        });    
        
        $A.enqueueAction(action); 
	},
  //added for wholesale
  loadSubPackages: function(component, event, helper){
    if (!component.get("v.changeOrderId")) {
      var url = new URL(location.href);
      var id = url.searchParams.get('id');
      if (id && !id.startsWith('006') && !id.startsWith('001')) {
        component.set("v.changeOrderId", id);
        component.set("v.ExistingChangeOrder", true);
      } else if (id) {
        component.set("v.changeOrderId", id);
      }
    }
    var action = component.get("c.loadSubPackages"); 
    action.setParams({
      parentPackageId: component.get("v.changeEdition"),
      oppId: component.get("v.changeOrderId")
    });
    action.setCallback(this, function (result) {
      var state = result.getState();
      console.log(JSON.stringify(result.getError()));
      if(state === 'SUCCESS'){
        component.set("v.subPackages",result.getReturnValue());
        console.log(JSON.stringify(component.get("v.subPackages")));

      }
    });
    $A.enqueueAction(action); 
  }
})
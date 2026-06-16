({
	getPartnerContractTypes : function(component) {
        try
        {  
        var action = component.get('c.getPartnerContractTypes');    
        var partnerQuoteId = component.get('v.partnerQuoteId');
        action.setParams({"PartnerQuoteId" : partnerQuoteId});
        action.setCallback(this,function(response){
			component.set('v.partnerContractTypeWrapperList',response.getReturnValue());
            console.log('inside partner contrct type>>'+response.getReturnValue());
            console.log('response.getReturnValue().isAvaya',response.getReturnValue());
            console.log('partnerContractAttachmentList>' +component.get('v.partnerContractAttachmentList'));
            component.set('v.isAvaya',response.getReturnValue()[0].isAvaya);
            component.set('v.legalInputsDisplay',true);
            component.set('v.isContractTeam',response.getReturnValue()[0].isContractTeam);
            component.set("v.communityDetailsRecord", response.getReturnValue()[0].communityDetailsRecord);
            console.log('comm details>'+JSON.stringify(component.get("v.communityDetailsRecord")));
            //playbook changes start
            console.log('objDS--'+JSON.stringify(response.getReturnValue()[0].objDS));
            console.log('partnerContractWrapperList initial--'+JSON.stringify(component.get("v.partnerContractWrapperList")));
            var wrapperList=component.get("v.partnerContractWrapperList");
                    console.log('objDS--'+JSON.stringify(response.getReturnValue()[0].objDS));
                    if(response.getReturnValue()[0].objDS != undefined &&response.getReturnValue()[0].objDS!=null &&response.getReturnValue()[0].objDS!=null){
                        if(response.getReturnValue()[0].objDS.Status__c=='Closed-Approved' && (response.getReturnValue()[0].objDS.Promo_Code__c =='MIGRATE' || response.getReturnValue()[0].objDS.Promo_Code__c=='DEALDESK')){
                            component.set("v.show2MonthFreeCredit",true);
                        }
                    }
                    console.log('show2MonthFreeCredit--'+component.get("v.show2MonthFreeCredit"));
            if(wrapperList !=undefined && wrapperList !=null && wrapperList!=''){
            for (var i = wrapperList.length - 1; i >= 0; i--) 
                    {     
                        console.log('wrapperListnew--'+(wrapperList[i].term));
                        console.log('index--'+wrapperList.indexOf(i));
                        console.log('legth>>'+wrapperList.length);
                        if(wrapperList[i].term =='Free Services (Credit) 2 month' || wrapperList[i].term=='2 Month Free Services (by way of a credit)'){
                            console.log('index inside--'+wrapperList.indexOf(i));
                            if(component.get("v.show2MonthFreeCredit") == false){
                                //wrapperListfinal.push(wrapperList[wrapper]);
                                //continue;
                                var index=wrapperList.indexOf(i);
                                wrapperList.splice(i, 1);
                                console.log('wrapperList logix>'+JSON.stringify(wrapperList));
                                 console.log('legth>>'+wrapperList.length);
                               // component.set("v.partnerContractWrapperList",wrapperList);
                               // break;
                                 console.log('wrapperList logix>'+JSON.stringify(wrapperList));
                                console.log('legth>>'+wrapperList.length);

                            }else{
                                console.log('inside 2 mnth show true');
                                wrapperList[i].isSelected=true;
                                component.set("v.partnerContractWrapperList",wrapperList);
                            }
                            console.log('terms>>'+wrapperList[i].term);
                        }
                        
                    }
                   component.set("v.partnerContractWrapperList",wrapperList);
            }
              //playbook changes ends

        },'SUCCESS');
        $A.enqueueAction(action,false);
        }
        catch(e)
        {
            console.log('error - ' + e);
        }        
	}, 
    getExistingPartnerContractDetails : function(component) {		       
		var action = component.get('c.getPartnerContractDetails');
        var partnerQuoteId = component.get('v.partnerQuoteId');
        var isUpdate = component.get('v.isUpdateDetailClicked');
        action.setParams({"partnerQuoteId" : partnerQuoteId});
		console.log('inside not update');         
        action.setCallback(this,function(response){
            console.log('response.getReturnValue()>>',response.getReturnValue());
            console.log('isUpdate',isUpdate);
            var responseReceived = response.getReturnValue();   
             console.log('responseReceived>>>',responseReceived); 
            if(responseReceived != null && responseReceived != undefined)
            {
                console.log('responseReceived>>>',responseReceived);
                if(responseReceived.existingApprovalRec) {
                    if(responseReceived.existingApprovalRec.Standard_Terms__c) {
                        component.set("v.isStandard",true);
                    } else {
                        component.set("v.isStandard",false);
                    }
                    console.log(responseReceived.existingApprovalRec);
                    component.set('v.objApprovalRec',responseReceived.existingApprovalRec);
                }
                
				if(isUpdate == true)
                {
                    component.set('v.legalInputsDisplay',true);
                    
                    component.set('v.partnerContractTypeWrapperList',responseReceived.lstPartnerContractTypeWrapper);
                    component.set('v.partnerContractWrapperList',responseReceived.lstPartnerContractWrapper); 
                    component.set('v.inputWrapper',responseReceived.inputWrapper);
                    component.set('v.partnerContract',responseReceived.partnerContract);
                    var contractType = responseReceived.partnerContract.Contract_Type__c;
                    if(contractType != undefined)
                    {
                        if(contractType == 'Standard')
                        {
                            component.set('v.standardMSAOptionValue','Yes');
                        }
                        else
                        {
                            component.set('v.standardMSAOptionValue','No');
                        }
                    }                 
                    component.set('v.nonStandardInputValue',responseReceived.partnerContract.Inputs_for_Legal__c);
                    component.set('v.standardDisplay',false);
                    component.set('v.initialDisplay',true);
                    component.set('v.nonStandardDisplay',false);
                    component.set('v.playBookDisplay',false);
                    component.set('v.partnerContractCreated',false);
                    component.set('v.partnerContractApprovalSubmitted',false);
                    component.set('v.partnerContractApprovalRecalled',false);
                    component.set('v.partnerContractApprovalApproved',false);
                    component.set('v.partnerContractApprovalRejected',false);
                    component.set('v.partnerContractId',responseReceived.partnerContract.Id);
                    console.log('responseReceived.pcsList>>',responseReceived.pcsList);
                    if(responseReceived.pcsList.length > 0)
                    	component.set('v.partnerContractServiceList',responseReceived.pcsList);
                    component.set('v.isAvaya',responseReceived.isAvaya);
                    component.set('v.isContractTeam',responseReceived.isContractTeam);
                    component.set('v.avayaLegalComments',responseReceived.partnerContract.Avaya_Legal_Comments__c);
                    component.set("v.communityDetailsRecord", responseReceived.communityDetailsRecord);
                    console.log('comm details>'+JSON.stringify(component.get("v.communityDetailsRecord")));	
                    //playbook changes starts 
                    var wrapperList=responseReceived.lstPartnerContractWrapper;
                    if(responseReceived.objDS != undefined && responseReceived.objDS !=null && responseReceived.objDS !=null){
                        if(responseReceived.objDS.Status__c=='Closed-Approved' && (responseReceived.objDS.Promo_Code__c =='MIGRATE' || responseReceived.objDS.Promo_Code__c=='DEALDESK')){
                            component.set("v.show2MonthFreeCredit",true);
                        }
                    }
                    if(wrapperList !=undefined && wrapperList !=null && wrapperList!=''){
                    for (var i = wrapperList.length - 1; i >= 0; i--) 
                    {     
                        if(wrapperList[i].term =='Free Services (Credit) 2 month' || wrapperList[i].term=='2 Month Free Services (by way of a credit)'){
                            if(component.get("v.show2MonthFreeCredit") == false){
                                var index=wrapperList.indexOf(i);
                                wrapperList.splice(i, 1);
                            }else{
                                wrapperList[i].isSelected=true;
                                component.set("v.partnerContractWrapperList",wrapperList);
                            }
                        }
                        
                    }
                    component.set("v.partnerContractWrapperList",wrapperList);
                    }
                } //playbook changes ends
                else
                {  
                   
                    if(responseReceived.partnerContract.Status__c == 'Approved')
                    {
                        component.set('v.partnerContractApprovalApproved',true);
                        component.set('v.partnerQuoteAttachmentList',responseReceived.lstAttachments);
						if(responseReceived.lstAttachments != '')
                        {
                            component.set('v.displayAttachments',true);
                        }
                    }
                    else if(responseReceived.partnerContract.Status__c == 'Rejected')
                    {
                        component.set('v.partnerContractApprovalRejected',true);
                    }
                    else if(responseReceived.partnerContract.Status__c == 'Pending Approval')
                    {
                        component.set('v.partnerContractApprovalSubmitted',true);                        
                    } 
                    else if(responseReceived.partnerContract.Status__c == 'Recalled')
                    {
                        component.set('v.partnerContractApprovalRecalled',true);                        
                    } 
                    else
                    {
                        component.set('v.legalInputsDisplay',true);
                        component.set('v.standardDisplay',false);
                        component.set('v.playBookDisplay',false);
                        component.set('v.partnerContractCreated',false);
                        component.set('v.initialDisplay',true);
                        component.set('v.nonStandardDisplay',false);
                    }                    
                    component.set('v.partnerContractTypeWrapperList',responseReceived.lstPartnerContractTypeWrapper);
                    component.set('v.partnerContractWrapperList',responseReceived.lstPartnerContractWrapper); 
                    component.set('v.partnerContract',responseReceived.partnerContract); 
                    component.set('v.detailComments',responseReceived.partnerContract.Detail_Comments__c); 
                    component.set('v.approvalComments',responseReceived.partnerContract.Approval_Comments__c); 
                    component.set('v.partnerContractId',responseReceived.partnerContract.Id);
                    component.set('v.inputWrapper',responseReceived.inputWrapper);
                    console.log('v.inputWrapper>>',responseReceived.inputWrapper);
                    if(responseReceived.pcsList.length > 0 )
                    	component.set('v.partnerContractServiceList',responseReceived.pcsList);
                    else if(component.get('v.partnerContractServiceList').length == 0) {
                        this.addPartnerContractService(component);
                    }
                    component.set('v.playBookDisplay',true);
                    component.set('v.isAvaya',responseReceived.isAvaya);
                    component.set('v.isContractTeam',responseReceived.isContractTeam);
                    component.set('v.avayaLegalComments',responseReceived.partnerContract.Avaya_Legal_Comments__c);
                    component.set("v.communityDetailsRecord", responseReceived.communityDetailsRecord);
                    console.log('comm details>'+JSON.stringify(component.get("v.communityDetailsRecord")));
                    var contractType = responseReceived.partnerContract.Contract_Type__c;
                    component.set("v.contractType",contractType);
                    //playbook changes starts
                     var wrapperList=responseReceived.lstPartnerContractWrapper;
                     var wrapperListfinal=[];
                    if(responseReceived.objDS != undefined && responseReceived.objDS !=null && responseReceived.objDS !=null){
                        if(responseReceived.objDS.Status__c=='Closed-Approved' && (responseReceived.objDS.Promo_Code__c =='MIGRATE' || responseReceived.objDS.Promo_Code__c=='DEALDESK')){
                            component.set("v.show2MonthFreeCredit",true);
                        }
                    }
                     if(wrapperList !=undefined && wrapperList !=null && wrapperList!=''){
                  for (var i = wrapperList.length - 1; i >= 0; i--) 
                    {     
                        console.log('wrapperListnew--'+(wrapperList[i].term));
                        console.log('index--'+wrapperList.indexOf(i));
                        console.log('legth>>'+wrapperList.length);
                        if(wrapperList[i].term =='Free Services (Credit) 2 month' || wrapperList[i].term=='2 Month Free Services (by way of a credit)'){
                            if(component.get("v.show2MonthFreeCredit") == false){
                                var index=wrapperList.indexOf(i);
                                wrapperList.splice(i, 1);
                            }else{
                                wrapperList[i].isSelected=true;
                                component.set("v.partnerContractWrapperList",wrapperList);
                            }
                        }
                        
                    }
                   component.set("v.partnerContractWrapperList",wrapperList);
                     }
                     //playbook changes ends
                    if(contractType != undefined)
                    {
                        //alert(contractType);
                        if(contractType == 'Standard')
                        {
                            component.set('v.standardMSAOptionValue','Yes');
                        }
                        else
                        {
                            component.set('v.standardMSAOptionValue','No');
                        }
                    }
                    console.log('standardMSAValue>>existing',component.get('v.standardMSAOptionValue'));
                    console.log('partnerContractAttachmentList>' +component.get('v.partnerContractAttachmentList'));
                    component.set('v.nonStandardInputValue',responseReceived.partnerContract.Inputs_for_Legal__c);
                }
			}
            else
            {                
                component.set('v.initialDisplay',true);
                this.getPartnerContractTypes(component); 
            }
        },'SUCCESS');
        $A.enqueueAction(action,false);        
	},
    loadCustomMetaData : function(component) {
        try
        {
        var wrapperList = component.get('v.partnerContractWrapperList'); 
        var pcsList = component.get('v.partnerContractServiceList');
        for(var wrapper in wrapperList)
        {            
            var mappingWrapper = wrapperList[wrapper].mappingsWrapper;            
            for (var mapping in mappingWrapper)
            {                
                if(mappingWrapper[mapping].isSelectedOption == true)
                {					                   
                   component.find('OptionList')[wrapper].set('v.value',mappingWrapper[mapping].option);
                }                                
            }            
        }        
        if(wrapperList == '')
        {
           var action = component.get('c.getCustomMetaData');                 
            var PartnerQuoteId = component.get('v.partnerQuoteId'); 
            console.log('PartnerQuoteId '+ PartnerQuoteId);
            action.setParams({"PartnerQuoteId" : PartnerQuoteId});   
            action.setCallback(this,function(response){
                component.set('v.partnerContractWrapperList',response.getReturnValue());                        
            },'SUCCESS');
            $A.enqueueAction(action,false);            
        }
        console.log('I am in custom load',pcsList);
		if(pcsList == '')
        {
            console.log('I am in inside load',pcsList);
            this.addPartnerContractService(component);
        }
        }
        catch(e)
        {
            console.log('error - ' + e);
        }
	},
    handleApproval : function(component) {
		var partnerContractId = component.get('v.partnerContractId');        
		var action = component.get('c.submitForApproval'); 
        action.setParams({"partnerContractId" : partnerContractId});
        action.setCallback(this,function(response){
			if(response.getReturnValue() == 'Success')
            {
                component.set('v.partnerContractApprovalSubmitted',true);
                this.showToast('Success', 'Partner Contract submitted for approval', 'success'); 
            }
            else
            {
                this.showToast('Error', response.getReturnValue(), 'error'); 
            }
        },'SUCCESS');
        $A.enqueueAction(action,false);       
	},
    recallApproval : function(component) {
		var partnerContractId = component.get('v.partnerContractId');        
		var action = component.get('c.recallApprovalController');        
        action.setParams({"partnerContractId" : partnerContractId});
        action.setCallback(this,function(response){
			if(response.getReturnValue() == 'Success')
            {
                component.set('v.partnerContractApprovalRecalled',true);
            }
            else
            {
                this.showToast('Error', response.getReturnValue(), 'error'); 
            }
        },'SUCCESS');
        $A.enqueueAction(action,false);       
	}, 
    addPartnerContractService: function(component) {       
        var pcsList = component.get("v.partnerContractServiceList");        
        pcsList.push({
            'sobjectType': 'Partner_Contract_Service__c',
            'Minimum_Target__c': null,
            'Minimum_Target_Effective_Date__c': null            
        });
        component.set("v.partnerContractServiceList", pcsList);
    },
    
    submitToRC : function(component) {
        var action = component.get('c.createDealSupport');    
        var partnerQuoteId = component.get('v.partnerQuoteId');
        action.setParams({
            "partnerQuoteId" : partnerQuoteId
        });
        action.setCallback(this,function(response){
			if(response.getState() == "SUCCESS"){
                this.showToast('Success', 'Submitted to RC successfully !', 'Success');  
                component.set("v.dealSupportExists", true);
            }
            else{
                this.showToast('Error', response.getReturnValue(), 'error'); 
            }
        });
        $A.enqueueAction(action,false);       
	},
    
    checkForDealSupport : function(component) {
        try
        {
		var action = component.get('c.dealSupportExists');    
        var partnerQuoteId = component.get('v.partnerQuoteId');
        action.setParams({
            "partnerQuoteId" : partnerQuoteId
        });
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){
            	var dealSupportExists =	response.getReturnValue();
                component.set("v.dealSupportExists", dealSupportExists);
            }
        });
        $A.enqueueAction(action,false);
        }
        catch(e)
        {
            console.log('error - ' + e);
        }       
	},
	  //Translation Start
         getTranslations: function (component, event, helper) {
            try {
                function setTranslations(result) {
                    var state = result.getState();
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
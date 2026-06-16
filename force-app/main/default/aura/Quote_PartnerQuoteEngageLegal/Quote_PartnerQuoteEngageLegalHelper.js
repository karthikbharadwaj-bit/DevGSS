({
	addPartnerContractService: function(component) {       
        var pcsList = component.get("v.partnerContractServiceList");        
        pcsList.push({
            'sobjectType': 'Partner_Contract_Service__c',
            'Minimum_Target__c': null,
            'Minimum_Target_Effective_Date__c': null            
        });
        component.set("v.partnerContractServiceList", pcsList);
    },
    getPartnerContractTypes : function(component) {        
		var action = component.get('c.getPartnerContractTypes');        
        action.setCallback(this,function(response){
			component.set('v.partnerContractTypeWrapperList',response.getReturnValue());
              var resultData = result.getReturnValue(); 
           /* console.log('att list>' +resultData.attachmentTypesWrapper);
            for(var i=0;resultData.attachmentTypesWrapper.length;i++){
                 var row = resultData.attachmentTypesWrapper[i]; 
                if(row.Description=='Standard')
                    component.set("v.standardDesc",resultData.attachmentTypesWrapper);
                if(row.Description=='Non Standard')
                     component.set("v.nonStandardDesc",resultData.attachmentTypesWrapper);
                console.log('std list>>' +component.get("v.standardDesc"));
            }*/
            console.log('response.getReturnValue().isAvaya',response.getReturnValue());
            component.set('v.isAvaya',response.getReturnValue()[0].isAvaya);
        },'SUCCESS');
        $A.enqueueAction(action,false);        
	}, 
    getExistingPartnerContractDetails : function(component) {		       
		var action = component.get('c.getPartnerContractDetails');
        var partnerQuoteId = component.get('v.partnerQuoteId');
        var isUpdate = component.get('v.isUpdateDetailClicked');
        action.setParams({"partnerQuoteId" : partnerQuoteId});
		console.log('inside not update');         
        action.setCallback(this,function(response){
            var responseReceived = response.getReturnValue();   
            if(responseReceived != null && responseReceived != undefined)
            {
				if(isUpdate == true)
                {
                    component.set('v.partnerContractTypeWrapperList',responseReceived.lstPartnerContractTypeWrapper);
                    component.set('v.partnerContractWrapperList',responseReceived.lstPartnerContractWrapper); 
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
                    component.set('v.partnerContractServiceList',responseReceived.pcsList);
                    component.set('v.isAvaya',responseReceived.isAvaya);
                }
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
                        component.set('v.standardDisplay',false);
                        component.set('v.playBookDisplay',false);
                        component.set('v.partnerContractCreated',false);
                        component.set('v.initialDisplay',true);
                        component.set('v.nonStandardDisplay',false);
                    }                    
                    component.set('v.partnerContractTypeWrapperList',responseReceived.lstPartnerContractTypeWrapper);
                    component.set('v.partnerContractWrapperList',responseReceived.lstPartnerContractWrapper); 
                    component.set('v.partnerContract',responseReceived.partnerContract);                    
                    component.set('v.partnerContractId',responseReceived.partnerContract.Id);                        
                    component.set('v.partnerContractServiceList',responseReceived.pcsList);
                    component.set('v.isAvaya',responseReceived.isAvaya);
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
                    console.log('inpts for legal' +responseReceived.partnerContract.Inputs_for_Legal__c);
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
            action.setCallback(this,function(response){
                component.set('v.partnerContractWrapperList',response.getReturnValue());                        
            },'SUCCESS');
            $A.enqueueAction(action,false);            
        }
		if(pcsList == '')
        {
            this.addPartnerContractService(component);
        }
	},
    handleOptionChange : function(component) {
        var wrapperList = component.get('v.partnerContractWrapperList'); 
        for(var wrapper in wrapperList)
        {
            var mappingWrapper = wrapperList[wrapper].mappingsWrapper;          
            for (var mapping in mappingWrapper)
            {                
                if(mappingWrapper[mapping].option == component.find('OptionList')[wrapper].get('v.value'))
                {
                    if(wrapperList[wrapper].isGridInputNeeded == false)
                    {
                        document.getElementById(wrapperList[wrapper].term).innerHTML = mappingWrapper[mapping].text;
                        mappingWrapper[mapping].isSelectedOption = true;
                    }                    
                }
				else 
                {
                    mappingWrapper[mapping].isSelectedOption = false;
                }
            }            
        }
    },
    createPartnerContractRecords : function(component, event, helper)
    {     
        console.log('com>>'+component.get("v.avayaLegalComments"));
        console.log('ip com>>' +component.get('v.nonStandardInputValue'));
        var approvalRequired = true;
        var action = component.get('c.createPartnerContractRecords'); 
        var isStandardMSAorNot = true;
        var isNoStandardPlayBook = false;
        var wrapperParameter = component.get('v.partnerContractWrapperList');
        var wrapperTypeParameter = component.get('v.partnerContractTypeWrapperList');        
        var partnerQuoteId = component.get('v.partnerQuoteId');
        var partnerContractId = component.get('v.partnerContractId');
        console.log('wrapperTypeParameter>>>',wrapperTypeParameter[0].attachmentTypesWrapper);
        for( var objAttachment of wrapperTypeParameter[0].attachmentTypesWrapper) {
            if(objAttachment.isSelected && !objAttachment.isStandard) {
                isStandardMSAorNot = false;
            } 
        }

        for(var objPlayBook of wrapperParameter) {
            if(objPlayBook.approvalRequired == true){
                approvalRequired = true;
            }
            if(objPlayBook.isSelected)
            	isNoStandardPlayBook = true;
        }
        component.set("v.isNoStandardPlayBook",isNoStandardPlayBook);
        var nonStandardInputValue = component.get('v.nonStandardInputValue');
        if(nonStandardInputValue && !partnerContractId) {
            component.set('v.isOpenContractRequest',true);
        }
    
        if(nonStandardInputValue || !isStandardMSAorNot) {
           component.set('v.standardMSAOptionValue','No');
        }
        else {
            	component.set('v.standardMSAOptionValue','Yes');
        }
        var standardMSAOptionValue = component.get('v.standardMSAOptionValue');
        var isUpdate = component.get('v.isUpdateDetailClicked');
        var objApprovalRec = component.get('v.objApprovalRec');
        objApprovalRec.Partner_Quote__c = partnerQuoteId;
        var FileList = [];
        for(var objFile of component.get("v.sObjectAttachedFiles")) {
            FileList.push(objFile.Id);
        }
        
        
		var partnerContractServiceList = component.get('v.partnerContractServiceList');
        var contractType = component.get("v.contractType");
        console.log('objApprovalRec>>',objApprovalRec);
        action.setParams({"partnerContractWrapperString" : JSON.stringify(wrapperParameter),
                        "partnerContractTypeWrapperString" : JSON.stringify(wrapperTypeParameter),
                        "partnerQuoteId" : partnerQuoteId,
                          "isUpdate" : isUpdate,
                          "partnerContractId" : partnerContractId,
                          "lstPCS" : partnerContractServiceList,
                          "contractType" : contractType,
                          "inputsForLegal" : nonStandardInputValue,
                          "detailComments" : component.get('v.detailComments'),
                          "approvalComments" : component.get('v.approvalComments'),
                          "objNewApprovalRec"   : objApprovalRec,
                          "sObjectAttachedFiles" : FileList,
                          "currentTabId" : component.get("v.currentTabId"),
                          "inputValuesParameter" : JSON.stringify(component.get('v.inputWrapper')),
                          "avayaLegalComments":component.get("v.avayaLegalComments")
                         });        
        action.setCallback(this,function(response){
		   component.set("v.showCreateContractCMP",false);	             
           var responseReceived = response.getReturnValue(); 
            //alert(responseReceived);
           if(responseReceived.responseMessage == 'Success')
           {
               component.set("v.isPartnerContractExist",true);
               component.set("v.showCreateContractCMP",false);
               component.set('v.partnerContractCreated',true);
               component.set('v.playBookDisplay',true);
               component.set('v.legalInputsDisplay',false);
               component.set('v.initialDisplay',false);
               component.set('v.partnerContractId',responseReceived.partnerContractId);
			   component.set('v.partnerQuoteAttachmentList',responseReceived.lstAttachments);
               component.set('v.showSpinner',false);
               if(responseReceived.objApprovalRec) {
                   component.set('v.objApprovalRec',responseReceived.objApprovalRec);
               }
               if(responseReceived.lstAttachments != '')
               {
                   component.set('v.displayAttachments',true);
               }
			    this.showToast('Success', 'Partner Contract Details saved successfully!', 'success');               
           }
           else
           {
             this.showToast('Error', responseReceived.responseMessage, 'error');   
           }
        },'SUCCESS');
        $A.enqueueAction(action,false);                
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
    checkForDealSupportExist : function(component, event, helper) {
        var action = component.get('c.dealSupportExists');    
        var partnerQuoteId = component.get('v.partnerQuoteId');
        action.setParams({
            "partnerQuoteId" : partnerQuoteId
        });
        
        action.setCallback(this,function(response){
           if(response.getState() == "SUCCESS"){
            	var dealSupportExists =	response.getReturnValue();
                component.set("v.isOpenContractRequest", dealSupportExists);
            }
        });
        
        $A.enqueueAction(action);       
	},
})
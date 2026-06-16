({
    getFilesWrap : function(id_str, component, event, helper)
    {
        try
        {
        var resultData1;
        var action1 = component.get("c.getUserRecordAccess");
        action1.setParams({
            "DealSupportRecordId":id_str
        });
        action1.setCallback(this, function(result) {			            
            resultData1 = result.getReturnValue(); 
            component.set("v.recordAccess",resultData1);
            console.log("HasReadAccess - " + component.get("v.recordAccess.HasReadAccess"));
            console.log("HasEditAccess - " + component.get("v.recordAccess.HasEditAccess"));
            if(resultData1.HasReadAccess == true)
            {
                console.log("Inside If --");
                helper.getAttachments(component, event, helper);
                //helper.getuploadedFiles(component, event, helper);//commented for getting files uploaded from SF Lightning - starts
                helper.getAllAttachmentsForDeal(component, event, helper);//Added for getting files uploaded from SF Lightning
                helper.getuploadedFilesForLightning(component, event, helper);//Added for getting files uploaded from SF Lightning
                helper.getuploadedFilesForLightningFromOpp(component, event, helper);//Added for opp files
            }
            else
            {
                console.log("Inside else --");
                component.set("v.LightningFilesOppMessage", true);
                component.set("v.AttachmentsMessage", true);
                component.set("v.AttachmentsForDealMsg", true);
                component.set("v.LightningFilesMessage", true);
                component.set("v.ShowOppFilesMessage","Insufficient Privilege to View Record..");
                component.set("v.ShowFilesMessage","Insufficient Privilege to View Record..");
            }
        });
        $A.enqueueAction(action1);
        }
        catch(err) {
            console.log('err - '+ err.message);
        }
    },
    
    getuploadedFiles:function(component){
        var oppId=component.get("v.DealSupportRecord.Opportunity__c");
        var dealStatus=component.get("v.DealSupportRecord.Status__c");
        var action = component.get("c.getFiles");  
        action.setParams({  
            "recordId":component.get("v.recordID")  
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                var result = response.getReturnValue();           
                component.set("v.files",result);  
                console.log('getuploadedFiles - '+result);
                for (var i = 0; i < result.length; i++) {
                    var row = result[i]; 
                    if(row.Title==undefined ||row.Title=='')
                        row.Title='';
                    else
                        row.Title=row.Title+'.'+row.FileType;
                }
                if(result == undefined || result =='' ||result ==null)
                {
                    component.set("v.FilesMessage", true);
                    if(dealStatus=='Ready for Signature'){
                        component.set("v.ShowFilesMessage",'Upload Files for Signature');
                    }
                    
                    else{
                        component.set("v.ShowFilesMessage",'No Records found..');
                    }  
                } 
                else{
                    component.set("v.FilesMessage", false);
                }
            } 
            else{
                component.set("v.FilesMessage", true);
            }
        }); 
        
        $A.enqueueAction(action);  
    },
    
    //Method Added for getting files uploaded from SF Lightning
    getuploadedFilesForLightning:function(component){
        try
        {
        var oppId=component.get("v.DealSupportRecord.Opportunity__c");
        var dealStatus=component.get("v.DealSupportRecord.Status__c");
        var action = component.get("c.getFilesForLightning");  
        action.setParams({  
            "recordId":component.get("v.recordID")  
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                console.log('files retrieved');
                var result = response.getReturnValue();           
                component.set("v.Lightningfiles",result);  
                console.log('getuploadedFilesForLightning - '+result);
                for (var i = 0; i < result.length; i++) {
                    var row = result[i]; 
                    if(row.Title==undefined ||row.Title=='')
                        row.Title='';
                    else
                        row.Title=row.Title+'.'+row.FileType;
                }
                if(result == undefined || result =='' ||result ==null)
                {
                    component.set("v.LightningFilesMessage", true);
                    if(dealStatus=='Ready for Signature'){
                        component.set("v.ShowFilesMessage",'Upload Files for Signature');
                    }                    
                    else{
                        component.set("v.ShowFilesMessage",'No Records found..');
                    }  
                } 
                else{
                    component.set("v.LightningFilesMessage", false);
                }
            } 
            else{
                component.set("v.LightningFilesMessage", true);
            }
            console.log('LightningFilesMessage '+component.get("v.LightningFilesMessage"));
        }); 
        
        $A.enqueueAction(action);  
        }
        catch(e)
        {
            console.log('getuploadedFilesForLightning error - '+e.message);
        }
    },
    
    //Method Added for getting files uploaded from SF Lightning
    getAllAttachmentsForDeal:function(component, event, helper){
        var dealStatus=component.get("v.DealSupportRecord.Status__c");
        var action = component.get("c.getAttachmentOppo");
        action.setParams({
            "recordId":component.get("v.recordID")
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                component.set("v.AttachmentsForDeal",resultData);
                console.log('getAllAttachmentsForDeal - '+resultData);
                if(resultData == undefined || resultData =='' ||resultData ==null){
                    component.set("v.AttachmentsForDealMsg", true);
                    if(dealStatus=='Ready for Signature'){
                        component.set("v.ShowFilesMessage",'Upload Files for Signature');
                    }else{
                        component.set("v.ShowFilesMessage",'No Records found..');
                    }  
                }
                else{
                    component.set("v.AttachmentsForDealMsg", false);
                }
            }
            else{
                component.set("v.AttachmentsForDealMsg", false);
            }
        });
        $A.enqueueAction(action); 	
    },
    getAttachments:function(component, event, helper){
        var oppId=component.get("v.DealSupportRecord.Opportunity__c");
        var dealStatus=component.get("v.DealSupportRecord.Status__c");
        var action = component.get("c.getAttachmentOppo");
        action.setParams({
            "recordId":oppId
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                component.set("v.Attachments",resultData);
                 console.log('getAttachments - '+resultData);
                if(resultData == undefined || resultData =='' ||resultData ==null){
                    component.set("v.AttachmentsMessage", true);
                    component.set("v.ShowOppFilesMessage",'No Records found..');
                    
                }
                else{
                    //if(dealStatus=='Ready for Signature'){
                    var dealStatus=component.get("v.DealSupportRecord.Status__c");
                    if(dealStatus=='Ready for Signature'||dealStatus=='Signature Complete'||dealStatus=='Closed-Approved'){
                        component.set("v.AttachmentsMessage", false);
                    }
                    else{
                        component.set("v.AttachmentsMessage", true);
                        component.set("v.ShowOppFilesMessage",'Documents are available only for Pending Signature,Signature Complete and Closed Approved Status');
                    }
                }
            }
            else{
                
            }
        });
        $A.enqueueAction(action); 	
    },
    //Method Added for getting files uploaded from SF Lightning opportunity
    getuploadedFilesForLightningFromOpp:function(component){
        var oppId=component.get("v.DealSupportRecord.Opportunity__c");
        console.log('typeof oppId - ',typeof oppId);
        var action = component.get("c.getFilesForLightning");  
        action.setParams({  
            "recordId":oppId  
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                console.log('files retrieved');
                var result = response.getReturnValue();   
                console.log('getuploadedFilesForLightningFromOpp - ',result);
                component.set("v.LightningfilesOpp",result);  
                for (var i = 0; i < result.length; i++) {
                    var row = result[i]; 
                    if(row.Title==undefined ||row.Title=='')
                        row.Title='';
                    else
                        row.Title=row.Title+'.'+row.FileType;
                }
                var dealStatus=component.get("v.DealSupportRecord.Status__c");
                if(result == undefined || result =='' ||result ==null)
                {
                    component.set("v.LightningFilesOppMessage", true);
                    if(dealStatus =='Ready for Signature'){
                        component.set("v.ShowFilesMessage",'Upload Files for Signature');
                    }                    
                    else{
                        component.set("v.ShowFilesMessage",'No Records found..');
                    }  
                } 
                else{
                    var dealStatus=component.get("v.DealSupportRecord.Status__c");
                    if(dealStatus=='Ready for Signature'||dealStatus=='Signature Complete'||dealStatus=='Closed-Approved'){
                        component.set("v.LightningFilesOppMessage", false);
                    }
                    else{
                        component.set("v.LightningFilesOppMessage", true);
                        component.set("v.ShowOppFilesMessage",'Documents are available only for Pending Signature,Signature Complete and Closed Approved Status');
                    }
                }
            } 
            else{
                component.set("v.LightningFilesOppMessage", true);
            }
            console.log('LightningFilesOppMessage '+component.get("v.LightningFilesOppMessage"));
        }); 
        
        $A.enqueueAction(action);  
    },
    changeStatus:function(component, event, helper) {
        var action = component.get("c.updateQuoteStatus");  
        action.setParams({  
            "DealSupportRecordId":component.get("v.recordID") ,
            "PartnerQuote":component.get("v.DealSupportRecord.Partner_Quote__r.Id"),
            "SelButton":event.getSource().getLocalId()
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS' && response.getReturnValue() == 'SUCCESS'){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                   // 'url': '/partner/s/dealsupport?id='+component.get("v.recordID")
                    'url': window.location.pathname +'?id=' +component.get("v.recordID")
                });
                urlEvent.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Status updated successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                
            }
            else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There was some error during status update",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });  
        $A.enqueueAction(action);  
    },
    reloadDealSupport:function(component, event, helper) {
        var action = component.get("c.ReloadDealSupport");
        action.setParams({
            "DealSupportRecordId":component.get("v.recordID"),
        });
        action.setCallback(this, function(result) {	
            var state = response.getState(); 
            if(state=='SUCCESS'){
                var resultData = result.getReturnValue();                
                component.set("v.DealSupportRecord", resultData);
                component.set("v.ShowEditSection",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Deal Support Status updated successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showAssignToRCButton : function(component, event, helper) {
        var dealSupportType = component.get("v.DealSupportRecord").Type__c;
        if(dealSupportType = 'POC Request'|| dealSupportType == 'Discount Request' || dealSupportType == 'Initial Order' || dealSupportType == 'New Contract Request' || dealSupportType == 'Lead Conversion'){
            var action = component.get("c.getShowAssignToRCButton");  
            action.setParams({  
                "dealSupportId" : component.get("v.recordID"),
                
            });      
            action.setCallback(this,function(response){  
                var state = response.getState();  
                if(state == 'SUCCESS'){
                    var result = response.getReturnValue();
                    component.set("v.showAssignToRCButton", result);
                    console.log('showAssignToRCButton>'+ component.get("v.showAssignToRCButton"));
                }
            });
            $A.enqueueAction(action);
        }
        else{
            component.set("v.showAssignToRCButton", false);
        }
        
    },
    
    updateOwnerQueue : function(component, event, helper) {
        var action = component.get("c.updateDSOwner");  
        action.setParams({  
            "dealSupportId" : component.get("v.recordID") ,
            "dealSupportType" : component.get("v.DealSupportRecord").Type__c
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){
                component.set("v.showAssignToRCButton", false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Deal Support assigned to RC.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                component.set("v.ShowRecordDetail", false);
                component.set("v.ShowListView", true);
                component.set("v.ShowNewSection", false);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    //'url': '/partner/s/dealsupport'
                    'url':window.location.pathname
                });
                urlEvent.fire();
                
            }
            
        });
        $A.enqueueAction(action);
    },
    editDealSupport:function(component, event, helper) {
        component.set("v.ShowSpinnerDeal",true);
        console.log('++proserv '+component.get("v.availProServ"));
        var action = component.get("c.updateDealSupportList");
        console.log("type"+component.get("v.DealSupportRecord.Partner_ProServ__c"));
        console.log("type"+component.get("v.DealSupportRecord").Type__c);
        if(component.get("v.DealSupportRecord").Type__c ==  "Discount Request"&&
           (component.get("v.Discount") == '' || component.get("v.Discount") == null
            || (component.get("v.Discount") > 100 && component.get("v.DealSupportRecord").Discount__c > 0))){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": "Please enter a valid approved discount value",
                "mode":'dismissible'
            });
            toastEvent.fire();
        }else{
            action.setParams({
                "DealSupportRecordId":component.get("v.recordID"),
                "Status":component.get("v.selectedStatusValue"),
                "Discount":component.get("v.Discount"),
                "engageProServ":component.get("v.availProServ"),
            });
            action.setCallback(this, function(result) {	
                 var state = result.getState(); 
               
               if(state== "SUCCESS"){
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    //'url': '/partner/s/dealsupport?id='+component.get("v.recordID")
                    'url': window.location.pathname +'?id=' +component.get("v.recordID")
                });
                urlEvent.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "The status has been updated successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
               }
                else{
                urlEvent.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "There is some error during procesing.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }
    },
    updateDealSupport:function(component, event, helper) {
        var dealSupportRec = component.get("v.DealSupportRecord");
        dealSupportRec.Id = component.get("v.recordID");
        dealSupportRec.POC_Conversion_to_Paid_Requested__c = true;
        var action = component.get("c.updateDealSupportPocCheckbox");
        action.setParams({
            "DealSupportRecord":component.get("v.DealSupportRecord")
        });
        action.setCallback(this, function(result) {	
            var resultData = result.getReturnValue();                
            component.set("v.DealSupportRecord", resultData);
        });
        
        $A.enqueueAction(action);
    },
    
    updateContractsAttachments:function(component, event, helper,accountId) {
        var action = component.get("c.updateContractsAttachmentFiles");
        action.setParams({
            "DealSupportRecord":component.get("v.DealSupportRecord"),
            "dealSupportFiles":component.get("v.files"),
            "accountId":accountId
        });
        action.setCallback(this, function(result) {	
            var state = response.getState();  
            var resultData = result.getReturnValue();   
            if(state=='SUCCESS'){               
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Files moved to contract successfully.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
            
            
        });
        $A.enqueueAction(action);
    },
    assignToAvayaDealDesk:function(component, event, helper) {
        console.log('component.get("v.DealSupportRecord").Id'+component.get("v.DealSupportRecord").Id);
        var action = component.get("c.updateDSOwnerQueue");  
        action.setParams({  
            "dealSupportId" : component.get("v.DealSupportRecord").Id
            
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            console.log('state'+state);
            console.log('ds rec*'+response.getReturnValue());
            if(state=='SUCCESS'){
                component.set("v.DealSupportRecord", response.getReturnValue());
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success!",
                    "message": "Deal Support assigned to Avaya Deal Desk Queue.",
                    "mode":'dismissible'
                });
                toastEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    }
})
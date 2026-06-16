({
    getCaseList: function(component, pageNumber, pageSize) {
        try
        {
            var action = component.get("c.getListView");        
            action.setParams({
                "searchKeyWord": component.get("v.searchKeyword"),
                "searchBy": component.get("v.searchBy"),
                "pageNumber": pageNumber, 
                "pageSize":pageSize
            });
            action.setCallback(this, function(result) {            
                var state = result.getState();
                console.log('isValid - '+ component.isValid());
                if (component.isValid() && state === "SUCCESS"){
                    console.log('inside success');
                    var resultData = result.getReturnValue();
                    var data = resultData.caseList;
                    component.set("v.caseList", resultData.caseList);
                    component.set("v.pageNumber", resultData.pageNumber);
                    component.set("v.totalRecords", resultData.totalRecords);
                    component.set("v.recordStart", resultData.recordStart);
                    component.set("v.recordEnd", resultData.recordEnd);
                    console.log('pageSize - '+ pageSize);
                    component.set("v.totalPages", Math.ceil(resultData.totalRecords / pageSize));
                }
                else
                {
                    console.log('state - '+ state);
                }
                
                if (data == undefined || data == '' || data == null) {
                    component.set("v.Message", true);
                } else {
                    component.set("v.Message", false);
                } 
                
            });        
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('error - '+e);
        }
    },
    
     //Translation Start
    getTranslations : function (component, event, helper) 
    {
        try
        {
            var action = component.get("c.getTranslations");
            action.setParams({
                "objNames": 'Case'
            });
            action.setCallback(this, function (result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if(resultData != undefined && resultData != null && resultData != '')
                    {
                        if(resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null && 
                           resultData.allObjFieldsMap != '')
                        {
                            component.set("v.caseFieldsMap", resultData.allObjFieldsMap.Case);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            });
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('err - ' + e);
        } 
    },
     //Translation End
    
    getSelectedCase : function(component, id ) {
        try
        {
            var action = component.get("c.getSelectedCase"); 
            console.log('caseId - '+ id);
            action.setParams({
                "caseId": id
            });
            action.setCallback(this, function(result) {            
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var resultData = result.getReturnValue();
                    console.log('resultData - '+resultData);
                    component.set("v.caseRec", resultData);
                }                
            });        
            $A.enqueueAction(action);
        }
        catch(e)
        {
            console.log('error - '+e);
        }
    },
    
    getAttachments :function(component, id){
        var action = component.get("c.getAttachments");
        action.setParams({
            "recordId": id
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                component.set("v.Attachments",resultData);
                console.log('getAttachments - '+resultData);
                if(resultData == undefined || resultData =='' ||resultData ==null)
                {
                    component.set("v.AttachmentsMessage", true);
                    
                }
                else
                {
                    component.set("v.AttachmentsMessage", false);
                }
            }
        });
        $A.enqueueAction(action); 	
    },
    
    getLightningFiles :function(component, id){
        var action = component.get("c.getLightningFiles");  
        action.setParams({  
            "recordId" : id  
        });      
        action.setCallback(this,function(response){  
            var state = response.getState();  
            if(state=='SUCCESS'){ 
                console.log('files retrieved');
                var result = response.getReturnValue();   
                console.log('getLightningFiles - ',result);
                component.set("v.Lightningfiles",result);  
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
                } 
                else
                {
                    component.set("v.LightningFilesMessage", false);
                }
            } 
            else
            {
                component.set("v.LightningFilesMessage", true);
            }
            console.log('LightningFilesMessage '+component.get("v.LightningFilesMessage"));
        });
        $A.enqueueAction(action);  
    },
    
    getComments :function(component, id){
        var action = component.get("c.getCaseComments");
        action.setParams({
            "recordId": id
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                component.set("v.caseComments",resultData);
                console.log('getCaseComments - '+resultData);
                if(resultData == undefined || resultData =='' ||resultData ==null)
                {
                    component.set("v.caseCommentsMessage", true);
                    
                }
                else
                {
                    component.set("v.caseCommentsMessage", false);
                }
            }
        });
        $A.enqueueAction(action); 	
    },
    
    getEmails :function(component, id){
        var action = component.get("c.getCaseEmails");
        action.setParams({
            "recordId": id
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                console.log('typeof resultData - '+ typeof resultData);
                var resultData = resultData.map(myFunction);
                function myFunction(email) 
                {
                    console.log('email - '+email);
                    console.log('email.Subject - ' + email.Subject);
                    email.Subject = email.Subject.substring(0, email.Subject.indexOf("[ ref:"));
                    return email;
                }
                component.set("v.caseEmails",resultData);
                console.log('getCaseEmails - '+resultData);
                if(resultData == undefined || resultData =='' ||resultData ==null)
                {
                    component.set("v.caseEmailsMessage", true);
                    
                }
                else
                {
                    component.set("v.caseEmailsMessage", false);
                }
            }
        });
        $A.enqueueAction(action); 	
    },
    
    getCaseEmail :function(component, id){
        var action = component.get("c.getCaseEmail");
        action.setParams({
            "recordId": id
        });
        action.setCallback(this, function(result) {			            
            var state = result.getState();
            if (state === "SUCCESS"){
                var resultData = result.getReturnValue(); 
                if(resultData.emailMessage.Subject != undefined)
                {
                    resultData.emailMessage.Subject = resultData.emailMessage.Subject.substring(0, resultData.emailMessage.Subject.indexOf("[ ref:"));
                }
                if(resultData.emailMessage.TextBody != undefined)
                {
                    resultData.emailMessage.TextBody = resultData.emailMessage.TextBody.substring(0, resultData.emailMessage.TextBody.indexOf("ref:"));
                }
                if(resultData.emailMessage.HtmlBody != undefined)
                {
                    resultData.emailMessage.HtmlBody = resultData.emailMessage.HtmlBody.substring(0, resultData.emailMessage.HtmlBody.indexOf("ref:"));
                }
                component.set("v.caseEmail",resultData);
                console.log('getCaseEmail - '+resultData);
                component.set("v.showSelectedEmail", true); 
                if((resultData.emailAttachments == undefined || resultData.emailAttachments == '' || resultData.emailAttachments == null)
                  && (resultData.emailFiles == undefined || resultData.emailFiles == '' || resultData.emailFiles == null))
                {
                    component.set("v.caseEmailMessage", true);
                }
                else
                {
                    component.set("v.caseEmailMessage", false);
                }
            }
        });
        $A.enqueueAction(action); 
    }
    
})
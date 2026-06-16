({
   
    doInitHelper : function(component,event){
       
        component.set('v.columns',[
            {
                label : 'Action',
                fieldName : 'workItemId',
                type : 'url',
                typeAttributes : {label:{fieldName:'workItemName'},target:'_blank'}
            },
            {
                label : 'Related To',
                fieldName : 'recordId',
                type : 'url',
                typeAttributes : {label:{fieldName:'recordName'},target:'_blank'}
            },
            
            {
                label : 'Type',
                fieldName : 'relatedTo',
                type : 'text',
                sortable : true
            },
            {
                label : 'Most Recent Approver',
                fieldName : 'submittedBy',
                type : 'text',
                sortable : true
            },
            {
                label : 'Submitted date',
                fieldName : 'submittedDate',
                //type : 'date',
                //typeAttributes : {year:"2-digit",month:"short",day:"2-digit"},
                type : 'text',
                sortable : true
            }
        ]);
        
        var isViewAll = component.get("v.viewAllBool");
        if(!isViewAll)
        	this.getData(component,event,false,5);
        else
            this.getData(component,event,true,0);
    },
    
  
    getData : function(component,event,viewAllFlag,intLimit){
        
        var spinner = component.find("spinnerId");
        $A.util.toggleClass(spinner, "slds-hide");
        var toastRef = $A.get('e.force:showToast');
        var selected=[];
        var action = component.get('c.getSubmittedRecords');
        action.setParams({            
            "viewAllFlag" : viewAllFlag,
            "intLimit" : intLimit             
        });
        
        action.setCallback(this,function(response){
            var state = response.getState();
            console.log('state : ' + state);
            
            if(state == 'SUCCESS'){
                var records = response.getReturnValue();
                console.log('res'+JSON.stringify(records));
                records.forEach(function(record){
                   record.recordId = '/'+record.recordId;
                   record.workItemId = '/'+record.workItemId;
                });
                
                component.set('v.data',records);
            }else{
                var errors = response.getError();
                var errorMessage = '';
                if (errors && Array.isArray(errors) && errors.length > 0) {
        			errorMessage = errors[0].message;
    			}
                console.log('errorMessage : ' + errorMessage);
                toastRef.setParams({
                        'type' : 'error',
                        'title' : 'Error',
                        'message' : 'An Internal error has occured while loading items to approve.',
                        'mode' : 'sticky'
                });
                toastRef.fire();
            }
            
            $A.util.toggleClass(spinner, "slds-hide");
        });
        $A.enqueueAction(action);
    },
    
    //Method to handle sorting of records
    handleSortingOfRows : function(component,event,helper){
        //Set field name and direction of sorting
        var sortedBy = event.getParam('fieldName');
        var sortedDirection = event.getParam('sortDirection');
        component.set('v.sortedBy',sortedBy);
        component.set('v.sortDirection',sortedDirection);
        this.sortRecords(component,event,helper,sortedBy,sortedDirection);
    },
    
    //Method to handle sorting of records
    sortRecords : function(component,event,helper,sortedBy,sortedDirection){
        var records = component.get('v.data');
         var key = function(records) { return records[sortedBy]; }
        var reverse = sortedDirection == 'asc' ? 1: -1;
              records.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        
        //set sorted data to accountData attribute
        component.set("v.data",records);
        /*var direction = sortedDirection == 'asc' ? 1 : -1;
        var fieldValue = function(record){ return record[sortedBy]; }//returns the field value(field used for sorting) for each record
        records.sort(function(record1,record2){
            var fieldValue1 = fieldValue(record1);
            var fieldValue2 = fieldValue(record2);
            return direction * (fieldValue1 > fieldValue2) - (fieldValue2 > fieldValue1);//For asc,return value of -1 sorts the record,1 or 0 keeps the order intact.
        });
        component.set('v.data',records);*/
    },
    
    //Method to enable or disable Approve and Reject button
    handleRowSelection : function(component,event,helper){
        var select =[];
        var rowsSelected = event.getParam('selectedRows');
         for ( var i = 0; i < rowsSelected.length; i++ ) {
            
            select.push(rowsSelected[i].workItemId);
         }
        component.set("v.selectedRows",select);

        console.log('rowsSelected'+ JSON.stringify(rowsSelected));
        if(rowsSelected.length > 0){
            component.find('approvalButtonId').set('v.disabled',false);
            component.find('rejectButtonId').set('v.disabled',false);
        }
        else{
            component.find('approvalButtonId').set('v.disabled',true);
            component.find('rejectButtonId').set('v.disabled',true);
        }
    },
    
    //Method to Approve or Reject the selected records
    processSelectedRecords : function(component,event,helper,processType){
        //To approve, reject selected records based on 'processType' variable
        component.find('approvalButtonId').set('v.disabled',true);
        component.find('rejectButtonId').set('v.disabled',true);
        component.set('v.loaded',true);
        var selectedRows = component.get('v.selectedRows');
        
        console.log('processType'+processType);
        console.log('selectedRows'+selectedRows);
        console.log('???'+component.get('v.selectedRows'))
        var action = component.get('c.processRecords');//Calling server side method with selected records
        action.setParams({
            lstWorkItemIds : selectedRows,
            processType : processType
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            var toastRef = $A.get('e.force:showToast');
            if(state == 'SUCCESS'){
                var message = response.getReturnValue();
                if(message.includes('success')){
                    toastRef.setParams({
                        'type' : 'success',
                        'title' : 'Success',
                        'message' : message,
                        'mode' : 'dismissible'
                    });
                }
                else{
                   toastRef.setParams({
                        'type' : 'error',
                        'title' : 'Error',
                        'message' : message,
                        'mode' : 'sticky'
                    });
                }
                toastRef.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    //navigate to same component for View All Mode
    navigateToViewAllMode : function(component, event, helper) {
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:Homepage_ItemstoApprove",
                componentAttributes: {
                    viewAllData : component.get("v.viewAllData"),
                    viewAllBool : component.get("v.viewAllBool")
                },
                isredirect : true
            });
            evt.fire();
    }
})
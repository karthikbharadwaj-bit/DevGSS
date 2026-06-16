({
    doEdit : function(component, event, acr) {
        var accId = component.get("v.accountId");
        var action = component.get('c.editContactRole');
        action.setParams({
            'acrId' : acr
        })
        action.setCallback(this,function(response) {
            var state = response.getState();  
            if(state === 'SUCCESS'){
                var retResponse = JSON.parse(response.getReturnValue());
                
                var acrId = acr;
                var cId = retResponse.cId;
                var role = retResponse.role;
                var is_prim = retResponse.primary;
                if(acrId != '' && acrId != null && acrId != undefined) {
                    var url = new URL(location.href);
                    var baseURL = url.href.substring(0, url.href.indexOf("/s"));
                    var vfurl='/apex/AccountContactRoleCreation?accId='+ accId+'&contactId='+cId+
                        '&role='+role+'&isPrimary='+is_prim+'&crId='+acrId;
                    window.open(vfurl);                    
                }
                
            }
        });
    $A.enqueueAction(action);
     
 },
 doDelete : function(component, event, acr){
    var action = component.get('c.deleteContactRole');
    var validationState = component.get("v.validateState");
    if (validationState === false) {
        action.setParams({
            'acrId' : acr
        })
        action.setCallback(this,function(response) {
            var state = response.getState();  
            if(state === 'SUCCESS'){
                if(response.getReturnValue() == 'success') {
                    window.location.reload();
                    alert('Contact Role has been deleted successfully');               
                } else {
                    alert('There is some error while processing');
                }
            }
        });
        $A.enqueueAction(action);
    }
},
 
 validateAccountContactRole :  function(component, event, acr){
     var action = component.get('c.validateContactRole');
     action.setParams({
         'acrId' : acr
     })
     action.setCallback(this,function(response) {
         var state = response.getState();  
         if(state === 'SUCCESS'){
             if (response.getReturnValue()) {
                 component.set("v.validateState" , true);
                 alert('You cannot delete this Contact Role because it is used on the Approval');
             } else {
                 component.set("v.validateState" , false);
                 this.doDelete(component, event, acr);
             }
         }
     });
     $A.enqueueAction(action);

 }
})
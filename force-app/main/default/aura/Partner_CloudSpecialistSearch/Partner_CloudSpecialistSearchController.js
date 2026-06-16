({  
	onInputChange : function (component, event, helper) {
        var searchContent = component.get("v.searchUser");
        var userPaneCmp = component.find("userPane");
        var dropDownPane = component.find("dropDownList");
        console.log('searchContent'+searchContent);
        if ( searchContent && searchContent.trim().length > 0 ) {
            searchContent = searchContent.trim();
            $A.util.addClass(userPaneCmp,"slds-is-open");
            $A.util.removeClass(userPaneCmp,"slds-is-close");
            //$A.util.addClass(dropDownPane,"slds-is-open");
            //$A.util.removeClass(dropDownPane,"slds-is-close");
            helper.searchUsers(component,event, helper,searchContent);
        } else {
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
        }
        
    },
    
    selectedUser: function (component, event, helper) {
        var ctarget = event.currentTarget;
        //var selectedUserName = ctarget.dataset.username;
        var selectedContactId = ctarget.dataset.contactid;
        var selectedContactName = ctarget.dataset.contactname;
        //console.log('selectedUserName>'+selectedUserName);
        console.log('selectedContactId>'+selectedContactId);
        console.log('selectedContactName>'+selectedContactName);
        if(selectedContactName !=undefined && selectedContactName !=null && selectedContactName !=''){
            var userPaneCmp = component.find("userPane");
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
            component.set("v.searchUser",selectedContactName);
            console.log('user set>' +component.get("v.searchUser"));
            var cmpEvent = component.getEvent("cloudSpecialistValueEvent");   
            cmpEvent.setParams({
            "cloudSpecialistContactId":selectedContactId,
            "cloudSpecialistContactName":selectedContactName
        });
            cmpEvent.fire();
           // component.destroy();
        }else{
            var userPaneCmp = component.find("userPane");
            $A.util.removeClass(userPaneCmp,'slds-is-open');
            $A.util.addClass(userPaneCmp,'slds-is-close');
        }
    },
    
    hideOnBlur: function (component, event, helper) {
        console.log('inside blur');
        var userPaneCmp = component.find("userPane").getElement();
          var userPaneCmp1 = component.find("usersearch");
        userPaneCmp.focus();
        //var userr=userPaneCmp.focus();
        console.log('userr focus>'+userPaneCmp);
        console.log('event.getSource().get("v.value").trim()>'+event.getSource().get("v.value").trim());
        console.log('event.currentTarget>'+event.currentTarget);
        
        
       // if(event.getSource().get("v.value").trim() == 0){
        //if(userr==undefined || userr=='' || userr== null){
              console.log('inside blur if');
            $A.util.removeClass(userPaneCmp1,'slds-is-open');
            $A.util.addClass(userPaneCmp1,'slds-is-close');
       
        //}/
        //
        //component.set("v.searchUser",null);
        //this.selectedUser(component, event, helper);
            /*var dropDownPane = component.find("dropDownList");
             * $A.util.removeClass(dropDownPane,'slds-is-open');
            $A.util.addClass(dropDownPane,'slds-is-close');*/
        
    }
})
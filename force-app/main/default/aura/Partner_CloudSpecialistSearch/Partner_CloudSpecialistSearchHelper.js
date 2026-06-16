({
	searchUsers : function(component,event, helper,searchContent) {
        console.log('name>'+searchContent);
        var action = component.get('c.getUsersForCloudSpecialist');
        action.setParams({
            "UserName":searchContent,
            "SFBrandName" : component.get("v.SFBrandName")
        });
        //pbc-10695
        action.setCallback(this,function(result){
            var state = result.getState();
            console.log('state>'+state);
            if(state=== "SUCCESS"){
                var resultData = result.getReturnValue(); 
                console.log('userList>'+JSON.stringify(resultData));
                console.log('user res length>'+resultData.length);
                if(resultData != undefined && resultData !=null && resultData !='' && resultData.length>0){
                    component.set("v.portalUserList",resultData);
                }
                else if( resultData.length==0){
                    component.set("v.portalUserList",null);
                    //component.set("v.searchUser",null);
                    var userPaneCmp = component.find("userPane");
                    setTimeout(function(){
                        $A.util.removeClass(userPaneCmp,'slds-is-open');
                        $A.util.addClass(userPaneCmp,'slds-is-close');
                        component.set("v.searchUser",null);
                    }, 1000);
                }
                console.log('user result>'+JSON.stringify(component.get("v.portalUserList")));
                /*else if(resultData == undefined || resultData ==null || resultData ==''){
                    $A.util.removeClass(userPaneCmp,'slds-is-open');
                    $A.util.addClass(userPaneCmp,'slds-is-close');
                     //component.set("v.portalUserList",'');
                }*/
            }
        });
        $A.enqueueAction(action);
    }
})
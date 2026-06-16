({
    init : function(component) {
        const action = component.get("c.getQueueMemberByQueueName"),
            groupIdParam = component.get("v.queueId"),
            helper = this;

        action.setParams({
            groupId: groupIdParam
        });

        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                const responseData = response.getReturnValue();
                if (responseData) {
                    component.set("v.users", helper.getUserNameString(responseData));
                }
            } else if(response.getState() === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                     if (errors[0] && errors[0].message) {
                         alert("Error message: " +
                                  errors[0].message);
                     }
                 } else {
                     console.log("Unknown error");
                 }
            }
        });

        $A.enqueueAction(action);
    },

    getUserNameString: function (listOfUsers) {
        let usersName = listOfUsers.map( user => user.Name);
        return usersName.join(", ");
    }
})
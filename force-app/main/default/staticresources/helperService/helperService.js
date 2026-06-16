window.helperService = {

    /*
     * Improving of standard calling apex methods;
     */
    request: function(component, helper, controller, params) {
        var p = new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get(controller);
            if(params) {
                action.setParams(params);
            }
            action.setCallback(helper, function(response) {
                if(response.getState() === 'SUCCESS') {
                    var res = response.getReturnValue();
                    if(res) {
                        resolve(res);
                    } else {
                        reject(res);
                    }
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        }));

        return p;
    },

}

// window.helperService = function(component) {
//     return window.helperService;
// }

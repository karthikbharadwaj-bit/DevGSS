({
    getBaseUrl : function (component) {
		var lang = document.documentElement.lang;
        this.request(component, "c.setLanguageForCoveoResultPage", {
            language: lang
        }).then (
            $A.getCallback(function(response) {
                if (response) {
                    component.set("v.baseUrl", response);
                }
            })
        ).catch (
            $A.getCallback(function(response) {
            })
        );
	},

	request: function(component, controller, params) {
        return new Promise(function (resolve, reject) {
            let action = component.get(controller);
            if (params) {
                action.setParams(params);
            }

            action.setCallback(null, function (response) {
                if (response.getState() === 'SUCCESS') {
                    let res = response.getReturnValue();
                    resolve(res);
                } else {
                    reject(response);
                }
            });
            $A.enqueueAction(action);
        });
    }
})
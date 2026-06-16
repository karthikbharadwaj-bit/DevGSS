({
    checkVisibility: function(component){
        RC.salesforce.request(component, 'c.getData', {
            oppId: component.get('v.recordId')
        })
        .then($A.getCallback(result => {
            const res = JSON.parse(result);
            component.set('v.isVisible', res.isDisplayMessage);

            if (res.isDisplayMessage) {
                component.set('v.Opportunity', res.opp);
            }
        }))
        .catch($A.getCallback(error => console.log('ERROR:', error)))
    },

})
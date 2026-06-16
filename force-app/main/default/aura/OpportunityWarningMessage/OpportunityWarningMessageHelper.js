({
    checkVisibility: function(component){
        RC.salesforce.request(component, 'c.getData', {
            oppId: component.get('v.recordId')
        })
        .then($A.getCallback(result => {
            const res = JSON.parse(result);
            component.set('v.message', res.message);

            if (res.message) {
                component.set('v.showComponent', true);
            }
        }))
        .catch($A.getCallback(error => console.log('ERROR:', error)))
    },

})
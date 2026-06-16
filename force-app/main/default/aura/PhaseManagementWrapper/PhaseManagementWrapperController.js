({
    afterScriptsLoaded: function(component, event, helper){
        component.set('v.order', {
            Id: component.get('v.orderId')
        });

      new Promise((resolve, reject) => {
        new Promise((resolve, reject) => {
          resolve(helper.getIsNewProservFlow(component));
        })
          .then(() => {
            if (component.get('v.isNewProservFlow')) {
              reject();
            } else {
              component.find('phaseManagement').startApp();
              resolve();
            }
          });
      })
        .catch((err) => {
          console.log(err);
        });

      Promise.all([
        helper.getOrder(component),
        helper.getUserPermissions(component),
        helper.getIsNewChangeOrder(component),
        helper.getRcVariousSettings(component),
        component.find('phaseManagement').reloadPhases(),
        component.find('phaseManagement').getPhaseTypePicklist(),
        component.find('phaseManagement').loadUserAccessInfo()
      ])
        .then($A.getCallback( function () {
          component.find('phaseManagement').discard();
        }))
        .catch((err) => {
          console.log(err);
        });
    },

    /**
     * User Clicked Expand Window button
     */
    openStandalone: function(component){
        window.open('/apex/phasemanagement?id='+ component.get('v.order.Id') +'&isStandalone=true', '_blank');
    },

    /**
     * User Clicked Discard Button
     */
    discard: function(component) {
        component.find('phaseManagement').discard();
    },

    /**
     * User Clicked Save Button
     */
    save: function(component) {
        component.find('phaseManagement').save();
    },
});
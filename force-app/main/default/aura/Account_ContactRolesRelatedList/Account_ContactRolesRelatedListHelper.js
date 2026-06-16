({
    doEdit : function(component, event, acr) {
      const accId = component.get('v.recordId');
      //get all parameters
      const action = component.get('c.editContactRole');
      action.setParams({
        'acrId' : acr
      });
      action.setCallback(this,function(response) {
        const state = response.getState();
        if (state !== 'SUCCESS') {
            return;
        }
        const retResponse = JSON.parse(response.getReturnValue());
        const cId = retResponse.cId;
        const role = retResponse.role;
        const is_prim = retResponse.primary;
        if (!acr) {
            return;
        }
        const url = new URL(location.href);
        const baseURL = url.href.substring(0, url.href.indexOf('/s'));
        const vfurl = baseURL +'/apex/AccountContactRoleCreation?accId=' + accId + '&contactId=' + cId +
        '&role=' + role + '&isPrimary=' + is_prim + '&crId=' + acr;
        const urlEvent = $A.get('e.force:navigateToURL');
        urlEvent.setParams({
          'url': vfurl,
          'isredirect': 'true'
        });
        urlEvent.fire();
      });
      $A.enqueueAction(action);
    },

    doDelete : function(component, event, acr){
      const validationState = component.get('v.validateState');
      const action = component.get('c.deleteContactRole');
      if (!validationState) {
        action.setParams({
          'acrId' : acr
        });
        action.setCallback(this,function(response) {
          const state = response.getState();
          if (state !== 'SUCCESS') {
              return;
          }
          if (response.getReturnValue() === 'success') {
            const toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
              'type': 'success',
              'title': 'Success!',
              'message': 'Contact Role has been deleted successfully',
              'mode':'dismissible'
            });
            toastEvent.fire();
            window.location.reload();
          } else {
            const toastEvent = $A.get('e.force:showToast');
            toastEvent.setParams({
              'type': 'error',
              'title': 'Error!',
              'message': 'There is some error while processing',
              'mode':'dismissible'
            });
            toastEvent.fire();
          }
       });
       $A.enqueueAction(action);
     }
    },

    validateAccountContactRole :  function(component, event, acr){
      const action = component.get('c.validateContactRole');
      action.setParams({
        'acrId' : acr,
      });
      action.setCallback(this,function(response) {
        const state = response.getState();
        if (state !== 'SUCCESS') {
            return;
        }
        if (response.getReturnValue()) {
          component.set('v.validateState' , true);
          const toastEvent = $A.get('e.force:showToast');
          toastEvent.setParams({
            'type': 'error',
            'title': 'Error!',
            'message': 'You cannot delete this Contact Role because it is used on the Approval',
            'mode':'dismissible'
          });
          toastEvent.fire();
        } else {
          component.set('v.validateState' , false);
          this.doDelete(component, event, acr);
        }
      });
      $A.enqueueAction(action);
    }
})
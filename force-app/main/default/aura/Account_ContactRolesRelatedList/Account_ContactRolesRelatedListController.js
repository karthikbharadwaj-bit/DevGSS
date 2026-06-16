({
    doInit : function(component) {
      const action = component.get('c.getAllContactRole');
      const accId = component.get('v.recordId');
      const accContactRoleArray = [];
      const header = 'Contact Roles';
      action.setParams({
          'accId' : accId
      });
      action.setCallback(this,function(response) {
        const state = response.getState();

        if (state !== 'SUCCESS') {
          return;
        }
        const retResponse = JSON.parse(response.getReturnValue());

        if (!retResponse) {
          return;
        }
        const rolesLength = retResponse.accountContactsList.length;
        if (rolesLength < 4) {
          component.set('v.headerTitle', header + ' ' + '(' + rolesLength + ')');
          component.set('v.ContactRolesList', retResponse.accountContactsList);

        } else {
          component.set('v.headerTitle', header + ' ' + '(' + '3+' + ')');
          component.set('v.viewAllFlag', true);
          for(let i = 0; i < 3; i++) {
            accContactRoleArray.push(retResponse.accountContactsList[i]);
          }
          component.set('v.ContactRolesList', accContactRoleArray);
        }
        //To check if the edit and delete access is present for the user

        component.set('v.deleteflag', retResponse.checkdeleteAccess);
        component.set('v.editflag', retResponse.checkeditAccess);
        component.set('v.createflag', retResponse.checkcreateAccess);

        component.set('v.accountRecord', retResponse.account);
        component.set('v.isCustomerAccount', retResponse.isCustomerAccount);
      });
      $A.enqueueAction(action);
    },

    addContactRole: function(component) {
      const account = component.get('v.accountRecord');
      const isCustomerAccount = component.get('v.isCustomerAccount');
      const url = new URL(location.href);
      const baseURL = url.href.substring(0, url.href.indexOf('/s'));
      const vfUrl= baseURL + '/apex/AccountContactRoleCreation?accId=' + account.Id + '&accName=' + account.Name + '&isCustomerAcc=' + isCustomerAccount;
      const urlEvent = $A.get('e.force:navigateToURL');
      urlEvent.setParams({
        'url': vfUrl,
        'isredirect': 'true'
      });
      urlEvent.fire();
    },

    navigateToRelatedList: function(component){
      const accId = component.get('v.recordId');
      const accName = component.get('v.accountRecord.Name');
      const url = new URL(location.href);
      const baseURL = url.href.substring(0, url.href.indexOf('/s'));
      const vfurl = baseURL + '/apex/AccountContactRoleListView?accId=' + accId + '&accName=' + accName;
      const urlEvent = $A.get('e.force:navigateToURL');
      urlEvent.setParams({
        'url': vfurl,
        'isredirect': 'true'
      });
      urlEvent.fire();
    },

    handleSelect: function(component, event, helper){
      const menuValue = event.detail.menuItem.get('v.label');
      const acr = event.detail.menuItem.get('v.value');
      switch(menuValue) {
        case 'Edit':
          helper.doEdit(component,event,acr);
          break;
        case 'Delete':
          helper.validateAccountContactRole(component, event, acr);
          break;
      }
    },

    //Methods to show and hide spinners
    showSpinner: function(component) {
      const spinner = component.find('loadingSpinner');
      $A.util.removeClass(spinner, 'slds-hide');
    },

    hideSpinner : function(component){
      const spinner = component.find('loadingSpinner');
      $A.util.addClass(spinner, 'slds-hide');
    }
})
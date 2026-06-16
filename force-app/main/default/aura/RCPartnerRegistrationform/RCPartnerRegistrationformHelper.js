({
  //Translation Start
  getTranslations: function (component, event, helper) {
    try {
      var action = component.get("c.getTranslations1");
      var selectedLanguage = component.get("v.selectedLanguageValue");
      action.setParams({
        "objNames": 'Partner_Request__c,Contact',
        "selectedLanguage": selectedLanguage
      });
      action.setCallback(this, function (result) {
        var state = result.getState();
        if (component.isValid() && state === "SUCCESS") {
          var resultData = result.getReturnValue();
          if (resultData != undefined && resultData != null && resultData != '') {
            if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
              resultData.allObjFieldsMap != '') {
              component.set("v.partnerrequestFieldsMap", resultData.allObjFieldsMap.Partner_Request__c);
            }
            component.set("v.translationsMap", resultData.prmLabelsMap);
            component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
            var yesval = component.get("v.translationsMap.Yes");
            var noval = component.get("v.translationsMap.No");
            var opt = [{ value: yesval, label: yesval }, { value: noval, label: noval }];
            component.set('v.options', opt);

          }
        }
      });
      $A.enqueueAction(action);
    }
    catch (e) {
      console.error('err - ' + e);
    }
  },
  //Translation End


  getCountryList: function (component, obj, field) {
    var action = component.get("c.getCountryPicklistvalues");
    action.setParams({
      'objectName': obj,
      'fieldapiname': field,
      'nullRequired': 'false'
    });
    action.setCallback(this, function (Response) {
      if (Response.getState() === "SUCCESS") {
        var result = Response.getReturnValue();
        component.set("v.allCountries", result);

      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.log("Error message: " +
              errors[0].message);
          }
        } else {
          console.error("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  },
  handleSuccess: function (component, event, helper) {
    var action = component.get("c.directPartnerReg");
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        var result = response.getReturnValue();
        component.set("v.showThanks", result);
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error("Error message: " +
              errors[0].message);
          }
        } else {
          console.error("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  }
})
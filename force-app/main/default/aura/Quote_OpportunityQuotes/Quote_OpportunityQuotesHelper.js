({
  loadQuotes: function (component, event, helper) {
    try {
      var oppId = component.get("v.recordId");

      if (!oppId) {
        var url = new URL(location.href);
        oppId = url.searchParams.get('oppId');
      }

      if (oppId) {
        var getQuotesAction = component.get("c.getQuotes");
        getQuotesAction.setParams({
          opportunityId: oppId
        });
        getQuotesAction.setCallback(this, function (response) {

          if (response.getState() === "SUCCESS") {
            var listOfQuotes = response.getReturnValue();
            component.set("v.QuoteList", listOfQuotes);
            component.set("v.Spinner", false);
          }
          else {
            component.set("v.Spinner", false);
            helper.showToast('Error', 'There is some error in updating Quotes.', 'error');
          }
        });
        $A.enqueueAction(getQuotesAction);
        component.set("v.Spinner", true);
      }
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },

  deletePartnerQuote: function (component, event, helper) {
    try {
      var index = event.currentTarget.id;

      var listOfQuotes = component.get("v.QuoteList");
      var id = listOfQuotes[index].Id;
      var deleteQuoteAction = component.get("c.deleteQuote");
      deleteQuoteAction.setParams({
        quoteId: id
      });
      deleteQuoteAction.setCallback(this, function (response) {

        if (response.getState() === "SUCCESS") {
          listOfQuotes.splice(index, 1);
          component.set("v.QuoteList", listOfQuotes);
          component.set("v.Spinner", false);
          component.set("v.Message", "Quote delete successfully !");
          helper.showToast('Success', 'Quote delete successfully !', 'info');
        }
        else {
          component.set("v.Spinner", false);
          helper.showToast('Error', 'There is some error in loading Quote Line Items. Please contact your Admin.', 'error');
        }
      });
      component.set("v.Spinner", true);
      $A.enqueueAction(deleteQuoteAction);

    }
    catch (e) {
      console.error('Error = ', e);
    }
  },

  updatePartnerQuotes: function (component, event, helper) {
    try {
      var index = event.getSource().get("v.class");
      var listOfQuotes = component.get("v.QuoteList");
      var isUpdate = true;
      var quoteRec = listOfQuotes[index];
      if (!quoteRec.Primary__c && quoteRec.Status__c === 'Signature Complete') {
        helper.showToast('Error', 'The quote is alreadying ' + quoteRec.Status__c + '. It can not be marked as not primary now.', 'error');
        listOfQuotes[index].Primary__c = true;
        component.set("v.QuoteList", listOfQuotes);
        return;
      }
      var oppId = component.get("v.recordId");
      if (!oppId) {
        var url = new URL(location.href);
        oppId = url.searchParams.get('oppId');
      }
      var primaryCount = 0;
      for (var i = 0; i < listOfQuotes.length; i++) {
        if (listOfQuotes[i].Primary__c)
          primaryCount++;
        if (primaryCount > 1) {
          listOfQuotes[index].Primary__c = false;
          component.set("v.QuoteList", listOfQuotes);
          break;
        }
      }
      if (primaryCount > 1) {
        component.set("v.showToastMessage", true);
        component.set("v.isSuccess", false);
        helper.showToast('Error', 'There can be only one primary quote.', 'error');
      }
      else {
        if (isUpdate) {
          var updateQuotesAction = component.get("c.updateQuotes");
          updateQuotesAction.setParams({
            opportunityId: oppId,
            listOfQuotes: listOfQuotes
          });
          updateQuotesAction.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
              var listOfQuotes = response.getReturnValue();
              component.set("v.QuoteList", listOfQuotes);
              component.set("v.Spinner", false);
              component.set("v.showToastMessage", true);
              component.set("v.isSuccess", true);
              helper.showToast('Success', 'Quote updated successfully !', 'success');
            }
            else {
              component.set("v.Spinner", false);
              helper.showToast('Error', 'There is some error in updating Quote(s). Please contact your Admin.', 'error');
            }
          });
          $A.enqueueAction(updateQuotesAction);
          component.set("v.Spinner", true);
        }
      }
    }
    catch (e) {
      console.error('Error = ', e);
    }

    setInterval(function () { component.set("v.showToastMessage", false); }, 13000);
  },

  //Translation Start
  getTranslations: function (component, event, helper) {
    try {
      var action = component.get("c.getTranslations");
      action.setParams({
        "objNames": 'Partner_Quote__c'
      });
      action.setCallback(this, function (result) {
        var state = result.getState();
        if (component.isValid() && state === "SUCCESS") {
          var resultData = result.getReturnValue();
          if (resultData != undefined && resultData != null && resultData != '') {
            if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
              resultData.allObjFieldsMap != '') {
              component.set("v.quoteFieldsMap", resultData.allObjFieldsMap.Partner_Quote__c);
            }
            component.set("v.translationsMap", resultData.prmLabelsMap);
            component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
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

  createPartnerQuote: function (component, event, helper) {
    var action = component.get("c.createPartnerQuoteForUpsell");
    action.setParams({
      accID: component.get("v.accountId")
    });
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        window.open('https://e2euat-rc-portal.cs4.force.com/partner/s/quotetool?id=' + response.getReturnValue().Id + '&editionId=' + response.getReturnValue().Product_Edition__c, '_top');
      }
    });
    $A.enqueueAction(action);
    event.preventDefault();
  },

  pocDealSupportExist: function (component, event, helper) {
    var action = component.get("c.checkPOCRequestExist");
    action.setParams({
      oppId: component.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        component.set("v.isInternalRC", response.getReturnValue().isInternalRc);
        component.set("v.isOppOwnerExistInQueue", response.getReturnValue().isOppOwnerExistInQueue);
		component.set("v.isMitelContact",response.getReturnValue().isMitelContact);//added for mitel pbc-10625
        if (response.getReturnValue().objDealSupport) {
          component.set("v.ObjNewDealSupport", response.getReturnValue().objDealSupport);
          component.set("v.isPOCRequestExists", true);
        }
        component.set("v.isSuperUser", response.getReturnValue().isSuperUser);
      }
    });
    $A.enqueueAction(action);
  },

  // BZS-9309 wholesale
  getWholesalePartnerPckEditions: function (component, event, helper) {
    var action = component.get("c.checkAndGetWholesalePartnerPackageEditions");
    action.setParams({
      oppId: component.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        var result = response.getReturnValue()
        if (result != null) {
          component.set("v.wholesalePartnerPckEditions", result);
          component.set("v.isWholesalePartner", true);
        } else {
          component.set("v.isWholesalePartner", false);
        }
      }
    });
    $A.enqueueAction(action);
  }
})
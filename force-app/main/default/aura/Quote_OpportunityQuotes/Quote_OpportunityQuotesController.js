({
  doInit: function (component, event, helper) {
    helper.getTranslations(component, event, helper);
  },

  loadQuotes: function (component, event, helper) {
    helper.loadQuotes(component, event, helper);
    helper.pocDealSupportExist(component, event, helper);
    helper.getWholesalePartnerPckEditions(component, event, helper); // BZS-9309 wholesale
  },

  redirectToQuote: function (component, event, helper) {
    var oppStage = component.get("v.oppStage");
    if (oppStage == '1. Qualify' || oppStage == '2. Problem'
      || oppStage == '3. Solution' || oppStage == '4. Proof' || oppStage == '5. Agreement') {

      var oppType = component.get("v.oppType");
      // BZS-5535 modified Upsell to Existing Business 
      if (oppType != 'Existing Business') {
        var baseURL = component.get('v.baseURL');
        var urlLink = baseURL + '/s/quotetool?oppId=' + component.get("v.recordId");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          'url': urlLink
        });
        urlEvent.fire();
      }
      else {
        if (component.get("v.isChangeOrderSubmitted")) {
          helper.showToast('Error', 'You have already submitted Change Order.', 'error');
        }
        else {
          component.set("v.showChangeRequestCMP", true);
        }
      }
    }
    else {
      helper.showToast('Error', 'Quote can not be created when Opportunity Stage is \'' + oppStage + '\'', 'error');
    }
  },

  redirectTOQuoteTool: function (component, event, helper) {
    var rectarget = event.currentTarget;
    var indx = rectarget.getAttribute("class");
    var quoteRec = component.get("v.QuoteList")[indx];
    var baseURL = component.get('v.baseURL');
    var urlLink = baseURL + '/s/quotetool?step=5&id=' + quoteRec.Id;

    if (quoteRec.RecordType.Name != 'Change Order Request') {
      var urlEvent = $A.get("e.force:navigateToURL");
      urlEvent.setParams({
        'url': urlLink
      });
      urlEvent.fire();
    }
    else {
      component.set("v.changeOrderId", quoteRec.Id);
      component.set("v.ExistingChangeOrder", true);
      component.set("v.showChangeRequestCMP", true);
    }
  },

  deletePartnerQuote: function (component, event, helper) {
    helper.deletePartnerQuote(component, event, helper);
  },

  updatePartnerQuotes: function (component, event, helper) {
    helper.updatePartnerQuotes(component, event, helper);
  },

  showPOCRequest: function (component, event, helper) {
    component.set("v.showPOCRequest", true);
  },
})
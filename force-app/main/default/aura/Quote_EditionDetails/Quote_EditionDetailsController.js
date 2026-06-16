({
  loadEditionDetails: function (component, event, helper) {
    helper.loadCategoriesFromPackage(component, event, helper);
    helper.loadCategories(component, event, helper);
	helper.getTranslations(component, event, helper);
  },
  reLoadCategoriesFromPackage: function (component, event, helper) {
    helper.loadCategoriesFromPackage(component, event, helper);
  },
  resetCategoryAndLoadEditionDetails: function (component, event, helper) {
    component.set("v.subCatSel", null);
    component.set("v.FinalSelectedSubCategories", null);
    helper.loadCategories(component, event, helper);
  },
  getSelectedCategoryDetails: function (component, event, helper) {
    var selectedItem = event.currentTarget;
    var categoryname = selectedItem.dataset.value;
    var selectedCategories = [];
    selectedCategories.push(categoryname);
    component.set("v.selectedSubCategories", selectedCategories);
    component.set("v.subCatSel", categoryname);
    helper.loadEditionDetails(component, event, helper);
  },
  reLoadEditionDetails: function (component, event, helper) {
    var reLoadData = component.get("v.ReloadDataOnLineDelete");
    if (reLoadData) {
      helper.loadEditionDetails(component, event, helper);
      helper.loadQuoteLines(component, event, helper);
    }
  },
  addSelectedProduct: function (component, event, helper) {
    try {
      var doReload = false;
      var selectedProducts = component.get("v.SelectedProductList");
      var selectedProductsToAdd = event.getParam("evtParam_Product");
      selectedProductsToAdd.forEach(function (eachProduct) {
        if (eachProduct.objRule && eachProduct.objRule.Rule_Type__c != '')
          doReload = true;
        selectedProducts.push(eachProduct);
      });

      //helper.updatePrice(component, event, helper, selectedProducts, true);
      component.set("v.SelectedProductList", selectedProducts);

      helper.createUpdateQuote(component, event, helper, null, null, null, doReload, true, false);
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },
  updatePrice: function (component, event, helper) {
    helper.updatePrice(component, event, helper);
  },
  handleUpdatePricingEvent: function (component, event, helper) {
    try {
      var noOfLicenses = event.getParam("evtParam_NoOfLicenses");
      var pricingTerm = event.getParam("evtParam_PricingTerm");
      var objQuote = component.get("v.Quote");
      objQuote.Number_of_Licenses__c = noOfLicenses;
      objQuote.Payment_Term__c = pricingTerm;
      component.set("v.Quote", objQuote);
      helper.updatePrice(component, event, helper);
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },
  showHideEngageModel: function (component, event, helper) {
    try {
      component.set("v.isAvailProServ", component.get("v.Quote.Avail_ProServ__c"))
      if (!component.get("v.showConfirmModal")) {
        component.set("v.showConfirmModal", true);
      } else {
        component.set("v.showConfirmModal", false);
      }
    } catch (e) {
      console.error(e);
    }
  },
  engageProServ: function (component, event, helper) {
    component.set("v.Spinner", true);
    helper.engageProServ(component, event, helper);
  },
  onchangeProServ: function (component, event, helper) {
    //console.log('tatadaaa : ' + component.find("availProServ").get("v.value"));
  }
})
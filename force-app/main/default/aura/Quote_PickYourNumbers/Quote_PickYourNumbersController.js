({
  loadPickYourNumberDetails: function (component, event, helper) {
    helper.loadPickYourNumberDetails(component, event, helper);
	helper.getTranslations(component, event, helper);
  },
  reloadPickYourNumberDetails: function (component, event, helper) {
    var reLoadData = component.get("v.ReloadDataOnLineDelete");
    if (reLoadData) {
      helper.loadPickYourNumberDetails(component, event, helper);
    }
  },
  addSelectedProduct: function (component, event, helper) {
    try {
      var selectedProducts = component.get("v.SelectedProductList");
      var selectedProduct = event.getParam("evtParam_Product");
      selectedProducts.push(selectedProduct);
      component.set("v.SelectedProductList", selectedProducts);
      helper.createUpdateQuote(component, event, helper, null, null, null, true, true, false);
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },
})
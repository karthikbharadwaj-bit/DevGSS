({
  loadEditionDetails: function (component, event, helper) {
    try {
      var getEditionAction = component.get("c.getProductsForEdition");
      var url = new URL(location.href);
      var quoteId = url.searchParams.get('id');
      component.set("v.Spinner", true);
      if (quoteId) {
        getEditionAction.setParams({
          quoteId: quoteId,
          packageProductType: 'Normal',
          categoryName: component.get("v.selectedCategory"),
          showQuoteLinesOnly: component.get("v.ShowQuoteLines"),
          selectedSubCategory: component.get("v.selectedSubCategories")
        });
        getEditionAction.setCallback(this, function (response) {
          component.set("v.Spinner", true);
          if (response.getState() == "SUCCESS") {
            var listOfProducts = response.getReturnValue();
            //helper.updatePrice(component, event, helper, listOfProducts);

            //Ratuls' wholesale changes
            let finalList = [];
            const tempMap = new Map();
            const categorySet = new Set();
            for (let i = 0; i < listOfProducts.length; i++) {
              categorySet.add(listOfProducts[i].productCategory);
            }
            for (let i = 0; i < listOfProducts.length; i++) {
              if (listOfProducts[i].rowType === 'Rule Header' && !tempMap.has(listOfProducts[i].productCategory)) {
                categorySet.delete(listOfProducts[i].productCategory);
                tempMap.set(listOfProducts[i].productCategory, [listOfProducts[i]]);
              }
            }
            for (let i = 0; i < listOfProducts.length; i++) {
              if (listOfProducts[i].rowType === 'Record' && tempMap.get(listOfProducts[i].objRule ? listOfProducts[i].objRule.Header_Text__c : '')) {
                tempMap.get(listOfProducts[i].objRule.Header_Text__c).push(listOfProducts[i]);
              }
            }
            for (const [key, value] of tempMap.entries()) {
              finalList = finalList.concat(value);
            }
            for (let i = 0; i < listOfProducts.length; i++) {
              if (categorySet.has(listOfProducts[i].productCategory) && (finalList.indexOf(listOfProducts[i]) === -1) && listOfProducts[i].rowType === 'Record') {
                finalList.push(listOfProducts[i]);
              }
            }
            if (tempMap.size === 0) {
              component.set("v.ProductList", listOfProducts);
            } else {
              component.set("v.ProductList", finalList);
            }
            //Ratuls' wholesale changes

            if (!listOfProducts.length) {
              component.set("v.noProductsAvailable", true);
            } else {
              component.set("v.noProductsAvailable", false);
            }
            component.set("v.Spinner", false);
          }
        });
        $A.enqueueAction(getEditionAction);
      }
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },
  loadCategoriesFromPackage: function (component, event, helper) {
    var categories = component.get("v.Quote.Product_Edition__r.Product_Categories__c");
    if (categories) {
      var categoriesList = categories.split(";");
      component.set("v.CategoryNames", categoriesList);
    }
  },
  loadCategories: function (component, event, helper) {
    try {
      var url = new URL(location.href);
      var id = url.searchParams.get('id');
      var editionIdJS = component.get("v.Quote").Product_Edition__c;
      component.set("v.spinner", true);
      if (editionIdJS) {
        var getCategoriesAction = component.get("c.getProductCategories");
        getCategoriesAction.setParams({
          editionId: editionIdJS,
          objQuoteRec: component.get("v.Quote")
        });
        getCategoriesAction.setCallback(this, function (response) {
          if (response.getState() == "SUCCESS") {
            var listOfCategories = response.getReturnValue();
            component.set("v.ProductCategories", listOfCategories);
            var ProductCategories = component.get("v.ProductCategories");
            var selectedCategory = component.get("v.selectedCategory");
            for (var i = 0; i < ProductCategories.length; i++) {
              if (ProductCategories[i].categoryName == selectedCategory) {
                var newVaule = [];
                var tempHold = [];
                component.set("v.selectedSubCategories", newVaule);
                component.set("v.subCatSel", '');
                component.set("v.FinalSelectedSubCategories", ProductCategories[i].subCategories);
                if (selectedCategory != 'Service' && ProductCategories[i].subCategories) {
                  component.set("v.subCatSel", ProductCategories[i].subCategories[0]);
                  tempHold.push(ProductCategories[i].subCategories[0]);
                  component.set("v.selectedSubCategories", tempHold);
                }
                component.set("v.isInitialOrder", ProductCategories[i].isInitialOrder);
              }
            }
            helper.loadEditionDetails(component, event, helper);
          }
        });
        $A.enqueueAction(getCategoriesAction);
      }
    }
    catch (e) {
      console.error('Error = ', e);
    }
  },
  engageProServ: function (component, event, helper) {
    const url = new URL(location.href);
    const id = url.searchParams.get('id');
    component.set("v.showConfirmModal", false);
    var action = component.get("c.createDealSprtForEngageProServ");
    action.setParams({
      quoteId: id,
      availProServ: true,
      proServNotes: component.get("v.proServNotes")
    });
    action.setCallback(this, function (response) {
      if (response.getState() === "SUCCESS") {
        component.set("v.Spinner", false);
        component.set("v.isInitialOrder", false);
        helper.showToast('Success !', 'ProServ Engaged and Details Saved Successfully!', 'success');
        helper.loadQuote(component, event, helper);

      } else {
        component.set("v.Spinner", false);
      }
    });
    $A.enqueueAction(action);
  },
     //Translation Start
       getTranslations: function (component, event, helper) {
        try {
            function setTranslations(result) {
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS") {
                    console.log('AllObjFields - ' + JSON.stringify(result.getReturnValue()));
                    var resultData = result.getReturnValue();
                    if (resultData != undefined && resultData != null && resultData != '') {
                        if (resultData.allObjFieldsMap != undefined && resultData.allObjFieldsMap != null &&
                            resultData.allObjFieldsMap != '') {
                            component.set("v.DealRegFieldsMap", resultData.allObjFieldsMap.Deal_Registration__c);
                        }
                        component.set("v.translationsMap", resultData.prmLabelsMap);
                        component.set("v.PRMSpecificTranslationsMap", resultData.prmSpecificLabelsMap);
                    }
                }
            };
            var getTranslations = component.get("c.getTranslations");
            getTranslations.setParams({
                "objNames": 'Deal_Registration__c'
            });
            getTranslations.setCallback(this, setTranslations);
            $A.enqueueAction(getTranslations);
        }
        catch (e) {
            console.log('err - ' + e);
        }
    }
    //Translation End
})
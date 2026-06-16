({
  loadPickYourNumberDetails: function (component, event, helper) {
    try {
      var getEditionAction = component.get("c.getProductsForEdition");
      var url = new URL(location.href);
      var quoteId = url.searchParams.get('id');
      component.set("v.Spinner", true);
      if (quoteId) {
        getEditionAction.setParams({
          quoteId: quoteId,
          packageProductType: 'Pick Your Numbers',
          categoryName: ''
        });
        getEditionAction.setCallback(this, function (response) {
          if (response.getState() == "SUCCESS") {
            var listOfProducts = response.getReturnValue();
            component.set("v.isProductSelectedFROMPYNTab", false);
            for (var objProd of listOfProducts) {
              if (objProd.objCatalogue && objProd.objCatalogue.Package_Product_Type__c.includes('Pick Your Numbers - Mandatory') && objProd.isSelected) {
                component.set("v.isProductSelectedFROMPYNTab", true);
                break;
              }
            }

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
            
            component.set("v.Spinner", false);
          }
          else {
            component.set("v.Spinner", false);
            helper.showToast('Error', 'There is some error in loading products. Please contact your system admin.', 'error');
          }
        });
        $A.enqueueAction(getEditionAction);
      }
    }
    catch (e) {
      console.error('Error = ', e);
      component.set("v.Spinner", false);
    }
  },
  //Translation Start
  getTranslations: function (component, event, helper) {
    try {
      function setTranslations(result) {
        var state = result.getState();
        if (component.isValid() && state === "SUCCESS") {
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
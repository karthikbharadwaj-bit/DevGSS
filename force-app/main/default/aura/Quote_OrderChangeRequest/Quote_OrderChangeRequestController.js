({
    doInit : function(component,event,helper) {
        
        if(!component.get("v.changeOrderId")) {
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
            if(id && !id.startsWith('006') && !id.startsWith('001')) {
                component.set("v.changeOrderId",id);
                component.set("v.ExistingChangeOrder",true);
            } else if(id){
                component.set("v.changeOrderId",id);
            }
            //alert(component.get("v.changeOrderId"));
        }
        helper.doInit(component, event, helper,false);
    },
    packageChange : function(component,event,helper) {
        helper.doInit(component, event, helper,true);
    },
    
    addproduct : function(component, event, helper) { 
        var productIndex = event.getSource().get("v.value");
        var MainCategoryIndex = event.getSource().get("v.name");
        var subCategoryIndex = event.getSource().get("v.class");
        var selectedProductList = component.get("v.CategoryWrapperList");

        //Added for GO Pricing - start (If and else if)
      	var selectedPackageName = component.get("v.selPackageName");
        var existingOrderPkgName = component.get("v.initialOrderPkgEdition");
        var showDLError = false;
        if (selectedPackageName.includes('Unlimited') && selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].productName.includes('Unlimited')) {
          var totalDLlicense = parseInt(selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].quantity);
            var noOfDLAcctLicense = component.get("v.No_Of_DL_Acct");
            if (selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].actionType == 'Add') {
              totalDLlicense = parseInt(noOfDLAcctLicense) + totalDLlicense;
            } else {
              totalDLlicense = parseInt(noOfDLAcctLicense) - totalDLlicense;
            }
          if (totalDLlicense < selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].MinValue
          ) {
            showDLError = true;
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
              toastEvent.setParams({
                title: "Error",
                message: 'Quantity can not be less than 20 for EU Unlimited Packages',
                duration: ' 5000',
                key: 'info_alt',
                type: "Error",
                mode: 'dismissible'
              });
              toastEvent.fire();
            }
          } else if (totalDLlicense > selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].MaxValue
          ) {
            showDLError = true;
            var toastEvent = $A.get("e.force:showToast");
            if (toastEvent) {
              toastEvent.setParams({
                title: "Error",
                message: 'Quantity can not be more than 50000 for EU Unlimited Packages',
                duration: ' 5000',
                key: 'info_alt',
                type: "Error",
                mode: 'dismissible'
              });
              toastEvent.fire();
            }
          }
        }
        if(!showDLError) {
          if (selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].isSelected) {
              selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].isSelected = false;
              selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].buttonLabel = 'Add';
          }
          else {
              selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].isSelected = true;
              selectedProductList[MainCategoryIndex].subCategoryList[subCategoryIndex].productList[productIndex].buttonLabel = 'Remove';
          }
          component.set("v.CategoryWrapperList", selectedProductList);
        }
        //Added for GO Pricing - end
    },
    submitDetails : function(component, event, helper) {
        var buttonLabel = event.getSource().getLocalId();
        var Status = 'Draft';
        if(buttonLabel == 'Submit') {
            Status = 'Pending Order';
        }
        helper.submitDetails(component, event, helper,Status);
    },
    closeModel : function(component, event, helper) {
        component.set("v.showChangeRequestCMP",false);
    },
    handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');
        
        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
    },
    
    handleSelect: function (cmp, event, helper) {
        var nextConfigs = cmp.get('v.tabs').map(function (config) {
            if (config.id === event.getParam('id')) {
                config.count += 1;
                config.content = 'Number of times "' + config.label + '" selected: ' + config.count;
            }
            return config;
        });
        cmp.set('v.tabs', nextConfigs);
    },
    goToStep1: function(component, event, helper) {
        component.set("v.Step", "1");
    },
    goToStep2: function(component, event, helper) {
        var selectedProductList = component.get("v.CategoryWrapperList");
        var selectedRecords = [];
        for(var objParent of selectedProductList) {
            for(var objSub of objParent.subCategoryList) {
                if (objSub.productList != null) {
                    for(var objProduct of objSub.productList) {
                        if(objProduct.isSelected) {
                            selectedRecords.push(objProduct);
                        }
                    }
                }
            }
        }
        component.set("v.selectedproductList",selectedRecords);
        component.set("v.Step", "2");
    },
    parentPackageChange: function(component, event, helper){
    helper.doInit(component, event, helper, true);
    helper.loadSubPackages(component, event, helper);

  },
})
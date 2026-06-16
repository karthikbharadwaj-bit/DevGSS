({
	AddNewRow : function(component, event, helper) {
        //alert('test');
        // call the comman "createObjectData" helper method for add new Object Row to List  
        helper.createObjectData(component, event);
    },
    removeRowContactCenter : function(component,event,helper) {
        helper.removeRowCheck(component, event, helper,true);
    },
    removeRowSalesQuote : function(component,event,helper) {
        helper.removeRowCheck(component, event, helper,false);
    },
    removeRow: function(component, event, helper) {
        // get the selected row Index for delete, from Lightning Event Attribute  
        var index = event.target.dataset.indexvardel;
        // get the all List (DQDiscountList attribute) and remove the Object Element Using splice method    
        var AllRowsList = component.get("v.DQDiscountList");
        var DQDiscountRec = AllRowsList[index];
        if(DQDiscountRec.Id) {
            helper.removeRow(component, event, helper,DQDiscountRec,index);
        }
        else{
            AllRowsList.splice(index, 1);
            // set the DQDiscountList after remove selected row element  
            component.set("v.DQDiscountList", AllRowsList);
        }
    },
    SearchProd : function(component, event, helper) {
        var index = event.target.dataset.indexvardel;
        var AllRowsList = component.get("v.DQDiscountList");
        var DQDiscountRec = AllRowsList[index];
        console.log('DQDiscountRec>>>>',DQDiscountRec);
        if(DQDiscountRec.Product_Category__c == '' && DQDiscountRec.Product_Sub_Categories__c == '') {
            alert('Please Select Product Category or sub Category to Search related product');
            /*var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message: 'Please Select Product Category or sub Category to Search related product',
                duration:' 5000',
                key: 'info_alt',
                type: 'success',
                mode: 'pester'
            });
            toastEvent.fire();*/
            return;
        }
        component.set("v.ProductCategoryName",DQDiscountRec.Product_Category__c);
        component.set("v.ProdSubCategoryName",DQDiscountRec.Product_Sub_Categories__c);
        
        helper.openSearchProd(component, event, helper)
    },
    onRender : function(component,event,helper){
       /* debugger;
        console.log('From Render method');
        var rootElem = component.find('parent-aura-div-id').getElement();
        var stateElemArray = rootElem.querySelectorAll('select[id$="_state"]');
        var stateCityMap = component.get('v.stateCityMap');
        var dataArray = component.get('v.dataArray');
        for (var i = 0; i < stateElemArray.length; i++) {
            console.log(stateElemArray[i].value);
            var rowId = stateElemArray[i].id.split('_')[0];
            var citySelElem = rootElem.querySelector('select[id$="' + rowId +'_city"]');
            var cityArray = stateCityMap[stateElemArray[i].value];
            var innerHTMLVar = '';
            for (var j = 0; j < cityArray.length; j++) {
                if(cityArray[j] == dataArray[rowId-1].city){
                    innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[j]+ '" selected="true">'+ cityArray[j] +'</option>';    
                }else{
                    innerHTMLVar = innerHTMLVar + '<option value="' + cityArray[j]+ '">'+ cityArray[j] +'</option>';
                }
            }
            citySelElem.innerHTML = innerHTMLVar;           
        }*/
    },
    showAddProductsSalesQuote : function(component,event,helper){
        component.set("v.showAddProducts",true);
        component.set("v.dqDiscountRecordTypeName",'Sales Quote');
    },
    showAddProductsContactCenter : function(component,event,helper){
        component.set("v.showAddProducts",true);
        component.set("v.dqDiscountRecordTypeName",'Contact Center');
    },
    
})
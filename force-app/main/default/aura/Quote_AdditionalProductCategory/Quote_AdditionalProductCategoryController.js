({
	loadCategories : function(component, event, helper) {
		helper.loadCategories(component, event, helper);
	},
    
    selectCategory : function(component, event, helper) {
        try{
            var currentCategory = component.get("v.ProductCategory");
            component.set("v.selectedCategory", currentCategory.categoryName);	
        }
    	catch(e){
        	console.log('Error = ', e);
        }	
	},
    
})
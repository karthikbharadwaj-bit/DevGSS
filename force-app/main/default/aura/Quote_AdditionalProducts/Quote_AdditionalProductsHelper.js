({
	loadCategories : function(component, event, helper) {
		try{
            var url = new URL(location.href);
            var id = url.searchParams.get('id');
    		var editionIdJS = url.searchParams.get('editionId');
            component.set("v.spinner", true);
            if(editionIdJS){
            	var getCategoriesAction = component.get("c.getProductCategories");
                getCategoriesAction.setParams({  
                    editionId : editionIdJS  
                });
                getCategoriesAction.setCallback(this, function(response){
                    if(response.getState() == "SUCCESS"){
                       	var listOfCategories = response.getReturnValue();
                        console.log('listOfCategories=', listOfCategories);
                        component.set("v.ProductCategories", listOfCategories);
                    }
                });
                $A.enqueueAction(getCategoriesAction);
            }
            
        }
        catch(e){
        	console.log('Error = ', e);
        }
                          
	}
})
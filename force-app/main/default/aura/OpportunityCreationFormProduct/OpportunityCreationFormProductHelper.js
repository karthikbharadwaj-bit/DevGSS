({
    syncSelectedCheckbox: function(component){
    	if(component.find('selectedCheckbox')) {
        	component.find('selectedCheckbox').set('v.checked', component.get('v.product.selected'));
    	}
    },

    focusQuantityInput: function(component){
        setTimeout($A.getCallback(() => {
            component.find('quantityInput').focus();
        }));
    }
});
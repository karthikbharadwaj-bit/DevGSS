({
    doInit : function(component, event, helper) { 
        console.log('PlayBook>>>',component.get("v.playBookDisplay"));
        console.log('v.partnerContractId'+component.get('v.partnerContractId'));
        console.log('PlayBookisAvaya>>>',component.get("v.isAvaya"));
        console.log('PlayBookpartnerContractWrapperList>>>',component.get("v.partnerContractWrapperList"));
        console.log('inputWrapper>>>',component.get("v.inputWrapper"));
        var wrapperList = component.get('v.partnerContractWrapperList'); 
        try{
            for(var wrapper in wrapperList)
            {      
                if(wrapperList[wrapper].approvalRequired == true)
                {
                    component.set("v.approvalDisplay", true);
                }    
                var mappingWrapper = wrapperList[wrapper].mappingsWrapper;            
                for (var mapping in mappingWrapper)
                {                
                    if(mappingWrapper[mapping].isSelectedOption == true)
                    {		
                        component.find('OptionList')[wrapper].set('v.value',mappingWrapper[mapping].option);
                    }                                
                }            
            }
        }catch(e){
            console.log(e);
        }
        
    },
    addRow: function(component, event, helper) {
        helper.addPartnerContractService(component);
    },
    removeRow: function(component, event, helper) {        
        var pcsList = component.get("v.partnerContractServiceList");        
        var selectedItem = event.currentTarget;        
        var index = selectedItem.dataset.record;
        pcsList.splice(index, 1);
        component.set("v.partnerContractServiceList", pcsList);
    },
    handleOptionChange : function(component, event, helper) {      
        helper.handleOptionChange(component);
    },
})
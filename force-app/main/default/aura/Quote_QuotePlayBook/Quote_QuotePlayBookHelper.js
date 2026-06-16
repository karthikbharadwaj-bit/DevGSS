({
    addPartnerContractService: function(component) {       
        var pcsList = component.get("v.partnerContractServiceList");        
        pcsList.push({
            'sobjectType': 'Partner_Contract_Service__c',
            'Minimum_Target__c': null,
            'Minimum_Target_Effective_Date__c': null            
        });
        component.set("v.partnerContractServiceList", pcsList);
    },
    handleOptionChange : function(component) {
        try
        {
            var wrapperList = component.get('v.partnerContractWrapperList'); 
            console.log('wrapperList-- '+wrapperList);
            for(var wrapper in wrapperList)
            {
                var mappingWrapper = wrapperList[wrapper].mappingsWrapper; 
                for (var mapping in mappingWrapper)
                {
                    
                    console.log('term - '+wrapperList[wrapper].term+wrapperList[wrapper].approvalRequired+mapping);
                    if(mappingWrapper[mapping].option == component.find('OptionList')[wrapper].get('v.value'))
                    {
                        if(wrapperList[wrapper].isGridInputNeeded == false)
                        {
                            /*if(wrapperList[wrapper].term == 'Free Services (Credit) 1 month' && component.get('v.freeCredit') != undefined)
                        {
                           mappingWrapper[mapping].text = mappingWrapper[mapping].text.substring(0,mappingWrapper[mapping].text.indexOf('USD $')+5)+component.get('v.freeCredit').toString()+mappingWrapper[mapping].text.substring(mappingWrapper[mapping].text.indexOf('USD $')+5+component.get('v.freeCredit').toString().length-1,mappingWrapper[mapping].text.length);
                        }*/
                        
                        if(document.getElementsByClassName(wrapperList[wrapper].term+wrapperList[wrapper].approvalRequired).length > 0)
                        {
                            var el = document.getElementsByClassName(wrapperList[wrapper].term+wrapperList[wrapper].approvalRequired)[0];
                            //console.log('el - '+el);
                            el.getElementsByClassName("text")[0].innerHTML = mappingWrapper[mapping].text;

                            if(el.getElementsByClassName("frenchtext").length > 0)
                            el.getElementsByClassName("frenchtext")[0].innerHTML = mappingWrapper[mapping].frenchtext;
                        }
                        mappingWrapper[mapping].isSelectedOption = true;
                    }                    
                }
                else 
                {
                    mappingWrapper[mapping].isSelectedOption = false;
                }
            }                
        }
        }
        catch(e)
        {
            console.log(e);
        }
    }
})
({
    onInit: function(component, event, helper) {
        helper.defineRoutingType(component); 
        helper.getKAUrls(component);
        helper.getEmployeePicklistValues(component);
        helper.getFieldsInfoFromParams(component);       
        helper.getTypeService(component);
        var type = component.get('v.typeService');

        if (helper.isEnoughInfoToAuthenticate(component)) {
            helper.populateAuthInfo(component);
            // search user for sales GW or support GW or SW or Community
            if (type != 'sales' && type != 'support'){ // logic for SW and Community (not Sales or Support For GW)
                helper.searchUsers(component, helper); //helper.openGreetingScreen(component);
            }else if (type == 'sales'){ // logic for Sales GW
                helper.searchUsersForSales(component, helper); // helper.openGreetingScreen(component);
            }else if (type == 'support'){ // logic for Support GW
                helper.searchUsersForSupport(component, helper); // helper.openGreetingScreen(component);
            }
        } else {
            helper.openAuthScreen(component);
        }
    },

    onSalesChatClick: function (component, event, helper) {
        helper.startChat(component, helper, 'sales');
        helper.dispatchDetailEvent(component, 'click', '', 'Sales');
    },
    
    onSupportChatButtonClick: function (component, event, helper) {
        var liveChatType = component.get('v.liveChatType');
        var supportRouting = component.get('v.supportRouting');
        if (liveChatType == 'omniChannel' && supportRouting == 'bot') {
            $A.enqueueAction(component.get('c.onSupportChatClick'));
        } else {
            $A.enqueueAction(component.get('c.onSearchClick'));
        }
    },
    
    onSupportChatClick: function (component, event, helper) {
        helper.startChat(component, helper, 'support');
        helper.dispatchDetailEvent(component, 'click', '', 'Support');
    },

    onSalesUnknownUserChatClick: function (component, event, helper) {
        if (helper.isEnoughAdditionalInformation(component,'inputSaSAuthaiForm')){
            helper.defineSalesByEmployeeNumber(component, helper);
        }
    },
    onSupportUnknownUserChatClick: function (component, event, helper) {
        if (helper.isEnoughAdditionalInformation(component, 'inputSupportAuthaiForm')){
            helper.defineSalesByEmployeeNumber(component, helper);
        }
    },
    onSalesLogic: function (component, event, helper) {      
        if (helper.isEnoughInfoToAuthenticateForSales(component, helper)) {
            helper.populateAuthInfo(component);
        	helper.salesLogic(component, helper); 
        }
    },
    
    onSupportLogic: function (component, event, helper) {
        if (helper.isEnoughInfoToAuthenticateForSupport(component, helper)){
            helper.populateAuthInfo(component);
        	helper.searchUsersForSupport(component, helper);
        }
    },
    
    onSearchClick: function (component, event, helper) {
        helper.openSearchScreen(component);
        helper.dispatchEvent('click', '', 'Search');
    },

    onSalesAndSupportLogic: function (component, event, helper){
        if (helper.isFormValid(component, helper)) {
            helper.populateAuthInfo(component);
            helper.searchUsers(component, helper);
        }
    },
    
    onRetryClick: function (component, event, helper) {
        helper.openAuthScreen(component);
        helper.dispatchEvent('click', '', 'TryAnotherNumber');
    },

    onAdditionalInfoClick: function (component, event, helper) {
        helper.openAuthAdditionalInformation(component);
        helper.dispatchEvent('click', '', 'LearnMore');
    },

    onFormSubmit: function(component, event, helper) {
        event.preventDefault();
    },

    onInputBlur: function(component, event, helper) {
        let source = event.getSource();
        let sourceId = source.getLocalId();
        helper.normalizeField(component.find(sourceId));
    }
});
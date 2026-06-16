({
    doInit : function(component, event, helper) {    
        component.set('v.isActive',true);
        var selectedContact = component.get('v.searchKeyword');
        var isPartnerReg = component.get('v.isPartnerReg');
        var isMasterPartner = component.get('v.isMasterPartner');
        var searchPartnerAccount = component.get('v.searchPartnerAccount');
        var isSFDC = component.get('v.isSFDC');
        var searchAccount = component.get('v.searchPartnerAccount');
        console.log('searchAccount>'+searchAccount);
        console.log('isSFDC'+isSFDC);
        if(selectedContact != undefined && selectedContact != '' && selectedContact != null && isSFDC == false){
            helper.searchPartners(component, event, helper);
        }else if(searchAccount == true  && isSFDC == false){
            helper.searchPartnerAccounts(component, event, helper);
        }else if(isSFDC == true){
            helper.searchPartnersSFDC(component, event, helper);
        }else{
            helper.searchPartners(component, event, helper);
        }
            helper.getTranslations(component, event, helper);
    },
    closeModal : function(component, event, helper) {
        component.set('v.isActive', false);
        component.destroy();
    },
    searchPartners : function(component, event, helper) {
        var searchField = component.find('searchField');
        var isValueMissing = searchField.get('v.validity').valueMissing;
        // if value is missing show error message and focus on field  
        if(component.get("v.isMasterPartner") == true){
            component.set("v.searchBy","partner");
        }
        if(isValueMissing) {
            searchField.showHelpMessageIfInvalid();
            searchField.focus();
        }else{      
            var isSFDC = component.get("v.isSFDC");
            var searchAccount = component.get('v.searchPartnerAccount');
            if(searchAccount == true)
            {
                console.log("if+++")
                helper.searchPartnerAccounts(component, event, helper);
            }
            else if(isSFDC == true){
                helper.searchPartnersSFDC(component, event, helper);
            }
            else
            {
                helper.searchPartners(component, event, helper);
            }
        }
    },
    onSelectPartner : function(component, event, helper) {
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var name_str = ctarget.dataset.name;
        var partnerId = ctarget.dataset.id;   
        var partneracc = ctarget.dataset.accountname;
        var partnerCountry = ctarget.dataset.country;
        var permittedBrands=ctarget.dataset.permittedbrands;
        var accountMasterAgentChlMgr=ctarget.dataset.masteragentchlmgr;
        var accountVARTerritory=ctarget.dataset.varterritory;
        var accountPartnerType=ctarget.dataset.partnertype;
        var territoryAlignmentMap=ctarget.dataset.territoryalignmentmap;       
        var insideSalesRep=ctarget.dataset.insidesalesrep;
        var accountid = ctarget.dataset.accountid;
        let partnerClassification = ctarget.dataset.partnerclassification;//PBC-9705 P2CSharing
        var businessIdentity = ctarget.dataset.businessidentity; //BZS-9016

        //Added for multiple countries for ACO 3.0
        var partnerAvailableCountries = ctarget.dataset.partneravailablecountries;
        //Added for mitel phase-1
        var isMitel =false;
        //PBC-9705 P2CSharing; Removing earlier logic and updating following condition under PBC-11680
        //if (ctarget.dataset.partnerclassification == 'Mitel Referral' || 
        //ctarget.dataset.partnerclassification == 'Mitel Referral P2C Sharing')
        if(permittedBrands != undefined && permittedBrands.toString().includes("RingCentral")){
            isMitel = true;
        }
        console.log('permittedBrands'+permittedBrands);
        console.log('name_str'+name_str);
        console.log('partneracc' +partneracc);
        console.log('accountMasterAgentChlMgr'+accountMasterAgentChlMgr);
        console.log('insideSalesRep - '+insideSalesRep);
        
        var cmpEvent = component.getEvent("populatePartnerEvent");   

        cmpEvent.setParams({
            "Id": id_str,
            "Name": name_str,
            "PartnerId":partnerId,
            "PartnerAccountName":partneracc,
            "PartnerAccount" : component.get('v.searchPartnerAccount'),
            "PartnerCountry": partnerCountry,
            "brandsPermitted": permittedBrands,
            "accountMasterAgentChlMgr":accountMasterAgentChlMgr,
            "partnerAvailableCountries":partnerAvailableCountries,
            "accountVARTerritory" : accountVARTerritory,
            "accountPartnerType" : accountPartnerType,
            "businessIdentity": businessIdentity,
            "territoryAlignmentMap":territoryAlignmentMap,
            "insideSalesRep" : insideSalesRep,
            "AccountId" : accountid,
            "isMitel" :isMitel,
            "partnerClassification" : partnerClassification
        });
        //PBC-9705 P2CSharing
        
        try{
            cmpEvent.fire();
        }catch(e){
            console.log(e);
        }
        component.set('v.isActive', false);        
        component.destroy();
    },
    onSelectPartnerName : function(component, event, helper) {
        var ctarget = event.currentTarget;
        var id_str = ctarget.dataset.value;
        var name_str = ctarget.dataset.name;
        var partnerAccountId = ctarget.dataset.id;
        var cmpEvent = component.getEvent("populatePartnerEvent");   
        
        cmpEvent.setParams({
            
            "PartnerAccountName": name_str,
        });
        
        try{
            cmpEvent.fire();
        }catch(e){
            console.log(e);
        }
        component.set('v.isActive', false);        
        component.destroy();
    }
})
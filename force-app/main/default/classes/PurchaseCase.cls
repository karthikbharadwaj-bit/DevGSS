public without sharing class PurchaseCase {
    
    public string titleText{get;set;}  
    public boolean isEdit{get;set;}
    public Case caseObj{get;set;} 
    public boolean isPortal{get;set;}   
    public Contact contact {get;set;}
    public string caseID{get;set;}
    public map<integer,itemWrapper> itemWrapperMap{get;set;}
    public integer srNo{get;set;}
     public boolean displayPopup {get; set;}
    
    public integer itemToDelete{get;set;} 
    public List<selectOption> itemTypeList{get;set;}
    public List<selectOption> itemSubTypeList{get;set;}
    public List<selectOption> itemVendor{get;set;}
    public string jsonStr{get;set;}
    public List<itemWrapper> wrapperList{get;set;}
    // This flag is used to indicate if there is any null value across the records entered
    public boolean dataIssueflag{get; set;}
    public boolean isTableWithData {get; set;} 
    public string managerName{get;set;}
    public String managerId {get;set;}
    public Map<Id,Contact> usersMap{get;set;}
    public string searchStr{get;set;}
    
    public PurchaseCase(){       
    }
    
    //Constructor
    public PurchaseCase(ApexPages.StandardController controller){
        getContacts();
        titleText = 'IT Procurement Self Service Portal';
        isPortal = true;
        isEdit = true;
        dataIssueflag = false;
        
        itemWrapperMap = new map<integer,itemWrapper>();
        itemTypeList = new List<selectOption>();
        itemSubTypeList = new List<selectOption>();
        wrapperList = new List<itemWrapper>();
        srNo = 0;
        
        if(URL.getOrgDomainUrl().toExternalForm().containsIgnoreCase('visual')){
            isPortal = false;
        }
        caseID = ApexPages.currentPage().getParameters().get('id');
        String pageAction =  ApexPages.currentPage().getParameters().get('action');
        caseObj = new Case();     
        if (!test.isrunningtest()){ 
               
        controller.addFields(ITHelpDeskPortal.getCaseFields());
        }
        if(String.isNotBlank(caseID)){
            if(!Test.isRunningTest()){
                List<String> lstFields = new List<String>();
                lstFields.add('Manager__r.Name');
                controller.addFields(lstFields);
            }
            this.caseObj = (Case) controller.getRecord();
            isEdit = false;
        }else{
            caseObj = new Case();
            caseObj.Status = 'New';
            caseObj.Request_Type__c = 'Procurement';
            caseObj.origin = 'Web';
            caseObj.Location__c = 'Headquarters';
            caseObj.ContactId = [SELECT id,ContactID FROM User WHERE id=:userInfo.getUserId()].ContactId;
            caseObj.recordTypeId = Schema.Sobjecttype.Case.getRecordTypeInfosByName().get('IT Helpdesk').getRecordTypeId();
            
            isEdit = true;
            addRow();                   
        }
        
        itemTypeList = getPickValues(new IT_Product__c(),'Asset_Type__c','-None-');
        itemVendor = getPickValues(new IT_Product__c(),'Vendor__c','-None-');
        
    }
    public List<String> contactMap{get;set;} 
    private void getContacts() {
        contactMap = new List<String>();
        try {
            for(User uObj : [SELECT Id, Name, ContactId, Contact.Name FROM User WHERE ContactId != NULL AND Profile.Name =: ProfileHelper.IT_HELPDESK_COMMUNITY_LOGIN AND IsActive=TRUE] ) {
                contactMap.add(uObj.Contact.Name);
            }
        } catch(Exception ex) { System.debug('#### = ' + ex);}
        system.debug('##### = '+ contactMap);
    }
    
    
    //Call to save record
    public pageReference saveData(){
        isEdit = false;    
        String itemDetails = '<html><table class="tblCls" id="tbl" border="1" width="50%"><th>Sr.No.</th><th>Quantity</th><th>Item Type</th><th>Item Sub Type</th><th>Vendor</th><th>Model</th><th>Price</th>';
        
        Set<string> uniqueModelSet = new Set<String>();
        boolean isDuplicate = false;
        
        if(string.isBlank(caseObj.contactId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'Please enter Requester Name.'));
            return null;
        }
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            integer i=0;
            for(integer key : itemWrapperMap.keySet()){
                itemWrapper item = itemWrapperMap.get(key);
                if(!uniqueModelSet.contains(item.model)){
                    uniqueModelSet.add(item.model);
                } else {
                    isDuplicate = true;
                    break;
                }
                i++;
                if(item.price==null || item.price ==0 ){
                    isEdit = true;
                    break;
                }else{
                    if(string.isNotBlank(item.itemType) && string.isNotBlank(item.itemSubtype) && string.isNotBlank(item.model)
                            && item.itemType!='-None-' && item.itemSubtype!='-None-' && item.model != '-None-' && item.quantity != 0){
                        isEdit = true;
                        if (item.vendor == null){
                            item.vendor = '';
                        }
                        itemDetails+='<tr><td style="text-align:center;">'+i+'</td><td style="text-align:center;">'+item.quantity+'</td><td style="text-align:center;">'+item.itemType+'</td><td style="text-align:center;">'+item.itemSubtype+'</td><td style="text-align:center;">'+item.vendor+'</td><td style="text-align:center;">'+item.model+'</td><td style="text-align:center;">'+item.price+'</td></tr>';
                    } else {
                        isEdit = true;
                        break;
                    }
                }
            }     
            if(!isDuplicate){    
                itemDetails+='</table></html>';
                caseObj.items__c = itemDetails;
                TriggerHandler.BY_PASS_CASE_ON_UPDATE = true;
                upsert caseObj;
                TriggerHandler.BY_PASS_CASE_ON_UPDATE = false;             
                return reloadPage();
            } else {
                itemDetails+='</table></html>'; 
                isEdit = true;   
                if(isDuplicate){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,  'Duplicate item found. Please remove one to proceed.'));
                }
                return null;
            }
        }else{
            itemDetails+='</table></html>'; 
            return null;  
        }
    }
    
    //To open edit format
    public void editData(){
        isEdit = true;        
        dataIssueflag = false;
    }
    
    //Call on hot of Submit request button
    public pageReference submitCase(){
        caseObj.Status = 'Need Review';
        caseObj.OwnerId = [SELECT id FROM User WHERE Name='RC Support Agent'].Id;
        update caseObj;  
        return reloadPage();
    }
    
    //Reload the complete page
    public PageReference reloadPage(){
        if(string.isnotBlank(caseObj.Id)){
            PageReference detailPage = new PageReference('/apex/PurchaseCase?id=' + caseObj.id);
            detailPage.setRedirect(true);
            return detailPage;
        }else{
            PageReference detailPage = new PageReference('/apex/PurchaseCase');
            detailPage.setRedirect(true);
            return detailPage;
        }        
    }
    
    //Add one blank row on hit of Add Item Button
    public void addRow(){
        if(itemWrapperMap!=NULL && itemWrapperMap.size() == 1){
            for(integer key : itemWrapperMap.keySet()){
                itemWrapper item = itemWrapperMap.get(key);
                if(item.itemType==null && item.itemSubType==null){
                    itemWrapperMap = new Map<Integer,itemWrapper>();        
                }
            }           
        }
        srNo = srNo+1;
        itemWrapper wrapperObj = new itemWrapper(srNo,1,'-None-','-None-','-None-','-None-',null, null);
        itemWrapperMap.put(srNo,wrapperObj);        
    }
    
    //Delete row from Item HTML
    public void deleteRow(){
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            if(itemWrapperMap.get(itemToDelete)!=null){
                itemWrapperMap.remove(itemToDelete);
            }
        } 
    }   
     public void searchAndfind() {       
    
      }     
    
    public PageReference redirectToPopUp() {
        PageReference contactPage = new PageReference('/_ui/common/data/LookupPage?lknm=CF00NQ0000001QLNr&lktp=003&lksrch=');
        
        contactPage.setRedirect(true);
        return contactPage;
        
    }
    //Modify price on select of model
    public void updatePrice(){
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            if(itemWrapperMap.get(itemToDelete)!=null){
                itemWrapper wrapperObj = itemWrapperMap.get(itemToDelete);
                List<IT_Product__c> productsList = [SELECT id,Model__c,Price__c, vendor__c FROM IT_Product__c WHERE Asset_Type__c=:wrapperObj.itemType 
                                                    AND Sub_Asset_Type__c=: wrapperobj.itemSubtype 
                                                    AND Model__c=:wrapperObj.model];
                if(productsList!=null && productsList.size() > 0){                    
                    wrapperObj.vendor= productsList[0].vendor__c;
                    if (productsList[0].Price__c != null && wrapperObj.quantity != null  ){
                        wrapperObj.unitPrice = productsList[0].Price__c;
                        wrapperObj.price = (productsList[0].Price__c * wrapperObj.quantity).setScale(2);
                    }
                }else{
                    wrapperObj.unitPrice = 0;
                    wrapperObj.price = 0;   
                }
                
            }
        }
    }
    
    //Update Model on select of Item Sub Type
    public void updateModel(){
        String nameOfModel = null;
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            if(itemWrapperMap.get(itemToDelete)!=null){
                itemWrapper wrapperObj = itemWrapperMap.get(itemToDelete);
                List<IT_Product__c> productsList = [SELECT id,Model__c FROM IT_Product__c WHERE Asset_Type__c=:wrapperObj.itemType 
                                                    AND Sub_Asset_Type__c=: wrapperobj.itemSubtype];
                Set<String> productsSet = new Set<String>();
                wrapperObj.modelPickList = new List<selectOption>();
                wrapperObj.modelPickList.add(new selectOption('-None-','-None-'));                                  
                if(productsList!=null && productsList.size() > 0){                    
                    for(IT_Product__c model : productsList){
                        nameOfModel = model.Model__c;                        
                        if (!productsSet.contains(nameOfModel)){
                            productsSet.add(nameOfModel);
                            wrapperObj.modelPickList.add(new selectOption(model.Model__c,model.Model__c));
                        }
                    }
                }
            }
        }
    }
    
    //Update Item Sub Type on select of Item type 
    public void updateSubType(){
        String nameOfSubType = null;
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            if(itemWrapperMap.get(itemToDelete)!=null){
                itemWrapper wrapperObj = itemWrapperMap.get(itemToDelete);
                List<IT_Product__c> productsList = [SELECT Sub_Asset_Type__c FROM IT_Product__c WHERE Asset_Type__c=:wrapperObj.itemType];
                Set<String> productsSet = new Set<String>();                
                wrapperObj.itemSubTypeList= new List<selectOption>();
                wrapperObj.itemSubTypeList.add(new selectOption('-None-','-None-'));
                wrapperObj.itemSubType = '-None-';
                if(productsList !=null && productsList.size() > 0 ){         
                    for(IT_Product__c itemSubType: productsList){                      
                        nameOfSubType = itemSubType.Sub_Asset_Type__c;  
                        wrapperObj.price = null;
                        wrapperObj.vendor = '-None-';
                        wrapperObj.modelPickList = new List<selectOption>();                 
                        if (!productsSet.contains(nameOfSubType)){
                            productsSet.add(nameOfSubType);
                            wrapperObj.itemSubTypeList.add(new selectOption(itemSubType.Sub_Asset_Type__c,itemSubType.Sub_Asset_Type__c));                            
                        }
                    }
                   
                }
                
            }
        }
    }
    
    //Update price on quantity update
    public void updatePriceOnQuantity(){       
        if(itemWrapperMap!=null && itemWrapperMap.size() > 0){
            if(itemWrapperMap.get(itemToDelete)!=null){
                itemWrapper wrapperObj = itemWrapperMap.get(itemToDelete);                 
                if(wrapperObj.unitPrice!=null) {
                    wrapperObj.price = (wrapperObj.unitPrice * wrapperObj.quantity).setScale(2);
                }
            }
        }
    }
    
    //Generic function to get picklist value by providing field and object name to the function.
    public List<selectOption> getPickValues(Sobject object_name, String field_name, String first_val) {
        List<selectOption> options = new List<selectOption>();
        if (first_val != null) {
            options.add(new selectOption(first_val, first_val));
        }
        Schema.sObjectType sobject_type = object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            options.add(new selectOption(a.getLabel(), a.getValue()));
        }
        return options; 
    }
    
    //Read the Rich Text Area field data and create wrapper map.
    public void jsMethod(){     
        if(string.isNotBlank(jsonStr.trim())){
            List<itemWrapper> wrapperList = (List<itemWrapper>)JSON.deserialize(jsonStr, List<itemWrapper>.class);
            if(wrapperList != NULL && wrapperList.size() > 0){
                integer i=1;
                for(itemWrapper wrp : wrapperList){
                    List<IT_Product__c> productModelList = [SELECT id,Model__c FROM IT_Product__c WHERE Asset_Type__c=:wrp.itemType 
                                                    AND Sub_Asset_Type__c=: wrp.itemSubtype];
                    List<IT_Product__c> productSubTypeList = [SELECT Sub_Asset_Type__c FROM IT_Product__c WHERE Asset_Type__c=:wrp.itemType];
                    if(productModelList!=null && productModelList.size() > 0){
                        wrp.modelPickList = new List<selectOption>();
                        wrp.modelPickList.add(new selectOption('-None-','-None-'));  
                        map<String,Boolean> uniqueModelMap = new map<String,Boolean>();                      
                        for(IT_Product__c model : productModelList){
                            if(uniqueModelMap!=null && uniqueModelMap.get(model.Model__c) == null){
                                wrp.modelPickList.add(new selectOption(model.Model__c,model.Model__c));
                                uniqueModelMap.put(model.Model__c,true);
                            }
                        }
                    }
                    if(productSubTypeList!=null && productSubTypeList.size() > 0){
                        wrp.itemSubTypeList = new List<selectOption>();
                        wrp.itemSubTypeList.add(new selectOption('-None-','-None-'));  
                        map<String,Boolean> uniqueSubTypeMap = new map<String,Boolean>();                      
                        for(IT_Product__c subType : productSubTypeList){
                            if(uniqueSubTypeMap!=null && uniqueSubTypeMap.get(subType.Sub_Asset_Type__c) == null){
                                wrp.itemSubTypeList.add(new selectOption(subType.Sub_Asset_Type__c,subType.Sub_Asset_Type__c));
                                uniqueSubTypeMap.put(subType.Sub_Asset_Type__c,true);
                            }
                        }
                    }
                    
                    itemWrapperMap.put(i++,wrp);
                }
                srNo = wrapperList.size();
            }    
        }  
    }
    
    public PageReference redirectTOLARCall() {       
        PageReference leadPage = new PageReference('/apex/CommunityPortalUserLookup');        
        leadPage.setRedirect(true);
        return leadPage;
        }
         public pagereference showPopup() {
        displayPopup = true;      
        return null;
   }
    public void searchUser(){
        String filter = searchStr + '%';        
        usersMap = new Map<Id,Contact>([select id,Name from Contact WHERE name like :filter order by Name limit 20]);
    }
     
    
    //Wrapper class for Item details
    public class itemWrapper{   
        
        public integer srNo{get;set;}   
        public string itemType{get;set;}
        public List<SelectOption>itemSubTypeList{get;set;}
        public string itemSubType{get;set;}
        public string model{get;set;}
        public integer quantity{get;set;}
        public decimal price{get;set;}
        public decimal unitPrice{get;set;}
        public string vendor{get;set;}
        public List<SelectOption> modelPickList{get;set;} 
        
        public itemWrapper(Integer srNo,Integer quantity,String itemType,String itemSubtype,String vendor,String model,decimal price, decimal unitPrice){
            this.srNo = srNo;
            this.quantity = quantity;
            this.itemType = itemType;
            this.itemSubType= itemSubType;
            this.itemSubTypeList= itemSubTypeList;
            this.vendor = vendor;
            this.modelPickList = modelPickList;
            this.price = price;
            this.model = model;
            this.unitPrice = unitPrice;
        }
    }
}
public class Partner_DealSupport {
    
    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }
    
    @AuraEnabled
    public static DealSupportListWrapper getDealSupportDataController(String selectedPartnerAccount,String selectedSupportStatus, String selectedType, Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord,Boolean isSalesOverlay ,Boolean isEscalated,Boolean isClosedStsIncluded,Boolean isAvayaEscalated, Boolean includeRecordsRoutedToDD) {
        //Method to get list of Deal Supports to display in list view
        DealSupportListWrapper obj=new DealSupportListWrapper();
        List<Account> accList = new List<Account>();       
        List<Deal_Support__c> dealSupportList = new List<Deal_Support__c>();
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;
        String supportStatusQry  = '';
        String selectedTypeQry ='';
        String selectedOwnerQry = '';
        String escalatedToLegalQry = '';
        String escalatedToAvayaQry = '';
        Integer totalRecords;
        String AvayaOffice='';
        
        AccountListWrapper accWrapper = getAccountList();
        Community_Details__mdt comDetail=accWrapper.communityDetailsRecord;
        String brandName = comDetail.Brand_Name__c;
        String salesOverlayQueueLabel = comDetail.Portal_SalesOverlay_Queue__c;
        String portalQueueLabel=comDetail.Portal_Queue__c;
        String portalDealDeskQueueLabel=comDetail.Portal_Deal_Desk_Queue__c;
        String acoDealDeskQueueLabel = 'ACO Deal Desk users';
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords=1000;
        }
        //Single Login code starts
        Set<Id> setUserAccIds = new Set<Id>();
        if(accWrapper != null && accWrapper.listUserAccountMap != null && !accWrapper.listUserAccountMap.isEmpty()){
            for(User_Account_Mapping__c uam : accWrapper.listUserAccountMap){
                setUserAccIds.add(uam.Partner_Account__c);
            }
        }
        system.debug('setUserAccIds>'+setUserAccIds);
        //Single Login code ends
        
        if(selectedPartnerAccount == null)
        {
            accList =  accWrapper.listPartnerAccounts;
            if(accList != null && accList.size() > 0)
            {
                selectedPartnerAccount = accList[0].Id;  
            }            
        }
        if(selectedSupportStatus == null){
            selectedSupportStatus='Any';         
        } 
        if(selectedType == null){
            selectedTypeQry='and Type__c =\'New Sales Order\'';         
        }else if(selectedType == 'Any'){
            selectedTypeQry ='';
        }else{
            selectedTypeQry = 'and Type__c =\''+selectedType+'\'';   
        }
        if(selectedSupportStatus == null){
            supportStatusQry = ' And Status__c = \'New\'';
        }else if(selectedSupportStatus == 'Any'){
            supportStatusQry  = '';       
        }else{
            supportStatusQry = ' And Status__c = \''+selectedSupportStatus+'\''; 
        }
        
        if(selectedType=='Any' || selectedType=='New Contract Request'){
            if(isEscalated&&!isAvayaEscalated){
                escalatedToLegalQry = ' AND Escalated_To_Legal__c = true ';
            }else{
                escalatedToLegalQry = '';
            }
        }else{
            escalatedToLegalQry = '';
        }
        
        if(isAvayaEscalated){
            escalatedToAvayaQry = ' AND Escalated_To_Avaya_Deal_Desk__c=true ';
        }else{
            escalatedToAvayaQry = '';
        }
        
        if(!Test.isRunningTest()){
            if(!isAvayaEscalated){
                if(!accWrapper.isAvaya){
                    selectedOwnerQry =' AND (Owner.name =  \''+ salesOverlayQueueLabel+'\' OR Owner.name = \''+ portalQueueLabel + (includeRecordsRoutedToDD ? '\' OR Owner.name = \''+acoDealDeskQueueLabel+'\')' : '\')');
                }else{
                    if(isSalesOverlay == true){
                        selectedOwnerQry =' AND Owner.name = \''+salesOverlayQueueLabel+'\'';
                    }else{
                        selectedOwnerQry =' AND Owner.name = \''+portalQueueLabel+'\'';
                    }
                    
                    if(includeRecordsRoutedToDD) {
                        selectedOwnerQry = ' (' + selectedOwnerQry + 'OR Owner.name = \''+acoDealDeskQueueLabel+'\')';
                    }
                }
            }else{
                selectedOwnerQry =' AND Owner.name =  \''+portalDealDeskQueueLabel+'\'';
            }
        }
        if(!isClosedStsIncluded){
            supportStatusQry = ' And Status__c not in (\'Closed-Approved\',\'Closed-Rejected\',\'Closed\')';
        }
        String searchQry = '';
        
        if(null!= searchKeyWord && searchKeyWord != ''){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            System.debug('searchBy '+searchBy);
            if(selectedType!=null && !selectedType.equalsIgnoreCase('New Contact Request')){
                if(searchBy.contains('Partner_Account__r.BillingCountry')){
                    searchQry = ' And (Customer_Account__r.BillingCountry Like '+searchKey+' OR Lead__r.Country__c Like'+searchKey+')';
                }else if(searchBy.contains('Partner_Account__r.BillingState')){
                    searchQry = ' And (Customer_Account__r.BillingState Like '+searchKey+' OR Lead__r.State__c Like'+searchKey+')';
                }else if(searchBy.contains('Portal_Cloud_Specialist__c')){
                    searchQry = ' And (Opportunity__r.Portal_Cloud_Specialist__r.Name  Like '+searchKey+' OR Lead__r.Portal_Cloud_Specialist__r.Name  Like'+searchKey+')';
                }else{
                    searchQry = ' And '+ searchBy+ '  Like '+searchKey;
                }
            }else{
                searchQry = ' And '+ searchBy+ '  Like '+searchKey;
            }
        }
        String query = 'select count() from Deal_Support__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) '+supportStatusQry+selectedTypeQry+selectedOwnerQry+escalatedToLegalQry+escalatedToAvayaQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
        if(brandNamesList.contains('Unify Office')){
            query = 'select count() from Deal_Support__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) '+supportStatusQry+selectedTypeQry+selectedOwnerQry+escalatedToLegalQry+escalatedToAvayaQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
        }
        system.debug('query paccounts*'+query);
        if(null!= searchKeyWord){
            query+=searchQry;
        }
        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        
        if(null!=totalRecords && totalRecords > 0){
            if(brandNamesList.contains('Unify Office')){
                query = 'select Id,POC_Term__c,Phone_and_Shippment__c,Phone_type__c,Main_Area_Code__c,Number_of_User__c,Edition__c,Comment__c,Name,toLabel(Type__c),Opportunity__c,Opportunity__r.Name,Partner_Account__c,Customer_Account__c,' +
                    'Customer_Account__r.Name,Partner_Quote__c,Partner_Quote__r.Name, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,' +
                    'Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.Name,Partner_Contact__r.LastName,toLabel(Status__c),Lead__c,' +
                    'Lead__r.Company,CreatedDate,Escalated_To_Legal__c,Engage_Legal_Comments__c,Escalated_To_Avaya_Deal_Desk__c,Partner_Account__r.BillingCountry,'+
                    'Partner_Account__r.BillingState,Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__r.Name,'+
                    'Opportunity__r.Portal_Cloud_Specialist__c,Opportunity__r.Portal_Cloud_Specialist__r.Name,Customer_Account__r.BillingCountry,'+
                    'Customer_Account__r.BillingState,Lead__r.Country__c,Lead__r.State__c,Last_Comment_By__c, Last_Comment_By__r.Full_Name__c, Last_Comment_Date__c from Deal_Support__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__r.Partner_Account__r.Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) '+supportStatusQry+selectedTypeQry+selectedOwnerQry+escalatedToLegalQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
                
            }else{
                query = 'select Id,POC_Term__c,Phone_and_Shippment__c,Phone_type__c,Main_Area_Code__c,Number_of_User__c,Edition__c,Comment__c,Name,toLabel(Type__c),Opportunity__c,Opportunity__r.Name,Partner_Account__c,Customer_Account__c,' +
                    'Customer_Account__r.Name,Partner_Quote__c,Partner_Quote__r.Name, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,' +
                    'Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.Name,Partner_Contact__r.LastName,toLabel(Status__c),Lead__c,' +
                    'Lead__r.Company,CreatedDate,Escalated_To_Legal__c,Engage_Legal_Comments__c,Escalated_To_Avaya_Deal_Desk__c,Partner_Account__r.BillingCountry,'+
                    'Partner_Account__r.BillingState,Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__r.Name,'+
                    'Opportunity__r.Portal_Cloud_Specialist__c,Opportunity__r.Portal_Cloud_Specialist__r.Name,Customer_Account__r.BillingCountry,'+
                    'Customer_Account__r.BillingState,Lead__r.Country__c,Lead__r.State__c,Last_Comment_By__c, Last_Comment_By__r.Full_Name__c, Last_Comment_Date__c from Deal_Support__c where (Partner_Account__c='+'\''+selectedPartnerAccount+'\' OR Partner_Account__c IN: setUserAccIds) '+supportStatusQry+selectedTypeQry+selectedOwnerQry+escalatedToLegalQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
            }
            if(null!= searchKeyWord){
                query += searchQry;
            }
            
            query += ' ORDER BY CreatedDate DESC'; 
            query += ' LIMIT :pSize OFFSET :offset'; 
            System.debug('Query+++++ '+query);
            dealSupportList = Database.query(query);
            obj.dealSupportList = dealSupportList;
        }
        
        obj.pageSize = pSize;
        obj.pageNumber = pNumber;
        obj.recordStart = offset + 1;
        obj.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        obj.totalRecords = totalRecords;
        return obj;
    }
    
    @AuraEnabled
    public static UserRecordAccess getUserRecordAccess(String DealSupportRecordId){
        String userId = UserInfo.getUserId();
        List<UserRecordAccess> recordAccess = [SELECT RecordId, HasEditAccess, HasReadAccess FROM UserRecordAccess WHERE UserId = :userId and RecordId = :DealSupportRecordId];
        return recordAccess[0];
    }
    
    //Method to get partner accounts
    @AuraEnabled
    public static AccountListWrapper getAccountList(){
        //get ParentAccount list to be populated in drop-down of list view
        AccountListWrapper accListWrapper=new AccountListWrapper();
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        List<Account> listofPartnerAccounts =new List<Account>();
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
        
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        accListWrapper.communityDetailsRecord=comDetail;
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        //Single Login code starts
        Set<Id> setUserId = new Set<Id>();
        setUserId.add(UserInfo.getUserId());
        List<User_Account_Mapping__c> listUserAccountMap = new List<User_Account_Mapping__c>([Select Id, Partner_Account__c, Partner_User__c 
                                                                                              from User_Account_Mapping__c 
                                                                                              where Partner_User__c IN:setUserId]);
        system.debug('listUserAccountMap>>'+listUserAccountMap);
        if(!listUserAccountMap.isEmpty()){
            accListWrapper.isSingleLogin = true;
            accListWrapper.listUserAccountMap = listUserAccountMap;
        }
        //Single Login code ends
        
        if(selectedPartnerAccount != NULL){
            for(Account acc : [SELECT Id, Name,Partner_Role__c FROM Account WHERE Id =:selectedPartnerAccount 
                               AND Type='Partner' order by Name]){
                                   listofPartnerAccounts.add(acc);
                                   if(acc.Partner_Role__c=='General Partner'){
                                       accListWrapper.isAvaya=false;
                                   }
                                   else{
                                       accListWrapper.isAvaya=true;           
                                   }
                                   
                                   if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                       accListWrapper.isOnlyAvaya=true;
                                   }
                               }
            accListWrapper.listPartnerAccounts=listofPartnerAccounts;
            accListWrapper.isReadOnly=isReadOnlyProfile;
        }
        accListWrapper.partnerCommunityName=brandNamesList;
        return accListWrapper;
    }
    
    
    @AuraEnabled
    public static DealSupportWrapper getDealSupportRecordList(String DealSupportRecordId){
        //get data for record detail page for selected Deal Support
        List<Deal_Support__c> dealsupportRecord =new List<Deal_Support__c>();
        DealSupportWrapper dsw = new DealSupportWrapper();
        Boolean isReadOnlyProfile=Quote_PartnerQuoteUtil.getReadOnlyFlagForUser();
        
        AccountListWrapper accWrapper = getAccountList();
        Community_Details__mdt comDetail=accWrapper.communityDetailsRecord;
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        dsw.partnerCommunityName= brandNamesList;
        
        dsw.communityDetailsRecord=comDetail;
        
        //Added Partner_Quote__r.RecordType.Name, Partner_Quote__r.Status__c for JIRA fix as part of ACO 4.0
        //Added Justification_for_Rejection__c for JIRA 4698
        dealsupportRecord= [select Id,POC_Term__c,Phone_and_Shippment__c,Phone_type__c,Main_Area_Code__c,Number_of_User__c,Edition__c,Comment__c,Name,Opportunity__c,POC_Conversion_to_Paid_Requested__c,Opportunity__r.Name, Discount_Details__c,Status__c,toLabel(Status__c) statusValue, Sub_Status__c,
                            Type__c,toLabel(Type__c) TranslatedTypes, Customer_Account__c, Partner_Quote__r.POC__c,Partner_Quote__c,
                            Customer_Account__r.Name, Customer_Account__r.VATNumber__c,Customer_Account__r.BillingCountry, Partner_Account__c, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c, 
                            Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName,Partner_ProServ_Notes__c,Brand_Name__c,
                            Promo_code__c,Escalated_To_Avaya_Deal_Desk__c,Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__r.Name,Opportunity__r.Portal_Cloud_Specialist__c,Opportunity__r.Portal_Cloud_Specialist__r.Name,
                            Partner_Quote__r.Name,Lead__c,Lead__r.Company, Discount__c,Approved_Discount__c, Owner.Name,Escalated_To_Legal__c,Engage_Legal_Comments__c,Opportunity__r.Avaya_Cloud_Specialist__c,Opportunity__r.Owner.Name,Partner_ProServ__c, Discount_Amount__c, Approved_Discount_Amount__c,
                            (select Id,Comments__c from Deal_Support_Comments__r),Partner_Quote__r.RecordType.Name, Partner_Quote__r.Status__c,Justification_for_Rejection__c from Deal_Support__c 
                            where Id=:DealSupportRecordId];
        Boolean isAvaya = accWrapper.isAvaya;
        Boolean isOnlyAvaya = accWrapper.isOnlyAvaya;
        String translatedType; 
        String statusValueTranslated;
        translatedType = (String)dealsupportRecord[0].get('TranslatedTypes'); 
        statusValueTranslated = (String)dealsupportRecord[0].get('statusValue');
        if (dealsupportRecord!=null && dealsupportRecord.size() > 0)
        { 
            system.debug('dealsupportRecord - ' +dealsupportRecord[0]);
            dsw.dealSupport = dealsupportRecord[0];
        }
        dsw.isAvaya = isAvaya;
        dsw.isOnlyAvaya=isOnlyAvaya;
        dsw.isReadOnly=isReadOnlyProfile;
        dsw.isSingleLogin=accWrapper.isSingleLogin;
        dsw.translatedType=translatedType;
        dsw.statusValueTranslated=statusValueTranslated;
        if (dealsupportRecord!=null && dealsupportRecord.size() > 0)
        {
            if(dealsupportRecord[0].Partner_Quote__c != null && dealsupportRecord[0].Partner_Quote__r.POC__c) {
                dsw.isPOCQuote = true;
            }
        }
        
        return dsw;
    }
    
    @AuraEnabled
    public static Deal_Support__c insertDealSupportNew(String dealname,string comments){
        //Addition of new Deal Support record
        Deal_Support__c ds=new Deal_Support__c();
        ds.Partner_Account__c=PartnerDealRegistrationUtil.getSelectedPartnerId();
        User u = [SELECT Id, Name, ContactId, Contact.AccountId, Partner_Account_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
        ds.Partner_Contact__c = u.ContactId;   
        ds.Type__c='New Sales Order';
        
        Community_Details__mdt comDetail=getAccountList().communityDetailsRecord;
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        ds.Brand_Name__c = brandNamesList[0];
        
        String AvayaOffice = '';
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        String queueId = '';
        queueId = Quote_PartnerQuoteUtil.getQueueId(comDetail.Portal_Queue__c);
        
        if(queueId != null) {
            ds.OwnerId = queueId;
        }
        try{
            Database.SaveResult sr= Database.Insert(ds,true);
            if(sr.isSuccess()){
                Deal_Support_Comments__c dscom=new Deal_Support_Comments__c();
                dscom.Comments__c=comments;
                dscom.Deal_Support__c=ds.Id;
                insert dscom;     //Insertion of Deal Support Comment for corresponding Deal support
            }
        }catch(Exception ex){
            
        }
        return ds;
    }
    
    @AuraEnabled
    public static PartnerDealSupportCommentsWrapper getSupportComments(String dealSupportId) { 
        //get Deal Support Comments for corresponding Deal support to be displayed in record detail page
        PartnerDealSupportCommentsWrapper objDSCW =  new PartnerDealSupportCommentsWrapper();  
        String query1 = 'select count() from Deal_Support_Comments__c '+
            ' Where Deal_Support__c= '+'\''+dealSupportId+'\'';  
        Integer totalRecords = Database.countquery(query1);
        if(null!=totalRecords && totalRecords > 0){
            String query = 'select Id, CreatedBy.Name,CreatedDate,Comments__c '+
                ' FROM Deal_Support_Comments__c '+
                ' Where Deal_Support__c= '+'\''+dealSupportId+'\'';  
            query += ' ORDER BY CreatedDate DESC';
            objDSCW.partnerDealSupportCommentsList = Database.query(query);    
        }
        return objDSCW;
    }
    
    @AuraEnabled
    public static void updateDSOwner(String dealSupportId, String dealSupportType){
        Community_Details__mdt comDetail=getAccountList().communityDetailsRecord;
        String salesOverlayQueue = comDetail.Portal_SalesOverlay_Queue__c;
        
        String queueId = Quote_PartnerQuoteUtil.getQueueId(salesOverlayQueue);
        Deal_Support__c objDSToUpdate = new Deal_Support__c(id = dealSupportId, ownerId = queueId);
        if(dealSupportType == 'Discount Request') {
            objDSToUpdate.Sub_Status__c = 'Pending RC Approval';
        }
        try{
            update objDSToUpdate;
        }catch(Exception ex){
            
        }
    }
    
    @AuraEnabled
    public static Boolean getShowAssignToRCButton(String dealSupportId){
        Community_Details__mdt comDetail=getAccountList().communityDetailsRecord;
        String salesOverlayQueue = comDetail.Portal_SalesOverlay_Queue__c;
        
        String queueId = Quote_PartnerQuoteUtil.getQueueId(salesOverlayQueue);
        Deal_Support__c objDS = [SELECT ownerId FROM Deal_Support__c WHERE id =: dealSupportId];
        if(objDS.ownerId == queueId){
            return false;
        }
        return Quote_PartnerQuoteUtil.checkSuperUser();
    }
    
    @AuraEnabled
    public static Deal_Support_Comments__c getNewDealComments(String dealSupportId,string comments){
        //Further addition of comments to deal support
        Deal_Support_Comments__c dscomment=new Deal_Support_Comments__c();
        dscomment.Comments__c=comments;
        dscomment.Deal_Support__c=dealSupportId;
        try{
            insert dscomment;
            return dscomment;
        }catch(Exception ex){
            return null;
        }
    }
    
    @AuraEnabled
    public static Deal_Support__c updateDealSupportList(String DealSupportRecordId,String Status, Decimal Discount,Boolean engageProServ,String JustificationForRejection){
        //update record upon edit of Deal Support Status
        Deal_Support__c dealsupportRecord =new Deal_Support__c();
        dealsupportRecord.Id=DealSupportRecordId;
        dealsupportRecord.Status__c=Status;
        if(dealsupportRecord.Discount__c > 0){
            dealsupportRecord.Approved_Discount__c = Discount;
        }else if(dealsupportRecord.Discount_Amount__c > 0){
            dealsupportRecord.Approved_Discount_Amount__c = Discount;
        }
        dealsupportRecord.Partner_ProServ__c= engageProServ;
        //Added Justification_for_Rejection__c for JIRA 4698
        dealsupportRecord.Justification_for_Rejection__c=JustificationForRejection;
        try{
            update dealsupportRecord;
            return [select Id,Name,Type__c,Opportunity__c,Opportunity__r.Name,Customer_Account__c,Status__c,Sub_Status__c,Discount__c,Approved_Discount__c,Customer_Account__r.Name,Partner_Account__c, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName,Partner_Quote__c,Partner_Quote__r.Name,Lead__c,Lead__r.Company,Escalated_To_Legal__c,Engage_Legal_Comments__c,Escalated_To_Avaya_Deal_Desk__c, Discount_Amount__c, Approved_Discount_Amount__c,Justification_for_Rejection__c, (select Id,Comments__c from Deal_Support_Comments__r) from Deal_Support__c 
                    where Id=:DealSupportRecordId];
        } catch(Exception ex){
            return null;
        }
    }
    
    @AuraEnabled
    public static Deal_Support__c updateDealSupportPocCheckbox(Deal_Support__c DealSupportRecord){
        try{
            update DealSupportRecord;
            return DealSupportRecord;
        }catch(Exception ex){
            return null;
        }
    }
    
    @AuraEnabled
    public static String updateQuoteStatus(string DealSupportRecordId,String PartnerQuote, String SelButton,String JustificationForRejection){
        //On approval,update corresponding Partner Quote Status to Approved
        Partner_Quote__c pquote=new Partner_Quote__c();
        pquote.Id=PartnerQuote;
        
        Deal_Support__c dealsupportRecord =new Deal_Support__c();
        dealsupportRecord.Id=DealSupportRecordId;
        
        if(SelButton == 'Approve'){
            pquote.Status__c='Approved';
            dealsupportRecord.Status__c='Closed-Approved';            
        }else{
            pquote.Status__c='Rejected';
            dealsupportRecord.Status__c='Closed-Rejected';
            //Added Justification_for_Rejection__c for JIRA 4698
            dealsupportRecord.Justification_for_Rejection__c=JustificationForRejection;
        }
        try{
            update pquote;
            update dealsupportRecord;
            return 'SUCCESS';
        }
        catch(Exception ex){
            System.debug('Error'+ex);
            return 'Error';
        }
    }
    
    @AuraEnabled  
    public static List<Attachment> getAttachmentOppo(string recordId){ 
        
        return Partner_Customer_ContactController.getAttachmentOppo(recordId); 
    } 
    
    @AuraEnabled  
    public static List<ContentDocument> getFiles(string recordId){ 
        //get list of attachments to be displayed in record detail page for selected deal support
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:recordIds];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        
        return [SELECT Id,Title,FileType FROM ContentDocument WHERE id IN: documentIds];  
    } 
    
    //Method added for getting files uploaded from SF Lightning
    @AuraEnabled  
    public static List<ContentVersion> getFilesForLightning(string recordId){ 
        Set<Id> recordIds=new Set<Id>{recordId};
            Set<Id> documentIds = new Set<Id>(); 
        List<ContentDocumentLink> cdl=[SELECT id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:recordId];  
        for(ContentDocumentLink cdLink:cdl){  
            documentIds.add(cdLink.ContentDocumentId);  
        }
        
        return [SELECT Id,Title,FileType,ContentDocument.LatestPublishedVersionId FROM ContentVersion WHERE contentDocumentId IN: documentIds];  
    }     
    
    @AuraEnabled
    public static DealSupportListWrapper getDataForViewAll(String selectedSupportStatus, String selectedType,Decimal pageNumber, Decimal pageSize,String searchBy,String searchKeyWord,Boolean isSalesOverlay,Boolean isEscalated,Boolean isClosedStsIncluded,Boolean isAvayaEscalated, Boolean includeRecordsRoutedToDD){
        //get list view of Leads
        DealSupportListWrapper objOppWrapper = new DealSupportListWrapper();
        
        List<Deal_Support__c> dealSupportList = new List<Deal_Support__c>();
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;
        
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;        
        String query = '';        
        String searchQry = '';
        String supportStatusQry = '';
        String selectedStatusQry = '';
        String selectedOwnerQry = '';
        String whereQry ='where ';
        String escalatedToLegalQry = '';
        String escalatedToAvayaQry = '';
        String brandQuery = '';
        Integer totalRecords;
        String AvayaOffice='';
        
        AccountListWrapper accWrapper = getAccountList();
        Community_Details__mdt comDetail=accWrapper.communityDetailsRecord;
        String brandName = comDetail.Brand_Name__c;
        String salesOverlayQueueLabel = comDetail.Portal_SalesOverlay_Queue__c;
        String portalQueueLabel=comDetail.Portal_Queue__c;
        String portalDealDeskQueueLabel=comDetail.Portal_Deal_Desk_Queue__c;
        String acoDealDeskQueueLabel = 'ACO Deal Desk users';
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AvayaOffice=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords=1000;
        }
        if(selectedSupportStatus == null){
            selectedSupportStatus ='Any'; 
        }
        
        if(!isClosedStsIncluded){
            supportStatusQry = ' Status__c not in (\'Closed-Approved\',\'Closed-Rejected\',\'Closed\')';
        }else{
            if(selectedSupportStatus == null){
                supportStatusQry = ' Status__c = \'New\'';
            }else if(selectedSupportStatus == 'Any'){
                supportStatusQry  = '';       
            }else{
                supportStatusQry = ' Status__c = \''+selectedSupportStatus+'\''; 
            }
        }
        
        if(selectedType == null){
            selectedType='Type__c= \'New Sales Order\'';         
        }else if(selectedType == 'Any'){
            selectedStatusQry ='';
        }else{
            selectedStatusQry='Type__c= \''+selectedType+'\'';
        }
        if(!isAvayaEscalated){
            if(!accWrapper.isAvaya){
                selectedOwnerQry =' (Owner.name =  \''+ salesOverlayQueueLabel+'\' OR Owner.name = \''+ portalQueueLabel + (includeRecordsRoutedToDD ? '\' OR Owner.name = \''+acoDealDeskQueueLabel+'\')' : '\')');
            }
            else{
                if(isSalesOverlay == true){
                    selectedOwnerQry =' Owner.name = \''+salesOverlayQueueLabel+'\'';
                }
                else{
                    selectedOwnerQry ='  Owner.name = \''+portalQueueLabel+'\'';
                }
                
                if(includeRecordsRoutedToDD) {
                    selectedOwnerQry = ' (' + selectedOwnerQry + 'OR Owner.name = \''+acoDealDeskQueueLabel+'\')';
                }
            }
        }
        else{
            selectedOwnerQry =' Owner.name = \''+portalDealDeskQueueLabel+'\'';
            
        }
        if(isEscalated&&!isAvayaEscalated){
            escalatedToLegalQry = ' Escalated_To_Legal__c = true ';
        }else{
            escalatedToLegalQry = '';
        }
        
        if(isAvayaEscalated){
            escalatedToAvayaQry = ' Escalated_To_Avaya_Deal_Desk__c=true ';
        }else{
            escalatedToAvayaQry = '';
        }
        
        if(selectedStatusQry != '' && supportStatusQry != ''){
            whereQry += selectedStatusQry+' and '+ supportStatusQry;
        }else if(selectedStatusQry == ''){
            whereQry += supportStatusQry;
        }else if(supportStatusQry == ''){
            whereQry += selectedStatusQry;
        }
        
        
        if(whereQry == 'where '){
            whereQry += selectedOwnerQry;
        }
        else{
            whereQry += +' and '+selectedOwnerQry;
        }
        
        if(whereQry == 'where '){
            whereQry += escalatedToLegalQry;
        }
        else if(escalatedToLegalQry != ''){
            whereQry = whereQry +' and ' +escalatedToLegalQry;
        }
        
        if(selectedType=='Any' || selectedType=='Discount Request'){
            if(escalatedToAvayaQry != ''){
                whereQry = whereQry +' and ' +escalatedToAvayaQry;
            }
        }
        
        query = 'select count() from Deal_Support__c '+whereQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
        system.debug('query view all*'+query);
        
        if(null!= searchKeyWord && whereQry != '' && searchKeyWord != ''){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            System.debug('searchBy '+searchBy);
            if(!selectedType.equalsIgnoreCase('New Contact Request')){
                if(searchBy.contains('Partner_Account__r.BillingCountry')){
                    searchQry = ' And (Customer_Account__r.BillingCountry Like '+searchKey+' OR Lead__r.Country__c Like'+searchKey+')';
                }else if(searchBy.contains('Partner_Account__r.BillingState')){
                    searchQry = ' And (Customer_Account__r.BillingState Like '+searchKey+' OR Lead__r.State__c Like'+searchKey+')';
                }else if(searchBy.contains('Portal_Cloud_Specialist__c')){
                    searchQry = ' And (Opportunity__r.Portal_Cloud_Specialist__r.Name  Like '+searchKey+' OR Lead__r.Portal_Cloud_Specialist__r.Name  Like'+searchKey+')';
                }else{
                    searchQry = ' And '+ searchBy+ '  Like '+searchKey;
                }
            }else{
                searchQry = ' And '+ searchBy+ '  Like '+searchKey;    
            } 
            query+=searchQry;
        }else if(null!= searchKeyWord && searchKeyWord != ''){
            String searchKey =  '\'%'+searchKeyWord + '%\'';
            System.debug('searchBy '+searchBy);
            if(!selectedType.equalsIgnoreCase('New Contact Request')){
                if(searchBy.contains('Partner_Account__r.BillingCountry')){
                    searchQry = ' where (Customer_Account__r.BillingCountry Like '+searchKey+' OR Lead__r.Country__c Like'+searchKey+')';
                }else if(searchBy.contains('Partner_Account__r.BillingState')){
                    searchQry = ' where (Customer_Account__r.BillingState Like '+searchKey+' OR Lead__r.State__c Like'+searchKey+')';
                }else if(searchBy.contains('Portal_Cloud_Specialist__c')){
                    searchQry = ' where (Opportunity__r.Portal_Cloud_Specialist__r.Name  Like '+searchKey+' OR Lead__r.Portal_Cloud_Specialist__r.Name  Like'+searchKey+')';
                }else{
                    searchQry = ' where '+ searchBy+ '  Like '+searchKey;    
                }
            }else{
                searchQry = ' where '+ searchBy+ '  Like '+searchKey;
            }
            query+=searchQry;
        }
        
        system.debug('query - '+query);
        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        if(null!=totalRecords && totalRecords > 0){     
            query = 'select Id,Name,toLabel(Type__c),Phone_type__c,Main_Area_Code__c,Opportunity__c,Opportunity__r.Name,Partner_Account__c,Customer_Account__c,'+
                'Customer_Account__r.Name,Partner_Quote__c,Partner_Quote__r.Name, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c,'+
                'Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.Name,Partner_Contact__r.LastName,'+
                'toLabel(Status__c),CreatedDate,Escalated_To_Legal__c,Engage_Legal_Comments__c,Escalated_To_Avaya_Deal_Desk__c,Partner_Account__r.BillingCountry,'+
                'Partner_Account__r.BillingState,Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__c,Lead__r.Portal_Cloud_Specialist__r.Name,'+
                'Opportunity__r.Portal_Cloud_Specialist__c,Opportunity__r.Portal_Cloud_Specialist__r.Name,Customer_Account__r.BillingCountry,'+
                'Customer_Account__r.BillingState,Lead__r.Country__c,Lead__r.State__c,Last_Comment_By__c, Last_Comment_By__r.Full_Name__c, Last_Comment_Date__c from Deal_Support__c '+whereQry+' and (Brand_Name__c = null  OR Brand_Name__c IN: brandNamesList)';
            if(null!= searchKeyWord){
                query += searchQry;
            }
            query += ' ORDER BY CreatedDate DESC'; 
            query += ' LIMIT :pSize OFFSET :offset';
            dealSupportList = Database.query(query);
            
            objOppWrapper.dealSupportList = dealSupportList;
        }
        objOppWrapper.pageSize = pSize;
        objOppWrapper.pageNumber = pNumber;
        objOppWrapper.recordStart = offset + 1;
        objOppWrapper.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objOppWrapper.totalRecords = totalRecords;
        return objOppWrapper;
    }
    
    @AuraEnabled
    public static Deal_Support__c updateDSOwnerQueue(String dealSupportId){
        Community_Details__mdt comDetail=getAccountList().communityDetailsRecord;
        String portalDealDeskQueue = comDetail.Portal_Deal_Desk_Queue__c;
        
        String queueId = Quote_PartnerQuoteUtil.getQueueId(portalDealDeskQueue);
        Deal_Support__c objDSToUpdate = new Deal_Support__c(id = dealSupportId, ownerId = queueId,Escalated_To_Avaya_Deal_Desk__c=true);
        if(test.isRunningTest())
        {
            objDSToUpdate = new Deal_Support__c(id = dealSupportId, Escalated_To_Avaya_Deal_Desk__c=true);
        }
        try{
            update objDSToUpdate;
            
            Set<Id> deal = new Set<Id>();
            deal.add(objDSToUpdate.id);
            
            return [select Id,POC_Term__c,Phone_and_Shippment__c,Phone_type__c,Main_Area_Code__c,Number_of_User__c,Edition__c,Comment__c,Name,Opportunity__c,POC_Conversion_to_Paid_Requested__c,Opportunity__r.Name, Discount_Details__c,Status__c, Sub_Status__c,
                    Type__c, Customer_Account__c, Partner_Quote__r.POC__c,Partner_Quote__c,
                    Customer_Account__r.Name,Partner_Account__c, Partner_Account__r.Name,Partner_Account__r.Partner_ID__c, 
                    Partner_Contact__c,Partner_Contact__r.FirstName,Partner_Contact__r.LastName,
                    Promo_code__c,Escalated_To_Avaya_Deal_Desk__c,
                    Partner_Quote__r.Name,Lead__c,Lead__r.Company, Discount__c,Approved_Discount__c, Owner.Name,Escalated_To_Legal__c,Engage_Legal_Comments__c,Opportunity__r.Avaya_Cloud_Specialist__c,Opportunity__r.Owner.Name, Discount_Amount__c, Approved_Discount_Amount__c,
                    (select Id,Comments__c from Deal_Support_Comments__r) from Deal_Support__c 
                    where Id=:objDSToUpdate.Id];
        } catch(Exception ex){
            System.debug('Error++++'+ex.getMessage());
            return null;
        }
    }
    
    
    public class PartnerDealSupportCommentsWrapper {        
        @AuraEnabled
        public List<Deal_Support_Comments__c> partnerDealSupportCommentsList {get;set;}        
    }
    public class DealSupportWrapper {        
        @AuraEnabled
        public Deal_Support__c dealSupport {get;set;}    
        @AuraEnabled
        public Boolean isAvaya {get;set;} 
        @AuraEnabled
        public Boolean isPOCQuote {get;set;} 
        @AuraEnabled
        public boolean isOnlyAvaya {get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public boolean isSingleLogin {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}  
        @AuraEnabled
        public String translatedType {get;set;}
        @AuraEnabled
        public String statusValueTranslated {get;set;} 
    }
    public class DealSupportListWrapper{
        @AuraEnabled
        public Integer pageSize {get;set;}
        @AuraEnabled
        public Integer pageNumber {get;set;}
        @AuraEnabled
        public Integer totalRecords {get;set;}
        @AuraEnabled
        public Integer recordStart {get;set;}
        @AuraEnabled
        public Integer recordEnd {get;set;}
        @AuraEnabled
        public List<Deal_Support__c> dealSupportList {get;set;}
    }
    public class AccountListWrapper{
        @AuraEnabled
        public List<Account> listPartnerAccounts {get;set;}
        @AuraEnabled
        public boolean isAvaya {get;set;}
        @AuraEnabled
        public boolean isOnlyAvaya {get;set;}
        @AuraEnabled
        public boolean isReadOnly {get;set;}
        @AuraEnabled
        public boolean isSingleLogin {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public List<User_Account_Mapping__c> listUserAccountMap {get;set;}  //added for Single Login
        
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}    
    }
}
public class PartnerQuoteListController {
    
    //Translation Start

    @AuraEnabled
    public static CommunityInfo.Translationswrap getTranslations(String objNames)
    {        
        return CommunityInfo.getTranslations(objNames);
    }    
    //Translation End
    @AuraEnabled
    public static QuoteListWrapper getQuoteData(String selectedPartnerAccount,Decimal pageNumber, Decimal pageSize,String searchKeyWord, String searchBy,String viewAll){
        
        QuoteListWrapper quoteWrapperObj = new QuoteListWrapper();
        Integer pSize = (Integer)pageSize;
        Integer pNumber = (Integer)pageNumber;  
        //Offset for SOQL 
        Integer offset = (pNumber - 1) * pSize; 
        Integer recordEnd = pSize * pNumber;
        List<Partner_Quote__c> quoteLst = new List<Partner_Quote__c>();
        List<Account> accList = new List<Account>();  
        String whereCon = '';
        Integer totalRecords;
        String sortQry = '';
        //get the current logged in Network Name
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        List<String> brandNamesList = comDetail.Brand_Name__c.split(';');
        
        String AVAYAOFFICE = '';
        if(System.Label.AVAYACLOUDOFFICE!= null&&String.valueOf(System.Label.AVAYACLOUDOFFICE)!=null) {
            AVAYAOFFICE=String.valueOf(System.Label.AVAYACLOUDOFFICE);
        }
        if(System.Label.Avaya_Pagination_Limit != null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)!=null && Integer.valueOf(System.Label.Avaya_Pagination_Limit)>0) {
            totalRecords = Integer.valueOf(System.Label.Avaya_Pagination_Limit);
        } else {
            totalRecords=1000;
        }
        Set<Id> setUserAccIds = new Set<Id>();
        if(getAccountList().listUserAccountMap != null && !getAccountList().listUserAccountMap.isEmpty()){
            for(User_Account_Mapping__c uam : getAccountList().listUserAccountMap){
                setUserAccIds.add(uam.Partner_Account__c);
            }
        }
        system.debug('setUserAccIds>'+setUserAccIds);
        
        if( !viewAll.equalsIgnoreCase('all') && selectedPartnerAccount == null){
            accList = getAccountList().listPartnerAccounts;
            system.debug('accList>>' +accList);
            if(accList.size() > 0){
                selectedPartnerAccount = accList[0].Id;  
            }
            // where    
            whereCon = ' where (Opportunity__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__c IN: setUserAccIds)';
            
            if(brandNamesList.contains('Unify Office')) {
                whereCon = ' where (Opportunity__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__r.Partner_Account__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__c IN: setUserAccIds)';
            }
            if(null!= searchKeyWord && searchKeyWord != ''){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                whereCon += ' And '+ searchBy+ '  Like '+searchKey;
            }
        }else if(!viewAll.equalsIgnoreCase('all') && selectedPartnerAccount != null){
            whereCon = ' where (Opportunity__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__c IN: setUserAccIds)';
            if(brandNamesList.contains('Unify Office')) {
                whereCon = ' where (Opportunity__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__r.Partner_Account__r.Partner_Account__c =\''+ selectedPartnerAccount +'\' OR Opportunity__r.Partner_Account__c IN: setUserAccIds)';
            }
            if(null!= searchKeyWord){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                whereCon += ' And '+ searchBy+ '  Like '+searchKey;
            }
        }else{
            if(null!= searchKeyWord && searchKeyWord != ''){
                String searchKey =  '\'%'+searchKeyWord + '%\'';
                whereCon += ' where '+ searchBy+ '  Like '+searchKey;
            }
        }
        
        if(!brandNamesList.contains('Avaya Cloud Office')){
            if(whereCon != null && whereCon != ''){
                whereCon += ' and Opportunity__r.Brand_Name__c IN: brandNamesList';
            }else{
                whereCon = ' where Opportunity__r.Brand_Name__c IN: brandNamesList';
            } 
        }else{
            if(whereCon != null && whereCon != ''){
                whereCon += ' and (Opportunity__r.Brand_Name__c = \''+AVAYAOFFICE+'\' OR Brand_Name__c = null)' ;
            }else{
                whereCon = ' where (Opportunity__r.Brand_Name__c = \''+AVAYAOFFICE+'\' OR Brand_Name__c = null)' ;
            }
        }
        String query = 'select count() from Partner_Quote__c '+whereCon;        

        Integer totSize = Database.countquery(query);
        
        if(totSize<totalRecords){
            totalRecords = totSize;
        }
        if(null!=totalRecords && totalRecords > 0){
            query = 'select Id,Opportunity__r.Type,Name,Opportunity__r.Name, CreatedDate,Product_Edition__r.Name,Number_of_Licenses__c,Payment_Term__c,Opportunity__r.Partner_Contact__r.Name,Primary__c,toLabel(Status__c),Opportunity__r.Partner_Account__r.Name,Opportunity__r.Partner_Account__r.Partner_ID__c,Opportunity__r.Partner_Account__r.Id,CurrencyIsoCode from Partner_Quote__c ';
            query += whereCon;
            query += '  ORDER BY CreatedDate DESC LIMIT :pSize OFFSET :offset'; 
            
            quoteLst = Database.query(query);
            quoteWrapperObj.quoteList = quoteLst;
        }
        quoteWrapperObj.pageSize = pSize;
        quoteWrapperObj.pageNumber = pNumber;
        quoteWrapperObj.recordStart = offset + 1;
        quoteWrapperObj.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        quoteWrapperObj.totalRecords = totalRecords;
        
        return quoteWrapperObj;
    }
    @AuraEnabled
    public static AccountListWrapper getAccountList(){
        //get ParentAccount list to be populated in drop-down of list view
        AccountListWrapper accListWrapper=new AccountListWrapper();
        
        List<Account> listofPartnerAccounts =new List<Account>();
        String selectedPartnerAccount = PartnerDealRegistrationUtil.getSelectedPartnerId();
        
        CommunityInfo comm = new CommunityInfo();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        
        //Single Login 24-08-2020
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
        
        if(selectedPartnerAccount != NULL){
            for(Account acc : [SELECT Id, Name,Partner_Role__c FROM Account WHERE Id =:selectedPartnerAccount 
                               AND Type='Partner' order by Name]){
                                   listofPartnerAccounts.add(acc);
                                   if(acc.id==comDetail.Portal_Top_Master_Account_Id__c){
                                       accListWrapper.isAvaya=true;
                                       accListWrapper.isMaster=false;
                                   }else if(acc.Partner_Role__c=='Master Agent'){
                                       accListWrapper.isAvaya=false;
                                       accListWrapper.isMaster=true;
                                   }
                               }
            accListWrapper.listPartnerAccounts=listofPartnerAccounts;
        }
        //get the current logged in Network Name
        accListWrapper.partnerCommunityName=comDetail.Brand_Name__c.split(';');
        accListWrapper.communityDetailsRecord=comDetail;
        return accListWrapper;
    }
    public class QuoteListWrapper{
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
        public List<Partner_Quote__c> quoteList {get;set;}
    }
    public class AccountListWrapper{
        @AuraEnabled
        public List<Account> listPartnerAccounts {get;set;}
        @AuraEnabled
        public boolean isAvaya {get;set;}
        @AuraEnabled
        public boolean isMaster {get;set;}
        @AuraEnabled
        public boolean isSingleLogin {get;set;}
        @AuraEnabled
        public List<String> partnerCommunityName{get;set;}
        @AuraEnabled
        public Community_Details__mdt communityDetailsRecord {get;set;}  
        @AuraEnabled
        public List<User_Account_Mapping__c> listUserAccountMap {get;set;}
    }
}
public without sharing class Partner_CloudSpecialistSearchController {

    @AuraEnabled
    public static List<Contact> getUsersForCloudSpecialist(String UserName, String SFBrandName){
        String ProfileId = UserInfo.getProfileId();
        String topMasterId='';
        Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        if(comDetail == null) {
            //pbc-10695
        	Map<String,Community_Details__mdt> commdetails = CommunityInfo.getAllCommunityDetails();
        	comDetail = commdetails.get(SFBrandName);
        }
        if(comDetail != null) {
        	topMasterId=comDetail.Portal_Top_Master_Account_Id__c;
        }
        String query='';
        List<Contact> listOfCloudSpecialist=new List<Contact>();
        if(UserName!=null && UserName!=''){
            query='Select Id, Name,Account.Name,Account.Id,Email FROM Contact '+
                    ' Where Account.type= '+'\'Partner\' And Account.Avaya_partnership_account__c = true And AccountId = \''+topMasterId+'\'';
            String searchKey =  '\'%'+UserName + '%\'';
            query += ' And Name Like '+searchKey;
            listOfCloudSpecialist= Database.query(query);
            system.debug('listOfCloudSpecialist--'+listOfCloudSpecialist);
           
        }
        return listOfCloudSpecialist;
    }
    
    @AuraEnabled
    public static Contact PartnerAccountMasterAgtChlMgr(String cloudSpecialistName){
        List<Contact> listOfContacts=new List<Contact>();
        String masterAgentChlMgrId='';
       
         system.debug('cloudSpecialistName--'+cloudSpecialistName);
        String topMasterId='';
         Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();
        if(comDetail!=null) {
        	topMasterId=comDetail.Portal_Top_Master_Account_Id__c;
        }
        if(cloudSpecialistName!=null && cloudSpecialistName !=''){
            if(cloudSpecialistName.startsWithIgnoreCase('003')){
                listOfContacts=[select Id,Name from contact 
                                where contact.account.avaya_partnership_account__c=true and id=:cloudSpecialistName and contact.accountid=:topMasterId
                                and account.ispartner=true and account.type='Partner'];
            }
            else{
                listOfContacts=[select Id,Name from contact 
                                where contact.account.avaya_partnership_account__c=true and name=:cloudSpecialistName and contact.accountid=:topMasterId
                                and account.ispartner=true and account.type='Partner'];
            }
        }
        if(listOfContacts !=null && !listOfContacts.isEmpty() && listOfContacts.size()>0){
            masterAgentChlMgrId=listOfContacts[0].Id;
            return listOfContacts[0];
        }
        return null;
    }
    
    
}
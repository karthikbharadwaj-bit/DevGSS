public without sharing class GSPGuestLoginController {
    @AuraEnabled
    public static EmailCheckWrapper checkContactEmail(String GuestEmail)
    {
        EmailCheckWrapper emailCheckWrapper = new EmailCheckWrapper();
        String CommunityName;
        String GuestEmailDomain;
        List<String> GSPBrandNames = new List<String> ();
		List<Contact> ContactReltoEmail = new List<Contact> ();
        List<Contact> ContactReltoEmailDomain = new List<Contact> ();
        List<Account> AccountReltoEmailDomain = new List<Account> ();
        List<GSP_Partner_Email_Domain__c> GspEmailDomain=new List<GSP_Partner_Email_Domain__c>();
        List<Network> netwrk = [Select id, Name from Network where Id =: Network.getNetworkId()];
        if(!netwrk.isEmpty()){
            CommunityName = netwrk[0].Name;
        }
        if(Test.isRunningTest()) {
            CommunityName = 'GSP';
        }
        system.debug('network - ' + CommunityName);
        List<Community_Details__mdt> CommunityDetailList = [select Brand_Name__c from Community_Details__mdt where MasterLabel =: CommunityName];
        system.debug('CommunityDetailList - ' + CommunityDetailList);
        for(Community_Details__mdt CommunityDetail : CommunityDetailList)
        {
            for(String GSPBrandName : CommunityDetail.Brand_Name__c.split(';'))
            {                
                GSPBrandNames.add(GSPBrandName);
            }
        }
        system.debug('GSPBrandNames - ' + GSPBrandNames);
        system.debug('GuestEmail - ' + GuestEmail);

        GuestEmailDomain = GuestEmail.substringAfterLast('@');
        
		List<Id> AccountIdsLinkedtoDomain = new List<Id>();
        List<Account> AccountsLinkedtoDomain = new List<Account>();
        Set<Id> PartnerContactIdsReltoEmail = new Set<Id>();
        List<Contact> PartnerContactsReltoEmail = new List<Contact>();
        
        List<NetworkMember> NetworkMember = [select NetworkId, network.Name, MemberId, Member.Name, Member.username, Member.isActive from NetworkMember 
                                             where NetworkId = :Network.getNetworkId() and Member.isActive = true and Member.Email = : GuestEmail 
                                            and Member.Profile.UserLicense.Name = 'Partner Community'];
        
        if(!NetworkMember.isEmpty())
        {
            emailCheckWrapper.PartnerUserExist = true;
            return emailCheckWrapper;
        }
        
        List<GSP_Partner_Email_Domain__c> GSP_Partner_Domains = [Select Id, Name, Email_Domain__c, Partner_Account__c, Partner_Account__r.RC_Brand__c,  
                                                                 Partner_Account__r.Permitted_Brands__c from GSP_Partner_Email_Domain__c 
                                                                 where Partner_Account__c != null and Email_Domain__c = :GuestEmailDomain];
        if(!GSP_Partner_Domains.isEmpty())
        {
            emailCheckWrapper.PartnerDomainExist = true;
            for(GSP_Partner_Email_Domain__c GSP_Partner_Domain : GSP_Partner_Domains)
            {
                AccountIdsLinkedtoDomain.add(GSP_Partner_Domain.Partner_Account__c);
            }
        }
        
        if(!AccountIdsLinkedtoDomain.isEmpty())
        {
            AccountsLinkedtoDomain = [Select Id, Name, RC_Brand__c, Permitted_Brands__c from Account where Id in: AccountIdsLinkedtoDomain];
            
            if(!AccountsLinkedtoDomain.isEmpty())
            {
                emailCheckWrapper.PartnerReltoDomain = AccountsLinkedtoDomain[0];
                emailCheckWrapper.PartnersReltoDomain = AccountsLinkedtoDomain;
            }
            Map<Id, Contact> PartnerContactsReltoEmailMap = new Map<Id, Contact>([Select Id, Name, Email,AccountId, Account.Permitted_Brands__c,Account.RC_Brand__c from Contact 
                                                                                  where Email =: GuestEmail and AccountId in :AccountIdsLinkedtoDomain]);
            if(!PartnerContactsReltoEmailMap.isEmpty())
            {
                emailCheckWrapper.PartnerContactExist = true;
                PartnerContactIdsReltoEmail = PartnerContactsReltoEmailMap.keySet();
                PartnerContactsReltoEmail = PartnerContactsReltoEmailMap.values();
                if(!PartnerContactsReltoEmail.isEmpty())
                {
                    emailCheckWrapper.PartnerContactReltoEmail = PartnerContactsReltoEmail[0];
                }
            }
        }
        system.debug('AccountsLinkedtoDomain - ' + AccountsLinkedtoDomain);
        system.debug('PartnerContactsReltoEmail - ' + PartnerContactsReltoEmail);
        return emailCheckWrapper;
    }
    
    @AuraEnabled
    public static Map<String, String> createContactRecord(Contact newContact, String dealSupportType) {
        // Forming a  string map to return response
        Map<String,String> resultMap = new Map<String,String>();
        String CommunityName;
        String BrandName;
        String BrandNameStr;
        Id accid = newContact.AccountId;
        // Adding try catch for exception handling
        try {
            
            List <RecordType> rtList = [select id, Name from RecordType where SobjectType='Contact' And Name = 'VAR Visible'];
            List<Account> accList = [select id, name, RC_Brand__c from Account where id =:accid ];
            if(!accList.isEmpty())
            {
            BrandName = accList[0].RC_Brand__c;
            BrandNameStr = '%'+ BrandName + '%';    
            }
            if(null!=rtList && rtList.size()>0){
                newContact.RecordTypeId = rtList.get(0).id;
            }
        List<Network> network = [Select id, Name from Network where Id =: Network.getNetworkId()];
        if(!network.isEmpty()){
            CommunityName = network[0].Name;
        }
        system.debug('network - ' + CommunityName);
        List<Community_Details__mdt> CommunityDetailList = [select Brand_Name__c, Portal_Deal_Desk_User__c from Community_Details__mdt 
                                                            where MasterLabel =: CommunityName and Brand_Name__c like :BrandNameStr];
            if(!CommunityDetailList.isEmpty()) {
                newContact.OwnerId =CommunityDetailList[0].Portal_Deal_Desk_User__c;
            }
            newContact.Marketo_Sync_Disabled__c = true;
            newContact.Avaya_Partnership_Contact__c = true;
            
            // Inserting the Contact
            insert newContact;
            ID contactId = newContact.Id;
            if(dealSupportType.equals('New Partner User Request')){
                Boolean dealSupportExist=false;
                if(contactId != null) {
                    dealSupportExist = dealSupportExists(contactId,'New Partner User Request');
                }
                if(!dealSupportExist){
                    Deal_Support__c dealSupp = new Deal_Support__c();
                    if(newContact.AccountId != null) {
                        dealSupp.Partner_Account__c = newContact.AccountId;
                    }
                    dealSupp.Partner_Contact__c = contactId;
                    dealSupp.Type__c = 'New Partner User Request';
                    dealSupp.Name ='New Partner User Request - ' +newContact.FirstName +' ' +newContact.LastName;
                    dealSupp.Brand_Name__c = accList.get(0).RC_Brand__c;
                    insert dealSupp; 
            }
            }else{
                Deal_Support__c dealSupp = new Deal_Support__c();
                dealSupp.Partner_Account__c = newContact.AccountId;
                dealSupp.Partner_Contact__c = newContact.Id;
                dealSupp.Type__c = 'New Contact Request';
                dealSupp.Name ='New Contact Request - ' +newContact.FirstName +' ' +newContact.LastName; 
                dealSupp.Brand_Name__c = accList.get(0).RC_Brand__c;
                insert dealSupp; 
            } 
            
            resultMap.put('status', 'success');
            resultMap.put('message', 'Contact created successfully!');    
            resultMap.put('contactId', contactId);
        }
        catch(Exception e) {
            // Setting the error status and message in resultMap
            resultMap.put('status', 'error');
            resultMap.put('message',e.getMessage());
        }
        // Returning the result string map
        return resultMap;        
    }
    @AuraEnabled
    public static Map<String, String> createNewPartnerContactRecord(Contact newContact){
        EmailCheckWrapper emailCheckWrapper = checkContactEmail((string)newContact.Email);
        newContact.AccountId=emailCheckWrapper.PartnerReltoDomain.Id;
        Map<String,String> resultMap = createContactRecord(newContact,'New Partner User Request');
        return resultMap; 
    }
    @AuraEnabled
    public static void sendVerificationCode(String GuestEmail, Integer verificationCode, String emailBody) {
        try{
        List<Messaging.SingleEmailMessage> allMails =  new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> sendToAddresses = new List<String>();
        sendToAddresses.add(GuestEmail);
        email.setToAddresses(sendToAddresses);
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address ='vikram.sharma@ringcentral.com']; 
        if( owea.size() > 0 ){ 
            email.setOrgWideEmailAddressId(owea.get(0).Id); 
        }
        email.setSubject('GSP Portal - Verification Code');   
        email.setReplyTo('noreply@ringcentral.com');
            email.setHtmlBody(emailBody);
        allMails.add(email);
        Messaging.sendEmail(allMails);
        }catch(Exception e){
            system.debug('error'+e);
        }
    }
    @AuraEnabled
    public static Boolean dealSupportExists(Id contactId,String type){
        List<Deal_Support__c> listOfDSs = [SELECT id FROM Deal_Support__c 
                                           WHERE Partner_Contact__c =: contactId and type__c = :type];
        return !listOfDSs.isEmpty();
    }
    @AuraEnabled
    public static String requestForUserAccessPortal(String partnerUserRequestEmail){
        EmailCheckWrapper emailCheckWrapper= checkContactEmail(partnerUserRequestEmail);
        Contact existingContact = emailCheckWrapper.PartnerContactReltoEmail;
        try {
            if(existingContact != null){
                String accountId=existingContact.AccountId;
                String contactId=existingContact.Id;
                Boolean dealSupportExist=false;
                if(contactId != null) {
                    dealSupportExist = dealSupportExists(existingContact.Id,'New Partner User Request');
                }
                if(!dealSupportExist){
                    Deal_Support__c dealSupp = new Deal_Support__c();
                    if(accountId != null) {
                        dealSupp.Partner_Account__c = accountId;
                    }
                    if(contactId != null) {
                        dealSupp.Partner_Contact__c = contactId;
                    }
                    dealSupp.Type__c = 'New Partner User Request';
                    dealSupp.Name ='New Partner User Request - ' +existingContact.Name; 
                    dealSupp.Brand_Name__c = existingContact.Account.RC_Brand__c;
                    insert dealSupp; 
                    return	'SUCCESS';
                }else{
                    return	'User Activation Request Sent Already!!';
                }
            }
        }  catch(Exception e) {
            system.debug('Exception--'+e.getMessage());
            return	'ERROR ';
            
        }
        return partnerUserRequestEmail;
    }
    
    @AuraEnabled
    public static Boolean getLastLoginDetails(){
       String userId = UserInfo.getUserId();
        List<LoginHistory> loginHistoryList=Database.query('select CountryIso,Id,LoginTime,LoginType,UserId,Status from LoginHistory where UserId=\''+userId+'\' order by LoginTime desc limit 100');
        List<LoginHistory> successLoginHistory=new List<LoginHistory>();
        DateTime currentTime = DateTime.now();
        for(LoginHistory eachLogin:loginHistoryList){
            if(eachLogin.Status.equals('Success')) {
                successLoginHistory.add(eachLogin);
            }
        }
        Double timeDifferenceMins=(currentTime.getTime() - successLoginHistory[0].LoginTime.getTime())/60000;
        System.debug('timeDifferenceMins '+timeDifferenceMins);
        System.debug('successLoginHistory '+successLoginHistory.size());
        if(successLoginHistory.size() <= 2 && timeDifferenceMins <2) {
            return true;
        }
        return false;
    }
    
    public class EmailCheckWrapper
    {
        @AuraEnabled
        public boolean PartnerContactExist {get;set;}
        @AuraEnabled
        public boolean PartnerUserExist {get;set;}
        @AuraEnabled
        public boolean PartnerDomainExist {get;set;}
        @AuraEnabled
        public Account PartnerReltoDomain {get;set;}
        @AuraEnabled
        public List<Account> PartnersReltoDomain {get;set;}
        @AuraEnabled
        public Contact PartnerContactReltoEmail {get;set;}
    }
}
public class Partner_HelpController {
    @AuraEnabled
    public static void sendEmailController(String emailSubject, String emailBody)
    {
        List<Messaging.SingleEmailMessage> allMails =  new List<Messaging.SingleEmailMessage>();  
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> sendToAddresses = new List<String>();
        List<Account> userInfoDetailAccount = new List<Account>();
        String currentUserPartnerCountry='';
        String emailAddresses ='';
        List<String> brandNamesList=new List<String>();
        Community_Details__mdt comDetail=CommunityInfo.getCommunityDetails();
        brandNamesList=comDetail.Brand_Name__c.split(';');
        String masterLabel=comDetail.MasterLabel;
        if(Test.isRunningTest())
        {
            brandNamesList.add('RingCentral');
            masterLabel='ignite';
        }
        if(brandNamesList.contains('RingCentral')&&(masterLabel=='ignite')){ 
            List<User> userInfoDetail =  [select contact.accountid from user where id =: UserInfo.getUserId()];
            system.debug('userInfoDetail -'+userInfoDetail);
            if(!userInfoDetail.isEmpty()) {
                userInfoDetailAccount =  [select id,name,Partner_country__c,RC_Brand__c from account where id =: userInfoDetail.get(0).contact.accountid ];
            }
            system.debug('userInfoDetailAccount -'+userInfoDetailAccount);
            if(!userInfoDetailAccount.isEmpty()){
                currentUserPartnerCountry=userInfoDetailAccount.get(0).Partner_country__c;
            }
            system.debug('brandNamesList*'+brandNamesList);
            List<Community_Detail_Child__mdt> helpToAddressList =[select id,MasterLabel,DeveloperName,Portal_Help_SendTo_Address__c,Country_Name__c from Community_Detail_Child__mdt where Country_Name__c=:currentUserPartnerCountry and Community_Details__r.masterlabel =: comDetail.MasterLabel];
            system.debug('helpToAddressList*'+helpToAddressList);
            if(!helpToAddressList.isEmpty()) {
                emailAddresses =helpToAddressList[0].Portal_Help_SendTo_Address__c;
            }
        }else{
            emailAddresses=comDetail.Portal_Help_SendTo_Addresses__c;
        }
        /*Commented to send from address as current user String fromAddress=comDetail.Portal_Help_Email_Address__c;BZS-5110*/
        if(emailAddresses != null){
            sendToAddresses = emailAddresses.split(';');
        }
        email.setToAddresses(sendToAddresses);
        email.setReplyTo('noreply@ringcentral.com'); 
        email.setSubject(emailSubject);
        email.setHtmlBody(emailBody);        
        allMails.add(email);
        if(!Test.isRunningTest()) {
            Messaging.sendEmail(allMails);
        }
    }
}
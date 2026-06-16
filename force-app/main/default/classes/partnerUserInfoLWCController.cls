/*
Change History
********************************************************************************************************************
SCRUM/Jira      		ModifiedBy      Date     	Description       									Tag
Partner Home Tab		Ishwarya		11/26/2019	Added logic to display contact details dynamically	T1	
********************************************************************************************************************
*/
public class partnerUserInfoLWCController {
    //<T1>***********************
    @AuraEnabled(cacheable = true)
    public static partnerUserWrapper getUserInfo(String Id){
        partnerUserWrapper partnerUser;
        Boolean isAvaya = false;
        Boolean isIgnite = false;
        Boolean isInsideSalesRep = false;
        try{
            String brandName = CommunityInfo.getBrandName();
            
            User u = [SELECT Id,Name,ContactId,Contact.Account.Name,Contact.Account.Partner_ID__c, Contact.Account.Inside_Sales_Rep__r.Name, 
                        Contact.Account.Inside_Sales_Rep__r.Email, Contact.Account.Inside_Sales_Rep__r.Phone,Contact.Account.Master_Agent_Channel_Manager__c,
                        Contact.Account.Partner_Country__c,Contact.Account.Permitted_Brands__c,Contact.Account.Channel_Manager_Email__c,Contact.Account.Channel_Manager_Name__c,Contact.Account.Channel_Manager_Phone__c  FROM User WHERE Id = :Id];
                        
            if(u.Contact != null && u.Contact.Account != null && u.Contact.Account.Permitted_Brands__c != null && u.Contact.Account.Permitted_Brands__c != ''){
                if(brandName == 'Avaya Cloud Office'){
                    isAvaya = true;
            	}
                else if((brandName.indexOf('RingCentral') != -1) || (brandName == 'Rainbow Office')){
                    isInsideSalesRep = true;
                    if(brandName.indexOf('RingCentral') != -1){
                        isIgnite = true;
                    }
                }
                else{
                    isAvaya = true;
                }
            }
            partnerUser = new partnerUserWrapper(u.Name,u.Contact.Account.Name,u.Contact.Account.Partner_ID__c,u.Contact.Account.Master_Agent_Channel_Manager__c, 
                        '',
                        u.Contact.Account.Partner_Country__c, u.Contact.Account.Channel_Manager_Name__c,
                        u.Contact.Account.Channel_Manager_Phone__c,u.Contact.Account.Channel_Manager_Email__c,isAvaya,isIgnite,isInsideSalesRep);           
        }
        catch(Exception e){
           partnerUser = new partnerUserWrapper('', '', '', '', '', '','','','',false,false,false);
        }        
        return partnerUser;
    }
    //</T1>**********************
    public class partnerUserWrapper {
        @AuraEnabled
        public String UserName {get;set;}
        @AuraEnabled       
        public String CompanyName {get;set;}
        @AuraEnabled
        public String PartnerId {get;set;}
        @AuraEnabled
        public String ChannelManagerName {get;set;}
        @AuraEnabled
        public String ChannelManagerPhone {get;set;}
        @AuraEnabled
        public String PartnerCountry {get;set;}
        @AuraEnabled
        public String InsideSalesRepName {get;set;}
        @AuraEnabled
        public String InsideSalesRepPhone {get;set;}
        @AuraEnabled
        public String InsideSalesRepEmail {get;set;}
        @AuraEnabled
        public Boolean isIgnite {get;set;}
        @AuraEnabled
        public Boolean isAvaya {get;set;}
        @AuraEnabled
        public Boolean isInsideSalesRep {get;set;}

        public partnerUserWrapper(String UserName, String CompanyName, String PartnerId, String ChannelManagerName, String ChannelManagerPhone,
         String PartnerCountry,String InsideSalesRepName,String InsideSalesRepPhone,
         String InsideSalesRepEmail,Boolean isAvaya,Boolean isIgnite,Boolean isInsideSalesRep){
            this.UserName = UserName;
            this.CompanyName = CompanyName;
            this.PartnerId = PartnerId;
            this.ChannelManagerName = ChannelManagerName;
            this.ChannelManagerPhone = ChannelManagerPhone;
            this.PartnerCountry = PartnerCountry;
            this.InsideSalesRepName = InsideSalesRepName;
            this.InsideSalesRepPhone = InsideSalesRepPhone;
            this.InsideSalesRepEmail = InsideSalesRepEmail;
            this.isIgnite = isIgnite;
            this.isAvaya = isAvaya;
            this.isInsideSalesRep=isInsideSalesRep;
        }
    }
}
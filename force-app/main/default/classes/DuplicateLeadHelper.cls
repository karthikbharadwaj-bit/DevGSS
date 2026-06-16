/**
 * Created by capitan on 8/7/17.
 */

public with sharing class DuplicateLeadHelper {

    public static String createLeadJson (Lead leadObj, User usr) {
        DuplicateLeadInfo dli = new DuplicateLeadInfo();
//        dli.FirstName = leadObj.FirstName;
//        dli.LastName = leadObj.LastName;
//        dli.Title = leadObj.Title;
//        dli.Company = leadObj.Company;
//        dli.Email = leadObj.Email;
//        dli.Phone = leadObj.Phone;
        dli.LeadSource = leadObj.LeadSource;
        dli.OwnerId = usr != null ? usr.Id : null;
        dli.Website = leadObj.Website;
        dli.Industry = leadObj.Industry;
        dli.Lead_Brand_Name = leadObj.Lead_Brand_Name__c;
        dli.Lead_Tier_Name = leadObj.Lead_Tier_Name__c;
        dli.Country = leadObj.Country;
        dli.State = leadObj.State;
        dli.City = leadObj.City;
        dli.Partner_Lead_Source = leadObj.Partner_Lead_Source__c;
        dli.Estimated_Close_Date = leadObj.Estimated_Close_Date__c;
//        dli.Phone_Alternate = leadObj.Phone_Alternate__c;
        dli.RC_Edition = leadObj.RC_Edition__c;
        dli.RC_Term = leadObj.RC_Term__c;

        return JSON.serializePretty(dli);
    }

    public static void fillLeadFromJson(Lead leadObj, String jsonString) {
        DuplicateLeadInfo dli = (DuplicateLeadInfo) JSON.deserialize(jsonString, DuplicateLeadInfo.class);

//        leadObj.FirstName = dli.FirstName;
//        leadObj.LastName = dli.LastName;
//        leadObj.Title = dli.Title;
//        leadObj.Company = dli.Company;
//        leadObj.Email = dli.Email;
//        leadObj.Phone = dli.Phone;
        leadObj.LeadSource = dli.LeadSource;
        leadObj.OwnerId = dli.OwnerId;
        leadObj.Website = dli.Website;
        leadObj.Industry = dli.Industry;
        leadObj.Lead_Brand_Name__c = dli.Lead_Brand_Name;
        leadObj.Lead_Tier_Name__c = dli.Lead_Tier_Name;
        leadObj.Country = dli.Country;
        leadObj.Country__c = dli.Country;
        leadObj.State = dli.State;
        leadObj.State__c = dli.State;
        leadObj.City = dli.City;
        leadObj.City__c = dli.City;
        leadObj.Partner_Lead_Source__c = dli.Partner_Lead_Source;
        leadObj.Estimated_Close_Date__c = dli.Estimated_Close_Date;
//        leadObj.Phone_Alternate__c = dli.Phone_Alternate;
        leadObj.RC_Edition__c = dli.RC_Edition;
        leadObj.RC_Term__c = dli.RC_Term;
    }

    public class DuplicateLeadInfo {
//        public String FirstName;
//        public String LastName;
//        public String Title;
//        public String Company;
//        public String Email;
//        public String Phone;
        public String LeadSource;
        public String OwnerId;
        public String Website;
        public String Industry;
        public String Lead_Brand_Name;
        public String Lead_Tier_Name;
        public String Country;
        public String State;
        public String City;
        public String Partner_Lead_Source;
        public Date Estimated_Close_Date;
//        public String Phone_Alternate;
        public String RC_Edition;
        public String RC_Term;
    }
}
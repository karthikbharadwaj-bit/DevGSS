/*       
* Created By    : Saradha
* Created Date  : 11-05-2020
* Description   : Controller class for Partner details component
* Test Class    :       

Change History
********************************************************************************************************************
SCRUM/Jira          ModifiedBy      Date            Description                                 Tag
Multiple Brands    Ishwarya        12/05/2020      Updated logic for multiple brands            T1
********************************************************************************************************************
*/
public class CommunityInfo {
    
    public static String CommunityName{get; set;}
    public static boolean enableRestrictCntry{get;set;}
    public static String brandName{get;set;}
    public CommunityInfo(){
        getCommunityName();
    }
    public static String getCommunityName(){        
        if(Test.isRunningTest())
        {        
            CommunityName = 'partner';
            return CommunityName;
        }
        else{
            String communityId = Network.getNetworkId();
            List<Network> network = [Select id,Name from Network where Id =: communityId];
        if(network!=null && network.size() > 0){
            CommunityName = network.get(0).Name;
            return CommunityName;
        }else{
            return null;
        }
    }
    }
    public static String getBrandName(){
        //get the current logged in Network Name
        CommunityInfo comm = new CommunityInfo();
        String comm_info = CommunityInfo.CommunityName;
        system.debug('comm_info:'+comm_info);
        
        List<Community_Details__mdt> comm_mdt = [Select MasterLabel,DeveloperName,Brand_Name__c,Enable_Restrict_Country__c
                                                 from Community_Details__mdt where MasterLabel=:comm_info];
        
        if(comm_mdt.size() > 0){
            enableRestrictCntry = comm_mdt.get(0).Enable_Restrict_Country__c;
            return comm_mdt.get(0).Brand_Name__c;    
        }else{
            return '';
        }
        
    }
    public static Community_Details__mdt getCommunityDetails(){
        //get the current logged in Network Name
        CommunityInfo comm = new CommunityInfo();
        String comm_info = CommunityInfo.CommunityName;
        system.debug('comm_info:'+comm_info);
        if(comm_info == null){
            return null;
        }

        List<Community_Details__mdt> comm_mdt = [Select MasterLabel,DeveloperName,Brand_Name__c,Portal_Top_Master_Account_Id__c,Portal_Cloud_Specialist__c,Brands_Permitted_To_Sell__c,Portal_Deal_Desk_Queue__c,Portal_Deal_Desk_User__c,
                                                 Portal_Help_Email_Address__c,Portal_Main_Label__c,Portal_Queue__c,Portal_SalesOverlay_Queue__c,VAR_Territory__c,Portal_Deal_Desk_Escalation__c,Portal_Opportunity_Owner_Label__c,Portal_Submit_Contract_Legal_Label__c,Portal_Quote_Contract_Team__c,
                                                 Portal_Link_Id__c,Portal_Master_Agent_Channel_Manager__c,UserName_Suffix__c,Portal_Assign_To_Deal_Desk_Label__c,Portal_Help_SendTo_Addresses__c,Portal_Partner_Type__c,Portal_Partner_Source__c,Portal_Partner_Hierarchy__c,

Estimated_12M_Booking_Standard__c, Estimated_12M_RingCentral_Video_Pipeline__c 
                                                 from Community_Details__mdt where MasterLabel=:comm_info];
        
        User currentUser = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.RC_Brand__c 
                                                 FROM User WHERE Id = :UserInfo.getUserId()];
                             
        if(comm_info == 'GSP'){
            for(Community_Details__mdt com : comm_mdt){
                 if(com.Brand_Name__c != null && currentUser.Contact.Account.RC_Brand__c != null){
                         if(com.Brand_Name__c.contains(currentUser.Contact.Account.RC_Brand__c)){
                                 system.debug('Community Info for gsp - ' + com);
                                 return com;
                             }
                     }
             }
        }
        if(comm_mdt.size() > 0){
            return comm_mdt.get(0);    
        }else{
            return null;
        }
        
    }
    
    public static Map<String,Community_Details__mdt> getAllCommunityDetails(){
        //get the current logged in Network Name
        Map<String,Community_Details__mdt> commDetailsMap = new Map<String,Community_Details__mdt>();
        List<Community_Details__mdt> comm_mdt = [Select MasterLabel,DeveloperName,Brand_Name__c,Portal_Top_Master_Account_Id__c,
                                                 Portal_Cloud_Specialist__c,Brands_Permitted_To_Sell__c,
                                                 Portal_Deal_Desk_Queue__c,Portal_Deal_Desk_User__c,
                                                 Portal_Help_Email_Address__c,Portal_Main_Label__c,Portal_Queue__c,
                                                 Portal_SalesOverlay_Queue__c,VAR_Territory__c,Portal_Deal_Desk_Escalation__c,
                                                 Portal_Opportunity_Owner_Label__c,Portal_Submit_Contract_Legal_Label__c,
                                                 Portal_Quote_Contract_Team__c,Portal_Link_Id__c,
                                                 Portal_Master_Agent_Channel_Manager__c,Portal_Assign_To_Deal_Desk_Label__c,
                                                 Portal_Partner_Type__c,Portal_Partner_Source__c,Portal_Partner_Hierarchy__c,UserName_Suffix__c,Portal_Help_SendTo_Addresses__c, 
                                                 Deal_Desk_Queue__c, Is_Porting_Enabled__c, Estimated_12M_Booking_Standard__c, Estimated_12M_RingCentral_Video_Pipeline__c  
                                                from Community_Details__mdt];
        for(Community_Details__mdt commDetail :comm_mdt){
            List<String> brandList = commDetail.Brand_Name__c.split(';');
            for(String brandName:brandList){
                commDetailsMap.put(brandName,commDetail);
            }
        }
        system.debug('comm details map - '+ commDetailsMap);
        if(comm_mdt.size() > 0){
            system.debug('not empty');
            return commDetailsMap;    
        }else{
            system.debug('empty');
            return null;
        }
        
    }
    
    public static List<Id> getAllCommunityTopMastersIds(){        
        List<Id> commTopMastersIds = new List<Id>();
        String comm_info = CommunityInfo.CommunityName;
        system.debug('comm_info:'+comm_info);
        List<Community_Details__mdt> comm_mdt = [Select Portal_Top_Master_Account_Id__c
                                                 from Community_Details__mdt];
        for(Community_Details__mdt commDetail :comm_mdt){
            if(null!=commDetail && null!=commDetail.Portal_Top_Master_Account_Id__c){
                commTopMastersIds.add(commDetail.Portal_Top_Master_Account_Id__c);
            }
            
        }
        if(comm_mdt.size() > 0){
            return commTopMastersIds;    
        }else{
            return null;
        }
        
    }
        //Translation Start
    @AuraEnabled
    public static Translationswrap getTranslations(String objNames)
    {
        Translationswrap translationswrap = new Translationswrap();
        
        Map<String, String> fieldNametoLabelMap = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldsMap = new Map<String, Schema.SObjectField>();
        Map<String, Map<String, String>> allObjFieldsMap = new Map<String, Map<String, String>> ();
        if(objNames != null && objNames != '')
        {
            List<String> objNamesList = objNames.split(',');
            for(String objName : objNamesList)
            {
                fieldNametoLabelMap = new Map<String, String>(); 
                fieldsMap = ((SObject)Type.forName(objName).newInstance()).getSObjectType().getDescribe().fields.getMap(); 
                if(fieldsMap != null && !fieldsMap.isEmpty())
                {
                    for(String field : fieldsMap.keySet()) {
                        Schema.DescribeFieldResult fieldDesc = fieldsMap.get(field).getDescribe();
                        fieldNametoLabelMap.put(fieldDesc.getName(),fieldDesc.getLabel());
                    }
                    allObjFieldsMap.put(objName, fieldNametoLabelMap);
                }
            }
        }
        translationswrap.allObjFieldsMap = allObjFieldsMap;
       
        Map<String, String> prmLabelsMap = new Map<String, String>();
        Map<String, String> prmTranslationsMap = new Map<String, String>();
        List<PRM_Label__mdt> prmLabels = [select DeveloperName, Value__c from PRM_Label__mdt];
        for(PRM_Label__mdt prmLabel : prmLabels)
        {
            prmLabelsMap.put(prmLabel.DeveloperName, prmLabel.Value__c);
        }        
        List<PRM_Translation__mdt> prmTranslations = [select PRM_Label__c, PRM_Label__r.DeveloperName,PRM_Label__r.Value__c, Language__c, Value__c from PRM_Translation__mdt where Language__c =: UserInfo.getLanguage()];
        for(PRM_Translation__mdt prmTranslation : prmTranslations)
        {
            if(prmTranslation.Value__c != null){
                prmTranslationsMap.put(prmTranslation.PRM_Label__r.DeveloperName, prmTranslation.Value__c);
            }
        }
        prmLabelsMap.putAll(prmTranslationsMap);
        translationswrap.prmLabelsMap = prmLabelsMap;
        
        Map<String, String> prmSpecificLabelsMap = new Map<String, String>();
        Map<String, String> prmSpecificTranslationsMap = new Map<String, String>();
        String networkName;
        List<Network> network = [Select id, Name from Network where id =: Network.getNetworkId()];
        if(Test.isRunningTest()){
            network = [Select id, Name from Network limit 1];
        }
        if(network != null && network.size() > 0) {
            networkName = network[0].Name;
            networkName = '%' + networkName + '%';
            List<PRM_Specific_Label__mdt> prmSpecificLabels = [Select Generic_API_Name__c, Value__c, Site_Name__c from PRM_Specific_Label__mdt 
                                                               where Site_Name__c like : networkName];
            for(PRM_Specific_Label__mdt prmSpecificLabel : prmSpecificLabels)
            {
                prmSpecificLabelsMap.put(prmSpecificLabel.Generic_API_Name__c, prmSpecificLabel.Value__c);
            }    
            List<PRM_Specific_Translation__mdt> prmSpecificTranslations = [Select PRM_Specific_Label__r.Generic_API_Name__c, PRM_Specific_Label__r.Site_Name__c,  
                                                                           Language__c, Value__c from PRM_Specific_Translation__mdt 
                                                                           where Language__c =: UserInfo.getLanguage() and PRM_Specific_Label__r.Site_Name__c like : networkName];
            
            for(PRM_Specific_Translation__mdt prmSpecificTranslation : prmSpecificTranslations)
            {
                if(prmSpecificTranslation.Value__c != null){
                    prmSpecificTranslationsMap.put(prmSpecificTranslation.PRM_Specific_Label__r.Generic_API_Name__c, prmSpecificTranslation.Value__c);
                }
            } 
            prmSpecificLabelsMap.putAll(prmSpecificTranslationsMap);
        }
        translationswrap.prmSpecificLabelsMap = prmSpecificLabelsMap;
        
        return translationswrap;
    }
     //Translation End
     
     //Translation Start for PRM 80
    @AuraEnabled
    public static Translationswrap getTranslations1(String objNames,String selectedLanguage)
    {
        Translationswrap translationswrap = new Translationswrap();
        
        Map<String, String> fieldNametoLabelMap = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldsMap = new Map<String, Schema.SObjectField>();
        Map<String, Map<String, String>> allObjFieldsMap = new Map<String, Map<String, String>> ();
        if(objNames != null && objNames != '')
        {
            List<String> objNamesList = objNames.split(',');
            for(String objName : objNamesList)
            {
                fieldNametoLabelMap = new Map<String, String>(); 
                fieldsMap = ((SObject)Type.forName(objName).newInstance()).getSObjectType().getDescribe().fields.getMap(); 
                if(fieldsMap != null && !fieldsMap.isEmpty())
                {
                    for(String field : fieldsMap.keySet()) {
                        Schema.DescribeFieldResult fieldDesc = fieldsMap.get(field).getDescribe();
                        fieldNametoLabelMap.put(fieldDesc.getName(),fieldDesc.getLabel());
                    }
                    allObjFieldsMap.put(objName, fieldNametoLabelMap);
                }
            }
        }
        translationswrap.allObjFieldsMap = allObjFieldsMap;
       
        Map<String, String> prmLabelsMap = new Map<String, String>();
        Map<String, String> prmTranslationsMap = new Map<String, String>();
        List<PRM_Label__mdt> prmLabels = [select DeveloperName, Value__c from PRM_Label__mdt];
        for(PRM_Label__mdt prmLabel : prmLabels)
        {
            prmLabelsMap.put(prmLabel.DeveloperName, prmLabel.Value__c);
        }        
        system.debug(':::::selectedLanguage::::'+selectedLanguage);
        List<PRM_Translation__mdt> prmTranslations = [select PRM_Label__c, PRM_Label__r.DeveloperName,PRM_Label__r.Value__c, Language__c, Value__c from PRM_Translation__mdt where Language__c =: selectedLanguage];
        system.debug(':::::prmTranslations::::'+prmTranslations);
        for(PRM_Translation__mdt prmTranslation : prmTranslations)
        {
            if(prmTranslation.Value__c != null){
                prmTranslationsMap.put(prmTranslation.PRM_Label__r.DeveloperName, prmTranslation.Value__c);
            }
        }
        prmLabelsMap.putAll(prmTranslationsMap);
        translationswrap.prmLabelsMap = prmLabelsMap;
        
        Map<String, String> prmSpecificLabelsMap = new Map<String, String>();
        Map<String, String> prmSpecificTranslationsMap = new Map<String, String>();
        String networkName;
        List<Network> network = [Select id, Name from Network where id =: Network.getNetworkId()];
        if(Test.isRunningTest()){
            network = [Select id, Name from Network limit 1];
        }
        if(network != null && network.size() > 0) {
            networkName = network[0].Name;
            networkName = '%' + networkName + '%';
            List<PRM_Specific_Label__mdt> prmSpecificLabels = [Select Generic_API_Name__c, Value__c, Site_Name__c from PRM_Specific_Label__mdt 
                                                               where Site_Name__c like : networkName];
            for(PRM_Specific_Label__mdt prmSpecificLabel : prmSpecificLabels)
            {
                prmSpecificLabelsMap.put(prmSpecificLabel.Generic_API_Name__c, prmSpecificLabel.Value__c);
            }    
            List<PRM_Specific_Translation__mdt> prmSpecificTranslations = [Select PRM_Specific_Label__r.Generic_API_Name__c, PRM_Specific_Label__r.Site_Name__c,  
                                                                           Language__c, Value__c from PRM_Specific_Translation__mdt 
                                                                           where Language__c =: selectedLanguage and PRM_Specific_Label__r.Site_Name__c like : networkName];
            
            for(PRM_Specific_Translation__mdt prmSpecificTranslation : prmSpecificTranslations)
            {
                if(prmSpecificTranslation.Value__c != null){
                    prmSpecificTranslationsMap.put(prmSpecificTranslation.PRM_Specific_Label__r.Generic_API_Name__c, prmSpecificTranslation.Value__c);
                }
            } 
            prmSpecificLabelsMap.putAll(prmSpecificTranslationsMap);
        }
        translationswrap.prmSpecificLabelsMap = prmSpecificLabelsMap;
        
        return translationswrap;
    }
    
    public class Translationswrap {
        @AuraEnabled
        public Map<String, Map<String, String>> allObjFieldsMap {get;set;}
        @AuraEnabled
        public Map<String, String> prmLabelsMap {get;set;}
        @AuraEnabled
        public Map<String, String> prmSpecificLabelsMap {get;set;}
    }
}
public with sharing class GetSTCHandlingObjection {
    public ACE__c ACE{get;set;}
    public ACE__c ACE2{get;set;}
    public integer ACECount{get;set;}
    public String contactRt {get;set;}
    public GetSTCHandlingObjection (ApexPages.StandardController controller){
        try {
            contactRt = HardcodedIdsMapper.getMatchedObjectId('0128A0000000I1W');
            ACE = new ACE__c();
            ACE= [SELECT id, RecordTypeId, STC_Flipchart_01__c, STC_Flipchart_02__c, STC_Flipchart_03__c, STC_Flipchart_04__c, STC_Flipchart_05__c, STC_Flipchart_06__c, 
                        STC_Flipchart_07__c, STC_Flipchart_08__c, STC_Flipchart_09__c, STC_Flipchart_10__c, STC_Flipchart_11__c, 
                        STC_Flipchart_Title_01__c, STC_Flipchart_Title_02__c, STC_Flipchart_Title_03__c, STC_Flipchart_Title_04__c, STC_Flipchart_Title_05__c, 
                        STC_Flipchart_Title_06__c, STC_Flipchart_Title_07__c, STC_Flipchart_Title_08__c, STC_Flipchart_Title_09__c, STC_Flipchart_Title_10__c, 
                        STC_Flipchart_Title_11__c 
                        FROM ACE__c
                        WHERE OwnerId =: UserInfo.getUserId() and RecordType.Name = 'STC Flipchart'];
            if(ACE == null){
                ACE = new ACE__c();
                ACE= [SELECT id, RecordTypeId, STC_Flipchart_01__c, STC_Flipchart_02__c, STC_Flipchart_03__c, STC_Flipchart_04__c, STC_Flipchart_05__c, STC_Flipchart_06__c, 
                        STC_Flipchart_07__c, STC_Flipchart_08__c, STC_Flipchart_09__c, STC_Flipchart_10__c, STC_Flipchart_11__c, 
                        STC_Flipchart_Title_01__c, STC_Flipchart_Title_02__c, STC_Flipchart_Title_03__c, STC_Flipchart_Title_04__c, STC_Flipchart_Title_05__c, 
                        STC_Flipchart_Title_06__c, STC_Flipchart_Title_07__c, STC_Flipchart_Title_08__c, STC_Flipchart_Title_09__c, STC_Flipchart_Title_10__c, 
                        STC_Flipchart_Title_11__c 
                        FROM ACE__c WHERE RecordType.Name = 'STC Flipchart' Order By CreatedDate ASC LIMIT 1];
                ACECount = 0;
            }
            else{
                ACECount = 1;        
            }
                          
        } catch(exception ex){
            ACE = new ACE__c();
                ACE= [SELECT id, RecordTypeId, STC_Flipchart_01__c, STC_Flipchart_02__c, STC_Flipchart_03__c, STC_Flipchart_04__c, STC_Flipchart_05__c, STC_Flipchart_06__c, 
                        STC_Flipchart_07__c, STC_Flipchart_08__c, STC_Flipchart_09__c, STC_Flipchart_10__c, STC_Flipchart_11__c, 
                        STC_Flipchart_Title_01__c, STC_Flipchart_Title_02__c, STC_Flipchart_Title_03__c, STC_Flipchart_Title_04__c, STC_Flipchart_Title_05__c, 
                        STC_Flipchart_Title_06__c, STC_Flipchart_Title_07__c, STC_Flipchart_Title_08__c, STC_Flipchart_Title_09__c, STC_Flipchart_Title_10__c, 
                        STC_Flipchart_Title_11__c 
                        FROM ACE__c WHERE RecordType.Name = 'STC Flipchart' Order By CreatedDate ASC LIMIT 1];
                ACECount = 0;
        
        }
    }
}
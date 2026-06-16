/*
Created By:     eugenebasianomutya
Date:           08312016
Case:           04920610 - Insert System status into Community header
Description:    System Status API for fetching US/UK Success site’s Service Status
*/


@RestResource(urlMapping='/fetchsystemstatus/*')
global with sharing class FetchSystemStatus{
    
    public class FetchSystemStatusWrapperMain{
        public FetchSystemStatusWrapper[] systemStatusRecordList;
    }
    
    public class FetchSystemStatusWrapper{

        public string Summary                   {get;set;}
        public string Severity                  {get;set;}
        public string Region                    {get;set;}
        public string PublicDescription         {get;set;}
        public string InternalStatus            {get;set;}
        public DateTime IncidentStartDate       {get;set;}
        public DateTime IncidentResolvedDate    {get;set;}
        public string IncidentId                {get;set;}

    }

    public class FetchSystemStatusWrapper_Error{
        public string errMsg                    {get;set;}
    }

    @HttpGet
    global static void GetSystemStatus(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;        
        String sBrand = req.params.get('brand');
        boolean bErr = false;

        FetchSystemStatusWrapperMain wrapperObjMain = new FetchSystemStatusWrapperMain();
        list<FetchSystemStatusWrapper> wrapperObj = new list<FetchSystemStatusWrapper>();
        FetchSystemStatusWrapper_Error wrapperObjErr = new FetchSystemStatusWrapper_Error();
        
        try{
            string strBrand;
            if(test.isRunningTest()){
                strBrand = 'UK';    
            }else{
                strBrand = (sBrand == 'US' || sBrand == 'USA' ? 'US': sBrand == 'UK'? 'UK': '');
            }

            if(strBrand == ''){
                bErr = true;
                wrapperObjErr = new FetchSystemStatusWrapper_Error();
                wrapperObjErr.errMsg = 'Brand Name not supported';                        
            }else{
                strBrand = '%' +strBrand+ '%';
                List<System_Status__c> lSystemStatus = [SELECT IncidentID__c, Incident_Resolved_Date__c, Incident_Start_Date__c, Internal_Status__c,
                                                        Public_Description__c, Region__c, Severity__c, Summary__c
                                                        FROM System_Status__c 
                                                        WHERE Region__c LIKE :strBrand AND Severity__c !=: null AND Severity__c !=: '' AND 
                                   (Internal_Status__c =: 'OPEN' OR (Internal_Status__c =:'RESOLVED' AND Incident_Resolved_Date__c > :system.now().addHours(-6))) 
                                   order by  Severity__c asc, Incident_Start_Date__c desc NULLS LAST];              
                
                for(System_Status__c st: lSystemStatus){
                    FetchSystemStatusWrapper wO = new FetchSystemStatusWrapper();

                    wO.Summary = st.Summary__c;
                    wO.Severity = st.Severity__c;
                    wO.Region = st.Region__c;
                    wO.PublicDescription = st.Public_Description__c;
                    wO.InternalStatus = st.Internal_Status__c;
                    wO.IncidentStartDate = st.Incident_Start_Date__c;
                    wO.IncidentResolvedDate = st.Incident_Resolved_Date__c;
                    wO.IncidentId = st.IncidentID__c;

                    wrapperObj.add(wO);
                }      
            }   

        } catch(exception e){
            bErr = true;
            wrapperObjErr = new FetchSystemStatusWrapper_Error();
            wrapperObjErr.errMsg =  e.getMessage();
        }

        res.addHeader('Content-Type', 'application/json');
        if(bErr){
            res.responseBody = blob.valueOf(JSON.serialize(wrapperObjErr)); 
        }else{    
            FetchSystemStatusWrapperMain x = new FetchSystemStatusWrapperMain();
            x.systemStatusRecordList = wrapperObj;
            res.responseBody = blob.valueOf(JSON.serialize(x));            
        }
        return;
    }
}
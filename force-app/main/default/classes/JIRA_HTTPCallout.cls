public with sharing class JIRA_HTTPCallout{

    /* NOTE:
        For Jira,
        Base URL : 'http://apps.ringdemo.com/';

        Method to Get Only One Jira Case: '/webservice/jirasfdc/issue';
        Method to Get Multiple Jira Case: '/webservice/jirasfdc/issue-multiple';
        Method to Create Issue Jira Case: '/webservice/jirasfdc/create-issue';

        Passing Headers must be in list form separated by ~ . Ex:
            list<string> sheader = new list<string>();
            sheader.add('Accept-Encoding~gzip, deflate');
            sheader.add('Content-type~application/json');
    */

    private string myBase_URL {get;set;}
    private string myEndPoint {get;set;}
    private string myAction {get;set;}

    private string myHttpMethod {get;set;}   
    private list<string> myHeaders {get;set;}
    private list<string> myBody {get;set;}


    //Method to perform a callout and return an httpResponse
    public httpResponse CallOut(){ 
            
            httpRequest req = new httpRequest();

            req.setTimeout(120000);
            req.setMethod(myHttpMethod);
            req.setEndpoint(myBase_URL + myEndPoint + myAction);        

            system.debug('URL::' + myBase_URL + myEndPoint + myAction);

            if(myHeaders.size()>0){
                for(integer i=0; i<myHeaders.size(); i++){
                    String[] sHead = myHeaders[i].split('~');
                    system.debug('HEADER::' + sHead[0] + ' --- ' + sHead[1]);        
                    req.setHeader(sHead[0], sHead[1]);
                }   
            }

            string sBody;
            if(myBody!=NULL){
                if(myBody.size()>0){
                    for(integer i=0; i<myBody.size(); i++){
                        system.debug('BODY::' + myBody[i]);      
                        if(sBody == ''){
                            sBody = myBody[i];
                        }else{
                            sBody = myBody[i] + '&' + sBody + myBody[i];
                        }                    
                    }        
                    req.setBody(sBody);           
                }
            }
            
            if(Test.isRunningTest()){
                return NULL;
            }else{
                httpResponse res = new http().send(req);
                return res;
            }            

    }

    public void SetBaseURL(String sBaseURL){
        myBase_URL = sBaseURL;
    }

    public void SetEndPoint(String sEndPoint){
        myEndPoint = sEndPoint;
    }

    // This is the method we call in JIRA
    // Methods are: create-issue, issue, issue-multiple
    public void SetAction(String sAction){
        myAction = sAction;
    }

    public void SetHeader(list<String> sHeader){
        myHeaders = sHeader;
    }

    public void SetBody(list<String> sBody){
        myBody = sBody;
    }

    // Values can be GET, PUT, POST, DELETE  
    public void SetMethod(String sMethod){
        myHttpMethod = sMethod;
    }

}

    // ------------------------------------------------ TEST USING THE CODE BELOW ----------------------------------------//

    /*
    
    JIRA_HTTPCallout x = new JIRA_HTTPCallout();

    x.SetBaseURL('http://apps.ringdemo.com/');
    x.SetEndPoint('webservice/jirasfdc/');
    x.SetAction('issue-multiple');
    x.SetMethod('POST');
    list<String> lHeader = new list<string>();
    lHeader.add('apikey~34858d0b1734dfc35b02bf7d42e35571');
    lHeader.add('Content-type~application/x-www-form-urlencoded');
    x.SetHeader(lHeader);    
    
    list<string> lBody = new list<string>();
    lBody.add('issue_id=489492,489527,491161');
    x.SetBody(lBody);

    httpResponse res = new httpResponse();
    res = x.callout();
    
    system.debug('RESPONSE STATUS::::::::::::' + res.getStatus());
    system.debug('RESPONSE STATUS CODE::::::::::::' + res.getStatusCode());
    system.debug('RESPONSE BODY::::::::::::' + res.getBody());      

    ------ DIRECT

    httpRequest req = new httpRequest();

    req.setMethod('POST');
    req.setTimeout(120000);
    req.setEndpoint('http://apps.ringdemo.com/webservice/jirasfdc/issue-multiple');

    req.setHeader('apikey', '34858d0b1734dfc35b02bf7d42e35571');
    req.setHeader('Content-type', 'application/x-www-form-urlencoded');


    req.setBody('issue_id=489492,489527,491161');
    httpResponse res = new http().send(req);

    System.debug('BODY: '+ res.getBody());



    */
    // ------------------------------------------------------------------------------------------------------------------//
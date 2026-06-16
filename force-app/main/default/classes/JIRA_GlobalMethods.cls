global class JIRA_GlobalMethods{


    public string getJirBaseaURL(boolean bProduction){
        if(bProduction){
            return 'https://jira.ringcentral.com/browse/';
        }else{
            return 'https://jira-test.dins.ru/browse/';
        }
    }

    public string GetBaseURL(boolean bProduction){
        if(bProduction){
            return 'http://apps.ringdemo.com/';
        }else{
            return 'http://staging.ringdemo.com/';
        }
    }

    public string GetAPIKey(boolean bProduction){
        if(bProduction){
            return '34858d0b1734dfc35b02bf7d42e35571';
        }else{
            return '48D6C553356FC983BA3456ADF344F';
        }
    }
    
    // This will be used by the test class
    public string getJasonString(){


        // Case - 04516479 - Update on Webservice result sample - Start
        //String json='{"status":"success","data":[{"id":"530591","key":"CNV-16120","summary":"One-way audio after call hold/resume on Cisco SPA5xx","resolution":"","resolutionDate":"","created":"2015-09-03T09:58:07.000-0700","description":"h3. Background h3. Problem One-way audio after call hold/esume on Cisco SPA5xx. Two possible variants are found: # Conference call using conf softkey# Call holdresume using Hold key or Hold key + resume softkey.The issue is not reproduced on Polycom devices, only Ciscos are affected.h3. Steps to ReproduceScenario 1:1. Outbound call #1 from caller #1 to callee #1 (non-RC number)2. Call #1 is answered3. Caller #1 pressed conf softkey to put call #1 on hold4. Outbound call #2 from caller #1 to callee #2 (non-RC number)5. Call #2 is answered6. Caller #1 pressed conf softkey to connect calls #1, #2 to conference with  callees #1, #27. Caller #1 can0027t hear calees #1, #2Scenario 2:1. Inbound call #1 from caller#1 (non-RC number)2. Call #1 is answered by callee #13. Callee #1 put call #1 on hold4. Callee #1 make call #2 to calee #25. Calee #2 answered call #17. Call #2 is disconnected8. Callee resumed call #19. Callee #1 can0027t hear caller #1, caller #1 can hear callee #1h3. Actual BehaviorOne-way audio for user who put calls on holdresumed callsh3. Expected BehaviorTwo-way audio for user who put calls on holdresumed callsh3. Known Accounts781829981361234096008478847400h3. Workaroundh3. Technical DetailsProblem occured for SIPTLS+G.729 (POD6), SIPTLS+G.711U(POD6), SIPTCP+G.729 (POD7, call was disconnected by HMP after 35 sec of inactivity), SIPTCP+G.722 (POD7, call was disconnected by HMP after 35 sec of inactivity). No problem detected on Polycom phones.h3. Technical Logsh3. Impact - How Many, How Oftenh3. Solutionh3. Versions, Brands, 0026 Tiers","assignee":{"name":"vkrishnamurthy","email":"vasudevan.krishnamurthy@ringcentral.com","displayName":"Vasudevan Krishnamurthy","active":true},"issueType":{"id":"1","name":"Bug"},"priority":{"id":"6","name":"Normal"},"project":{"id":"10250","key":"CNV","name":"Telephony"},"reporter":{"name":"ilya.selitser","email":"ilya.selitser@nordigy.ru","displayName":"Ilya Selitser","active":true},"status":{"id":"1","name":"Open"},"comments":[{"name":"ilya.selitser","email":"ilya.selitser@nordigy.ru","displayName":"Ilya Selitser","body":"Logs attached for the following call scenario (SIPTLS+G.729):1. 5088921264 called 7818299813, the call was routed to extension 1202. ext. 120 answered3. ext. 120 put the call on hold4. ext. 120 resumed the call after ~73 sec, one-way audio detected5. ext. 120 put the call on hold one more time6. ext. 120 transferred call to ext. 120 (another line)7. ext. 120 received and answered the call, two-way audio detected ","created":"2015-09-03T10:47:36.000-0700","updated":"2015-09-03T10:48:06.000-0700"},{"name":"dmitryas","email":"dmitry.semenov@ringcentral.com","displayName":"Dmitry A Semenov","body":"[~vkrishnamurthy] We have several similar complaints from the customers. Can you please escalate this issue to Cisco Support.","created":"2015-09-03T12:13:33.000-0700","updated":"2015-09-03T12:13:33.000-0700"},{"name":"vkrishnamurthy","email":"vasudevan.krishnamurthy@ringcentral.com","displayName":"Vasudevan Krishnamurthy","body":"Trying to get a Cisco support issue opened. Communicated the issue to the Cisco0027s RC Account team.","created":"2015-09-03T17:35:58.000-0700","updated":"2015-09-03T17:35:58.000-0700"},{"name":"vkrishnamurthy","email":"vasudevan.krishnamurthy@ringcentral.com","displayName":"Vasudevan Krishnamurthy","body":"Ref Cisco TAC #:SUPPORT CASE:636250603 SUPPORT CASE TITLE:One-Way Audio on SPA phone ","created":"2015-09-08T13:33:14.000-0700","updated":"2015-09-08T13:33:14.000-0700"},{"name":"vkrishnamurthy","email":"vasudevan.krishnamurthy@ringcentral.com","displayName":"Vasudevan Krishnamurthy","body":"[~dmitryas] Can you confirm which SPA 5xx model was used to reproduce the issue ? Thx","created":"2015-09-08T16:47:17.000-0700","updated":"2015-09-08T16:47:17.000-0700"},{"name":"dmitryas","email":"dmitry.semenov@ringcentral.com","displayName":"Dmitry A Semenov","body":"[~vkrishnamurthy] We were not able to reproduce the issue in the office network (in UK, US and Russian offices). The customers reported the issues on Cisco SPA504G, SPA508G, SPA514G","created":"2015-09-08T17:26:17.000-0700","updated":"2015-09-08T17:26:17.000-0700"},{"name":"sonia.singh","email":"sonia.singh@ringcentral.com","displayName":"Sonia Singh","body":"[~vkrishnamurthy]Any updates on this one?  Did we escalate to Cisco?","created":"2015-09-10T15:17:47.000-0700","updated":"2015-09-10T15:17:47.000-0700"},{"name":"vkrishnamurthy","email":"vasudevan.krishnamurthy@ringcentral.com","displayName":"Vasudevan Krishnamurthy","body":"[~sonia.singh] The Cisco TAC was already open and being worked, Roscoe Bryant from Tier 3 is helping with logs.","created":"2015-09-10T16:09:50.000-0700","updated":"2015-09-10T16:09:50.000-0700"},{"name":"ilya.selitser","email":"ilya.selitser@nordigy.ru","displayName":"Ilya Selitser","body":"The problem reoccured on account ID=7818299813 for Secure voice (TLS). The one-way audio problem occurs only for SIP+TLS configuration. [~vkrishnamurthy], since Cisco support requested logs containing unencrypted SIP + RTP,  could Cisco support recommend us how to decrypt SIP and sRTP traffic in this case?  ","created":"2015-10-28T02:43:03.000-0700","updated":"2015-10-28T02:43:03.000-0700"}],"fixVersions":[{"id":"20320","name":"Prioritized Queue","description":"","archived":false,"released":false}]}]}';
        String json='{"status":"success","data":[{"id":"499267","key":"XQA-2285","summary":"SFDC Jira nightly sync not updating record Testing 21","resolution":{"self":"https://jira-test.dins.ru/rest/api/2/resolution/25","id":"25","description":"","name":"Defect submitted"},"resolutionDate":"2016-04-21T07:01:14.000-0700","created":"2016-04-21T06:41:29.000-0700","description":"SFDC Jira nightly sync not updating record Testing 21","assignee":{"name":"sonny.cabali","email":"sonny.cabali@ringcentral.com","displayName":"Sonny Cabali","active":true},"issueType":{"id":"8","name":"New Request"},"priority":{"id":"3","name":"High"},"project":{"id":"10351","key":"XQA","name":"Xiamen QA"},"reporter":{"name":"sonny.cabali","email":"sonny.cabali@ringcentral.com","displayName":"Sonny Cabali","active":true},"status":{"id":"5","name":"Resolved"},"comments":[{"name":"sonny.cabali","email":"sonny.cabali@ringcentral.com","displayName":"Sonny Cabali","body":"Testing purpose","created":"2016-04-21T07:01:14.000-0700","updated":"2016-04-21T07:01:14.000-0700"}],"fixVersions":[{"id":"17800","name":"Amarosa XMN QAA Backlog","description":"","archived":false,"released":false,"release_date":null}],"versions":[{"id":"16874","name":"Amarosa 5.13 XMN Sprint 2","description":"Amarosa 5.13 XMN Sprint 2","archived":false,"released":false,"release_date":null}],"exist_on_production":"","release_fixed":""}]}';
        // Case - 04516479 - Update on Webservice result sample - End

        return jSon;
    }

    // This will be used by the test class
    public string getJasonStringError(){

        String json='{"status":"success","data":[{"status":"error","message":"Failed to get issue: EBMX-9999"}]}';

        return jSon;
    }


    // Middleware sends this kind of date format:
    // 2015-11-06T13:04:19.000-0800
    public DateTime FormatDate(string sDateTimeSplit){

        //Salesforce date format is YYYYmmdd
        //Salesforce time format is HHMMSS AM/PM

        DateTime dtNew = NULL;

        if(sDateTimeSplit =='' || sDateTimeSplit == NULL){
            return NULL;
        }else{
            string sAMPM='';
            list<String> sDateTime = sDateTimeSplit.split('T');
            list<String> sDate = sDateTime[0].split('-');
            list<String> sTime1 = sDateTime[1].split(':');

            sAMPM = (Integer.valueOf(sTime1[0]) < 12? 'AM': 'PM');

            DateTime yourDateVariable = DateTime.newInstanceGmt
                (
                Integer.valueOf(sDate[0]), Integer.valueOf(sDate[1]), Integer.valueOf(sDate[2]), 
                Integer.valueOf(sTime1[0]), Integer.valueOf(sTime1[1]), 
                Integer.valueOf(sTime1[2].left(2)) 
                ); 
             return yourDateVariable;
        }
    }

}
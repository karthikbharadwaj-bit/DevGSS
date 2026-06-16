/************************************************************************************************************************************************************

    Case: 03684365 - Do Not Call Functionality in SFDC
    Case Desc:  Marketing requested to have a check box that is set to true when the lead should not be called.
    Update by: eugenebasianomutya
    Update date: 08062015
    Update made: Add Do Not Call in Lead and create a banner

    By..........................: eugenebasianomutya
    Date........................: 06/01/2016
    Case........................: 04645699
    Details.....................: RE Franchise Tagging, ROE and Sales Notes

************************************************************************************************************************************************************/

public class LeadHighlighter{

    public String strCampaignDiscription{get;private set;}
    public Lead objLead1{get;set;}
    public String strLeadSourceDescription{get;private set;}
    public Boolean isBTApproved {get;set;}
    public Boolean isDoNotCall {get;set;}

    public boolean isHasOptedOutOfEmail {get;set;}
    public String okToEmail {get;set;}
    public String Country {get;set;}
    public String imgPath{get;set;}
    public String imgPathRed{get;set;}
    public list<String> tempList{get;set;}
    public Boolean bRedAccount {get;set;}
    public Boolean isLongDescription { get; set; }
    public Boolean isSia { get; set; }

    // Case 05173539 - START
    public String sDomainType {get;set;}
    public Boolean bDomainType{get;set;}
    public string sDomainTypeMsg1{get;set;}
    public string sDomainTypeMsg2{get;set;}
    // Case 05173539 - END

    public Map<String, String> emailMap {get;set;}

    public static String EMAIL_ONLY_ONCE = 'EMAIL ONLY ONCE: ';
    public static String EMAIL_ONLY_ONCE_MESSAGE = 'You may legally send ONE email. Do not send multiple emails.';
    public static String EMAIL_6_MONTHS = 'EMAIL (6 Months): ';
    public static String EMAIL_6_MONTHS_MESSAGE = 'It is legal to send this person email. ' +
                                                'Email consent will be automatically revoked after the legal period.';
    public static String EMAIL_2_YEARS = 'EMAIL (2 Years): ';
    public static String EMAIL_2_YEARS_MESSAGE = 'This person is a former customer and may be contacted for up to 2 years.';
    public static String EMAIL = 'EMAIL: ';
    public static String EMAIL_IMPLIED_MESSAGE = 'This person came through referral program. ' +
                                                'It is legal to send email until they unsubscribe';
    public static String DO_NOT_EMAIL = 'DO NOT EMAIL THIS PERSON: ';
    public static String DO_NOT_EMAIL_MESSAGE = 'This person has unsubscribed from Marketing emails ' +
                                                'and it is a violation of privacy laws (i.e. it\'s illegal) ' +
                                                'to send them promotional messages.';
    public static String EMAIL_YES_MESSAGE = 'This person has opted in and you may email this person.';

    public LeadHighlighter(ApexPages.StandardController controller){

        ImgPath = '/resource/warning';
        ImgPathRed = '/resource/warningRed';
        isHasOptedOutOfEmail = false;
        isBTApproved = false;
        tempList = new List<String>();
        tempList.add('test');
        this.isLongDescription = false;
        this.isSia = false;

        map<String,String> mapLeadSrcToLeadsrcDescption = new map<String,String> ();
        objLead1 = [SELECT Id, LeadSource, Most_Recent_Campaign__c,
                        Most_Recent_Campaign__r.Description, Most_Recent_Campaign__r.Name,
                        PartnerDeal_Status__c, HasOptedOutOfEmail, Do_Not_Call__c,
                        Domain_Type__c, Campaign_Product__c, SIA_Information__c,
                        Partner_Account_Name__c, Ok_to_Email__c, Country__c
                    FROM Lead
                    WHERE id= :ApexPages.currentPage().getParameters().get('id')];
        String dealStatus = objLead1.PartnerDeal_Status__c;
        if('BT Approved'.equalsIgnoreCase(dealStatus)){
            isBTApproved = true;
        }
        if(objLead1.LeadSource != null &&
            objLead1.LeadSource.equalsIgnoreCase('SIA')) {
            this.isSia = true;
        }

        isDoNotCall = objLead1.Do_Not_Call__c;
        isHasOptedOutOfEmail = objLead1.HasOptedOutOfEmail;
        okToEmail = objLead1.Ok_to_Email__c;
        Country = objLead1.Country__c;

        Lead objLead=(Lead)controller.getRecord();
        mapLeadSrcToLeadsrcDescption = getDescriptionByLeadSource();
        system.debug('mapLeadSrcToLeadsrcDescption -----------------------'+mapLeadSrcToLeadsrcDescption);
        strLeadSourceDescription = mapLeadSrcToLeadsrcDescption.get(objLead1.LeadSource);
        system.debug('strLeadSourceDescription -----------------------'+strLeadSourceDescription);
        strCampaignDiscription = objLead1.Most_Recent_Campaign__r.Description;
        if ((objLead1.SIA_Information__c != null
            && objLead1.SIA_Information__c.length() > 100)
            || (strCampaignDiscription != null && strCampaignDiscription.length() > 100)) {
                this.isLongDescription = true;
        }
        try{
            String  csvbody='';
            List<Document> doc= [Select body, bodyLength, ContentType, Url
                                    from Document
                                    where Name = 'Frandata Franchise Executive List2'];
            if(doc.size()>0){
                Blob b = doc[0].body;
                csvbody= b.toString().toLowerCase();
            }
            String strDomainName=objLead.email.subString(objLead.email.IndexOf('@')+1);
            String regex = '\\b'+strDomainName+'\\b';
            Matcher matcher =Pattern.compile(regex).matcher(csvbody);

            if(matcher.find()){
                String strMessage='This is a franchise Lead. Sales reps must transfer to the Franchise Sales Team at (800) 378-8110 ext 1 and ensure transfer is complete.';

                /* Case 04645699 - Franchise Tagging, ROE and Sales Notes  - END */
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,strMessage));
            }

            // Case 05173539 - START
            if(objLead1 != null){
              sDomainType = '';
              bDomainType = False;
              string sDt = objLead1.Domain_Type__c;
              if(sDt!='' && sDt!=NULL){
                DomainTypeLeadContact__C myDomainType
                                = DomainTypeLeadContact__C.getValues(sDt.toLowerCase());
                if(myDomainType != NULL){
                    sDomainType = '<' +  sDt + '>';
                    bDomainType = (myDomainType.Lead__c == True? true:false);
                    sDomainTypeMsg1 = Label.DomainTypeLeadContact1;
                    sDomainTypeMsg2 = Label.DomainTypeLeadContact2;
                }
              }
            }
            // Case 05173539 - END

        }catch(Exception e){ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage())); }

        if (objLead1 != null) {
            emailMap = setEmailString(objLead1.Ok_to_Email__c, isHasOptedOutOfEmail, Country);
        }
    }

    public static Map <String, String > getDescriptionByLeadSource() {
        map < String, String > rtnLeadSourceMap = new map < String, String > ();
        try {
            List <Document> docList = [Select body, bodyLength, ContentType, Url
                                        from Document
                                        where Name = 'LeadSourceMap'];
            system.debug('docList----------------------------------------'+docList.size());
            if (docList != null && docList.size() > 0) {
                if (docList[0].Body != null) {
                    List <List<String > > parsedCSV = parseCSV(docList[0].Body.toString(), true);
                    system.debug('parsedCSV----------------------------------------'+parsedCSV);
                    if (parsedCSV != null) {
                        for (List < String > listObj: parsedCSV) {
                            if (!String.isBlank(listObj[0]) && !String.isBlank(listObj[1])) {
                                String formatLeadSourceDescription = listObj[1].replace('$', '').replace('"', '').replace(',', '').trim();
                                rtnLeadSourceMap.put(listObj[0], formatLeadSourceDescription);
                            }
                        }
                    }
                }
            }
            system.debug('rtnLeadSourceMap------------------------------------'+rtnLeadSourceMap);
            return rtnLeadSourceMap;
        } catch (Exception ex) {
            system.Debug('>>ex>>>' + ex.getMessage());
        }
        return null;
    }

    private static List < List < String >> parseCSV(String contents, Boolean skipHeaders) {
        List < List < String >> allFields
                            = new List < List < String >> ();
        contents = contents.replaceAll(',"""', ',"DBLQT').replaceall('""",', 'DBLQT",');
        contents = contents.replaceAll('""', 'DBLQT');
        List < String > lines = new List < String > ();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for (String line: lines) {
            if (line.replaceAll(',', '').trim().length() == 0) {
                break;
            }
            List < String > fields = line.split(',');
            List < String > cleanFields = new List < String > ();
            String compositeField;
            Boolean makeCompositeField = false;
            for (String field: fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                } else
                    if (field.startsWith('"')) {
                        makeCompositeField = true;
                        compositeField = field;
                } else
                    if (field.endsWith('"')) {
                        compositeField += ',' + field;
                        cleanFields.add(compositeField.replaceAll('DBLQT', '"'));
                        makeCompositeField = false;
                } else
                    if (makeCompositeField) {
                        compositeField += ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT', '"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) {
            allFields.remove(0);
        }
        return allFields;
    }

    public static Map<String, String> setEmailString(String okToEmail, Boolean isEmail, String Country) {
        if (String.isNotBlank(okToEmail) && isEmail != null && !isEmail && Country != 'Germany') {
            //EU Phase 3 IT Profile Changes - Start
            //Including EU restricted profiles as a part of EU Phase 3
            List<EU_Component_Reference__mdt> newMdt=new List<EU_Component_Reference__mdt>([Select  Values__c from EU_Component_Reference__mdt where Apex_Classes__c like '%LeadHighlighter%' and DeveloperName='Contact_And_Lead_Highlight']);
            Set<String> profileNames = new Set<String>();
            if(newMdt.size()>0){
                for(EU_Component_Reference__mdt i:newMdt){
                    profileNames.addAll(i.Values__c.split(','));
                }
            }
                
            //EU Phase 3 IT Profile Changes - End
            Map<Id, Profile> mapProfileIds = new Map<Id, Profile>([
                                                                SELECT Id
                                                                FROM Profile
                                                                WHERE Name IN : profileNames
                                                                ]);

            if (mapProfileIds.keySet().contains(UserInfo.getProfileId())) {
                Map<String, String> returnMap = new Map<String, String>();
                switch on okToEmail {
                    when 'Implied - ONCE' {
                        returnMap.put('title', EMAIL);
                        returnMap.put('message', EMAIL_YES_MESSAGE);
                    }
                    when 'Implied - 6 Months' {
                        returnMap.put('title', EMAIL);
                        returnMap.put('message', EMAIL_YES_MESSAGE);
                    }
                    when 'Implied - Former Customer' {
                        returnMap.put('title', EMAIL);
                        returnMap.put('message', EMAIL_YES_MESSAGE);
                    }
                    when 'Implied - Referral' {
                        returnMap.put('title', EMAIL);
                        returnMap.put('message', EMAIL_YES_MESSAGE);
                    }
                    when 'No' {
                        returnMap.put('title', DO_NOT_EMAIL);
                        returnMap.put('message', DO_NOT_EMAIL_MESSAGE);
                    }
                    when 'Yes-Single', 'Yes-Double' {
                        returnMap.put('title', EMAIL);
                        returnMap.put('message', EMAIL_YES_MESSAGE);
                    }
                }
                if (!returnMap.isEmpty()) {
                    return returnMap;
                }
            }
        }
        return null;
    }
}
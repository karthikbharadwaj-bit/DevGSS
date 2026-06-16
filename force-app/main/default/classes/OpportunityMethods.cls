/*************************************************
OpportunityMethods class
This Class is used by Account.trigger.
sendActivePipeLimitEmail sends an email notification to Opportunity owners who have crossed their activepipe limit

UPDATE:

By:       eugenebasianomutya
Date:     5/14/2015
Details:    Case # 03532574 - Update Account if Opp Stage name is set to Closed Won
        Create Edition, Sales Segment and Sales Edition picklist fields in Account and Opp
        When Opp Stage Name is update to Closed Won, push the values of the created fields to Account.
Update Made:  1. Create fields in Account and Opp object
        2. Update the Apex code to utilize the existing Account update instead of creating a new set of Account update (Avoiding SOQL limit)

By:       eugenebasianomutya
Date:     3/30/2016
Case:     04505672 - Opty Creation Process/Update - ContactCenter
Details:  Project: Opty Creation Process/Update - ContactCenter - START
          Change the computation on the Estimated 12 Month Booking field (X12_Month_Booking__c)

By:       eugenebasianomutya
Date:     8/30/2016
Case:     04953116 - Please add the following fields to the account
/************************************************/

global class OpportunityMethods {

    public static boolean OpportunityUpdate_FirstRun = true;
    public static Map<string,Decimal> leadBrandTierAmountMap = OpportunityMethods.getAmountByBrandAndTier();

    webservice static String checkForActiveQuote(String recordId) {
        Opportunity oppty = [SELECT Id, Account.RC_User_ID__c FROM Opportunity WHERE Id =: recordId LIMIT 1];
        List<Quote> quoteList = [SELECT Id FROM Quote WHERE OpportunityId =: recordId AND Status =: QuoteTriggerHelper.STATUS_ACTIVE LIMIT 1];
        if(!quoteList.isEmpty() && null != oppty.Account.RC_User_ID__c){
            return 'Active Sales Agreement already exists for the account.';
        }
        return '';
    }

  /*
  sendActivePipeLimitEmail accepts an Opportunity and two Integers
  activePipeCount is the number of ActivePipe Opps the Opportunity owner has.
  activePipeLimit is the limit of ActivePipe Opps the Opportunity owner is supposed to have.
  */
    public void sendActivePipeLimitEmail(Opportunity o, Integer activePipeCount, Integer activePipeLimit){
        system.debug('THIS IS acivepipecount / limit: ' + activePipeCount + ', ' + activePipeLimit);
        // send out warning email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // set recepient
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.setSaveAsActivity(false);
        String[] ccAddresses = new String[] {o.Owner_Manager_Email__c};
        //mail.setCcAddresses(ccAddresses);

        mail.setSubject('RingCentral SalesForce: You have crossed your ActivePipe Opportunity Limit');

        mail.setPlainTextBody('Your current total of ActivePipe Opportunties is ' + activePipeCount + '. Your ActivePipe limit is ' + activePipeLimit + ' Opportunities.\n\n\n' +
        'Please cleanup your ActivePipe Opportunities. \n\n\n' +
        'Thanks, \n' +
        'Business Services Team' );

        try{
            Messaging.sendEmail(new Messaging.Singleemailmessage[] {mail});
        }catch(Exception e){}
    }

    public class OpportunityEstimates {
        public Decimal officePipeline;
        public Decimal customerEngagementPipeline;
        public Decimal contactCenterPipeline;
        public Decimal engageDigitalPipeline;
        public Decimal engageVoicePipeline;
        public Decimal eventsPipeline;
        public Decimal globalOfficePipeline;
        public Decimal ringCentralVideoPipeline;
        public Decimal proServPipeline;
        public Decimal hardwarePipeline;
        public Decimal oneTimePipeline;

        public OpportunityEstimates(Decimal officePipeline, Decimal customerEngagementPipeline, Decimal contactCenterPipeline,
                            Decimal engageDigitalPipeline, Decimal engageVoicePipeline,Decimal eventsPipeline, Decimal globalOfficePipeline,
                            Decimal ringCentralVideoPipeline, Decimal proServPipeline, Decimal hardwarePipeline, Decimal oneTimePipeline) {
            this.officePipeline = officePipeline;
            this.customerEngagementPipeline = customerEngagementPipeline;
            this.contactCenterPipeline = contactCenterPipeline;
            this.engageDigitalPipeline = engageDigitalPipeline;
            this.engageVoicePipeline = engageVoicePipeline;
            this.eventsPipeline = eventsPipeline;
            this.globalOfficePipeline = globalOfficePipeline;
            this.ringCentralVideoPipeline = ringCentralVideoPipeline;
            this.proServPipeline = proServPipeline;
            this.hardwarePipeline = hardwarePipeline;
            this.oneTimePipeline = oneTimePipeline;
        }

        public Decimal get(String service) {
            switch on service {
                when 'Office' { return officePipeline; }
                when 'Contact Center' { return contactCenterPipeline; }
                when 'Engage Digital Standalone' { return engageDigitalPipeline; }
                when 'Engage Voice Standalone' { return engageVoicePipeline; }
                when 'Global Office' { return globalOfficePipeline; }
                when 'Events' { return eventsPipeline; }
                when 'RC Meetings' { return ringCentralVideoPipeline; }
                when 'Hardware' { return hardwarePipeline; }
                when 'ProServ' { return proServPipeline; }
                when 'One-Time' { return oneTimePipeline; }
                when else { return 0; }
            }
        }
    }

    public class OpportunityQuoteUsers {
        @AuraEnabled public Decimal officeUsers;
        @AuraEnabled public Decimal contactCenterUsers;
        @AuraEnabled public Decimal engageDigitalUsers;
        @AuraEnabled public Decimal engageVoiceUsers;
        @AuraEnabled public Decimal globalOfficeUsers;
        @AuraEnabled public Decimal ringCentralVideoUsers;
        @AuraEnabled public Decimal rcEventUsers;

        private Decimal getMVPUsers() {
            return NumberHelper.toNumber(this.officeUsers) + NumberHelper.toNumber(this.globalOfficeUsers) + NumberHelper.toNumber(this.ringCentralVideoUsers);
        }

        public Decimal get(String service) {
            switch on service {
                when 'Office' { return officeUsers; }
                when 'Contact Center' { return contactCenterUsers; }
                when 'Engage Digital Standalone' { return engageDigitalUsers; }
                when 'Engage Voice Standalone' { return engageVoiceUsers; }
                when 'Global Office' { return globalOfficeUsers; }
                when 'RC Meetings' { return ringCentralVideoUsers; }
                when 'Events' { return rcEventUsers; }
                when else { return 0; }
            }
        }

        public void populateNumberOfSeatsOnOppty(Opportunity opp) {
            opp.NumberOfOfficeDLs__c = Integer.valueOf(this.getMVPUsers());
            opp.NumberOfCCSeats__c = Integer.valueOf(NumberHelper.toNumber(this.contactCenterUsers));
            opp.NumberOfEngageVoiceDLs__c = Integer.valueOf(NumberHelper.toNumber(this.engageVoiceUsers));
            opp.NumberOfEngageDigitalDLs__c = Integer.valueOf(NumberHelper.toNumber(this.engageDigitalUsers));
        }

        public void add(String service, Decimal numberOfUsers) {
            switch on service {
                when 'Office' { this.officeUsers = numberOfUsers + NumberHelper.toNumber(this.officeUsers); }
                when 'Contact Center' { this.contactCenterUsers = numberOfUsers + NumberHelper.toNumber(this.contactCenterUsers); }
                when 'Engage Digital Standalone' { this.engageDigitalUsers = numberOfUsers + NumberHelper.toNumber(this.engageDigitalUsers); }
                when 'Engage Voice Standalone' { this.engageVoiceUsers = numberOfUsers + NumberHelper.toNumber(this.engageVoiceUsers); }
                when 'Global Office' { this.globalOfficeUsers = numberOfUsers + NumberHelper.toNumber(this.globalOfficeUsers); }
                when 'RC Meetings' { this.ringCentralVideoUsers = numberOfUsers + NumberHelper.toNumber(this.ringCentralVideoUsers); }
                when 'Events' { this.rcEventUsers = numberOfUsers + NumberHelper.toNumber(this.rcEventUsers); }
            }
        }
    }

    public static Map<Id, List<Quote>> fetchOpportunityQuotes(Set<Id> oppIds) {

        Map<Id, List<Quote>> quotesByOppId = new Map<Id, List<Quote>>();
        List<Quote> quotes = new QuoteSelector()
                                .selectQuotesByOppIds(oppIds)
                                .executeQuery();
        for(Quote quote : quotes) {

            if (quotesByOppId.containsKey(quote.opportunityId)) {
                List<Quote> quotesByOpp =  quotesByOppId.get(quote.opportunityId);
                quotesByOpp.add(quote);
                quotesByOppId.put(quote.opportunityId, quotesByOpp);
            } else {
                quotesByOppId.put(quote.opportunityId, new List<Quote> {quote});
            }
        }

        return quotesByOppId;
    }

    public static Map<Id, OpportunityQuoteUsers> getQuoteUsers(Map<Id, List<Quote>> quotesByOppId, Set<Id> oppIds) {
        Map<Id, OpportunityQuoteUsers> result = new Map<Id, OpportunityQuoteUsers>();

        for (Id oppId : oppIds) {
            result.put(oppId, new OpportunityQuoteUsers());
            if (!quotesByOppId.containsKey(oppId)) {
                continue;
            }
            for (Quote oppQuote : quotesByOppId.get(oppId)) {
                if (!oppQuote.isPrimary__c && !QuoteHelper.isCCQuote(oppQuote)) {
                    continue;
                }
                Boolean isEBAccountWithoutContract = oppQuote.Account != null &&
                        AccountHelper.isExistingBusiness(oppQuote.Account) &&
                        !AccountHelper.isContracted(oppQuote.Account);

                Boolean isPocToPaid = AccountHelper.isPOCToPaid(oppQuote?.Account);

                for (QuoteLineItem qli : oppQuote.QuoteLineItems) {
                    final Decimal qty = (isEBAccountWithoutContract || isPocToPaid) ? qli.NewQuantity__c :QuoteLineItemHelper.getQuantity(qli);
                    if (qli.Product2 == null || qty == null) {
                        continue;
                    }
                    if (Product2Helper.isCcService(qli.Product2) || qli.Product2.ExtID__c == Product2Helper.ELEMENT_ID_RC_CC_SEAT) {
                        result.get(oppId).add(OpportunityHelper.TIER_CONTACT_CENTER, qty);
                    } else if (qli.Product2.ExtID__c == Product2Helper.ELEMENT_ID_RC_VIDEO) {
                        result.get(oppId).add(OpportunityHelper.TIER_RC_MEETINGS, qty);
                    } else if (Product2Helper.ENGAGE_DIGITAL_LICENSE_EXT_IDS.contains(qli.Product2.ExtID__c)) {
                        result.get(oppId).add(OpportunityHelper.TIER_ENGAGE_DIGITAL_STANDALONE, qty);
                    } else if (Product2Helper.ENGAGE_VOICE_LICENSE_EXT_IDS.contains(qli.Product2.ExtID__c)) {
                        result.get(oppId).add(OpportunityHelper.TIER_ENGAGE_VOICE_STANDALONE, qty);
                    } else if (qli.Product2.ExtID__c == Product2Helper.ELEMENT_ID_GLOBAL_OFFICE) {
                        result.get(oppId).add(OpportunityPipelineHelper.GLOBAL_OFFICE, qty);
                    } else if (Product2Helper.OFFICE_DL.contains(qli.Product2.ExtID__c)) {
                        result.get(oppId).add(OpportunityHelper.TIER_OFFICE, qty);
                    } else if (Product2Helper.RC_EVENT_LICENSES.contains(qli.Product2.ExtID__c)) {
                        result.get(oppId).add(OpportunityHelper.TIER_EVENT, qty);
                    }
                }
            }
        }
        return result;
    }

    public static Map<Id, OpportunityEstimates> calculateQuoteByOpportunity(
        Map<Id, List<Quote>> quotesByOppId,
        Map<Id, Opportunity> oppsIdsToOpps,
        Map<Id, Boolean> oppIdToIsMaster
    ){
        Map<Id, OpportunityEstimates> quoteAmmountsByOppId = new Map<Id, OpportunityEstimates>();

        for (Id oppId : oppsIdsToOpps.keySet()) {
            List<Quote> oppQuotes = quotesByOppId.get(oppId);
            Boolean isMasterOpp = oppIdToIsMaster.get(oppId);
            if (oppQuotes?.size() > 0) {
                Decimal officePipeline = 0;
                Decimal customerEngagementPipeline = 0;
                Decimal contactCenterPipeline = 0;
                Decimal engageDigitalPipeline = 0;
                Decimal engageVoicePipeline = 0;
                Decimal eventsPipeline = 0;
                Decimal globalOfficePipeline = 0;
                Decimal ringCentralVideoPipeline = 0;
                Decimal proServPipeline = 0;
                Decimal hardwarePipeline = 0;
                Decimal oneTimePipeline = 0;  
                Boolean isMultiproductTechnicalOppty = oppsIdsToOpps.get(oppId).IsMultiProductTechnicalOpportunity__c;

                for (Quote oppQuote : oppQuotes) {

                    Opportunity currentOppState = (Opportunity) Trigger.newMap?.get(oppId);

                    if (QuoteHelper.isProservQuote(oppQuote) || QuoteHelper.isCCProservQuote(oppQuote)) {
                        proServPipeline += NumberHelper.toNumber(oppQuote.Total_First_Year_Cost__c);
                        continue;
                    }

                    Boolean isNewBillingQuoteInContact = QuoteHelper.isNewBillingQuote(oppQuote) && QuoteHelper.isRCCC(oppQuote);
                    Boolean isQuotePackageInfoHasMultipleProducts = QuoteHelper.isQuotePackageInfoHasMultipleProducts(oppQuote);
                    Opportunity currentOpp = oppsIdsToOpps.get(oppId);
                    Boolean isProServChangeOrderOpportunity = OpportunityHelper.isProServChangeOrderOpportunity(currentOpp);

                    if (!isQuotePackageInfoHasMultipleProducts) {

                        if (QuoteHelper.isCCQuote(oppQuote) || isNewBillingQuoteInContact) {
                            contactCenterPipeline += NumberHelper.toNumber(oppQuote.Delta_CC_ARR__c);
                            continue;
                        }

                        if (!oppQuote.isPrimary__c) {
                            continue;
                        }
                        if (QuoteHelper.isEngageDService(oppQuote)) {
                            engageDigitalPipeline += NumberHelper.toNumber(oppQuote.Delta_ARR__c);
                            oneTimePipeline += NumberHelper.toNumber(oppQuote.Total_One_Time__c);
                            continue;
                        }

                        if (QuoteHelper.isEngageVService(oppQuote)) {
                            engageVoicePipeline += NumberHelper.toNumber(oppQuote.Delta_ARR__c);
                            oneTimePipeline += NumberHelper.toNumber(oppQuote.Total_One_Time__c);
                            continue;
                        }
                        if (!String.isBlank(oppQuote.Package_Info__c) && QuoteHelper.isEventsService(oppQuote)) {
                            eventsPipeline += NumberHelper.toNumber(oppQuote.Delta_ARR__c);
                            oneTimePipeline += NumberHelper.toNumber(oppQuote.Total_One_Time__c);
                            continue;
                        }

                        if (currentOppState.Tier_Name__c != null && currentOppState.Tier_Name__c.containsIgnoreCase('RC Meetings')) {
                            ringCentralVideoPipeline += NumberHelper.toNumber(oppQuote.Delta_ARR__c);
                            continue;
                        }

                    }

                    if (!oppQuote.isPrimary__c || isMultiproductTechnicalOppty) {
                        continue;
                    }
                    for (QuoteLineItem quoteItem : oppQuote.QuoteLineItems) {

                        if (quoteItem.Product_Family__c == Product2Helper.FAMILY_TAXES
                            || quoteItem.Product2.Billing_Type__c == Product2Helper.BILLING_TYPE_USAGE) {
                            continue;
                        }

                        Boolean isSalesOrNewBillingQuote = QuoteHelper.isSalesQuote(oppQuote) || QuoteHelper.isNewBillingQuote(oppQuote);
                        Boolean isProductFamilyPhonesOrDevice = quoteItem.Product_Family__c != null &&
                            (quoteItem.Product_Family__c.containsIgnoreCase('phones') || quoteItem.Product_Family__c.containsIgnoreCase('device'));
                        Boolean isProductFamilyRentalPhone = quoteItem.Product_Family__c != null &&
                            quoteItem.Product_Family__c.containsIgnoreCase(Product2Helper.FAMILY_RENTAL_PHONES);

                        if (isSalesOrNewBillingQuote && isProductFamilyPhonesOrDevice && !isProductFamilyRentalPhone) {
                            hardwarePipeline += NumberHelper.toNumber(quoteItem.TotalPrice);
                            continue;
                        }

                        if (isSalesOrNewBillingQuote && quoteItem.Product2?.GOA_Group_V2__c == 'GOA_Global_Office') {
                            globalOfficePipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                        } else {
                            String chargeTerm = quoteItem.ChargeTerm__c != null ? quoteItem.ChargeTerm__c : quoteItem.Product2.Charge_Term__c;
                            if (chargeTerm == Product2Helper.CHARGE_TERM_ONE_TIME && quoteItem.ServiceName__c != 'Professional Services') {
                                oneTimePipeline += NumberHelper.toNumber(quoteItem.TotalPrice);
                            } else if (isMasterOpp || isQuotePackageInfoHasMultipleProducts || isProServChangeOrderOpportunity) {
                                switch on quoteItem.ServiceName__c {
                                    when 'Office' {
                                        officePipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                                    }
                                    when 'RingCentral Contact Center' {
                                        contactCenterPipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                                    }
                                    when 'Engage Voice Standalone' {
                                        engageVoicePipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                                    }
                                    when 'Engage Digital Standalone' {
                                        engageDigitalPipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                                    }
                                    when 'Events' {
                                        eventsPipeline += NumberHelper.toNumber(quoteItem.Delta_ARR__c);
                                    }
                                    when 'Professional Services' {
                                        proServPipeline += NumberHelper.toNumber(quoteItem.TotalPrice);
                                    }
                                }
                            } else {
                                officePipeline += quoteItem.Delta_ARR__c != null ? quoteItem.Delta_ARR__c : 0;
                            }
                        }
                    }
                }
                customerEngagementPipeline = contactCenterPipeline + engageDigitalPipeline + engageVoicePipeline + eventsPipeline;
                if (isMultiproductTechnicalOppty) {
                    quoteAmmountsByOppId.put(oppId, new OpportunityEstimates(0, 0, 0, 0, 0, 0, 0, 0, 0,0, oneTimePipeline));
                } else {
                    quoteAmmountsByOppId.put(oppId, new OpportunityEstimates(officePipeline, customerEngagementPipeline, contactCenterPipeline,
                    engageDigitalPipeline, engageVoicePipeline,eventsPipeline, globalOfficePipeline,
                    ringCentralVideoPipeline, proServPipeline, hardwarePipeline, oneTimePipeline));
                }
            } else {
                quoteAmmountsByOppId.put(oppId, new OpportunityEstimates(0, 0, 0, 0, 0, 0,0, 0, 0, 0, 0));
            }
        }
        return quoteAmmountsByOppId;
    }

        /***************Code for updating the Parent Account*********************/
    public void updateParentAccount(Map<Id, opportunity> newOppMap, Map<Id, opportunity> oldOppMap) {
        Set<Id> setOppOwnerIds = new Set<Id>();
        Map<Id, User> userMap = new Map<Id, User>();
        Map <Id, Account> mapAccount = new Map <Id, Account>();

        for (Opportunity opp : newOppMap.values()) {
            if (oldOppmap == null || (newOppMap.get(opp.Id).OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
                setOppOwnerIds.add(opp.OwnerId);
            }
        }
        userMap = getOwnerList(setOppOwnerIds);
        for (Opportunity opp : newOppMap.values()) {
            if (String.isBlank(opp.AccountId)) {
                continue;
            }

            //Check if Opp is Closed Won
            if (opp.StageName == '8. Closed Won' || OpportunityHelper.isClosed(opp.StageName)) {
                Account objAcc = new Account(Id = opp.Accountid);
                if (oldOppmap == null) {
                    objAcc.Sales_Segment__c = opp.Sales_Segment__c;
                } else {
                    if (opp.StageName != oldOppMap.get(opp.id).StageName) {
                        objAcc.Sales_Segment__c = opp.Sales_Segment__c;
                    }
                }
                mapAccount.put(objAcc.Id, objAcc);
            }

            if (oldOppmap == null || (opp.OwnerId != oldOppMap.get(opp.Id).OwnerId)) {
                User user = userMap.get(opp.OwnerId);
                Account objAcc = new Account();
                if (mapAccount.Containskey(opp.Accountid)) {
                    objAcc = mapAccount.get(opp.Accountid);
                } else {
                    objAcc = New Account(Id = opp.Accountid);
                }
                objAcc.Most_Recent_Opportunity_Owner__c = opp.OwnerId;
                objAcc.Most_Recent_Opportunity_Owner_Email__c = user.Email;
                objAcc.Most_Recent_Opportunity_Owner_FirstName__c = user.FirstName;
                objAcc.Most_Recent_Opportunity_Owner_LastName__c = user.LastName;
                objAcc.Most_Recent_Opportunity_Owner_Phone__c = user.Phone;

                //Case 04953116 - Please add the following fields to the account - START
                objAcc.Most_Recent_Opportunity_Forecasted_Users__c = opp.Forecasted_Users__c;
                objAcc.Most_Recent_Opportunity_Tier_Name__c = opp.Tier_Name__c;
                objAcc.Most_Recent_Opportunity_Stage__c = opp.StageName;
                //Case 04953116 - Please add the following fields to the account - END

                mapAccount.put(objAcc.Id, objAcc);
            }
        }
        if (!mapAccount.isEmpty()) {
            Triggers.switchOff();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            update mapAccount.values();
            Triggers.switchOn();
            ObjectCache.removeKey(ObjectCache.Partition.QUERIES, 'selectUserForOpportunities');
        }
    }
  // Case # 03532574 - Update Account if Opp is Closed Won - END

    public void updateAccountMostRecentContact(Map<Id,opportunity> newOppMap, Map<Id,opportunity> oldOppMap) {
            Map<Id, Account> accountsMap = new Map<Id, Account>();
            map<id,id> mapOpportunityToContact = new map<id,id>();
            for(OpportunityContactRole objOppContactRole: [
                    SELECT Id, IsPrimary, ContactId, OpportunityId
                    FROM OpportunityContactRole
                    WHERE OpportunityId IN: newOppMap.keyset()
                    AND IsPrimary = true
                    ORDER BY lastmodifieddate ASC
            ]) {
                mapOpportunityToContact.put(objOppContactRole.OpportunityId,objOppContactRole.ContactId);
            }
            set<Id> accountIdSet = new set<Id>();
            for(Opportunity oppObj : newOppMap.values()) {
                accountIdSet.add(oppObj.AccountId);
            }
            map<Id,Account> mapAccountMap = new map<Id,Account>([
                    SELECT Most_Recent_Opportunity_Contact__c
                    FROM Account
                    WHERE Id IN : accountIdSet
            ]);

        for (Opportunity opp : newOppMap.values()) {
            Account objAcc1 = New Account(Id = opp.AccountId);
            if (mapAccountMap != null
                && mapAccountMap.get(opp.AccountId) != null
                && mapOpportunityToContact != null
                && mapOpportunityToContact.get(opp.id) != null
                && mapAccountMap.get(opp.AccountId).Most_Recent_Opportunity_Contact__c
                != mapOpportunityToContact.get(opp.id)) {
                objAcc1.Most_Recent_Opportunity_Contact__c = mapOpportunityToContact.get(opp.id);
                accountsMap.put(objAcc1.Id, objAcc1);
            }
        }
        if(!accountsMap.values().isEmpty()) {
            Triggers.switchOff();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            update accountsMap.values();
            Triggers.switchOn();
        }
    }


    public static Map<Id, User> userStaticMap = new Map<Id, User>();

    private Map<Id, User> getOwnerList(Set<Id> setOppOwnerIds) {
        if (userStaticMap.keySet().containsAll(setOppOwnerIds) ) {
            return userStaticMap;
        } else {
            System.debug('select users');
            Map<Id, User> userMap = new Map<Id, User>(OpportunityMethods.getUserMap(setOppOwnerIds));
            userStaticMap.putAll(userMap);
            return userStaticMap;
        }
    }

    /********************************************************************************************************************************************
    * @Description : This method is used to parse the CSV file Product_Forecast_Amounts. The file contains the Price depeding on the RC Tier and*
    *                RC Brand.                                                          *
    * @Author    : Simplion Tecnologies. 25th April,2014.                                                                                     *
    * @Params      : void                                                                               *
    * @Return      : pageReference                                                                                    *
    ********************************************************************************************************************************************/
    public static Map<String, Decimal> getAmountByBrandAndTier() {
        Map<String, Decimal> rtnLeadSourceAmountMap = new Map<String, Decimal>();
        try {
            Document doc = OpportunityMethods.getDocument('Product_Forecast_Amounts');
            if(doc != null && doc.Body != null) {
                List<List<String>> parsedCSV =  parseCSV(doc.Body.toString(),true);
                if(parsedCSV != null) {
                    for(List<String> listObj : parsedCSV) {
                        if(!string.isBlank(listObj[0]) &&  !string.isBlank(listObj[1])) {
                            System.debug('>>listObj[1]>>>'+ listObj[1]);
                            String formatAmount = listObj[1].replace('$','').replace('"','').replace(',','').trim();
                            System.debug('>>formatAmount>>>'+ formatAmount);
                            rtnLeadSourceAmountMap.put(listObj[0],Decimal.valueOf(formatAmount));
                        }
                    }
                }
            }
            return rtnLeadSourceAmountMap;
        } catch (Exception ex) {
            System.debug('>>ex>>>'+ ex.getMessage());
        }
        return null;
    }
    /********************************************************************************************************************************************
    * @Description : This method is used to parse the CSV file Product_Forecast_Amounts.                            *
    * @Author    : Simplion Tecnologies. 25th April,2014.                                                                                     *
    * @Params      : String contents, Boolean skipHeaders                                               *
    * @Return      : List<List<String>>                                                                               *
    ********************************************************************************************************************************************/
    public static List<List<String>> parseCSV(string contents, Boolean skipHeaders) {
      List<List<String>> allFields = new List<List<String>>();
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        contents = contents.replaceAll('""','DBLQT');
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            if (line.replaceAll(',','').trim().length() == 0) {
                break;
            }
            List<String> fields = line.split(',');
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) {
            allFields.remove(0);
        }
        return allFields;
    }

    public static Document getDocument(String documentName) {
        Document requiredDocument;
        List<String> documentNames = new List<String> {
            '%OpportunityLeadSourceMapping%',
            '%Product_Forecast_Amounts%',
            '%Pipeline_Forecast_Amounts%'
        };

        List<Document> documents = (List<Document>) new DocumentSelector()
            .selectDocumentsByNames(new List<Object> {documentNames})
            .setQueryCaching(true)
            .executeQuery();

        for (Document doc : documents) {
            if (doc.Name != null && doc.Name.contains(documentName)) {
                requiredDocument = doc;
            }
        }

        return requiredDocument;
    }

    public static Map<Id,User> getUserMap(Set<Id> userIds) {
        Map<Id,User> queryResult = new Map<Id,User>();
        if (userIds.isEmpty()) {
            return queryResult;
        }
        List<Object> bindings = new List<Object>();
        bindings.add(userIds);
        UserSelector getUserInfo = new UserSelector();
        queryResult.putAll((List<User>) getUserInfo
                                               .selectUserForOpportunities(bindings)
                                               .executeQuery());
        return queryResult;
    }
    public void updateAccountMostRecentOppTouched(Map<Id,opportunity> newOppMap, Map<Id,opportunity> oldOppMap) {
        List<Account>  accountUpdateList = new List<Account>();
        map<Id,Id> mapOpportunityToAccount = new map<Id,Id>();
        set<Id> accountIdSet = new set<Id>();
        for(Opportunity opp : newOppMap.values()) {
            if(opp.accountId <> null
                && opp.Total_MRR__c >= 500.00
                && opp.StageName == '7. Closed Won'
            ){
                mapOpportunityToAccount.put(opp.accountId,opp.Id);
            }
        }
        for(Account acc : [SELECT Id,Most_Recent_Opp_Touched__c FROM Account WHERE Id IN : mapOpportunityToAccount.keyset()]){
            Id opportunityId = null;
            if(acc.Most_Recent_Opp_Touched__c != null && acc.Most_Recent_Opp_Touched__c != ''){
                String s2 = '.com/';
                opportunityId = (Id)acc.Most_Recent_Opp_Touched__c.substring(acc.Most_Recent_Opp_Touched__c.indexOf(s2) + s2.length());
            }
            if(opportunityId == null || opportunityId !=  mapOpportunityToAccount.get(acc.Id)) {
                acc.Most_Recent_Opp_Touched__c = OrgURL__c.getInstance().OrgURLValue__c+mapOpportunityToAccount.get(acc.Id);
                accountUpdateList.add(acc);
            }
        }
        if(accountUpdateList.size()>0) {
            Triggers.switchOff();
            TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
            update accountUpdateList;
            Triggers.switchOn();
        }
    }
}
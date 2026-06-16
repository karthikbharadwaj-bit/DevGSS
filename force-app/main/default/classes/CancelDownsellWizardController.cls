global with sharing class CancelDownsellWizardController {

    public Opportunity opp {get;set;}
    public Id accId {get;set;}
    public Id oppId {get;set;}
    public String type {get;set;}

    public String category1 {get;set;}
    public String category2 {get;set;}
    public String category3 {get;set;}

    public String category4 {get;set;}
    public String category5 {get;set;}
    public String category6 {get;set;}

    public String category7 {get;set;}

    public String category2Reason {get;set;}
    public String category3Reason {get;set;}

    public String category4Reason {get;set;}
    public String category5Reason {get;set;}
    public String category6Reason {get;set;}

    public CancelDownsellWizardController() {

        category1 = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Service_change_options__c'));
        category2 = JSON.serialize(
                SFDescribeHelper.getDependentOptions('Opportunity', 'Churn_reason__c', 'Sub_Churn_reason__c')
        );
        category3 = JSON.serialize(
                SFDescribeHelper.getDependentOptions('Opportunity', 'Replacement_option__c', 'Replacement_suboption__c')
        );

        category4 = JSON.serialize(
                SFDescribeHelper.getDependentOptions('Opportunity', 'Who_did_we_beat_option__c', 'Who_did_we_beat_suboptions__c')
        );
        category5 = JSON.serialize(
                SFDescribeHelper.getDependentOptions(
                        'Opportunity',
                        'What_are_we_replacing_option__c',
                        'What_are_we_replacing_suboption__c'
                )
        );
        category6 = JSON.serialize(
                SFDescribeHelper.getDependentOptions(
                        'Opportunity',
                        'Why_did_we_win_option__c',
                        'Why_did_we_win_suboption__c'
                )
        );

        category7 = JSON.serialize(null);

        if( isAllowToShowOptions(UserInfo.getUserRoleId()) ) {
            category7 = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Retention__c'));
        }

        accId = Apexpages.currentpage().getparameters().get('accId');
        oppId = Apexpages.currentpage().getparameters().get('oppId');
        type = Apexpages.currentpage().getparameters().get('type');
        if(oppId != null) {
            List<Opportunity> listOpp = [
                    SELECT Id, recordTypeId, Brand_Name__c, Type, Tier_Name__c, Forecasted_Users__c,
                            Account.Id, Account.Number_of_DL_s__c, Name, Parent_Order__c
                    FROM Opportunity
                    WHERE id =: oppId
            ];
            if(listOpp.size() > 0) {
                opp = listOpp[0];
            }
        }

        category2Reason = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Churn_reason__c'));
        category3Reason = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Replacement_option__c'));

        category4Reason = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Who_did_we_beat_option__c'));
        category5Reason = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'What_are_we_replacing_option__c'));
        category6Reason = JSON.serialize(SFDescribeHelper.getOptions('Opportunity', 'Why_did_we_win_option__c'));
    }

    public static Boolean isAllowToShowOptions(Id userId) {
        Boolean isAllowToShow = true;
        String dependedRoleName = RetentionOptionVisibility__c.getInstance().RoleName__c;

        if(String.isNotBlank(dependedRoleName)) {
            UserRole dependedRole = [SELECT Id FROM UserRole WHERE Name =: dependedRoleName LIMIT 1];
            Set<Id> dependedIds= new Set<Id>();
            dependedIds.add(dependedRole.Id);
            dependedIds.addAll(AquivaHelper.getAllSubRoleIds(dependedIds));
            isAllowToShow = dependedIds.contains(userId);
        }
        return isAllowToShow;
    }

    @AuraEnabled
    public static Opportunity createCancelOpportunity(String prms) {
        AccountDeactivationParams params = (AccountDeactivationParams) JSON.deserialize(prms, AccountDeactivationParams.class);

        Account acc = [SELECT Id, Name, RC_Brand__c, CurrencyIsoCode, RC_Tier__c
        FROM Account
        WHERE Id = :params.accountId];

        Schema.DescribeSObjectResult objectDesc = Opportunity.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByName = objectDesc.getRecordTypeInfosByName();

        Opportunity opp = new Opportunity(
                Name = acc.Name,
                AccountId = params.accountId,
                Brand_Name__c = acc.RC_Brand__c,
                CurrencyIsoCode = acc.CurrencyIsoCode,
                Description = acc.Name,
                RecordTypeId = rtMapByName.get('Cancel Opportunity').getRecordTypeId(),
                StageName = OpportunityHelper.STAGE_NAME_CLOSED_WON,
                Tier_Name__c = acc.RC_Tier__c,
                Type = 'Existing Business',
                CloseDate = System.today(),
                Churn_reason__c = params.churn.option,
                Sub_Churn_reason__c = params.churn.suboption,
                Sub_Churn_reason_detail_text__c = params.churn.details,
                Sub_Churn_reason_detail_date__c = params.churn.detailsDate,
                Replacement_option__c = params.replacement.option,
                Replacement_suboption__c = params.replacement.suboption,
                Replacement_suboption_detail_text__c = params.replacement.details
        );

        try{
            insert opp;
        } catch (Exception e){
            AquivaHelper.throwAuraException(e);
        }

        return opp;
    }

    @AuraEnabled
    public static Quote createCancelQuote(Map<String, String> params) {
        String accountId = params.get('accountId');
        String opportunityId = params.get('opportunityId');
        String contactId = params.get('contactId');
        String qName = params.get('Name');
        String isoCode = params.get('currency');
        if (accountId == null){
            return null;
        }

        Map<Id, Entitlement__c> entlsToProdId = new Map<Id, Entitlement__c>();

        List<Entitlement__c> updatedEntls =
            (List <Entitlement__c>) EntitlementSync.syncWithDWH(accountId).data.get(EntitlementSync.ENTITLEMENT_RESPONSE_DATA_KEY);

        for (Entitlement__c ent : updatedEntls) {
            entlsToProdId.put(ent.Product__c, ent);
        }

        Pricebook2 pb;
        Id pbId;
        if (Test.isRunningTest()) {
            pbId = Test.getStandardPricebookId();
            pb = new Pricebook2(
                    Id = pbId
            );
        } else {
            pb = [SELECT Id, CurrencyIsoCode, (SELECT Id, Product2Id
            FROM PriceBookEntries
            WHERE Product2Id IN :entlsToProdId.keySet()
            AND CurrencyIsoCode = :isoCode)
            FROM Pricebook2
            WHERE isStandard = true];
        }

        Quote qt = new Quote(
                OpportunityId = opportunityId,
                Account__c = accountId,
                Approval_Type__c = 'Sales Rep',
                Approved_Status__c = 'Approved',
                ContactId = contactId,
                Start_Date__c = System.today(),
                ExpirationDate = System.today(),
                Initial_Term_months__c = '36',
                Term_months__c = '36',
                isPrimary__c = true,
                isSalesAgreementExtension__c = false,
                Name = 'Cancel Quote',
                Pricebook2Id = pb.Id,
                QuoteType__c = 'Quote',
                Status = 'Draft',
                Upsell_Status__c = 'Upsell'
        );

        try{
            insert qt;
        } catch (Exception e){
            AquivaHelper.throwAuraException(e);
        }

        List<QuoteLineItem> cancelQlis = new List<QuoteLineItem>();

        List<PriceBookEntry> pbes;
        if (Test.isRunningTest()) {
            pbes = [SELECT Id, Product2Id
            FROM PriceBookEntry
            WHERE Product2Id IN :entlsToProdId.keySet()
            AND CurrencyIsoCode = :isoCode
            AND Pricebook2Id = :pbId];
        } else {
            pbes = pb.PriceBookEntries;
        }
        for (PriceBookEntry pbe : pbes) {
            Decimal entQuantity = entlsToProdId.get(pbe.Product2Id).Quantity__c;
            QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = qt.Id,
                    PriceBookEntryId = pbe.Id,
                    Product2Id = pbe.Product2Id,
                    Entitlement__c = entlsToProdId.get(pbe.Product2Id).Id,
                    Quantity = - entQuantity,
                    Deactivated__c = true
            );
            if(entQuantity == 0) {
                qli.Quantity = 1;
                qli.Zero_Quantity__c = true;
            }
            cancelQlis.add(qli);
        }

        try{
            insert cancelQlis;
        } catch (Exception e){
            AquivaHelper.throwAuraException(e);
        }

        return qt;
    }

    @AuraEnabled
    public static GenerateOrdersResult createCancelOrder(String opportunityId) {

        Quote qt = [
                SELECT Id, (SELECT Id FROM QuoteLineItems)
                FROM Quote
                WHERE isPrimary__c = true
                AND ((Opportunity.Is_Billing_Opportunity__c = true
                        AND RecordTypeId = :QuoteHelper.RT_ID_BILLING)
                    OR (Opportunity.Is_Billing_Opportunity__c = false
                        AND RecordTypeId = :QuoteHelper.RT_ID_SALES))
                AND OpportunityId = :opportunityId
        ];

        if (qt.QuoteLineItems.size() == 0) {
            GenerateOrdersResult gord = new GenerateOrdersResult();
            gord.status = 'success';
            gord.message = 'No orders created because Quote has no items';
            gord.details = '';

            return gord;
        }

        Boolean skipValidation = false;

        String result = GenerateOrders.processData(opportunityId, '0000000000', '0000000000');

        GenerateOrdersResult dresult = (GenerateOrdersResult) JSON.deserialize(result, GenerateOrdersResult.class);
        if (dresult.status != 'success') {
            String emessage = '';
            if (dresult.details != null && dresult.details != '') {
                emessage = dresult.message + ' --- ' + dresult.details;
            } else {
                emessage = dresult.message;
            }
            AquivaHelper.throwAuraException(emessage);
        }

        Schema.DescribeSObjectResult objectDesc = Order.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMapByName = objectDesc.getRecordTypeInfosByName();

        List<Order> ccOrders = [
                SELECT Id, Status
                FROM Order
                WHERE RecordTypeId = :rtMapByName.get('Contact Center').getRecordTypeId()
                AND OpportunityId = :opportunityId
        ];

        Order ccOrder;
        if (ccOrders != null && ccOrders.size() != 0){
            ccOrder = ccOrders.get(0);
        }

        if (ccOrder != null) {
            ccOrder.Status = 'Submitted';
            update ccOrder;
        }

        return dresult;
    }

    @AuraEnabled
    public static Account cancelAccount(String accountId) {
        Account acc = new Account(
                Id = accountId,
                RC_Account_Status__c = 'Disabled'
        );

        try{
            update acc;
        } catch (Exception e){
            AquivaHelper.throwAuraException(e);
        }

        return acc;
    }

    public class AccountDeactivationParams {
        public String accountId {get;set;}
        public CancelSurvey churn {get;set;}
        public CancelSurvey replacement {get;set;}
    }

    public class DownsellOpportunityParams {
        public String opportunityId {get;set;}
        public CancelSurvey change {get;set;}
        public CancelSurvey churn {get;set;}
        public CancelSurvey replacement {get;set;}
        public CancelSurvey retention {get;set;}
    }

    public class CloseOpportunityParams {
        public String opportunityId {get;set;}
        public Opportunity opp {get;set;}
        public CancelSurvey who_did_we_beat {get;set;}
        public CancelSurvey what_are_we_replacing {get;set;}
        public CancelSurvey why_did_we_win {get;set;}
        public CancelSurvey retention {get;set;}
    }

    public class CancelSurvey {
        public String option {get;set;}
        public String suboption {get;set;}
        public String details {get;set;}
        public Date detailsDate {get;set;}
    }

    public class GenerateOrdersResult {
        public String status {get;set;}
        public String message {get;set;}
        public String details {get;set;}
    }


    public class UpdateCloseOpportunityResult {
        @AuraEnabled public String opportunityId {get;set;}
        @AuraEnabled public String primaryContactId {get;set;}
        @AuraEnabled public Boolean toShowAppointmentSchedule {get;set;}
    }

    @AuraEnabled
    public static String updateDownsellOpportunity(String prms) {
        DownsellOpportunityParams params = (DownsellOpportunityParams) JSON.deserialize(prms, DownsellOpportunityParams.class);

        String result;
        if (params != null) {
            Opportunity opty = new Opportunity (
                    Id = params.opportunityId,
                    Churn_reason__c = params.churn.option,
                    Sub_Churn_reason__c = params.churn.suboption,
                    Sub_Churn_reason_detail_text__c = params.churn.details,
                    Sub_Churn_reason_detail_date__c = params.churn.detailsDate,
                    Replacement_option__c = params.replacement.option,
                    Replacement_suboption__c = params.replacement.suboption,
                    Replacement_suboption_detail_text__c = params.replacement.details,
                    Service_change_options__c = params.change.option,

                    Retention__c = getOpportunityValuesForRetention(params.retention).get('retention'),
                    Downgrade_Reason_Opp__c = getOpportunityValuesForRetention(params.retention).get('downgradeReasonOpp'),

                    StageName = getOpportunityValuesForRetention(params.retention).get('stageName')
            );

            try{
                update opty;
                makeQuotesInvalid(opty);
                result = opty.Id;
            } catch (DMLException e){
                AquivaHelper.throwAuraException(e);
            }
        }

        return result;
    }

    private static void makeQuotesInvalid(Opportunity opty) {
        List<Quote> quoteList = (List<Quote>) new QuoteSelector()
                .selectorQuotesAndQlisForCloseWizardByOppId(opty.Id)
                .executeQuery();

        // Should not invalidate quotes if change order opty is closed
        Boolean isChangeOptyClose = false;
        for (Quote q : quoteList) {
            if (OpportunityHelper.checkIsChangeOrderOrMigrationOpty(q.Opportunity.Name, q.Opportunity.Parent_Order__c) && q.Opportunity.Id == opty.Id) {
                isChangeOptyClose = true;
                break;
            }
        }

        Boolean isRenewalOptyWithoutChanges = OpportunityHelper.isRenewalOptyWithoutChanges(
            opty,
            OpportunityHelper.filterQuotesByOppId(opty.Id, quoteList)
        );

        if (isChangeOptyClose || isRenewalOptyWithoutChanges) {
            return;
        }

        List<Quote> quoteListToUpdate = new List<Quote>();
        for (Quote q : quoteList) {
            Boolean isNeedToSetQuoteInvalid = QuoteHelper.isNeedSetQuoteInvalid(q, new List<Opportunity>{opty});

            if (isNeedToSetQuoteInvalid) {
                q.Quote_is_Invalid__c = true;
                quoteListToUpdate.add(q);
            }
        }

        update quoteListToUpdate;
    }


    @AuraEnabled
    public static UpdateCloseOpportunityResult updateCloseOpportunity(String prms) {
        CloseOpportunityParams params = (CloseOpportunityParams) JSON.deserialize(prms, CloseOpportunityParams.class);

        UpdateCloseOpportunityResult result = new UpdateCloseOpportunityResult();

        if (params != null) {
            Opportunity opty = new Opportunity (
                    Id = params.opportunityId,

                    Who_did_we_beat_option__c = params.who_did_we_beat.option,
                    Who_did_we_beat_suboptions__c = params.who_did_we_beat.suboption,

                    What_are_we_replacing_option__c = params.what_are_we_replacing.option,
                    What_are_we_replacing_suboption__c = params.what_are_we_replacing.suboption,
                    
                    Why_did_we_win_option__c = params.why_did_we_win.option,
                    
                    Retention__c = getOpportunityValuesForRetention(params.retention).get('retention'),
                    Downgrade_Reason_Opp__c = getOpportunityValuesForRetention(params.retention).get('downgradeReasonOpp'),

                    StageName = getOpportunityValuesForRetention(params.retention).get('stageName')
            );

            try{
                update opty;
                result.opportunityId = opty.Id;
                ApexPages.StandardController std = new ApexPages.StandardController(opty);
                OpportunityClosedWizard ocw = new OpportunityClosedWizard(std);
                result.toShowAppointmentSchedule = false; //ocw.toShowImplementationAppointment(params.opp);
                result.primaryContactId = ocw.getImplementationContact(params.opp);
            } catch (DMLException e){
                AquivaHelper.throwAuraException(e);
            }
        }

        return result;
    }

    public static Map<String,String> getOpportunityValuesForRetention(CancelSurvey retention) {


        Map<String,String> result = new Map<String,String>();
        result.put('stageName', OpportunityHelper.STAGE_NAME_CLOSED_WON);
        result.put('downgradeReasonOpp', null);
        result.put('retention', null);

        if(retention != null && String.isNotBlank(retention.option)) {

            result.put('retention', retention.option);

            if(retention.option == 'Saved' ) {
                result.put('stageName', '0. Downgraded');
                result.put('downgradeReasonOpp', 'Retention Saved');
            }
        }
        return result;
    }

}
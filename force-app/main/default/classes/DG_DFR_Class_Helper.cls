public with sharing class DG_DFR_Class_Helper {
    private static final String ACTIVE_STATUS = 'Active';
    private static final String USD_ISO_CODE = 'USD';
    private static final Double USD_CONVERSION_RATE = 1.0;

    public static Demand_Funnel__c prospectBackfillForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = prospectMasterMappingFromLead(dfr, lead);
        dfr = prospectOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.Prospect_Backfilled__c = true;
        dfr.Prospect_DateTime_Exited__c = DateTime.now();
        dfr.Prospect_Entered_From__c = 'Backfilled';
        dfr.Prospect_Exited_To__c = 'Backfilled';
        dfr.Prospect_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c prospectOnCreationForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = prospectMasterMappingFromLead(dfr, lead);
        dfr = prospectOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.Prospect_Entered_From__c = 'Created';
        dfr.Lead_Name_on_Creation__c = (lead.FirstName != null ? lead.FirstName + ' ' : '') + lead.LastName;
        dfr.Lead__c = Lead.Id;
        dfr.Lead_Email_on_Creation__c = Lead.Email;
        return dfr;
    }

    public static Demand_Funnel__c mqlBackfillForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = mqlMasterMappingFromLead(dfr, lead);
        dfr = mqlOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.MQL_Backfilled__c = true;
        dfr.MQL_Entered_From__c = 'Backfilled';
        dfr.MQL_Exited_To__c = 'Backfilled';
        dfr.MQL_DateTime_Exited__c = DateTime.now();
        dfr.MQL_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c mqlOnCreationForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = mqlMasterMappingFromLead(dfr, lead);
        dfr = mqlOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.MQL_Entered_From__c = 'Created';
        dfr.Lead_Name_on_Creation__c = (lead.FirstName != null ? lead.FirstName + ' ' : '') + lead.LastName;
        dfr.Lead__c = Lead.Id;
        dfr.Lead_Email_on_Creation__c = Lead.Email;
        return dfr;
    }

    public static Demand_Funnel__c mqlStatusChangeForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String previousStatus,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = mqlMasterMappingFromLead(dfr, lead);
        dfr = mqlOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.MQL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c talBackfillForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = talMasterMappingFromLead(dfr, lead);
        dfr = talOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.TAL_Backfilled__c = true;
        dfr.TAL_Entered_From__c = 'Backfilled';
        dfr.TAL_Exited_To__c = 'Backfilled';
        dfr.TAL_DateTime_Exited__c = DateTime.now();
        dfr.TAL_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c talOnCreationForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = talMasterMappingFromLead(dfr, lead);
        dfr = talOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.TAL_Entered_From__c = 'Created';
        dfr.Lead_Name_on_Creation__c = (lead.FirstName != null ? lead.FirstName + ' ' : '') + lead.LastName;
        dfr.Lead__c = Lead.Id;
        dfr.Lead_Email_on_Creation__c = Lead.Email;
        return dfr;
    }

    public static Demand_Funnel__c talStatusChangeForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String previousStatus,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = talMasterMappingFromLead(dfr, lead);
        dfr = talOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.TAL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c salOnCreationForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = salMasterMappingFromLead(dfr, lead);
        dfr = salOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.SAL_Entered_From__c = 'Created';
        dfr.Lead_Name_on_Creation__c = (lead.FirstName != null ? lead.FirstName + ' ' : '') + lead.LastName;
        dfr.Lead__c = Lead.Id;
        dfr.Lead_Email_on_Creation__c = Lead.Email;
        return dfr;
    }

    public static Demand_Funnel__c salStatusChangeForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String previousStatus,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = salMasterMappingFromLead(dfr, lead);
        dfr = salOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.SAL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c salBackfillForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = salMasterMappingFromLead(dfr, lead);
        dfr = salOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.SAL_Backfilled__c = true;
        dfr.SAL_Entered_From__c = 'Backfilled';
        dfr.SAL_Exited_To__c = 'Backfilled';
        dfr.SAL_DateTime_Exited__c = DateTime.now();
        dfr.SAL_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c eolStatusChangeForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String previousStatus,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = eolMasterMappingFromLead(dfr, lead);
        dfr = eolOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.EOL_Downgrade_Reason__c = Lead.Downgrade_Reason__c;
        dfr.EOL_Sub_Downgrade_Reason__c = Lead.Sub_Downgrade_Reason__c;
        dfr.EOL_Entered_From__c = previousStatus;
        dfr.Pre_Opportunity_Close_Date__c = Date.today();
        dfr.Pre_Opportunity_Close_Reason__c = 'Downgraded';
        return dfr;
    }

    public static Demand_Funnel__c prospectBackfillForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = prospectMasterMappingFromContact(dfr, con);
        dfr = prospectOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.Prospect_Owner_Name__c = ownerName;
        dfr.Prospect_Owner_Id__c = ownerId;
        dfr.Prospect_Backfilled__c = true;
        dfr.Prospect_DateTime_Exited__c = DateTime.now();
        dfr.Prospect_Entered_From__c = 'Backfilled';
        dfr.Prospect_Exited_To__c = 'Backfilled';
        dfr.Prospect_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c prospectOnCreationForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = prospectMasterMappingFromContact(dfr, con);
        dfr = prospectOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.Prospect_Owner_Name__c = ownerName;
        dfr.Prospect_Owner_Id__c = ownerId;
        dfr.Prospect_Entered_From__c = 'Created';
        dfr.Contact_Name_on_Creation__c =
            (con.FirstName != null && !String.isBlank(con.FirstName) ? con.FirstName + ' ' : '') + con.LastName;
        dfr.Contact__c = con.Id;
        dfr.Contact_Email_on_Creation__c = con.Email;
        return dfr;
    }

    public static Demand_Funnel__c mqlBackfillForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = mqlMasterMappingFromContact(dfr, con);
        dfr = mqlOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.MQL_Backfilled__c = true;
        dfr.MQL_Entered_From__c = 'Backfilled';
        dfr.MQL_Exited_To__c = 'Backfilled';
        dfr.MQL_DateTime_Exited__c = DateTime.now();
        dfr.MQL_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c mqlOnCreationForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = mqlMasterMappingFromContact(dfr, con);
        dfr = mqlOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.MQL_Entered_From__c = 'Created';
        dfr.Contact_Name_on_Creation__c =
            (con.FirstName != null && !String.isBlank(con.FirstName) ? con.FirstName + ' ' : '') + con.LastName;
        dfr.Contact__c = con.Id;
        dfr.Contact_Email_on_Creation__c = con.Email;
        return dfr;
    }

    public static Demand_Funnel__c mqlStatusChangeForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId,
        String previousStatus
    ) {
        dfr = mqlMasterMappingFromContact(dfr, con);
        dfr = mqlOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.MQL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c talOnCreationForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = talMasterMappingFromContact(dfr, con);
        dfr = talOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.TAL_Entered_From__c = 'Created';
        dfr.Contact_Name_on_Creation__c =
            (con.FirstName != null && !String.isBlank(con.FirstName) ? con.FirstName + ' ' : '') + con.LastName;
        dfr.Contact__c = con.Id;
        dfr.Contact_Email_on_Creation__c = con.Email;
        return dfr;
    }

    public static Demand_Funnel__c talStatusChangeForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId,
        String previousStatus
    ) {
        dfr = talMasterMappingFromContact(dfr, con);
        dfr = talOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.TAL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c salOnCreationForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = salMasterMappingFromContact(dfr, con);
        dfr = salOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.SAL_Entered_From__c = 'Created';
        dfr.Contact_Name_on_Creation__c =
            (con.FirstName != null && !String.isBlank(con.FirstName) ? con.FirstName + ' ' : '') + con.LastName;
        dfr.Contact__c = con.Id;
        dfr.Contact_Email_on_Creation__c = con.Email;
        return dfr;
    }

    public static Demand_Funnel__c salStatusChangeForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId,
        String previousStatus
    ) {
        dfr = salMasterMappingFromContact(dfr, con);
        dfr = salOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.SAL_Entered_From__c = previousStatus;
        return dfr;
    }

    public static Demand_Funnel__c salBackfillForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = salMasterMappingFromContact(dfr, con);
        dfr = salOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.SAL_Backfilled__c = true;
        dfr.SAL_Entered_From__c = 'Backfilled';
        dfr.SAL_Exited_To__c = 'Backfilled';
        dfr.SAL_DateTime_Exited__c = DateTime.now();
        dfr.SAL_Entered_From__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c eolStatusChangeForContact(
        Demand_Funnel__c dfr,
        Contact con,
        User user,
        String ownerName,
        String ownerId,
        String previousStatus
    ) {
        dfr = eolMasterMappingFromContact(dfr, con);
        dfr = eolOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.EOL_Downgrade_Reason__c = con.Downgrade_Reason__c;
        dfr.EOL_Sub_Downgrade_Reason__c = con.Sub_Downgrade_Reason__c;
        dfr.EOL_Entered_From__c = previousStatus;
        dfr.Pre_Opportunity_Close_Date__c = Date.today();
        dfr.Pre_Opportunity_Close_Reason__c = 'Downgraded';
        return dfr;
    }

    public static Demand_Funnel__c prospectMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.Prospect_Assignment_Source_hidden__c = ld.Assignment_Source_hidden__c;
        dfr.Prospect_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.Prospect_BMID__c = ld.BMID__c;
        dfr.Prospect_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.Prospect_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.Prospect_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.Prospect_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.Prospect_Lead_Source__c = ld.LeadSource;
        dfr.Prospect_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.Prospect_PID__c = ld.PID__c;
        dfr.Prospect_Form_URL__c = ld.Form_URL__c;
        dfr.Prospect_AID__c = ld.AID__c;
        dfr.Prospect_Purchase_Timeframe__c = ld.Time_Frame__c;
        dfr.Prospect_Form_URL__c = ld.Form_URL__c;
        dfr.Prospect_DateTime_Entered__c = DateTime.now();
        return dfr;
    }

    public static Demand_Funnel__c prospectMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.Prospect_AID__c = con.AID__c;
        dfr.Prospect_Behavior_Score__c = con.Behavior_Score__c;
        dfr.Prospect_BMID__c = con.BMID__c;
        dfr.Prospect_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.Prospect_DateTime_Entered__c = DateTime.now();
        dfr.Prospect_Demographic_Score__c = con.Demographic_Score__c;
        dfr.Prospect_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.Prospect_Form_URL__c = con.Form_URL__c;
        dfr.Prospect_Lead_Source__c = con.LeadSource;
        dfr.Prospect_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.Prospect_PID__c = con.PID__c;
        dfr.Prospect_Purchase_Timeframe__c = con.Time_Frame__c;
        dfr.Prospect_Form_URL__c = con.Form_URL__c;
        return dfr;
    }

    public static Demand_Funnel__c prospectOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.Prospect_Owner_Division__c = user.Division;
        dfr.Prospect_Owner_Role__c = user.UserRoleName__c;
        dfr.Prospect_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.Prospect_Owner_Team__c = user.Team__c;
        dfr.Prospect_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.Prospect_Owner_Name__c = ownerName;
        dfr.Prospect_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c mqlMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.MQL_AID__c = ld.AID__c;
        dfr.MQL_Assignment_Source_hidden__c = ld.Assignment_Source_hidden__c;
        dfr.MQL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.MQL_BMID__c = ld.BMID__c;
        dfr.MQL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.MQL_DateTime_Entered__c = DateTime.now();
        dfr.MQL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.MQL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.MQL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.MQL_Lead_Source__c = ld.LeadSource;
        dfr.MQL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.MQL_Form_URL__c = ld.Form_URL__c;
        return dfr;
    }

    public static Demand_Funnel__c mqlMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.MQL_AID__c = con.AID__c;
        dfr.MQL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.MQL_BMID__c = con.BMID__c;
        dfr.MQL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.MQL_DateTime_Entered__c = DateTime.now();
        dfr.MQL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.MQL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.MQL_Lead_Source__c = con.LeadSource;
        dfr.MQL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.MQL_PID__c = con.PID__c;
        dfr.MQL_Purchase_Timeframe__c = con.Time_Frame__c;
        dfr.MQL_Type__c = 'New';
        dfr.MQL_Form_URL__c = con.Form_URL__c;
        return dfr;
    }

    public static Demand_Funnel__c mqlOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.MQL_Owner_Name__c = ownerName;
        dfr.MQL_Owner_Id__c = ownerId;
        dfr.MQL_Owner_Division__c = user.Division;
        dfr.MQL_Owner_Role__c = user.UserRoleName__c;
        dfr.MQL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.MQL_Owner_Team__c = user.Team__c;
        dfr.MQL_Owner_Territory__c = user.Upmarket_Territory__c;
        return dfr;
    }

    public static Demand_Funnel__c talMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.TAL_AID__c = ld.AID__c;
        dfr.TAL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.TAL_BMID__c = ld.BMID__c;
        dfr.TAL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.TAL_DateTime_Entered__c = DateTime.now();
        dfr.TAL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.TAL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.TAL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.TAL_Lead_Source__c = ld.LeadSource;
        dfr.TAL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.TAL_PID__c = ld.PID__c;
        dfr.TAL_Purchase_Timeframe__c = ld.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c talMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.TAL_AID__c = con.AID__c;
        dfr.TAL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.TAL_BMID__c = con.BMID__c;
        dfr.TAL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.TAL_DateTime_Entered__c = DateTime.now();
        dfr.TAL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.TAL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.TAL_Lead_Source__c = con.LeadSource;
        dfr.TAL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.TAL_PID__c = con.PID__c;
        dfr.TAL_Purchase_Timeframe__c = con.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c talOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.TAL_Owner_Division__c = user.Division;
        dfr.TAL_Owner_Role__c = user.UserRoleName__c;
        dfr.TAL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.TAL_Owner_Team__c = user.Team__c;
        dfr.TAL_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.TAL_Owner_Name__c = ownerName;
        dfr.TAL_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c talBackfillMapping(Demand_Funnel__c dfr) {
        dfr.TAL_Backfilled__c = true;
        dfr.TAL_DateTime_Exited__c = DateTime.now();
        dfr.TAL_Entered_From__c = 'Backfilled';
        dfr.TAL_Exited_To__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c tqlMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.TQL_AID__c = ld.AID__c;
        dfr.TQL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.TQL_BMID__c = ld.BMID__c;
        dfr.TQL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.TQL_DateTime_Entered__c = DateTime.now();
        dfr.TQL_DateTime_Exited__c = DateTime.now();
        dfr.TQL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.TQL_Entered_From__c = 'TAL';
        dfr.TQL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.TQL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.TQL_Lead_Source__c = ld.LeadSource;
        dfr.TQL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.TQL_PID__c = ld.PID__c;
        dfr.TQL_Purchase_Timeframe__c = ld.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c tqlMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.TQL_AID__c = con.AID__c;
        dfr.TQL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.TQL_BMID__c = con.BMID__c;
        dfr.TQL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.TQL_DateTime_Entered__c = DateTime.now();
        dfr.TQL_DateTime_Exited__c = DateTime.now();
        dfr.TQL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.TQL_Entered_From__c = 'TAL';
        dfr.TQL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.TQL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.TQL_PID__c = con.PID__c;
        dfr.TQL_Purchase_Timeframe__c = con.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c tqlOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.TQL_Owner_Division__c = user.Division;
        dfr.TQL_Owner_Role__c = user.UserRoleName__c;
        dfr.TQL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.TQL_Owner_Team__c = user.Team__c;
        dfr.TQL_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.TQL_Owner_Name__c = ownerName;
        dfr.TQL_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c tqlBackfillMapping(Demand_Funnel__c dfr) {
        dfr.TQL_Backfilled__c = true;
        dfr.TQL_DateTime_Exited__c = DateTime.now();
        dfr.TQL_Entered_From__c = 'Backfilled';
        dfr.TQL_Exited_To__c = 'Backfilled';
        return dfr;
    }

    public static Demand_Funnel__c salMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.SAL_AID__c = ld.AID__c;
        dfr.SAL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.SAL_BMID__c = ld.BMID__c;
        dfr.SAL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.SAL_DateTime_Entered__c = DateTime.now();
        dfr.SAL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.SAL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.SAL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.SAL_Lead_Source__c = ld.LeadSource;
        dfr.SAL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.SAL_PID__c = ld.PID__c;
        dfr.SAL_Purchase_Timeframe__c = ld.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c sqlOnCreationForContact(
        Demand_Funnel__c dfr,
        Contact con,
        Opportunity opp,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr = sqlMasterMappingFromContact(dfr, con);
        dfr = sqlOwnerMappingFromUser(dfr, user, ownerName, ownerId);
        dfr.Contact_Name_on_Creation__c =
            (con.FirstName != null && !String.isBlank(con.FirstName) ? con.FirstName + ' ' : '') + con.LastName;
        dfr.Contact__c = con.Id;
        dfr.Contact_Email_on_Creation__c = con.Email;
        dfr.Opportunity__c = opp.Id;
        return dfr;
    }

    public static Demand_Funnel__c salMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.SAL_AID__c = con.AID__c;
        dfr.SAL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.SAL_BMID__c = con.BMID__c;
        dfr.SAL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.SAL_DateTime_Entered__c = DateTime.now();
        dfr.SAL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.SAL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.SAL_Lead_Source__c = con.LeadSource;
        dfr.SAL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.SAL_PID__c = con.PID__c;
        dfr.SAL_Purchase_Timeframe__c = con.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c salOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.SAL_Owner_Division__c = user.Division;
        dfr.SAL_Owner_Role__c = user.UserRoleName__c;
        dfr.SAL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.SAL_Owner_Team__c = user.Team__c;
        dfr.SAL_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.SAL_Owner_Name__c = ownerName;
        dfr.SAL_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c sqlMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.Opportunity__c = ld.ConvertedOpportunityId;
        dfr.Pre_Opportunity_Status__c = 'SQL';
        dfr.SQL_AID__c = ld.AID__c;
        dfr.SQL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.SQL_BMID__c = ld.BMID__c;
        dfr.SQL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.SQL_DateTime_Entered__c = DateTime.now();
        dfr.SQL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.SQL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.SQL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.SQL_Lead_Source__c = ld.LeadSource;
        dfr.SQL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.SQL_PID__c = ld.PID__c;
        dfr.SQL_Purchase_Timeframe__c = ld.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c sqlMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.Pre_Opportunity_Status__c = 'SQL';
        dfr.SQL_AID__c = con.AID__c;
        dfr.SQL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.SQL_BMID__c = con.BMID__c;
        dfr.SQL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.SQL_DateTime_Entered__c = DateTime.now();
        dfr.SQL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.SQL_Entered_From__c = 'Created';
        dfr.SQL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.SQL_Lead_Source__c = con.LeadSource;
        dfr.SQL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.SQL_PID__c = con.PID__c;
        dfr.SQL_Purchase_Timeframe__c = con.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c sqlOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.SQL_Owner_Division__c = user.Division;
        dfr.SQL_Owner_Role__c = user.UserRoleName__c;
        dfr.SQL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.SQL_Owner_Team__c = user.Team__c;
        dfr.SQL_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.SQL_Owner_Name__c = ownerName;
        dfr.SQL_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c eolMasterMappingFromLead(Demand_Funnel__c dfr, Lead ld) {
        dfr.EOL_AID__c = ld.AID__c;
        dfr.EOL_Behavior_Score__c = ld.Behavior_Score__c;
        dfr.EOL_BMID__c = ld.BMID__c;
        dfr.EOL_Campaign__c = ld.Most_Recent_Campaign__c;
        dfr.EOL_DateTime_Entered__c = DateTime.now();
        dfr.EOL_Demographic_Score__c = ld.Demographic_Score__c;
        dfr.EOL_Lead_Entry_Source__c = ld.Lead_Entry_Source__c;
        dfr.EOL_Lead_Score_Category__c = ld.Lead_Score__c;
        dfr.EOL_Lead_Source__c = ld.LeadSource;
        dfr.EOL_Marketing_Asset__c = ld.Most_Recent_Asset__c;
        dfr.EOL_PID__c = ld.PID__c;
        dfr.EOL_Purchase_Timeframe__c = ld.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c eolMasterMappingFromContact(Demand_Funnel__c dfr, Contact con) {
        dfr.EOL_AID__c = con.AID__c;
        dfr.EOL_Behavior_Score__c = con.Behavior_Score__c;
        dfr.EOL_BMID__c = con.BMID__c;
        dfr.EOL_Campaign__c = con.Most_Recent_Campaign__c;
        dfr.EOL_DateTime_Entered__c = DateTime.now();
        dfr.EOL_Demographic_Score__c = con.Demographic_Score__c;
        dfr.EOL_Lead_Entry_Source__c = con.Lead_Entry_Source__c;
        dfr.EOL_Lead_Source__c = con.LeadSource;
        dfr.EOL_Marketing_Asset__c = con.Most_Recent_Asset__c;
        dfr.EOL_PID__c = con.PID__c;
        dfr.EOL_Purchase_Timeframe__c = con.Time_Frame__c;
        return dfr;
    }

    public static Demand_Funnel__c eolOwnerMappingFromUser(
        Demand_Funnel__c dfr,
        User user,
        String ownerName,
        String ownerId
    ) {
        dfr.EOL_Owner_Division__c = user.Division;
        dfr.EOL_Owner_Role__c = user.UserRoleName__c;
        dfr.EOL_Owner_Team__c = user.Team__c;
        dfr.EOL_Owner_Territory__c = user.Upmarket_Territory__c;
        dfr.EOL_Owner_Segment__c = user.SegmentPicklist__c;
        dfr.EOL_Owner_Name__c = ownerName;
        dfr.EOL_Owner_Id__c = ownerId;
        return dfr;
    }

    public static Demand_Funnel__c setLeadNameOnDFRCreation(Demand_Funnel__c dfr, Lead leadRecord) {
        dfr.Lead_Name_on_Creation__c =
            (leadRecord.FirstName != null ? leadRecord.FirstName + ' ' : '') + leadRecord.LastName;
        return dfr;
    }

    public static Demand_Funnel__c talUpdateDFRFieldsOnLeadOwnerChange(Demand_Funnel__c dfr, Lead leadRecord) {
        dfr = setLeadNameOnDFRCreation(dfr, leadRecord);
        if (dfr.SAL_Entered_From__c == DG_DFR_Class.DFRPROSPECT) {
            dfr.Prospect_Exited_To__c = DG_DFR_Class.DFRTAL;
        } else if (dfr.SAL_Entered_From__c == DG_DFR_Class.DFRMQL) {
            dfr.MQL_Exited_To__c = DG_DFR_Class.DFRTAL;
        }
        if (dfr.TAL_Entered_From__c == null) {
            dfr.TAL_Entered_From__c = dfr.SAL_Entered_From__c;
        }

        return dfr;
    }

    public static Demand_Funnel__c onCreationMapping(Demand_Funnel__c dfr, Lead lead) {
        dfr.Lead__c = lead.Id;
        dfr.Lead_Email_on_Creation__c = lead.Email;
        return dfr;
    }

    public static Demand_Funnel__c talOnChangeOwnerForLeadFromUser(
        Demand_Funnel__c dfr,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = TALOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.Pre_Opportunity_Status__c = DG_DFR_Class.DFRTAL;
        return dfr;
    }

    public static Demand_Funnel__c prospectOnChangeOwnerForLead(
        Demand_Funnel__c dfr,
        User user,
        String leadOwnerName,
        String leadOwnerId,
        String leadDFRStage
    ) {
        dfr.Prospect_Owner_Name__c = leadOwnerName;
        dfr.Prospect_Owner_Id__c = leadOwnerId;
        dfr = prospectOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);

        if (
            leadDFRStage == DG_DFR_Class.DFRSAL &&
            dfr.Prospect_Exited_To__c != 'Backfilled' &&
            dfr.TAL_Entered_From__c != DG_DFR_Class.DFRPROSPECT
        ) {
            dfr.Prospect_Exited_To__c = DG_DFR_Class.DFRSAL;
        }

        return dfr;
    }

    public static Demand_Funnel__c talOnChangeOwnerForLead(Demand_Funnel__c dfr, Lead lead) {
        dfr = TALMasterMappingFromLead(dfr, lead);
        dfr = onCreationMapping(dfr, lead);
        dfr = talUpdateDFRFieldsOnLeadOwnerChange(dfr, lead);
        return dfr;
    }

    public static Demand_Funnel__c stageSalOnChangeOwnerForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = SALMasterMappingFromLead(dfr, lead);
        dfr = onCreationMapping(dfr, lead);
        dfr = setLeadNameOnDFRCreation(dfr, lead);
        dfr.SAL_Entered_From__c = 'Created';
        dfr.Pre_Opportunity_Status__c = 'SAL';
        dfr.SAL_Owner_Name__c = leadOwnerName;
        dfr.SAL_Owner_Id__c = leadOwnerId;
        dfr = SALOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);

        if (dfr.MQL_Exited_To__c != 'Backfilled') {
            dfr.MQL_Exited_To__c = DG_DFR_Class.DFRSAL;
            dfr.SAL_Entered_From__c = DG_DFR_Class.DFRMQL;
        }

        return dfr;
    }

    public static Demand_Funnel__c stageMqlOnChangeOwnerForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = MQLMasterMappingFromLead(dfr, lead);
        dfr = onCreationMapping(dfr, lead);
        dfr = setLeadNameOnDFRCreation(dfr, lead);
        dfr.MQL_Entered_From__c = 'Created';
        dfr.Pre_Opportunity_Status__c = 'MQL';
        dfr.MQL_Owner_Name__c = leadOwnerName;
        dfr.MQL_Owner_Id__c = leadOwnerId;
        dfr = MQLOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);

        return dfr;
    }

    public static Boolean changeLeadOwnerShouldUpdateDFR(
        Demand_Funnel__c DFR,
        Lead newLead,
        Lead oldLead,
        Map<Id, User> mapUsers,
        Map<String, String> mapDFRSystemUsers
    ) {
        return DFR != null &&
            newLead.Status != DG_DFR_Class.STATUS_DOWNGRADED &&
            DFR.Pre_Opportunity_Status__c == DG_DFR_Class.DFRTAL &&
            DFR.TAL_DateTime_Entered__c != null &&
            ((!String.isEmpty(DFR.MQL_Owner_Team__c) &&
            (DFR.MQL_Owner_Team__c.contains(DG_DFR_Class.DFRSDR) ||
            DFR.MQL_Owner_Team__c.contains(DG_DFR_Class.DFRBDR))) ||
            (String.isEmpty(DFR.MQL_Owner_Team__c) && DFR.MQL_DateTime_Entered__c != null)) &&
            !mapDFRSystemUsers.containsKey(oldLead.OwnerId) &&
            (newLead.OwnerId != oldLead.OwnerId && !newLead.SDR_BDR_Owned__c);
    }

    public static Demand_Funnel__c tqlOnChangeOwnerForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = TQLMasterMappingFromLead(dfr, lead);
        dfr = TQLOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.TAL_Exited_To__c = 'TQL';
        dfr.TQL_Entered_From__c = 'TAL';
        dfr.TQL_Exited_To__c = 'SAL';
        dfr.TQL_DateTime_Exited__c = Datetime.now();
        dfr.TAL_DateTime_Exited__c = Datetime.now();

        return dfr;
    }

    public static Demand_Funnel__c salOnChangeOwnerForLead(
        Demand_Funnel__c dfr,
        Lead lead,
        User user,
        String leadOwnerName,
        String leadOwnerId
    ) {
        dfr = SALMasterMappingFromLead(dfr, lead);
        dfr = onCreationMapping(dfr, lead);
        dfr = SALOwnerMappingFromUser(dfr, user, leadOwnerName, leadOwnerId);
        dfr.SAL_Entered_From__c = 'TQL';
        dfr.Pre_Opportunity_Status__c = DG_DFR_Class.DFRSAL;

        return dfr;
    }

    public static Demand_Funnel__c talOnChangeOwnerForLead_updateMQL(
        Demand_Funnel__c dfr,
        Lead lead,
        String leadOwnerName,
        String leadOwnerId
    ) {
        if (dfr.TAL_Datetime_Entered__c == null) {
            dfr.TAL_Datetime_Entered__c = DateTime.now();
        }
        if (dfr.MQL_Exited_To__c != 'Backfilled') {
            dfr.MQL_DateTime_Exited__c = DateTime.now();
            dfr.MQL_Exited_To__c = DG_DFR_Class.DFRTAL;
            dfr.TAL_Entered_From__c = DG_DFR_Class.DFRMQL;
        } else if (dfr.Prospect_Exited_To__c != 'Backfilled') {
            dfr.Prospect_DateTime_Exited__c = DateTime.now();
            dfr.Prospect_Exited_To__c = DG_DFR_Class.DFRTAL;
            dfr.TAL_Entered_From__c = DG_DFR_Class.DFRPROSPECT;
        } else {
            dfr.TAL_Entered_From__c = 'Created';
        }

        dfr = TALMasterMappingFromLead(dfr, lead);

        dfr = onCreationMapping(dfr, lead);

        dfr = setLeadNameOnDFRCreation(dfr, lead);

        dfr.Pre_Opportunity_Status__c = 'TAL';
        dfr.TAL_Owner_Name__c = leadOwnerName;
        dfr.TAL_Owner_Id__c = leadOwnerId;

        return dfr;
    }

    public static Demand_Funnel__c salOnChangeOwnerForLead_updateMQL(
        Demand_Funnel__c dfr,
        Lead lead,
        String leadOwnerName,
        String leadOwnerId
    ) {
        if (dfr.SAL_Datetime_Entered__c == null) {
            dfr.SAL_Datetime_Entered__c = DateTime.now();
        }
        if (dfr.MQL_Exited_To__c != 'Backfilled') {
            dfr.MQL_DateTime_Exited__c = DateTime.now();
            dfr.MQL_Exited_To__c = DG_DFR_Class.DFRSAL;
            dfr.SAL_Entered_From__c = DG_DFR_Class.DFRMQL;
        } else if (dfr.Prospect_Exited_To__c != 'Backfilled') {
            dfr.Prospect_DateTime_Exited__c = DateTime.now();
            dfr.Prospect_Exited_To__c = DG_DFR_Class.DFRSAL;
            dfr.SAL_Entered_From__c = DG_DFR_Class.DFRPROSPECT;
        } else {
            dfr.SAL_Entered_From__c = 'Created';
        }

        dfr = SALMasterMappingFromLead(dfr, lead);

        dfr.Pre_Opportunity_Status__c = 'SAL';
        dfr.SAL_Owner_Name__c = leadOwnerName;
        dfr.SAL_Owner_Id__c = leadOwnerId;

        return dfr;
    }

    public static Demand_Funnel__c setDFRTALOwnerFields(
        Demand_Funnel__c dfr,
        Map<Id, User> ownerIdToUser,
        String leadOwnerID
    ) {
        User leadOwner = ownerIdToUser.get(leadOwnerID);

        if (leadOwner != null) {
            dfr.TAL_Owner_Role__c = leadOwner.UserRole.Name;
            dfr.TAL_Owner_Team__c = leadOwner.Team__c;
            dfr.TAL_Owner_Division__c = leadOwner.Division;
            dfr.TAL_Owner_Segment__c = leadOwner.SegmentPicklist__c;
            dfr.TAL_Owner_Territory__c = leadOwner.Upmarket_Territory__c;
        }

        return dfr;
    }

    public static Demand_Funnel__c setDFRSALOwnerFields(
        Demand_Funnel__c dfr,
        Map<Id, User> ownerIdToUser,
        String leadOwnerID
    ) {
        User leadOwner = ownerIdToUser.get(leadOwnerID);

        if (leadOwner != null) {
            dfr.SAL_Owner_Role__c = leadOwner.UserRole.Name;
            dfr.SAL_Owner_Team__c = leadOwner.Team__c;
            dfr.SAL_Owner_Division__c = leadOwner.Division;
            dfr.SAL_Owner_Segment__c = leadOwner.SegmentPicklist__c;
            dfr.SAL_Owner_Territory__c = leadOwner.Upmarket_Territory__c;
        }

        return dfr;
    }

    public static Demand_Funnel__c setDFRMQLOwnerFields(
        Demand_Funnel__c dfr,
        Id leadOwnerID,
        Map<Id, User> ownerIdToUser,
        Map<Id, QueueSObject> ownerIdToQueue
    ) {
        dfr.MQL_Owner_Name__c = ownerIdToUser.containsKey(leadOwnerID)
            ? ownerIdToUser.get(leadOwnerID).Name
            : (ownerIdToQueue.containsKey(leadOwnerID) ? ownerIdToQueue.get(leadOwnerID).Queue.Name : null);
        dfr.MQL_Owner_Id__c = leadOwnerID;
        dfr.MQL_Owner_Role__c = ownerIdToUser.containsKey(leadOwnerID)
            ? ownerIdToUser.get(leadOwnerID).UserRole.Name
            : null;
        dfr.MQL_Owner_Team__c = ownerIdToUser.containsKey(leadOwnerID) ? ownerIdToUser.get(leadOwnerID).Team__c : null;
        dfr.MQL_Owner_Division__c = ownerIdToUser.containsKey(leadOwnerID)
            ? ownerIdToUser.get(leadOwnerID).Division
            : null;
        dfr.MQL_Owner_Segment__c = ownerIdToUser.containsKey(leadOwnerID)
            ? ownerIdToUser.get(leadOwnerID).SegmentPicklist__c
            : null;
        dfr.MQL_Queue_Name__c = ownerIdToQueue.containsKey(leadOwnerID)
            ? ownerIdToQueue.get(leadOwnerID).Queue.Name
            : null;
        dfr.MQL_Owner_Territory__c = ownerIdToUser.containsKey(leadOwnerID)
            ? ownerIdToUser.get(leadOwnerID).Upmarket_Territory__c
            : null;

        return dfr;
    }

    public static List<String> getDFRLeadRType() {
        List<String> listDFRRType = new List<String>();

        if (!Test.isRunningTest()) {
            Map<String, DFR_Lead_Record_Types__c> mapDFRRType = DFR_Lead_Record_Types__c.getAll();
            for (String k : mapDFRRType.keySet()) {
                listDFRRType.add(k);
            }
        } else {
            listDFRRType = new List<String>{ 'Sales_Leads', 'Partner_Leads' };
        }
        return listDFRRType;
    }

    public static List<String> getDFROppRType() {
        List<String> listDFRRType = new List<String>();

        if (!Test.isRunningTest()) {
            Map<String, DFR_Opportunity_Record_Type__c> mapDFRRType = DFR_Opportunity_Record_Type__c.getAll();
            for (String k : mapDFRRType.keySet()) {
                listDFRRType.add(k);
            }
        } else {
            listDFRRType = new List<String>{ 'Sales_Opportunity', 'VAR_Opportunity', 'New_Sales_Opportunity' };
        }
        return listDFRRType;
    }

    public static Map<String, String> getContactTypeToFunnelType() {
        Map<String, String> mapContactTypeToFunnelType = new Map<String, String>();

        if (!Test.isRunningTest()) {
            Map<String, DFR_Contact_Type_to_Funnel_Type__c> mapDFRContactTypeToFunnelType = DFR_Contact_Type_to_Funnel_Type__c.getAll();
            for (String k : mapDFRContactTypeToFunnelType.keySet()) {
                mapContactTypeToFunnelType.put(k.ToLowerCase(), mapDFRContactTypeToFunnelType.get(k).Funnel_Type__c);
            }
        } else {
            mapContactTypeToFunnelType = new Map<String, String>{
                'prospect' => 'Acquisition',
                'customer' => 'Upsell',
                'winback' => 'Winback'
            };
        }

        return mapContactTypeToFunnelType;
    }

    public static Set<String> getExcludedLeadSources() {
        Set<String> setLS = new Set<String>();

        if (!Test.isRunningTest()) {
            Map<String, DFRExcludedLeadSource__c> mapExcludedLS = DFRExcludedLeadSource__c.getAll();
            for (String k : mapExcludedLS.keySet()) {
                setLS.add(mapExcludedLS.get(k).Lead_Source__c);
            }
        } else {
            setLS.add('Test LS Test');
        }
        return setLS;
    }

    public static Map<Id, String> getMapOfRecordTypes(List<String> dfrLeadRType) {
        Map<Id, String> mapRTId = new Map<Id, String>();
        Map<String, Schema.RecordTypeInfo> leadRTs = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
        for (String leadType : dfrLeadRType) {
            leadType = leadType.replace('_', ' ');
            if (leadRTs.containsKey(leadType)) {
                mapRTId.put(leadRTs.get(leadType).getRecordTypeId(), leadRTs.get(leadType).getName());
            }
        }
        return mapRTId;
    }

    public static Map<String, String> getDFRStatusToStage() {
        Map<String, String> mapStatusToStage = new Map<String, String>();
        if (!Test.isRunningTest()) {
            Map<String, Status_To_Stage__c> mapDFRStatusToStage = Status_To_Stage__c.getAll();
            for (String k : mapDFRStatusToStage.keySet()) {
                mapStatusToStage.put(k, mapDFRStatusToStage.get(k).Stage__c);
            }
        } else {
            mapStatusToStage = new Map<String, String>{
                '.5 Re-New' => 'Re-New',
                DG_DFR_Class.STATUS_CONTACTED => 'SAL',
                'X. Suspect' => 'Suspect',
                DG_DFR_Class.STATUS_CALLOUT => 'SAL',
                DG_DFR_Class.STATUS_DOWNGRADED => 'Downgraded',
                '1. New C' => 'MQL',
                '1. New A' => 'MQL',
                'X. Open' => 'Prospect',
                '1. New' => 'MQL',
                '1. New D' => 'MQL',
                '1. New B' => 'MQL'
            };
        }
        return mapStatusToStage;
    }

    public static Map<Id, User> getUsersById(Set<Id> ownerIdsList) {
        if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
            Map<Id,User> userById =  UserHelper.retrieveUserMapWithCache(ownerIdsList);
            return userById;
        }
        else 
        {
            return new Map<Id, User>((List<User>) new UserSelector().selectUserForDFRList(new List<Object>{ ownerIdsList }).executeQuery());
        }
    }

    public static Map<String, Id> getMapOpportunityContactRole(set<Id> setOId) {
        Map<String, Id> mapOIDCID = new Map<String, Id>();

        for (
            OpportunityContactRole o : ((List<OpportunityContactRole>) new OpportunityContactRoleSelector()
                .selectOpportunityContactRolesByOppId(new List<Object>{ setOId })
                .executeQuery())
        ) {
            mapOIDCID.put(o.OpportunityId + '~' + o.ContactId, o.Id);
        }

        return mapOIDCID;
    }

    public static Boolean isLeadGoingToTALTQL(Lead newLead, Map<Id, Demand_Funnel__c> dfrList) {
        Boolean isDFRListPopulated = !dfrList.isEmpty();

        Boolean isLeadStatusNotDowngraded = (newLead.Status != LeadTriggerHelper.LEADSTATUSDOWNGRADED);

        Boolean isLeadStatusMQLStage = (newLead.Status == LeadTriggerHelper.LEADSTATUSCALLOUT ||
        newLead.Status == LeadTriggerHelper.LEADSTATUSCONTACTED);

        Boolean isMQLOwnerTeamNull = isDFRListPopulated && dfrList.get(newLead.Id) != null
            ? (dfrList.get(newLead.Id).MQL_Owner_Team__c == null &&
              dfrList.get(newLead.Id).MQL_DateTime_Entered__c != null)
            : false;

        Boolean isMQLOwnerTeamSDRBDR = isDFRListPopulated && dfrList.get(newLead.Id) != null
            ? (String.isNotBlank(dfrList.get(newLead.Id).MQL_Owner_Team__c) &&
              (dfrList.get(newLead.Id).MQL_Owner_Team__c.contains(DG_DFR_Class.DFRSDR) ||
              dfrList.get(newLead.Id).MQL_Owner_Team__c.contains(DG_DFR_Class.DFRBDR)))
            : false;

        return (isDFRListPopulated &&
        isLeadStatusNotDowngraded &&
        isLeadStatusMQLStage &&
        (isMQLOwnerTeamNull || isMQLOwnerTeamSDRBDR));
    }

    public static Map<Id, Demand_Funnel__c> getDFRMap(Set<Id> leadsToProcess) {
        Map<Id, Demand_Funnel__c> queryResult = new Map<Id, Demand_Funnel__c>();
        if (!leadsToProcess.isEmpty()) {
            List<Demand_Funnel__c> dfrList = new DemandFunnelSelector()
                .selectDFRForTQLUpdate(new List<Object>{ leadsToProcess })
                .executeQuery();
            for (Demand_Funnel__c dfr : dfrList) {
                queryResult.put(dfr.Lead__c, dfr);
            }
        }
        return queryResult;
    }

    public static Map<Id, Demand_Funnel__c> getDFRMapForLeadStatusChange(Set<Id> leadIds) {
        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectDFRByLeadList(new List<Object>{ leadIds })
            .selectField(Demand_Funnel__c.MQL_DateTime_Entered__c)
            .addOrdering('CreatedDate', QueryFactory.SortOrder.DESCENDING)
            .executeQuery();
        Map<Id, Demand_Funnel__c> mapLeadIdToDFR = new Map<Id, Demand_Funnel__c>();
        for (Demand_Funnel__c d : dfrs) {
            if (d.DFR_Active_Status__c == 'Active') {
                mapLeadIdToDFR.put(d.Lead__c, d);
            }
        }
        return mapLeadIdToDFR;
    }

    public static Boolean backfillTALTQLCheck(Demand_Funnel__c dfr) {
        return ((dfr.MQL_Owner_Team__c == null && dfr.MQL_DateTime_Entered__c != null) ||
        (String.isNotBlank(dfr.MQL_Owner_Team__c) &&
        (dfr.MQL_Owner_Team__c.contains(DG_DFR_Class.DFRSDR) || dfr.MQL_Owner_Team__c.contains(DG_DFR_Class.DFRBDR))));
    }

    public static Map<Id, String> populateOldStagesMap(List<Lead> lds, Map<Id, Lead> mapOldLeads) {
        Map<Id, String> mapLeadToOldStatus = new Map<Id, String>();
        for (Lead ld : lds) {
            Lead oldLead = mapOldLeads.get(ld.Id);
            if (oldLead != null && oldLead.Status != null) {
                mapLeadToOldStatus.put(ld.Id, oldLead.Status);
            }
        }
        return mapLeadToOldStatus;
    }

    public static Map<Id, Demand_Funnel__c> populateDFRMapSALHandOff(Set<Id> lds) {
        return new Map<Id, Demand_Funnel__c>(
            (List<Demand_Funnel__c>) new DemandFunnelSelector().selectDFRsForSALHandOff(lds).executeQuery()
        );
    }

    public static Map<Id, Lead> filterLeadsByOwnerProfileSALHandOff(
        List<Lead> listNew,
        Map<Id, Lead> mapOld,
        Map<Id, User> mapUser
    ) {
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for (Lead newLead : listNew) {
            Lead oldLead = mapOld.get(newLead.Id);
            String oldOwnerProfile = mapUser.get(oldLead.OwnerId) != null
                ? mapUser.get(oldLead.OwnerId).Profile.Name
                : '';
            String newOwnerProfile = mapUser.get(newLead.OwnerId) != null
                ? mapUser.get(newLead.OwnerId).Profile.Name
                : '';
            if (OldOwnerProfile.contains('SDR') && !NewOwnerProfile.contains('SDR')) {
                mapLead.put(newLead.Id, newLead);
            }
        }
        return mapLead;
    }

    public static Map<String, String> getDFRContactStatusToStage() {
        Map<String, String> mapStatusToStage = new Map<String, String>();

        if (!Test.isRunningTest()) {
            Map<String, DFR_Contact_Status_To_Stage__c> mapDFRStatusToStage = DFR_Contact_Status_To_Stage__c.getAll();
            for (String k : mapDFRStatusToStage.keySet()) {
                mapStatusToStage.put(k, mapDFRStatusToStage.get(k).Stage__c);
            }
        } else {
            mapStatusToStage = new Map<String, String>{
                '.5 Re-New' => 'MQL',
                DG_DFR_Class.STATUS_DOWNGRADED => 'Downgraded',
                '1. New' => 'MQL',
                DG_DFR_Class.STATUS_CALLOUT => 'SAL',
                DG_DFR_Class.STATUS_CONTACTED => 'SAL',
                'X. Open' => 'Prospect',
                'X.5 Working Prospect' => 'Prospect'
            };
        }
        return mapStatusToStage;
    }

    public static Map<Id, QueueSobject> getMapOfQueues(Set<Id> listOwnerId, String objectType) {
        Map<Id, QueueSobject> mapQueue = new Map<Id, QueueSobject>();

        for (
            QueueSObject queue : (List<QueueSObject>) new QueueSelector()
                .selectQueueForDFRBySObjectType(new List<Object>{ objectType })
                .executeQuery()
        ) {
            if (listOwnerId.contains(queue.QueueId)) {
                mapQueue.put(queue.QueueId, queue);
            }
        }

        return mapQueue;
    }

    public static Set<Id> getListOwnerId(List<Contact> listNew) {
        Set<Id> ctOwners = new Set<Id>();
        for (Contact con : listNew) {
            ctOwners.add(con.OwnerId);
        }
        return ctOwners;
    }

    public static List<Contact> excludeBizContacts(List<Contact> listNew) {
        List<Contact> ctsExcludingBiz = new List<Contact>();
        for (Contact ct : listNew) {
            if (
                ct.Account_Brand__c != null &&
                System.Label.BizMerge_Brand_Exclusion_List != null &&
                System.Label.BizMerge_Brand_Exclusion_List.contains(ct.Account_Brand__c)
            ) {
                continue;
            } else {
                ctsExcludingBiz.add(ct);
            }
        }
        return ctsExcludingBiz;
    }

    public static Map<Id, Contact> getMapContactsWithStatusOrOwnerChanges(
        List<Contact> listNew,
        Map<Id, Contact> mapOld,
        Map<Id, User> mapUsers
    ) {
        Map<String, String> mapDFRSystemUsers = getDFRSystemUsers();
        Map<Id, Contact> mapContactsWithChanges = new Map<Id, Contact>();
        for (Contact con : listNew) {
            if (
                ((con.Contact_Status__c != mapOld.get(con.Id).Contact_Status__c) ||
                (con.OwnerId != mapOld.get(con.Id).OwnerId &&
                !mapDFRSystemUsers.containsKey(mapOld.get(con.Id).OwnerId) &&
                !isBDRSDRNullUserByTeam(mapUsers.get(con.OwnerId).Team__c) &&
                (con.Contact_Status__c == DG_DFR_Class.STATUS_CONTACTED ||
                con.Contact_Status__c == DG_DFR_Class.STATUS_CALLOUT))) &&
                (con.Account_Brand__c == null ||
                (con.Account_Brand__c != null &&
                System.Label.BizMerge_Brand_Exclusion_List != null &&
                !System.Label.BizMerge_Brand_Exclusion_List.contains(con.Account_Brand__c)))
            ) {
                mapContactsWithChanges.put(con.Id, con);
            }
        }
        return mapContactsWithChanges;
    }

    public static Map<Id, Demand_Funnel__c> getActiveDFRsForContacts(Set<Id> contactIds) {
        Map<Id, Demand_Funnel__c> mapContactDFR = new Map<id, Demand_Funnel__c>();
        for (
            Demand_Funnel__c dfr : (List<Demand_Funnel__c>) new DemandFunnelSelector()
                .selectActiveDFRByContactId(new List<Object>{ contactIds })
                .executeQuery()
        ) {
            mapContactDFR.put(dfr.Contact__c, dfr);
        }
        return mapContactDFR;
    }

    public static Map<String, String> getDFRSystemUsers() {
        Map<String, String> mapDFRSystemUsers = new Map<String, String>();
        Map<String, DFR_System_Users__c> mapSysUsers = DFR_System_Users__c.getAll();
        for (String k : mapSysUsers.keySet()) {
            mapDFRSystemUsers.put(k, mapSysUsers.get(k).Description__c);
        }
        return mapDFRSystemUsers;
    }

    public static Boolean isBDRSDRNullUserByTeam(String team) {
        return team == null || team.contains(DG_DFR_Class.DFRSDR) || team.contains(DG_DFR_Class.DFRBDR);
    }

    public static List<Demand_Funnel__c> populateActiveDFRsLeadOwnerChange(Set<Id> lds) {
        List<Demand_Funnel__c> dfrs = (List<Demand_Funnel__c>) new DemandFunnelSelector()
            .selectActiveDFRsForLeadOwnerChange(lds)
            .executeQuery();
        return dfrs;
    }

    public static Demand_Funnel__c setSALStampingToNull(Demand_Funnel__c dfr) {
        dfr.SAL_DateTime_Entered__c = null;
        dfr.SAL_DateTime_Exited__c = null;
        dfr.SAL_Lead_Source__c = null;
        dfr.SAL_Lead_Entry_Source__c = null;
        dfr.SAL_Campaign__c = null;
        dfr.SAL_Demographic_Score__c = null;
        dfr.SAL_Behavior_Score__c = null;
        dfr.SAL_Score__c = null;
        dfr.SAL_BMID__c = null;
        dfr.SAL_PID__c = null;
        dfr.SAL_AID__c = null;
        dfr.SAL_Purchase_Timeframe__c = null;
        dfr.SAL_Lead_Score_Category__c = null;
        dfr.SAL_Employee_Size__c = null;
        dfr.SAL_Owner_Role__c = null;
        dfr.SAL_Owner_Name__c = null;
        dfr.SAL_Owner_Id__c = null;
        dfr.SAL_Owner_Division__c = null;
        dfr.SAL_Owner_Segment__c = null;
        dfr.SAL_Owner_Territory__c = null;
        dfr.SAL_Owner_Team__c = null;
        dfr.SAL_Entered_From__c = null;
        dfr.SAL_Owner_Team__c = null;
        dfr.SAL_Owner_Role__c = null;
        dfr.SAL_Owner_Name__c = null;
        dfr.SAL_Owner_Id__c = null;
        dfr.SAL_Owner_Division__c = null;
        dfr.SAL_Owner_Segment__c = null;
        dfr.SAL_Exited_To__c = null;
        dfr.SAL_Handoff_Date__c = null;
        dfr.SAL_Handoff_Owner__c = null;
        dfr.SAL_Handoff_Owner_Role__c = null;
        dfr.SAL_Segment_Name__c = null;
        dfr.SAL_Marketing_Asset__c = null;
        dfr.SAL_Product__c = null;
        return dfr;
    }

    public static Demand_Funnel__c setTALStampingToNull(Demand_Funnel__c dfr) {
        dfr.TAL_DateTime_Entered__c = null;
        dfr.TAL_DateTime_Exited__c = null;
        dfr.TAL_Lead_Source__c = null;
        dfr.TAL_Lead_Entry_Source__c = null;
        dfr.TAL_Campaign__c = null;
        dfr.TAL_Demographic_Score__c = null;
        dfr.TAL_Behavior_Score__c = null;
        dfr.TAL_Score__c = null;
        dfr.TAL_BMID__c = null;
        dfr.TAL_PID__c = null;
        dfr.TAL_AID__c = null;
        dfr.TAL_Purchase_Timeframe__c = null;
        dfr.TAL_Lead_Score_Category__c = null;
        dfr.TAL_Employee_Size__c = null;
        dfr.TAL_Owner_Role__c = null;
        dfr.TAL_Owner_Name__c = null;
        dfr.TAL_Owner_Id__c = null;
        dfr.TAL_Owner_Division__c = null;
        dfr.TAL_Owner_Segment__c = null;
        dfr.TAL_Owner_Territory__c = null;
        dfr.TAL_Owner_Team__c = null;
        dfr.TAL_Entered_From__c = null;
        dfr.TAL_Owner_Team__c = null;
        dfr.TAL_Owner_Role__c = null;
        dfr.TAL_Owner_Name__c = null;
        dfr.TAL_Owner_Id__c = null;
        dfr.TAL_Owner_Division__c = null;
        dfr.TAL_Owner_Segment__c = null;
        dfr.TAL_Exited_To__c = null;
        dfr.TAL_Marketing_Asset__c = null;
        dfr.TAL_Product__c = null;
        return dfr;
    }

    public static Boolean meetsLeadRoutingCriteria(Lead newLead, Lead oldLead) {
        return newLead.Routing_Reason__c != oldLead.Routing_Reason__c &&
            String.isNotBlank(oldLead.Routing_Reason__c) &&
            oldLead.Routing_Reason__c == DG_DFR_Class.REROUTED_MARKETO_MQL_STATUS_UPDATE &&
            String.isNotBlank(newLead.OwnerId);
    }

    public static Demand_Funnel__c setTQLStampingToNull(Demand_Funnel__c dfr) {
        dfr.TQL_AID__c = null;
        dfr.TQL_Backfilled__c = false;
        dfr.TQL_Behavior_Score__c = null;
        dfr.TQL_BMID__c = null;
        dfr.TQL_Campaign__c = null;
        dfr.TQL_DateTime_Entered__c = null;
        dfr.TQL_DateTime_Exited__c = null;
        dfr.TQL_Demographic_Score__c = null;
        dfr.TQL_Employee_Size__c = null;
        dfr.TQL_Entered_From__c = null;
        dfr.TQL_Exited_To__c = null;
        dfr.TQL_Lead_Entry_Source__c = null;
        dfr.TQL_Lead_Score_Category__c = null;
        dfr.TQL_Lead_Source__c = null;
        dfr.TQL_Marketing_Asset__c = null;
        dfr.TQL_Owner_Division__c = null;
        dfr.TQL_Owner_Id__c = null;
        dfr.TQL_Owner_Name__c = null;
        dfr.TQL_Owner_Role__c = null;
        dfr.TQL_Owner_Segment__c = null;
        dfr.TQL_Owner_Team__c = null;
        dfr.TQL_Owner_Territory__c = null;
        dfr.TQL_PID__c = null;
        dfr.TQL_Purchase_Timeframe__c = null;
        dfr.TQL_Score__c = null;
        dfr.TQL_Product__c = null;
        return dfr;
    }

    public static Map<Id, Lead> getLeadsWithOwnerChangesFromQueueToUser(
        List<Lead> leads,
        Map<Id, Lead> mapOld,
        Map<Id, User> mapUser,
        Map<Id, QueueSobject> mapQueue
    ) {
        Map<Id, Lead> mapLead = new Map<Id, Lead>();
        for (Lead newLead : leads) {
            Lead oldLead = mapOld.get(newLead.Id);
            if (mapUser.containsKey(newLead.OwnerId) && mapQueue.containsKey(oldLead.OwnerId)) {
                mapLead.put(newLead.Id, newLead);
            }
        }
        return mapLead;
    }

    public static Map<Id, Demand_Funnel__c> getDFRMapMQLHandOff(Set<Id> lds) {
        return new Map<Id, Demand_Funnel__c>(
            (List<Demand_Funnel__c>) new DemandFunnelSelector().selectDFRsForMQLHandOff(lds).executeQuery()
        );
    }
    public static String getEstimated12MText(Opportunity opp, Decimal conversionRate) {
        String estimated12MText;
        if (opp.CurrencyIsoCode == 'USD') {
            estimated12MText = opp.Estimated_12M_Total_Pipeline__c != null ? 'USD ' + opp.Estimated_12M_Total_Pipeline__c : null;
        } else {
            estimated12MText = opp.Estimated_12M_Total_Pipeline__c != null ? 
                opp.CurrencyIsoCode + ' ' + opp.Estimated_12M_Total_Pipeline__c + ' (USD ' + NumberHelper.roundCurrency(opp.Estimated_12M_Total_Pipeline__c / ConversionRate, 2) + ')' : 
                null;
        }
        return estimated12MText;
    }

    public static String getAmountText(Opportunity opp, Decimal conversionRate) {
        String amountText;
        if (opp.CurrencyIsoCode == 'USD') { 
            amountText = opp.Amount != null ? 'USD ' + opp?.Amount : null;
        } else {
            amountText = opp.Amount != null ? opp.CurrencyIsoCode + ' ' + opp.Amount + ' (USD ' + NumberHelper.roundCurrency(opp?.Amount / ConversionRate, 2) + ')' : null;
        }
        return amountText;
    }

    public static String getBookingText(Opportunity opp, Decimal conversionRate) {
        String bookingText;
        if (opp.CurrencyIsoCode == 'USD') {
            bookingText = opp.X12_Month_Booking__c != null ? 'USD ' + opp.X12_Month_Booking__c : null;
        } else {
            bookingText = opp.X12_Month_Booking__c != null ? opp.CurrencyIsoCode + ' ' + opp.X12_Month_Booking__c + ' (USD ' + NumberHelper.roundCurrency(opp.X12_Month_Booking__c / ConversionRate, 2) + ')' : null;
        }
        return bookingText;
    }
    

    
    public static Boolean getIsACMActive() {
        Advanced_Currency_Management__mdt acmFlag = Advanced_Currency_Management__mdt.getInstance('is_ACM_Enabled');
        return acmFlag != null ? acmFlag.Enabled__c : false;
    }
    
    public static List<Demand_Funnel__c> DFRPipelineRecalculation(List<Demand_Funnel__c> dfrsToProcess, List<Opportunity> oppsToProcess) {
        Boolean isACMEnabled = getIsACMActive();
        Map<Id, List<Demand_Funnel__c>> dfrsByOppId = groupDFRsByOpportunity(dfrsToProcess);
        Map<String, Date> dateRange = getDateRange(oppsToProcess);
        List<DatedConversionRate> datedConversionRates = fetchDatedConversionRates(dateRange);
        Map<String, Decimal> currencyTypeRates = fetchCurrencyTypeRatesIfNeeded(datedConversionRates, isACMEnabled);

        Map<Id, Decimal> conversionRatesByOppId = mapConversionRatesToOpportunities(
            oppsToProcess, 
            datedConversionRates, 
            currencyTypeRates,
            isACMEnabled
        );
        return recalculateDFRs(oppsToProcess, dfrsByOppId, conversionRatesByOppId);
    }

    private static Map<String, Decimal> fetchCurrencyTypeRatesIfNeeded(List<DatedConversionRate> datedConversionRates, Boolean isACMEnabled) {
        if (isACMEnabled) {
            return new Map<String, Decimal>();
        }
        return fetchCurrencyTypeRates();
    }
    
    private static Map<String, Decimal> fetchCurrencyTypeRates() {
        List<CurrencyType> currencyTypes = (List<CurrencyType>) new CurrencyTypeSelector()
        .selectActiveCurrencyTypes()
        .executeQuery();

        Map<String, Decimal> conversionRates = new Map<String, Decimal>();
        
        for (CurrencyType currencyType : currencyTypes) {
            conversionRates.put(currencyType.IsoCode, currencyType.ConversionRate);
        }
        
        return conversionRates; 
    }
    
    private static List<DatedConversionRate> fetchDatedConversionRates(Map<String, Date> dateRange) {
        return new DatedConversionRateSelector().selectConversionRateByDate(dateRange.get('minDate'), dateRange.get('maxDate')).executeQuery();
    }

    private static Map<Id, Decimal> mapConversionRatesToOpportunities(
        List<Opportunity> opportunities, 
        List<DatedConversionRate> datedConversionRates, 
        Map<String, Decimal> currencyTypeRates,
        Boolean isACMEnabled) {
        
        Map<Id, Decimal> conversionRatesByOppId = new Map<Id, Decimal>();
        for (Opportunity opportunity : opportunities) {
            Decimal conversionRate = findConversionRateForOpportunity(
                opportunity, 
                datedConversionRates, 
                currencyTypeRates,
                isACMEnabled
            );
            conversionRatesByOppId.put(opportunity.Id, conversionRate);
        }

        return conversionRatesByOppId;
    }

     private static Decimal findConversionRateForOpportunity(
        Opportunity opportunity, 
        List<DatedConversionRate> datedConversionRates, 
        Map<String, Decimal> currencyTypeRates,
        Boolean isACMEnabled) {
        
        if (isACMEnabled) {
            return findDatedConversionRateForOpportunity(opportunity, datedConversionRates);
        } else {
            return findCurrencyTypeRateForOpportunity(opportunity, currencyTypeRates);
        }
    }

    private static Decimal findDatedConversionRateForOpportunity(
        Opportunity opportunity, 
        List<DatedConversionRate> datedConversionRates) {
        
        for (DatedConversionRate datedRate : datedConversionRates) {
            if (datedRate.IsoCode == opportunity.CurrencyIsoCode 
                && datedRate.StartDate <= opportunity.CloseDate 
                && datedRate.NextStartDate > opportunity.CloseDate) {
                return datedRate.ConversionRate;
            }
        }

        // Default rate USD if not found
        return 1.0;
    }

    private static Decimal findCurrencyTypeRateForOpportunity(
        Opportunity opportunity, 
        Map<String, Decimal> currencyTypeRates) {
        
        Decimal conversionRate = currencyTypeRates.get(opportunity.CurrencyIsoCode);

        // Default rate USD if not found
        return conversionRate != null ? conversionRate : 1.0;
    }
    
    private static Map<Id, List<Demand_Funnel__c>> groupDFRsByOpportunity(List<Demand_Funnel__c> dfrsToProcess) {
        Map<Id, List<Demand_Funnel__c>> dfrsByOppId = new Map<Id, List<Demand_Funnel__c>>();
        for (Demand_Funnel__c dfr : dfrsToProcess) {
            if (dfr.DFR_Active_Status__c == ACTIVE_STATUS || dfr.EOL_DateTime_Entered__c == null) {
                if (!dfrsByOppId.containsKey(dfr.Opportunity__c)) {
                    dfrsByOppId.put(dfr.Opportunity__c, new List<Demand_Funnel__c>());
                }
                dfrsByOppId.get(dfr.Opportunity__c).add(dfr);
            }
        }
        return dfrsByOppId;
    }
    
    private static Map<String, Date> getDateRange(List<Opportunity> oppsToProcess) {
        Date minDate;
        Date maxDate;
        if (oppsToProcess != null && !oppsToProcess.isEmpty()) {
            minDate = oppsToProcess[0].CloseDate;
            maxDate = oppsToProcess[0].CloseDate;
        } else {
            minDate = Date.today();
            maxDate = Date.today();
        }
        
        for (Opportunity opp : oppsToProcess) {
            minDate = opp.CloseDate < minDate ? opp.CloseDate : minDate;
            maxDate = opp.CloseDate > maxDate ? opp.CloseDate : maxDate;
        }
        return new Map<String, Date>{'minDate' => minDate, 'maxDate' => maxDate};
    }
    
    private static List<Demand_Funnel__c> recalculateDFRs(List<Opportunity> oppsToProcess, Map<Id, List<Demand_Funnel__c>> dfrsByOppId, Map<Id, Decimal> conversionRatesByOppId) {
        List<Demand_Funnel__c> dfrsRecalculated = new List<Demand_Funnel__c>();
        for (Opportunity opp : oppsToProcess) {
            Decimal conversionRate = conversionRatesByOppId.get(opp.Id);
            List<Demand_Funnel__c> dfrsForOpp = dfrsByOppId.get(opp.Id);
            if (dfrsForOpp != null && !dfrsForOpp.isEmpty()) {
                String estimated12MText = getEstimated12MText(opp, conversionRate);
                String amountText = getAmountText(opp, conversionRate);
                String bookingText = getBookingText(opp, conversionRate);
                for (Demand_Funnel__c dfr : dfrsForOpp) {
                    dfr.Opportunity_Currency__c = opp.CurrencyIsoCode;
                    dfr.Opportunity_Exchange_Rate__c = conversionRate;
                    dfr.Estimated_12M_Total_Pipeline_OC__c = opp.Estimated_12M_Total_Pipeline__c;
                    dfr.Estimated_12M_Total_Pipeline_DC__c = opp.Estimated_12M_Total_Pipeline__c != null ? NumberHelper.roundCurrency(opp.Estimated_12M_Total_Pipeline__c / conversionRate, 2) : null;
                    dfr.Estimated_12M_Total_Pipeline_TC__c = estimated12MText;
                    dfr.CLS_Amount_OC__c = opp.Amount;
                    dfr.CLS_Amount_DC__c = opp.Amount != null ? NumberHelper.roundCurrency(opp.Amount / conversionRate, 2) : null;
                    dfr.CLS_Amount_TC__c = amountText;
                    dfr.Opportunity_Estimated_12M_Booking_OC__c = opp.X12_Month_Booking__c;
                    dfr.Opportunity_Estimated_12M_Booking_DC__c = opp.X12_Month_Booking__c != null ? NumberHelper.roundCurrency(opp.X12_Month_Booking__c / conversionRate, 2) : null;
                    dfr.Opportunity_Estimated_12M_Booking_TC__c = bookingText;
                    dfrsRecalculated.add(dfr);
                }
            }
        }
        return dfrsRecalculated;
    }

    public static List<Opportunity> checkOpportunitiesForPipelineRecalculation(Map<Id, Opportunity> oldMap, List<Opportunity> oppList) {
        List<Opportunity> oppsToProcess = new List<Opportunity>();
    
        for (Opportunity opp : oppList) {
            if (opp.Estimated_12M_Total_Pipeline__c != oldMap.get(opp.Id).Estimated_12M_Total_Pipeline__c ||
                opp.CloseDate != oldMap.get(opp.Id).CloseDate ||
                opp.CurrencyIsoCode != oldMap.get(opp.Id).CurrencyIsoCode ||
                opp.Amount != oldMap.get(opp.Id).Amount ||
                opp.X12_Month_Booking__c != oldMap.get(opp.Id).X12_Month_Booking__c) {
                oppsToProcess.add(opp);
            }
        }
    
        return oppsToProcess;
    }
}
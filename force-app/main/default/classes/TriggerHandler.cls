public class TriggerHandler {

    //----------------ESB porting-----------------------------
    public static Boolean ESB_START = true;
    //--------------------------------------------------------
	public static Boolean BY_PASS_BEFORE = false;
    public static Boolean BY_PASS_AFTER = false;
    
    public static Boolean IsByPassedValidaionOnOppty = false; // New Line Case #03793086
    
    //----------------As/simplion/2/25/2015 start-----------------------------
    public static Boolean BY_PASS_ACCOUNT_ON_AFTER = false;
    public static Boolean BY_PASS_ACCOUNT_ON_BEFORE = false;
    public static Boolean BY_PASS_IMPLEMENTATION_ON_AFTER = false;
    public static Boolean BY_PASS_IMPLEMENTATION_ON_BEFORE = false;
    public static Boolean BY_PASS_EVENT_ON_BEFORE = false;
    public static Boolean BY_PASS_EVENT_ON_AFTER = false;
    public static Boolean BY_PASS_PARTNER_ACCOUNT_ON_AFTER = false;
    public static Boolean BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = false;
    public static Boolean BY_PASS_CONTACT_ON_AFTER = false;
    public static Boolean BY_PASS_CONTACT_ON_BEFORE = false;
	
	//----------------As/simplion/2/25/2015 end-----------------------------
    
	public static Boolean BY_PASS_ACCOUNT_ON_UPDATE = false;
	public static Boolean BY_PASS_ACCOUNT_ON_INSERT = false;

	public static Boolean BY_PASS_CONTACT_ON_UPDATE = false;
	public static Boolean BY_PASS_CONTACT_ON_INSERT = false;

	public static Boolean BY_PASS_OPPORTUNITY_ON_UPDATE = false;
	public static Boolean BY_PASS_OPPORTUNITY_ON_INSERT = false;

    public static Boolean BY_PASS_QUOTE_ON_UPDATE = false;
	public static Boolean BY_PASS_QUOTE_ON_INSERT = false;
    
    public static Boolean BY_PASS_OPPORTUNITY_ON_CONVERT = false;
    public static Boolean BY_PASS_QUOTE_ON_CONVERT = false;

	public static Boolean BY_PASS_CASE_ON_UPDATE = false;
	public static Boolean BY_PASS_CASE_ON_INSERT = false;

	public static Boolean BY_PASS_LINEITEM_ON_UPDATE = false;
	public static Boolean BY_PASS_LINEITEM_ON_INSERT = false;

	public static Boolean BY_PASS_RCQUOTE_ON_UPDATE = false;
	public static Boolean BY_PASS_RCQUOTE_ON_INSERT = false;

	public static Boolean BY_PASS_Approver_Trigger = false; 
	private static boolean ALLOW_TRIGGER_REQUEST_ONCE = true;

	public static Boolean BY_PASS_CARRIERDATA_ON_INSERT = false;
	public static Boolean BY_PASS_CARRIERDATA_ON_UPDATE = false;

	public static Boolean BY_PASS_CASE_Trigger = false;

	public static Boolean UPDATE_CONTACT_BMID = false;

	public static Boolean BY_PASS_LEAD_UPDATE = false;

	public static Boolean BY_PASS_CASECOMMENT_ON_UPDATE = false;
	public static Boolean BY_PASS_CASECOMMENT_ON_INSERT = false;

    public static Boolean BY_PASS_CAMPAIGNMEMBER_TRIGGER_CAMPAIGNATTRIBUTION = false;
    public static Boolean BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = false;
    public static Boolean BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = false;
    
	public static Boolean BY_PASS_PARTNERCOMM_ON_UPDATE = false;
	public static Boolean BY_PASS_PARTNERCOMM_ON_INSERT = false;

	/* Setting Bypass flag for Event Trigger. */
	public static Boolean BY_PASS_EVENT_ON_INSERT = false;
	public static Boolean BY_PASS_EVENT_ON_UPDATE =  false;

	public static Boolean BY_PASS_TOTAL_ESTIMATE_CALCULATION = false;

	//For Account Hierarchy Total DLS Field updation. Used to store the Ids of the related accounts of the account which is being deleted.
	public static Set<String> RELATED_ACCOUNT_ID_SET = new Set<String>();

	public static Boolean HIDE_VALIDATION_ERROR_ON_IMPLEMENTATION = false;
	public static void HIDE_VALIDATION_ERROR_ON_IMPLEMENTATION() {
		HIDE_VALIDATION_ERROR_ON_IMPLEMENTATION = true;
	}

	public static void BY_PASS_CARRIERDATA_ON_INSERT(){
		BY_PASS_CARRIERDATA_ON_INSERT = true;
	}
	public static void BY_PASS_CARRIERDATA_ON_UPDATE(){
		BY_PASS_CARRIERDATA_ON_UPDATE = true;
	}
	public static void BY_PASS_ACCOUNT_ON_UPDATE() {
		BY_PASS_ACCOUNT_ON_UPDATE = true;
	}
	public static void BY_PASS_ACCOUNT_ON_INSERT() {
		BY_PASS_ACCOUNT_ON_INSERT = true;
	}

	public static void BY_PASS_CONTACT_ON_UPDATE() {
		BY_PASS_CONTACT_ON_UPDATE = true;
	}
	public static void BY_PASS_CONTACT_ON_INSERT() {
		BY_PASS_CONTACT_ON_INSERT = true;
	}

	public static Boolean BY_PASS_LEAD_UPDATE_ON_INSERT = false;

	public static void BY_PASS_LEAD_UPDATE_ON_INSERT() {
		BY_PASS_LEAD_UPDATE_ON_INSERT = true;
	}

	public static void BY_PASS_OPPORTUNITY_ON_UPDATE() {
		BY_PASS_OPPORTUNITY_ON_UPDATE = true;
	}
	public static void BY_PASS_OPPORTUNITY_ON_INSERT() {
		BY_PASS_OPPORTUNITY_ON_INSERT = true;
	}
   public static void BY_PASS_OPPORTUNITY_ON_CONVERT(){
        BY_PASS_OPPORTUNITY_ON_CONVERT = true;
    }
    public static void BY_PASS_QUOTE_ON_CONVERT(){
        BY_PASS_QUOTE_ON_CONVERT = true;
    }
	public static void BY_PASS_CASE_ON_UPDATE() {
		BY_PASS_CASE_ON_UPDATE = true;
	}
	public static void BY_PASS_CASE_ON_INSERT() {
		BY_PASS_CASE_ON_INSERT = true;
	}
	public static void BY_PASS_LINEITEM_ON_UPDATE() {
		BY_PASS_LINEITEM_ON_UPDATE = true;
	}
	public static void BY_PASS_LINEITEM_ON_INSERT() {
		BY_PASS_LINEITEM_ON_INSERT = true;
	}
	public static void BY_PASS_RCQUOTE_ON_UPDATE() {
		BY_PASS_RCQUOTE_ON_UPDATE = true;
	}
	public static void BY_PASS_RCQUOTE_ON_INSERT() {
		BY_PASS_RCQUOTE_ON_INSERT = true;
	}
	public static void BY_PASS_EVENT_ON_INSERT() {
		BY_PASS_EVENT_ON_INSERT = true;
	}
	public static void BY_PASS_EVENT_ON_UPDATE() {
		BY_PASS_EVENT_ON_UPDATE = true;
	}
	public static void BY_PASS_CASECOMMENT_ON_UPDATE() {
		BY_PASS_CASECOMMENT_ON_UPDATE = true;
	}
	public static void BY_PASS_CASECOMMENT_ON_INSERT() {
		BY_PASS_CASECOMMENT_ON_INSERT = true;
	}
	public static void BY_PASS_PARTNERCOMM_ON_UPDATE() {
		BY_PASS_PARTNERCOMM_ON_UPDATE = true;
	}
	public static void BY_PASS_PARTNERCOMM_ON_INSERT() {
		BY_PASS_PARTNERCOMM_ON_INSERT = true;
	}
	public static void RESET_VARIABLES() {
		BY_PASS_ACCOUNT_ON_UPDATE = false;
		BY_PASS_ACCOUNT_ON_INSERT = false;

		BY_PASS_CONTACT_ON_UPDATE = false;
		BY_PASS_CONTACT_ON_INSERT = false;

		BY_PASS_OPPORTUNITY_ON_UPDATE = false;
		BY_PASS_OPPORTUNITY_ON_INSERT = false;
        
        BY_PASS_OPPORTUNITY_ON_CONVERT = false;
        BY_PASS_QUOTE_ON_CONVERT = false;

		BY_PASS_CASE_ON_UPDATE = false;
		BY_PASS_CASE_ON_INSERT = false;

		BY_PASS_LEAD_UPDATE_ON_INSERT = false;

		BY_PASS_LINEITEM_ON_UPDATE = false;
		BY_PASS_LINEITEM_ON_INSERT = false;

		BY_PASS_RCQUOTE_ON_UPDATE = false;
		BY_PASS_RCQUOTE_ON_INSERT = false;

		BY_PASS_CASECOMMENT_ON_UPDATE = false;
		BY_PASS_CASECOMMENT_ON_UPDATE = false;
	}
	public static Boolean ALLOW_TRIGGER_REQUEST_ONCE() {
		if(ALLOW_TRIGGER_REQUEST_ONCE) {
			ALLOW_TRIGGER_REQUEST_ONCE = false;
			return true;
		}
		return ALLOW_TRIGGER_REQUEST_ONCE;
	}


	public static Boolean BY_PASS_UPDATE_ACCOUNT_ACTIVE_DATE = false;
	public static Boolean BY_PASS_SEND_EMAILS = false;
	public static Boolean BY_PASS_SURVEY = false;
	public static Boolean BY_PASS_PARTNER_ACCOUNTS = false;
	public static Boolean BY_PASS_UP_LIST_ACCOUNT = false;
	public static Boolean BY_PASS_IMPLEMENTATION_LEADS = false;
	public static Boolean BY_PASS_DEINITALIZE = false;
	public static Boolean BY_PASS_TOGGLE_NUMBER_PORTING = false;

	public static Boolean CHECK_DUPLICATE = false;
	public static Boolean UPDATE_EMAIL = false;   
	public static Boolean DUPLICATE_CONTACT = false; 

	public static Boolean UPDATE_ACCOUNT_INFORMATION = false;
	public static Boolean ACCOUNT_SHARING_ON_INSERT =false;
	public static Boolean ACCOUNT_SHARING_ON_UPDATE0 = false;
	public static Boolean ACCOUNT_SHARING_ON_UPDATE2 = false;
	public static Boolean UPDATE_PARTNER_CODE_ON_INSERT_AND_UPDATE = false;

    public static void bypassTrigger(List<String> bypassVarNames, Boolean bypass) {
        if (bypassVarNames != null && bypass != null) {
            for (String bypassVarName : bypassVarNames) {
                bypassTrigger(bypassVarName, bypass);
            }
        }
    }

    public static void bypassTrigger(String bypassVarName, Boolean bypass) {
        if (String.isBlank(bypassVarName) || bypass == null) {
            return;
        }

        switch on bypassVarName {
            when 'BY_PASS_BEFORE' {
                TriggerHandler.BY_PASS_BEFORE = bypass;
            }
            when 'BY_PASS_AFTER' {
                TriggerHandler.BY_PASS_AFTER = bypass;
            }
            when 'BY_PASS_ACCOUNT_ON_AFTER' {
                TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = bypass;
            }
            when 'BY_PASS_ACCOUNT_ON_BEFORE' {
                TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = bypass;
            }
            when 'BY_PASS_IMPLEMENTATION_ON_AFTER' {
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_AFTER = bypass;
            }
            when 'BY_PASS_IMPLEMENTATION_ON_BEFORE' {
                TriggerHandler.BY_PASS_IMPLEMENTATION_ON_BEFORE = bypass;
            }
            when 'BY_PASS_EVENT_ON_BEFORE' {
                TriggerHandler.BY_PASS_EVENT_ON_BEFORE = bypass;
            }
            when 'BY_PASS_EVENT_ON_AFTER' {
                TriggerHandler.BY_PASS_EVENT_ON_AFTER = bypass;
            }
            when 'BY_PASS_PARTNER_ACCOUNT_ON_AFTER' {
                TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_AFTER = bypass;
            }
            when 'BY_PASS_PARTNER_ACCOUNT_ON_BEFORE' {
                TriggerHandler.BY_PASS_PARTNER_ACCOUNT_ON_BEFORE = bypass;
            }
            when 'BY_PASS_CONTACT_ON_AFTER' {
                TriggerHandler.BY_PASS_CONTACT_ON_AFTER = bypass;
            }
            when 'BY_PASS_CONTACT_ON_BEFORE' {
                TriggerHandler.BY_PASS_CONTACT_ON_BEFORE = bypass;
            }
            when 'BY_PASS_ACCOUNT_ON_UPDATE' {
                TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = bypass;
            }
            when 'BY_PASS_ACCOUNT_ON_INSERT' {
                TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = bypass;
            }
            when 'BY_PASS_CONTACT_ON_UPDATE' {
                TriggerHandler.BY_PASS_CONTACT_ON_UPDATE = bypass;
            }
            when 'BY_PASS_CONTACT_ON_INSERT' {
                TriggerHandler.BY_PASS_CONTACT_ON_INSERT = bypass;
            }
            when 'BY_PASS_OPPORTUNITY_ON_UPDATE' {
                TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = bypass;
            }
            when 'BY_PASS_OPPORTUNITY_ON_INSERT' {
                TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = bypass;
            }
            when 'BY_PASS_OPPORTUNITY_ON_CONVERT' {
                TriggerHandler.BY_PASS_OPPORTUNITY_ON_CONVERT = bypass;
            }
            when 'BY_PASS_QUOTE_ON_CONVERT' {
                TriggerHandler.BY_PASS_QUOTE_ON_CONVERT = bypass;
            }
            when 'BY_PASS_CASE_ON_UPDATE' {
                TriggerHandler.BY_PASS_CASE_ON_UPDATE = bypass;
            }
            when 'BY_PASS_CASE_ON_INSERT' {
                TriggerHandler.BY_PASS_CASE_ON_INSERT = bypass;
            }
            when 'BY_PASS_LINEITEM_ON_UPDATE' {
                TriggerHandler.BY_PASS_LINEITEM_ON_UPDATE = bypass;
            }
            when 'BY_PASS_LINEITEM_ON_INSERT' {
                TriggerHandler.BY_PASS_LINEITEM_ON_INSERT = bypass;
            }
            when 'BY_PASS_RCQUOTE_ON_UPDATE' {
                TriggerHandler.BY_PASS_RCQUOTE_ON_UPDATE = bypass;
            }
            when 'BY_PASS_RCQUOTE_ON_INSERT' {
                TriggerHandler.BY_PASS_RCQUOTE_ON_INSERT = bypass;
            }
            when 'BY_PASS_Approver_Trigger' {
                TriggerHandler.BY_PASS_Approver_Trigger = bypass;
            }
            when 'ALLOW_TRIGGER_REQUEST_ONCE' {
                TriggerHandler.ALLOW_TRIGGER_REQUEST_ONCE = bypass;
            }
            when 'BY_PASS_CARRIERDATA_ON_INSERT' {
                TriggerHandler.BY_PASS_CARRIERDATA_ON_INSERT = bypass;
            }
            when 'BY_PASS_CARRIERDATA_ON_UPDATE' {
                TriggerHandler.BY_PASS_CARRIERDATA_ON_UPDATE = bypass;
            }
            when 'BY_PASS_CASE_Trigger' {
                TriggerHandler.BY_PASS_CASE_Trigger = bypass;
            }
            when 'UPDATE_CONTACT_BMID' {
                TriggerHandler.UPDATE_CONTACT_BMID = bypass;
            }
            when 'BY_PASS_LEAD_UPDATE' {
                TriggerHandler.BY_PASS_LEAD_UPDATE = bypass;
            }
            when 'BY_PASS_CASECOMMENT_ON_UPDATE' {
                TriggerHandler.BY_PASS_CASECOMMENT_ON_UPDATE = bypass;
            }
            when 'BY_PASS_CASECOMMENT_ON_INSERT' {
                TriggerHandler.BY_PASS_CASECOMMENT_ON_INSERT = bypass;
            }
            when 'BY_PASS_PARTNERCOMM_ON_UPDATE' {
                TriggerHandler.BY_PASS_PARTNERCOMM_ON_UPDATE = bypass;
            }
            when 'BY_PASS_PARTNERCOMM_ON_INSERT' {
                TriggerHandler.BY_PASS_PARTNERCOMM_ON_INSERT = bypass;
            }
            when 'BY_PASS_EVENT_ON_INSERT' {
                TriggerHandler.BY_PASS_EVENT_ON_INSERT = bypass;
            }
            when 'BY_PASS_EVENT_ON_UPDATE' {
                TriggerHandler.BY_PASS_EVENT_ON_UPDATE = bypass;
            }
            when 'BY_PASS_TOTAL_ESTIMATE_CALCULATION' {
                TriggerHandler.BY_PASS_TOTAL_ESTIMATE_CALCULATION = bypass;
            }
        }
    }
}
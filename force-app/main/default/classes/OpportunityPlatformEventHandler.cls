public with sharing class OpportunityPlatformEventHandler {

    public static final String BRAND_ATTOFFICE = 'AT&T Office@Hand';
	public static final String BRAND_RCVERIZON = 'RingCentral with Verizon';
    public static final String BRAND_BIZDUMMY = 'Biz Dummy';
    public static final String OPPORTUNITY_UPDATE_EVENT_TYPE = 'OpportunityUpdated';
    public static final String OPPORTUNITY_CREATE_EVENT_TYPE = 'OpportunityCreated';
    public static final String OPPORTUNITY_ORIGINATED_FROM = 'Flow';

    public static void triggerOpportunityCreatePlatformEvent(List<Opportunity> newOpptyList) {
        List<OpportunityCreated__e> opptyCreateEventList = new List<OpportunityCreated__e>();
        for(Opportunity oppObj : newOpptyList) {
        	if(oppObj.Id != null && !isExcludedBrand(oppObj)) {
                OpportunityCreated__e opptyEvt = getOpportunityCreatePlatformEvent(oppObj);
                opptyCreateEventList.add(opptyEvt);
            }
        }
        if(opptyCreateEventList.size() > 0) {
            publishOpportunityEvent(opptyCreateEventList, new List<OpportunityUpdated__e>());
        }
    }

    public static void triggerOpportunityUpdatePlatformEvent(List<Opportunity> newOppList, Map<Id,Opportunity> oldOppMap) {
        List<OpportunityUpdated__e> opptyUpdateEventList = new List<OpportunityUpdated__e>();
        List<String> fieldsToBeTracked = getOpportunityFieldNames();
        for(Opportunity oppObj : newOppList) {
        	if(isAnyFieldUpdated(oppObj , oldOppMap.get(oppObj.Id),fieldsToBeTracked) && !isExcludedBrand(oppObj)) {
            	OpportunityUpdated__e oppEvent = getOpportunityUpdatePlatformEvent(oppObj);
                if(oppEvent != null) {
                    opptyUpdateEventList.add(oppEvent);
                }
            }
        }
        if(opptyUpdateEventList.size() > 0) {
            publishOpportunityEvent(new List<OpportunityCreated__e>(), opptyUpdateEventList);
        }
    }

    private static boolean isExcludedBrand(Opportunity opp) {
        if(opp?.Brand_Name__c == BRAND_ATTOFFICE
          || opp?.Brand_Name__c == BRAND_RCVERIZON
          || opp?.Brand_Name__c == BRAND_BIZDUMMY) {
            return true;
        }
        return false;
    }

    private static List<String> getOpportunityFieldNames() {
        List<String> avisoFieldAPINames = new List<String>();
        for (AvisoOpportunitySetup__mdt fieldAPIRow : [SELECT OppFieldAPINames__c FROM AvisoOpportunitySetup__mdt]) {
            avisoFieldAPINames.addAll(fieldAPIRow.OppFieldAPINames__c.split(','));
        }
        return avisoFieldAPINames;
    }

    private static boolean isAnyFieldUpdated(Opportunity oldOpp, Opportunity newOpp, List<String> fieldAPINames) {
		for(String fieldName:fieldAPINames) {
			if(newOpp.get(fieldName) != oldOpp.get(fieldName)) {
				return true;
			}
		}
		return false;
	}

    private static OpportunityUpdated__e getOpportunityUpdatePlatformEvent(Opportunity opp) {
        OpportunityUpdated__e oppUpdated = null;

        if(opp.Id != null) {
            oppUpdated = new OpportunityUpdated__e();
        	oppUpdated.ID__c = opp.ID;
        	oppUpdated.eventType__c = OPPORTUNITY_UPDATE_EVENT_TYPE;
        	oppUpdated.originatedFrom__c = OPPORTUNITY_ORIGINATED_FROM;
        	oppUpdated.IsDeleted__c = opp.IsDeleted;
        	oppUpdated.AccountId__c = opp.AccountId;
        	oppUpdated.RecordTypeId__c = opp.RecordTypeId;
        	oppUpdated.Name__c = opp.Name;
        	oppUpdated.Description__c = opp.Description;
        	oppUpdated.StageName__c = opp.StageName;
        	oppUpdated.Amount__c = String.valueOf(opp.Amount);
        	oppUpdated.Probability__c = String.valueOf(opp.Probability);
        	oppUpdated.CloseDate__c = opp.CloseDate;
        	oppUpdated.Type__c = opp.Type;
        	oppUpdated.LeadSource__c = opp.LeadSource;
        	oppUpdated.ForecastCategory__c = opp.ForecastCategory;
        	oppUpdated.ForecastCategoryName__c = opp.ForecastCategoryName;
        	oppUpdated.CurrencyIsoCode__c = opp.CurrencyIsoCode;
        	oppUpdated.HasOpportunityLineItem__c = opp.HasOpportunityLineItem;
        	oppUpdated.OwnerId__c = opp.OwnerId;
        	oppUpdated.CreatedDate__c = opp.CreatedDate;
        	oppUpdated.CreatedById__c = opp.CreatedById;
        	oppUpdated.Implementation_Status__c = opp.Implementation_Status__c;
        	oppUpdated.Brand_Name__c = opp.Brand_Name__c;
        	oppUpdated.Tier_Name__c = opp.Tier_Name__c;
        	oppUpdated.Activated_Billed__c = opp.Activated_Billed__c;
        	oppUpdated.Assisted_Setup__c = opp.Assisted_Setup__c;
        	oppUpdated.Download_Softphone__c = opp.Download_Softphone__c;
        	oppUpdated.Trial_Account__c = opp.Trial_Account__c;
        	oppUpdated.PID__c = opp.PID__c;
        	oppUpdated.Promotion__c = opp.Promotion__c;
        	oppUpdated.RC_Account_Status__c = opp.RC_Account_Status__c;
        	oppUpdated.Downgrade_Date_Opp__c = opp.Downgrade_Date_Opp__c;
        	oppUpdated.Downgrade_Reason_Opp__c = opp.Downgrade_Reason_Opp__c;
        	oppUpdated.Number_of_Employees__c = opp.Number_of_Employees__c;
        	oppUpdated.Sales_Model__c = opp.Sales_Model__c;
        	oppUpdated.Lead_Score__c = opp.Lead_Score__c;
        	oppUpdated.Probability_Stage__c = opp.Probability_Stage__c;
        	oppUpdated.AccountMRR__c = String.valueOf(opp.AccountMRR__c);
        	oppUpdated.Account_DLS__c = String.valueOf(opp.Account_DLS__c);
        	oppUpdated.Intended_Product__c = opp.Intended_Product__c;
        	oppUpdated.Primary_Competitor__c = opp.Primary_Competitor__c;
        	oppUpdated.Primary_Loss_Reason__c = opp.Primary_Loss_Reason__c;
        	oppUpdated.Service_Lost__c = opp.Service_Lost__c;
        	oppUpdated.Loss_Comments__c = opp.Loss_Comments__c;
        	oppUpdated.Term__c = String.valueOf(opp.Term__c);
        	oppUpdated.Proposal_Expiration_Date__c = opp.Proposal_Expiration_Date__c;
        	oppUpdated.Cancellation__c = opp.Cancellation__c;
        	oppUpdated.Describe_Reason_for_Cancellation__c = opp.Describe_Reason_for_Cancellation__c;
        	oppUpdated.Appeasement_Offered__c = opp.Appeasement_Offered__c;
        	oppUpdated.Reason__c = opp.Reason__c;
        	oppUpdated.Tier__c = opp.Tier__c;
        	oppUpdated.Sub_Stage__c = opp.Sub_Stage__c;
        	oppUpdated.HasActiveAgreement__c = String.valueOf(opp.HasActiveAgreement__c);
        	oppUpdated.Partner_ID__c = opp.Partner_ID__c;
        	oppUpdated.Is_Premium_Implementation_Required__c = opp.Is_Premium_Implementation_Required__c;
        	oppUpdated.Incentive__c = opp.Incentive__c;
        	oppUpdated.Forecasted_Users__c = String.valueOf(opp.Forecasted_Users__c);
        	oppUpdated.Couldn_t_get_it_working_details__c = opp.Couldn_t_get_it_working_details__c;
        	oppUpdated.Missing_feature_details__c = opp.Missing_feature_details__c;
        	oppUpdated.What_s_changing__c = opp.What_s_changing__c;
        	oppUpdated.What_will_cx_use_for_their_phone_system__c = opp.What_will_cx_use_for_their_phone_system__c;
        	oppUpdated.Why_is_cx_downselling__c = opp.Why_is_cx_downselling__c;
	        oppUpdated.RingCentral_Consolidating_Account__c = opp.RingCentral_Consolidating_Account__c;
        	oppUpdated.Sub_Downgrade_Reason__c = opp.Sub_Downgrade_Reason__c;
        	oppUpdated.RC_Product_Gaps_Features__c = opp.RC_Product_Gaps_Features__c;
        	oppUpdated.Customer_Limitations__c = opp.Customer_Limitations__c;
        	oppUpdated.Downgrade_Reason_Other__c = opp.Downgrade_Reason_Other__c;
        	oppUpdated.Competitor_Contract_End_Date__c = opp.Competitor_Contract_End_Date__c;
        	oppUpdated.Product_Gap_Feature_Other__c = opp.Product_Gap_Feature_Other__c;
        	oppUpdated.Other_Reason_for_Loss__c = opp.Other_Reason_for_Loss__c;
        	oppUpdated.Cancellation_Reason__c = opp.Cancellation_Reason__c;
        	oppUpdated.Brand_Cancel__c = opp.Brand_Cancel__c;
        	oppUpdated.Tier_Cancel__c = opp.Tier_Cancel__c;
        	oppUpdated.Service_Cancel__c = opp.Service_Cancel__c;
        	oppUpdated.RC_User_ID_Cancel__c = opp.RC_User_ID_Cancel__c;
        	oppUpdated.Transferred_by_AT_T_Care__c = opp.Transferred_by_AT_T_Care__c;
        	oppUpdated.Ported_In_Number_s__c = opp.Ported_In_Number_s__c;
        	oppUpdated.Implemented__c = opp.Implemented__c;
        	oppUpdated.Partner_Owner__c = opp.Partner_Owner__c;
        	oppUpdated.Marketo_Duplicate_Lead__c = opp.Marketo_Duplicate_Lead__c;
        	oppUpdated.Test_Account__c = opp.Test_Account__c;
        	oppUpdated.Number_of_RC_Office_Users__c = String.valueOf(opp.Number_of_RC_Office_Users__c);
        	oppUpdated.Opportunity_Owner_IsActive__c = opp.Opportunity_Owner_IsActive__c;
        	oppUpdated.Opportunity_Owner_Division__c = opp.Opportunity_Owner_Division__c;
        	oppUpdated.Lead_Entry_Source__c = opp.Lead_Entry_Source__c;
        	oppUpdated.Partner_Owner_Assignment_Date__c = opp.Partner_Owner_Assignment_Date__c;
        	oppUpdated.Partner_Lead_Source__c = opp.Partner_Lead_Source__c;
        	oppUpdated.Timeframe_greater_than_X_months__c = opp.Timeframe_greater_than_X_months__c;
        	oppUpdated.Sub_Downgrade_Reason_Other__c = opp.Sub_Downgrade_Reason_Other__c;
        	oppUpdated.Support_Customer_Care__c = opp.Support_Customer_Care__c;
        	oppUpdated.Sales_Expectation__c = opp.Sales_Expectation__c;
        	oppUpdated.New_Account_UID__c = opp.New_Account_UID__c;
        	oppUpdated.Partner_Classification__c = opp.Partner_Classification__c;
        	oppUpdated.Discovery_Next_Steps__c = opp.Discovery_Next_Steps__c;
        	oppUpdated.Discovery_Manager_Notes__c = opp.Discovery_Manager_Notes__c;
        	oppUpdated.Close_Date_Counter__c = String.valueOf(opp.Close_Date_Counter__c);
        	oppUpdated.Total_Potential_Users__c = String.valueOf(opp.Total_Potential_Users__c);
        	oppUpdated.Order__c = opp.Order__c;
        	oppUpdated.Inside_Sales_Rep__c = opp.Inside_Sales_Rep__c;
        	oppUpdated.RC_User_ID__c = opp.RC_User_ID__c;
        	oppUpdated.Partner_Account__c = opp.Partner_Account__c;
        	oppUpdated.CreateDateTime__c = opp.CreateDateTime__c;
        	oppUpdated.Opportunity_Owner_Team__c = opp.Opportunity_Owner_Team__c;
        	oppUpdated.Total_Contract_Value__c = String.valueOf(opp.Total_Contract_Value__c);
        	oppUpdated.EstimatedProfessionalServices12Month__c = String.valueOf(opp.EstimatedProfessionalServices12Month__c);
        	oppUpdated.Total_MRR__c = String.valueOf(opp.Total_MRR__c);
        	oppUpdated.Opportunity_Owner_Segment__c = opp.Opportunity_Owner_Segment__c;
        	oppUpdated.UCaaS_Competitor_s__c = opp.UCaaS_Competitor_s__c;
        	oppUpdated.CC_Competitor_s__c = opp.CC_Competitor_s__c;
        	oppUpdated.Forecast_Contact_Center_Users__c = String.valueOf(opp.Forecast_Contact_Center_Users__c);
        	oppUpdated.Partner_Account_Name__c = opp.Partner_Account_Name__c;
        	oppUpdated.STC_Problems__c = opp.STC_Problems__c;
        	oppUpdated.STC_Impact__c = opp.STC_Impact__c;
        	oppUpdated.STC_Ideal_Situation__c = opp.STC_Ideal_Situation__c;
        	oppUpdated.STC_Benefits__c = opp.STC_Benefits__c;
        	oppUpdated.STC_Decision_Making__c = opp.STC_Decision_Making__c;
        	oppUpdated.STC_Relationship_Building_Extras__c = opp.STC_Relationship_Building_Extras__c;
        	oppUpdated.STC_Current_Situation__c = opp.STC_Current_Situation__c;
        	oppUpdated.UCaaS_Incumbent_s__c = opp.UCaaS_Incumbent_s__c;
        	oppUpdated.CW_Win_Reason_Features__c = opp.CW_Win_Reason_Features__c;
        	oppUpdated.DGW_Downgrade_Reason__c = opp.DGW_Downgrade_Reason__c;
        	oppUpdated.X18_Digit_Id__c = opp.X18_Digit_Id__c;
        	oppUpdated.Mutual_Plan__c = opp.Mutual_Plan__c;
        	oppUpdated.RC_Executive_Alignment__c = opp.RC_Executive_Alignment__c;
        	oppUpdated.Total_ARR__c = String.valueOf(opp.Total_ARR__c);
        	oppUpdated.Estimated_12M_Contact_Center_Pipeline__c = String.valueOf(opp.Estimated_12M_Contact_Center_Pipeline__c);
        	oppUpdated.Estimated_12M_Engagement_Pipeline__c = String.valueOf(opp.Estimated_12M_Engagement_Pipeline__c);
        	oppUpdated.Forecast_Category_Internal__c = opp.Forecast_Category_Internal__c;
        	oppUpdated.Estimated_Hardware__c = String.valueOf(opp.Estimated_Hardware__c);
        	oppUpdated.Estimated_12M_Office_Pipeline__c = String.valueOf(opp.Estimated_12M_Office_Pipeline__c);
       		oppUpdated.Estimated_12M_Global_Office_Pipeline__c = String.valueOf(opp.Estimated_12M_Global_Office_Pipeline__c);
    	    oppUpdated.Estimated_12M_Engage_Voice_Pipeline__c = String.valueOf(opp.Estimated_12M_Engage_Voice_Pipeline__c);
	        oppUpdated.Estimated_12M_RingCentral_Video_Pipeline__c = String.valueOf(opp.Estimated_12M_RingCentral_Video_Pipeline__c);
    	    oppUpdated.Calculated_12M_Total_Pipeline__c = String.valueOf(opp.Calculated_12M_Total_Pipeline__c);
	        oppUpdated.Estimated_One_Time_Pipeline__c = String.valueOf(opp.Estimated_One_Time_Pipeline__c);
        	oppUpdated.Video_Competition__c = opp.Video_Competition__c;
        	oppUpdated.CC_Incumbent_s__c = opp.CC_Incumbent_s__c;
        	oppUpdated.Video_Incumbent__c = opp.Video_Incumbent__c;
        	oppUpdated.Identified_Risks__c = opp.Identified_Risks__c;
        	oppUpdated.KDR__c = opp.KDR__c;
        	oppUpdated.RFP__c = opp.RFP__c;
        	oppUpdated.ROI_TCO_Business_Case__c = opp.ROI_TCO_Business_Case__c;
        	oppUpdated.ProServ_Comments_Notes__c = opp.ProServ_Comments_Notes__c;
        	oppUpdated.Monthly_Cost_of_Delay__c = String.valueOf(opp.Monthly_Cost_of_Delay__c);
        	oppUpdated.Value_Assessment__c = opp.Value_Assessment__c;
        	oppUpdated.Estimated_12M_Total_Pipeline__c = String.valueOf(opp.Estimated_12M_Total_Pipeline__c);
        	oppUpdated.Segment_Name__c = opp.Segment_Name__c;
        	oppUpdated.Reason_for_not_needing_RCV__c = opp.Reason_for_not_needing_RCV__c;
        	oppUpdated.Forecasted_RingCentral_Video_Users__c = String.valueOf(opp.Forecasted_RingCentral_Video_Users__c);
        	oppUpdated.IsMultiProductTechnicalOpportunity__c = opp.IsMultiProductTechnicalOpportunity__c;
    	    oppUpdated.Deals_Desk_Stage__c = opp.Deals_Desk_Stage__c;
	        oppUpdated.White_Space__c = opp.White_Space__c;
	        oppUpdated.Op_RecordType_Name__c = opp.RecordType.Name;
        	oppUpdated.Op_Account_Name__c = opp.Account.Name;
        	oppUpdated.Op_Account_Industry__c = opp.Account.Industry;
        	oppUpdated.Op_Account_Inside_Sales_Rep__c = opp.Account.Inside_Sales_Rep__c;
        	oppUpdated.Op_Account_Account_Owner_Manager_Email__c = opp.Account.Account_Owner_Manager_Email__c;
        	oppUpdated.Op_Account_OwnerID__c = opp.Account.OwnerID;
        	oppUpdated.Op_Account_SM_Employees__c = String.valueOf(opp.Account.SM_Employees__c);
        	oppUpdated.Op_Account_Parent_Partner_Account__c = opp.Account.Parent_Partner_Account__c;
        	oppUpdated.Op_Account_Partner_Account_Name__c = opp.Account.Partner_Account_Name__c;
        	oppUpdated.Op_Account_Partner_ID__c = opp.Account.Partner_ID__c;
        	oppUpdated.Op_Account_Type_of_Customer_or_Prospect__c = opp.Account.Type_of_Customer_or_Prospect__c;
        	oppUpdated.Op_Account_Ultimate_Partner_Name__c = opp.Account.Ultimate_Partner_Name__c;

            If(opp.CreatedById != null) {
            	oppUpdated.Op_CreatedBy_Name__c = opp.CreatedBy.Name;
        	}
        	If(opp.OwnerId != null) {
	    		oppUpdated.Op_Owner_Department__c = opp.Owner.Department;
			    oppUpdated.Op_Owner_Division__c = opp.Owner.Division;
	    		oppUpdated.Op_Owner_ManagerID__c = opp.Owner.ManagerID;
	    		oppUpdated.Op_Owner_Name__c = opp.Owner.Name;
	    		oppUpdated.Op_Owner_Manager_Name__c = opp.Owner.Manager.Name;
	    		oppUpdated.Op_Owner_UserRole_ID__c = opp.Owner.UserRole.ID;
	    		oppUpdated.Op_Owner_UserRole_Name__c = opp.Owner.UserRole.Name;
    		}
        	if ( opp.Account.Parent_Partner_Account__c != null ) {
			    oppUpdated.Op_Account_Parent_Partner_Account_r_Name__c = opp.Account.Parent_Partner_Account__r.Name;
			}
			if ( opp.Partner_Account__c != null ) {
	    		oppUpdated.Op_Partner_Account_r_Name__c = opp.Partner_Account__r.Name;
			}
			if ( opp.Partner_Owner__c != null ) {
    			oppUpdated.Op_Partner_Owner_r_Name__c = opp.Partner_Owner__r.Name;
			}
			if ( opp.Portal_Cloud_Specialist__c != null ) {
	    		oppUpdated.Op_Portal_Cloud_Specialist_r_Name__c = opp.Portal_Cloud_Specialist__r.Name;
			}
			if ( opp.Strategic_Partner_RC_Owner__c != null ) {
    			oppUpdated.Op_Strategic_Partner_RC_Owner_r_Name__c = opp.Strategic_Partner_RC_Owner__r.Name;
			}
        }
        return oppUpdated;
    }

    private static OpportunityCreated__e getOpportunityCreatePlatformEvent(Opportunity Opp) {
        OpportunityCreated__e oppCreated = new OpportunityCreated__e();
        oppCreated.ID__c = opp.ID;
        oppCreated.eventType__c = OPPORTUNITY_CREATE_EVENT_TYPE;
        oppCreated.originatedFrom__c = OPPORTUNITY_ORIGINATED_FROM;
        oppCreated.IsDeleted__c = opp.IsDeleted;
        oppCreated.AccountId__c = opp.AccountId;
        oppCreated.RecordTypeId__c = opp.RecordTypeId;
        oppCreated.Name__c = opp.Name;
        oppCreated.Description__c = opp.Description;
        oppCreated.StageName__c = opp.StageName;
        oppCreated.Amount__c = String.valueOf(opp.Amount);
        oppCreated.Probability__c = String.valueOf(opp.Probability);
        oppCreated.CloseDate__c = opp.CloseDate;
        oppCreated.Type__c = opp.Type;
        oppCreated.LeadSource__c = opp.LeadSource;
        oppCreated.ForecastCategory__c = opp.ForecastCategory;
        oppCreated.ForecastCategoryName__c = opp.ForecastCategoryName;
        oppCreated.CurrencyIsoCode__c = opp.CurrencyIsoCode;
        oppCreated.HasOpportunityLineItem__c = opp.HasOpportunityLineItem;
        oppCreated.OwnerId__c = opp.OwnerId;
        oppCreated.CreatedDate__c = opp.CreatedDate;
        oppCreated.CreatedById__c = opp.CreatedById;
        oppCreated.Implementation_Status__c = opp.Implementation_Status__c;
        oppCreated.Brand_Name__c = opp.Brand_Name__c;
        oppCreated.Tier_Name__c = opp.Tier_Name__c;
        oppCreated.Activated_Billed__c = opp.Activated_Billed__c;
        oppCreated.Assisted_Setup__c = opp.Assisted_Setup__c;
        oppCreated.Download_Softphone__c = opp.Download_Softphone__c;
        oppCreated.Trial_Account__c = opp.Trial_Account__c;
        oppCreated.PID__c = opp.PID__c;
        oppCreated.Promotion__c = opp.Promotion__c;
        oppCreated.RC_Account_Status__c = opp.RC_Account_Status__c;
        oppCreated.Downgrade_Date_Opp__c = opp.Downgrade_Date_Opp__c;
        oppCreated.Downgrade_Reason_Opp__c = opp.Downgrade_Reason_Opp__c;
        oppCreated.Number_of_Employees__c = opp.Number_of_Employees__c;
        oppCreated.Sales_Model__c = opp.Sales_Model__c;
        oppCreated.Lead_Score__c = opp.Lead_Score__c;
        oppCreated.Probability_Stage__c = opp.Probability_Stage__c;
        oppCreated.AccountMRR__c = String.valueOf(opp.AccountMRR__c);
        oppCreated.Account_DLS__c = String.valueOf(opp.Account_DLS__c);
        oppCreated.Intended_Product__c = opp.Intended_Product__c;
        oppCreated.Primary_Competitor__c = opp.Primary_Competitor__c;
        oppCreated.Primary_Loss_Reason__c = opp.Primary_Loss_Reason__c;
        oppCreated.Service_Lost__c = opp.Service_Lost__c;
        oppCreated.Loss_Comments__c = opp.Loss_Comments__c;
        oppCreated.Term__c = String.valueOf(opp.Term__c);
        oppCreated.Proposal_Expiration_Date__c = opp.Proposal_Expiration_Date__c;
        oppCreated.Cancellation__c = opp.Cancellation__c;
        oppCreated.Describe_Reason_for_Cancellation__c = opp.Describe_Reason_for_Cancellation__c;
        oppCreated.Appeasement_Offered__c = opp.Appeasement_Offered__c;
        oppCreated.Reason__c = opp.Reason__c;
        oppCreated.Tier__c = opp.Tier__c;
        oppCreated.Sub_Stage__c = opp.Sub_Stage__c;
        oppCreated.HasActiveAgreement__c = String.valueOf(opp.HasActiveAgreement__c);
        oppCreated.Partner_ID__c = opp.Partner_ID__c;
        oppCreated.Is_Premium_Implementation_Required__c = opp.Is_Premium_Implementation_Required__c;
        oppCreated.Incentive__c = opp.Incentive__c;
        oppCreated.Forecasted_Users__c = String.valueOf(opp.Forecasted_Users__c);
        oppCreated.Couldn_t_get_it_working_details__c = opp.Couldn_t_get_it_working_details__c;
        oppCreated.Missing_feature_details__c = opp.Missing_feature_details__c;
        oppCreated.What_s_changing__c = opp.What_s_changing__c;
        oppCreated.What_will_cx_use_for_their_phone_system__c = opp.What_will_cx_use_for_their_phone_system__c;
        oppCreated.Why_is_cx_downselling__c = opp.Why_is_cx_downselling__c;
        oppCreated.RingCentral_Consolidating_Account__c = opp.RingCentral_Consolidating_Account__c;
        oppCreated.Sub_Downgrade_Reason__c = opp.Sub_Downgrade_Reason__c;
        oppCreated.RC_Product_Gaps_Features__c = opp.RC_Product_Gaps_Features__c;
        oppCreated.Customer_Limitations__c = opp.Customer_Limitations__c;
        oppCreated.Downgrade_Reason_Other__c = opp.Downgrade_Reason_Other__c;
        oppCreated.Competitor_Contract_End_Date__c = opp.Competitor_Contract_End_Date__c;
        oppCreated.Product_Gap_Feature_Other__c = opp.Product_Gap_Feature_Other__c;
        oppCreated.Other_Reason_for_Loss__c = opp.Other_Reason_for_Loss__c;
        oppCreated.Cancellation_Reason__c = opp.Cancellation_Reason__c;
        oppCreated.Brand_Cancel__c = opp.Brand_Cancel__c;
        oppCreated.Tier_Cancel__c = opp.Tier_Cancel__c;
        oppCreated.Service_Cancel__c = opp.Service_Cancel__c;
        oppCreated.RC_User_ID_Cancel__c = opp.RC_User_ID_Cancel__c;
        oppCreated.Transferred_by_AT_T_Care__c = opp.Transferred_by_AT_T_Care__c;
        oppCreated.Ported_In_Number_s__c = opp.Ported_In_Number_s__c;
        oppCreated.Implemented__c = opp.Implemented__c;
        oppCreated.Partner_Owner__c = opp.Partner_Owner__c;
        oppCreated.Marketo_Duplicate_Lead__c = opp.Marketo_Duplicate_Lead__c;
        oppCreated.Test_Account__c = opp.Test_Account__c;
        oppCreated.Number_of_RC_Office_Users__c = String.valueOf(opp.Number_of_RC_Office_Users__c);
        oppCreated.Opportunity_Owner_IsActive__c = opp.Opportunity_Owner_IsActive__c;
        oppCreated.Opportunity_Owner_Division__c = opp.Opportunity_Owner_Division__c;
        oppCreated.Lead_Entry_Source__c = opp.Lead_Entry_Source__c;
        oppCreated.Partner_Owner_Assignment_Date__c = opp.Partner_Owner_Assignment_Date__c;
        oppCreated.Partner_Lead_Source__c = opp.Partner_Lead_Source__c;
        oppCreated.Timeframe_greater_than_X_months__c = opp.Timeframe_greater_than_X_months__c;
        oppCreated.Sub_Downgrade_Reason_Other__c = opp.Sub_Downgrade_Reason_Other__c;
        oppCreated.Support_Customer_Care__c = opp.Support_Customer_Care__c;
        oppCreated.Sales_Expectation__c = opp.Sales_Expectation__c;
        oppCreated.New_Account_UID__c = opp.New_Account_UID__c;
        oppCreated.Partner_Classification__c = opp.Partner_Classification__c;
        oppCreated.Discovery_Next_Steps__c = opp.Discovery_Next_Steps__c;
        oppCreated.Discovery_Manager_Notes__c = opp.Discovery_Manager_Notes__c;
        oppCreated.Close_Date_Counter__c = String.valueOf(opp.Close_Date_Counter__c);
        oppCreated.Total_Potential_Users__c = String.valueOf(opp.Total_Potential_Users__c);
        oppCreated.Order__c = opp.Order__c;
        oppCreated.Inside_Sales_Rep__c = opp.Inside_Sales_Rep__c;
        oppCreated.RC_User_ID__c = opp.RC_User_ID__c;
        oppCreated.Partner_Account__c = opp.Partner_Account__c;
        oppCreated.CreateDateTime__c = opp.CreateDateTime__c;
        oppCreated.Opportunity_Owner_Team__c = opp.Opportunity_Owner_Team__c;
        oppCreated.Total_Contract_Value__c = String.valueOf(opp.Total_Contract_Value__c);
        oppCreated.EstimatedProfessionalServices12Month__c = String.valueOf(opp.EstimatedProfessionalServices12Month__c);
        oppCreated.Total_MRR__c = String.valueOf(opp.Total_MRR__c);
        oppCreated.Opportunity_Owner_Segment__c = opp.Opportunity_Owner_Segment__c;
        oppCreated.UCaaS_Competitor_s__c = opp.UCaaS_Competitor_s__c;
        oppCreated.CC_Competitor_s__c = opp.CC_Competitor_s__c;
        oppCreated.Forecast_Contact_Center_Users__c = String.valueOf(opp.Forecast_Contact_Center_Users__c);
        oppCreated.Partner_Account_Name__c = opp.Partner_Account_Name__c;
        oppCreated.STC_Problems__c = opp.STC_Problems__c;
        oppCreated.STC_Impact__c = opp.STC_Impact__c;
        oppCreated.STC_Ideal_Situation__c = opp.STC_Ideal_Situation__c;
        oppCreated.STC_Benefits__c = opp.STC_Benefits__c;
        oppCreated.STC_Decision_Making__c = opp.STC_Decision_Making__c;
        oppCreated.STC_Relationship_Building_Extras__c = opp.STC_Relationship_Building_Extras__c;
        oppCreated.STC_Current_Situation__c = opp.STC_Current_Situation__c;
        oppCreated.UCaaS_Incumbent_s__c = opp.UCaaS_Incumbent_s__c;
        oppCreated.CW_Win_Reason_Features__c = opp.CW_Win_Reason_Features__c;
        oppCreated.DGW_Downgrade_Reason__c = opp.DGW_Downgrade_Reason__c;
        oppCreated.X18_Digit_Id__c = opp.X18_Digit_Id__c;
        oppCreated.Mutual_Plan__c = opp.Mutual_Plan__c;
        oppCreated.RC_Executive_Alignment__c = opp.RC_Executive_Alignment__c;
        oppCreated.Total_ARR__c = String.valueOf(opp.Total_ARR__c);
        oppCreated.Estimated_12M_Contact_Center_Pipeline__c = String.valueOf(opp.Estimated_12M_Contact_Center_Pipeline__c);
        oppCreated.Estimated_12M_Engagement_Pipeline__c = String.valueOf(opp.Estimated_12M_Engagement_Pipeline__c);
        oppCreated.Forecast_Category_Internal__c = opp.Forecast_Category_Internal__c;
        oppCreated.Estimated_Hardware__c = String.valueOf(opp.Estimated_Hardware__c);
        oppCreated.Estimated_12M_Office_Pipeline__c = String.valueOf(opp.Estimated_12M_Office_Pipeline__c);
        oppCreated.Estimated_12M_Global_Office_Pipeline__c = String.valueOf(opp.Estimated_12M_Global_Office_Pipeline__c);
        oppCreated.Estimated_12M_Engage_Voice_Pipeline__c = String.valueOf(opp.Estimated_12M_Engage_Voice_Pipeline__c);
        oppCreated.Estimated_12M_RingCentral_Video_Pipeline__c = String.valueOf(opp.Estimated_12M_RingCentral_Video_Pipeline__c);
        oppCreated.Calculated_12M_Total_Pipeline__c = String.valueOf(opp.Calculated_12M_Total_Pipeline__c);
        oppCreated.Estimated_One_Time_Pipeline__c = String.valueOf(opp.Estimated_One_Time_Pipeline__c);
        oppCreated.Video_Competition__c = opp.Video_Competition__c;
        oppCreated.CC_Incumbent_s__c = opp.CC_Incumbent_s__c;
        oppCreated.Video_Incumbent__c = opp.Video_Incumbent__c;
        oppCreated.Identified_Risks__c = opp.Identified_Risks__c;
        oppCreated.KDR__c = opp.KDR__c;
        oppCreated.RFP__c = opp.RFP__c;
        oppCreated.ROI_TCO_Business_Case__c = opp.ROI_TCO_Business_Case__c;
        oppCreated.ProServ_Comments_Notes__c = opp.ProServ_Comments_Notes__c;
        oppCreated.Monthly_Cost_of_Delay__c = String.valueOf(opp.Monthly_Cost_of_Delay__c);
        oppCreated.Value_Assessment__c = opp.Value_Assessment__c;
        oppCreated.Estimated_12M_Total_Pipeline__c = String.valueOf(opp.Estimated_12M_Total_Pipeline__c);
        oppCreated.Segment_Name__c = opp.Segment_Name__c;
        oppCreated.Reason_for_not_needing_RCV__c = opp.Reason_for_not_needing_RCV__c;
        oppCreated.Forecasted_RingCentral_Video_Users__c = String.valueOf(opp.Forecasted_RingCentral_Video_Users__c);
        oppCreated.IsMultiProductTechnicalOpportunity__c = opp.IsMultiProductTechnicalOpportunity__c;
        oppCreated.Deals_Desk_Stage__c = opp.Deals_Desk_Stage__c;
        oppCreated.White_Space__c = opp.White_Space__c;
        oppCreated.Op_RecordType_Name__c = opp.RecordType.Name;
        oppCreated.Op_Account_Name__c = opp.Account.Name;
        oppCreated.Op_Account_Industry__c = opp.Account.Industry;
        oppCreated.Op_Account_Inside_Sales_Rep__c = opp.Account.Inside_Sales_Rep__c;
        oppCreated.Op_Account_Account_Owner_Manager_Email__c = opp.Account.Account_Owner_Manager_Email__c;
        oppCreated.Op_Account_OwnerID__c = opp.Account.OwnerID;
        oppCreated.Op_Account_SM_Employees__c = String.valueOf(opp.Account.SM_Employees__c);
        oppCreated.Op_Account_Parent_Partner_Account__c = opp.Account.Parent_Partner_Account__c;
        oppCreated.Op_Account_Partner_Account_Name__c = opp.Account.Partner_Account_Name__c;
        oppCreated.Op_Account_Partner_ID__c = opp.Account.Partner_ID__c;
        oppCreated.Op_Account_Type_of_Customer_or_Prospect__c = opp.Account.Type_of_Customer_or_Prospect__c;
        oppCreated.Op_Account_Ultimate_Partner_Name__c = opp.Account.Ultimate_Partner_Name__c;
        If(opp.CreatedById != null) {
            oppCreated.Op_CreatedBy_Name__c = opp.CreatedBy.Name;
        }
        If(opp.OwnerId != null) {
    		oppCreated.Op_Owner_Department__c = opp.Owner.Department;
		    oppCreated.Op_Owner_Division__c = opp.Owner.Division;
    		oppCreated.Op_Owner_ManagerID__c = opp.Owner.ManagerID;
    		oppCreated.Op_Owner_Name__c = opp.Owner.Name;
    		oppCreated.Op_Owner_Manager_Name__c = opp.Owner.Manager.Name;
    		oppCreated.Op_Owner_UserRole_ID__c = opp.Owner.UserRole.ID;
    		oppCreated.Op_Owner_UserRole_Name__c = opp.Owner.UserRole.Name;
    	}
        if ( opp.Account.Parent_Partner_Account__c != null ) {
		    oppCreated.Op_Account_Parent_Partner_Account_r_Name__c = opp.Account.Parent_Partner_Account__r.Name;
		}
		if ( opp.Partner_Account__c != null ) {
    		oppCreated.Op_Partner_Account_r_Name__c = opp.Partner_Account__r.Name;
		}
		if ( opp.Partner_Owner__c != null ) {
    		oppCreated.Op_Partner_Owner_r_Name__c = opp.Partner_Owner__r.Name;
		}
		if ( opp.Portal_Cloud_Specialist__c != null ) {
    		oppCreated.Op_Portal_Cloud_Specialist_r_Name__c = opp.Portal_Cloud_Specialist__r.Name;
		}
		if ( opp.Strategic_Partner_RC_Owner__c != null ) {
    		oppCreated.Op_Strategic_Partner_RC_Owner_r_Name__c = opp.Strategic_Partner_RC_Owner__r.Name;
		}
        return oppCreated;
    }

    private static void publishOpportunityEvent(List<OpportunityCreated__e> opptyCreateEventList, List<OpportunityUpdated__e> opptyUpdateEventList) {
		List<Database.SaveResult> results = new List<Database.SaveResult>();
		if(opptyUpdateEventList.size() > 0) {
			results = EventBus.publish(opptyUpdateEventList);
		} else if(opptyCreateEventList.size() > 0) {
		    results = EventBus.publish(opptyCreateEventList);
		}
        for (Database.SaveResult sr : results) {
			if(!sr.isSuccess()){
				for(Database.Error err : sr.getErrors()) {
            		System.debug('Error returned: ' + err.getStatusCode());
        		}
			}
		}
    }

}
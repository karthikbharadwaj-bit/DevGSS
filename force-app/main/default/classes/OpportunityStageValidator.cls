public without sharing class OpportunityStageValidator {
    /**
     * Created By 	: 	Jerslin Mary Alexander
     * Purpose		: 	This class validates the opportunity if the mandatory fields across various 
     *                  stages of an opportunity, designed as part of QTC-890/1057 Project are filled.
     *                  If not, those missed field labels or their Api names are returned.
     * Called From  :   OpportunityHelper, OpportunityTriggerHelperRefactored, OpportunityWarningMessageController
     *                  Opportunity_Downgrade,Test_OpportunityStageValidator
     */
    public static String stageName;
    public static String opptySegment;
    public static String opptyType;
    public static Decimal opptyPipelineThreshold;
    public static Boolean isDirectSales = false;
    public static Boolean isChannelPartnerOppty = false;
    public static Boolean isPartnerProgramHarmony = false;
    public static Boolean isGSPPartnerOppty = false;
    public static List<String> mandatoryFields = new List<String>();
    public static List<String> missingFields = new List<String>();
    public static final List<String> incumbentFields = new List<String> { 
        'Phone__c',
        'Meetings__c',                                  							
        'Message__c',
        'Contact_Center__c',
        'Digital_Channels__c',
        'Key_Deal_Integration__c' 
    };
    public static final List<String> competitorFields = new List<String> {
        'Competitor_Phone__c',                                   							
        'Competitor_Message__c',                                    							
        'Video_Competition__c',                                    							
        'CC_Competitor_s__c',                                    							
        'Competitor_Digital_Channels__c',                                            							
        'Identified_Risks__c'
    };
    public static final List<String> closeOpptyExitFields = new List<String> {
        'Why_We_Won__c',                                        							
        'Final_Competitor_we_won_against__c',                                        							
        'Additional_details_on_why_we_won__c'
    };
    public static final List<String> downgradeOpptyExitFields =new List<String> {
        'Why_We_Lost__c',                                            						
        'Final_Competitor_we_lost_against__c',                                            							
        'Additional_details_on_why_we_lost__c'
    };
    public static final Integer OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE = 10500;
    public static final Integer OPPORTUNITY_MAXIMUM_PIPELINE_THRESHOLDVALUE = 25000;

    private static Boolean isValidOpportunitySegment() {
        return String.isNotBlank(opptySegment) 
               && (opptySegment.equals(UserHelper.SEGMENT_MID_MARKET) || opptySegment.equals(UserHelper.SEGMENT_MAJORS) 
                   || opptySegment.equals(UserHelper.SEGMENT_ENTERPRISE) || opptySegment.equals(UserHelper.SEGMENT_SMALL_BUSINESS) 
                   || opptySegment.equals(UserHelper.SEGMENT_SOHO));
    }

	private static Boolean isLargerSegment() {
        return String.isNotBlank(opptySegment) 
               && (opptySegment.equals(UserHelper.SEGMENT_MID_MARKET) || opptySegment.equals(UserHelper.SEGMENT_MAJORS) 
                   || opptySegment.equals(UserHelper.SEGMENT_ENTERPRISE));
    }

	private static Boolean isSmallerSegment() {
        return String.isNotBlank(opptySegment) 
               && (opptySegment.equals(UserHelper.SEGMENT_SMALL_BUSINESS) || opptySegment.equals(UserHelper.SEGMENT_SOHO));
    }

    private static void getMandatoryFieldsForGivenStage() {
        mandatoryFields = new List<String>();
        switch on stageName {
            when '7. Closed Won', '7.1. Closed Won for ProServ' { 
                getClosedWonRequiredFields();
            } when '6. Order' {
                getStage5ExitRequiredFields();
            } when '5. Agreement' {
                getStage4ExitRequiredFields();
            } when '4. Proof' {
                getStage3ExitRequiredFields();
            } when '3. Solution' {
                getStage2ExitFields();
            } when '2. Problem' {
                getStage1ExitFields();
            } when '0. Downgraded'  {
                getDowngradeRequiredFields();
            }
        }
    }

    private static void getDowngradeRequiredFields() {
        if(isValidOpportunitySegment() && !isChannelPartnerOppty) {
            mandatoryFields.addAll(downgradeOpptyExitFields);                                    
		}
    }

    private static void getClosedWonRequiredFields() {
        if(isValidOpportunitySegment() && !isChannelPartnerOppty) {
            mandatoryFields.addAll(closeOpptyExitFields);                                      
        }
        if(isGSPPartnerOppty) { 
            return; 
        }
        getStage5ExitRequiredFields();
    }

    private static void getStage5ExitRequiredFields() {
        getStage4ExitRequiredFields();
    }

    private static void getStage4ExitRequiredFields() {
        getStage3ExitRequiredFields();
    }

    private static void getStage3ExitRequiredFields() {
        if(isDirectSales) {
            if(isLargerSegment() && opptyPipelineThreshold >= OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE) {
                List<String> fields = new List<String> {
                    'Mutual_Plan__c',
                    'STC_Relationship_Building_Extras__c',
                    'RC_Executive_Alignment__c',
                    'KDR__c' 
                };
                mandatoryFields.addAll(fields);
            } else if(isSmallerSegment()) {
                if(opptyPipelineThreshold >= OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE 
                   && opptyPipelineThreshold <= OPPORTUNITY_MAXIMUM_PIPELINE_THRESHOLDVALUE) {
                    mandatoryFields.add('Mutual_Plan__c');
                } else if (opptyPipelineThreshold > OPPORTUNITY_MAXIMUM_PIPELINE_THRESHOLDVALUE) {
                    List<String> fields = new List<String>{
                        'Mutual_Plan__c',
                        'KDR__c',
                        'RC_Executive_Alignment__c'
                    };
                    mandatoryFields.addAll(fields);
                }
            }
        } else {
            if(isLargerSegment() && opptyPipelineThreshold >= OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE) {
                mandatoryFields.add('Implementation_Comments_Notes__c');
            }
        }
        getStage2ExitFields();
    }

    private static void getStage2ExitFields() {
        if (isValidOpportunitySegment() && opptyPipelineThreshold >= OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE) {
            if (isDirectSales) {
                mandatoryFields.addAll(incumbentFields);                    
                mandatoryFields.addAll(competitorFields);
                List<String> stage2NonPartnerfields = new List<String> {
                    'STC_Decision_Making__c',
                    'STC_Ideal_Situation__c'
                };
                mandatoryFields.addAll(stage2NonPartnerfields);
                getStage1ExitFields();
            } else {
                if (isLargerSegment()) {
                    mandatoryFields.add('ProServ_Comments_Notes__c');
                }
                if (isPartnerProgramHarmony) {
                    mandatoryFields.addAll(incumbentFields);                    
                    mandatoryFields.addAll(competitorFields);    
                }
            }
        }
    }

    private static void getStage1ExitFields() {
        if( isValidOpportunitySegment() && opptyPipelineThreshold >= OPPORTUNITY_MINIMUM_PIPELINE_THRESHOLDVALUE 
            && isDirectSales) {
            List<String> fields = new List<String> {
                'STC_Current_Situation__c',
                'STC_Problems__c'
            };
            mandatoryFields.addAll(fields);
        }
    }

    public static List<String> getMissingFieldsforGivenStage(Opportunity oppty, Decimal convertedARR, OpportunityHelper.ValidationCategory valCategory) {
        stageName       = oppty.StageName;
        opptySegment    = oppty.Segment_Name__c;
        opptyType       = oppty.Type; 
        opptyPipelineThreshold = convertedARR;
        isDirectSales = (valCategory == OpportunityHelper.ValidationCategory.FULL_VALIDATION) ? true : false; 
        isChannelPartnerOppty = (valCategory == OpportunityHelper.ValidationCategory.PARTNER_VALIDATION) ? true : false; 
        isPartnerProgramHarmony = (valCategory == OpportunityHelper.ValidationCategory.CHANNEL_HARMONY_VALIDATION) ? true : false; 
        isGSPPartnerOppty = (valCategory == OpportunityHelper.ValidationCategory.GSP_VALIDATION) ? true : false; 
        if(String.isNotBlank(opptyType) && opptyType.equalsIgnoreCase(OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS)) {
            getMandatoryFieldsForGivenStage();
        }
        if(!mandatoryFields.isEmpty()) {   
            identifyMissingFields(oppty);
        } else {
            missingFields = new List<String>();
        }
        return missingFields;
    }

    public static List<String> getMissingFieldLabelsForGivenStage(Opportunity oppty, Decimal convertedARR, OpportunityHelper.ValidationCategory valCategory) {
        List<String> missingfieldLabels = new List<String>();
        getMissingFieldsforGivenStage(oppty, convertedARR, valCategory);
        for(String fieldApiName : missingFields) {
            missingfieldLabels.add(OpportunityHelper.FIELDS_MAP.get(fieldApiName).getDescribe().getLabel());
        }
        return missingfieldLabels;
    }
    
    private static void identifyMissingFields(Opportunity oppty) {
        missingFields = new List<String>();
        if(isGSPPartnerOppty) {
            missingFields = mandatoryFields;
            return;
        }
        for(String fieldApiName : mandatoryFields) {
            String fieldVal = (String)oppty.get(fieldApiName);
            if(String.isBlank(fieldVal)) {
                missingFields.add(fieldApiName);
            }
        }
    }
}
/*
 This is a Helper Class which is used for following purposes :
 CAMPAIGN ASSIGNMENT to LEAD
 Employee Range Validation
 Good and Bad Value Check for Employee Range based on CSV
 */
public class LeadTriggerHelperExt{
  /**************************************************STATIC VARIABLE DECLARATION*********************************************************/
  private static String JOB_FUNCTION = 'Job_Function__c';
  private static String NO_OF_EMPLOYEES = 'numberofemployees__c';
  private static String INDUSTRY = 'Industry';
  private static String PURCHASE_TIMEFRAME = 'Purchase_Timeframe__c';
  private static Set<String> BRANDS_TO_SKIP_CURRENCY_POPULATION = new Set<String>{ RingCentralHelper.BRAND_VODAFONE_UK, RingCentralHelper.BRAND_VODAFONE_EU, RingCentralHelper.BRAND_VODAFONE };
  /**************************************************************************************************************************************/
  /**********************Method to assign campaign on basis of Campaign Name to list of Leads***************************/
  public static void assignCampaignToList(String campName, List<Lead> leadList, Map<String, Campaign> campMap){
    for (List<Campaign> tempCampList : [SELECT Id, type, Lead_Creation_Score__c, Lead_Entry_Source__c, AID__c, PID__c, BMID__c, DNIS__c, Team__c, NumberOfLeads, Lead_Score__c, Name
                                    from Campaign
                                    where name = :campName AND IsActive = true
                                    limit 1]){
      if (tempCampList != null && tempCampList.size() > 0){
        Campaign tempCampObj = tempCampList.get(0);
        for (Lead trueWalkOnLead : leadList){
          trueWalkOnLead.Primary_Campaign__c = tempCampObj.Id;
          trueWalkOnLead.Most_Recent_Campaign__c = tempCampObj.Id;
          if (String.isNotBlank(tempCampObj.BMID__c)){
            trueWalkOnLead.BMID__c = tempCampObj.BMID__c;
          }
          campMap.put((String) trueWalkOnLead.Primary_Campaign__c, tempCampObj);
        }
      }
    }
  }

  /***********************************************************************************************************/
  /********************Returns Campaign Map on the basis of Campaign Id Set**************************************/
  public static map<String, Campaign> returnCampaignMap(Set<id> campaignIdSet){
    return new map<String, Campaign>([SELECT Id, type, Lead_Creation_Score__c, Lead_Entry_Source__c, AID__c, PID__c, BMID__c, DNIS__c, Team__c, NumberOfLeads, Lead_Score__c, Name
                                  from Campaign
                                  where Id in:campaignIdSet]);
  }

  /*****************************************************************************/
  /***************Method for Campaign distribution in Leads*************************/
  public static Map<String, Campaign> assignCampaigns(List<Lead> leadList){
    Map<String, Campaign> campaignMap = new Map<String, Campaign>();
    List<CampaignWrapper> camWrapperList = new List<CampaignWrapper>();

    set<id> campaignIdSet = new set<id>();
    List<Lead> ListOfleadForSpecificCampn = new List<Lead>();
    List<Campaign> tempCampList = new List<Campaign>();
    List<Lead> inboundCallChatCampList = new List<Lead>();
    try{
      for (Lead leadObj : leadList){
        if(leadObj.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null && System.Label.BizMerge_Brand_Exclusion_List.contains(leadObj.Lead_Brand_Name__c)) {
          continue;
        }
        if (String.isBlank(leadObj.Primary_Campaign__c)){
          if (String.isBlank(leadObj.AID__c) && String.isBlank(leadObj.PID__c) && String.isBlank(leadObj.BMID__c) && String.isBlank(leadObj.Five9_DNIS__c)){
            if (leadObj.Lead_System_Source__c == 'LivePerson'){
              inboundCallChatCampList.add(leadObj);
            } else{
              ListOfleadForSpecificCampn.add(leadObj);
            }
          } else{
            camWrapperList.add(new CampaignWrapper(leadObj.AID__c, leadObj.BMID__c, leadObj.PID__c, leadObj.Five9_DNIS__c, leadObj.Primary_Campaign__c, (leadObj.RecordTypeId == OpportunityHelper.getOppRecordTypeMap('Partner Leads'))));
          }
        } else{
          campaignIdSet.add(leadObj.Primary_Campaign__c);
          leadObj.Most_Recent_Campaign__c = leadObj.Primary_Campaign__c;
        }
      }

      if (campaignIdSet != null && campaignIdSet.size() > 0){
        campaignMap = returnCampaignMap(campaignIdSet);
      }

      if (ListOfleadForSpecificCampn != null && ListOfleadForSpecificCampn.size() > 0){
        assignCampaignToList('True_Walk_On_2024', ListOfleadForSpecificCampn, campaignMap);
      }

      if (inboundCallChatCampList != null && inboundCallChatCampList.size() > 0){
        assignCampaignToList('Inbound Call/Chat', inboundCallChatCampList, campaignMap);
      }

      if (camWrapperList != null && camWrapperList.size() > 0){
        //New Function "findCampaingsLogic" for Considering DNIS also for Campaign Calculation.
        Map<String, Campaign> criteriaToCamapaignMap = CampaignAssignmentHelper.findCampaingsLogic(camWrapperList);
        ListOfleadForSpecificCampn = new List<Lead>();
        for (Lead leadObj : leadList){
          if (String.isBlank(leadObj.Primary_Campaign__c)){
            Campaign campaignObj = CampaignAssignmentHelper.getLeadCampaignLogicWithoutDNIS(new CampaignWrapper(leadObj.AID__c, leadObj.BMID__c, leadObj.PID__c, leadObj.Five9_DNIS__c, leadObj.Primary_Campaign__c, (leadObj.RecordTypeId == OpportunityHelper.getOppRecordTypeMap('Partner Leads'))), criteriaToCamapaignMap);
            if (campaignObj != null){
              leadObj.Primary_Campaign__c = campaignObj.Id;
              leadObj.Most_Recent_Campaign__c = campaignObj.Id;
              leadObj.BMID__c = campaignObj.BMID__c;
              campaignMap.put((String) leadObj.Primary_Campaign__c, campaignObj);
            } else{
              ListOfleadForSpecificCampn.add(leadObj);
            }
          }
        }
        if (ListOfleadForSpecificCampn != null && ListOfleadForSpecificCampn.size() > 0){
          assignCampaignToList('Broken Attribution', ListOfleadForSpecificCampn, campaignMap);
        }
      }
    } catch (Exception ex){
      LeadPlatEvents.leadExceptionCreationAsync(new Exception[]{ ex }, 'assignCampaigns');
      throw ex;
    }

    return campaignMap;
  }

  /*************************************************************************************************/
  /***************************Returns List of Documnemt Based on Document Name*********************/
  public static List<Document> getMyDocument(String docName){
    return [SELECT body, Name, bodyLength, ContentType, Url
        FROM Document
        WHERE Name = :docName];
  }

  /***********************************************************************************************/
  /************************************************************************************************
   *@Description: Check number of employee Value is Valid Range value or not                       *
   *@Params: Set<String>,Lead                                                                      *
   *@Returns: Boolean                                                                              *
   *************************************************************************************************/
  private static Boolean isValidValue(Set<String> range, Lead leadObj){
    if (range.contains(leadObj.NumberOfEmployees__c)){
      return true;
    }
    return false;
  }

  /*********************************** rangeMapPerStartValue ends here********************************/
  /****************************************************************************************************
   *@Description: Check number of employee is Number or not                                            *
   *@Params:String                                                                                     *
   *@Returns: Boolean                                                                                  *
   *@Deployed Date: 06-March-14                                                                        *
   *@Case No: 2399518                                                                                  *
   *@Coded By: India Team                                                                              *
   *****************************************************************************************************/
  public static boolean isNumeric(String numberOfEmployeeRange){
    return Pattern.matches('^[0-9]{1,10}$', numberOfEmployeeRange);//^[0-9]+(\\.[0-9]+)?$
  }

  /*********************** isNumeric method end's here*************************************************/
  /****************************************************************************************************
   *@Description: getting Standard Value of No. Of Employee Range                                     *
   *@Params: no Parameters                                                                             *
   *@Returns: Set<String>                                                                              *
   *@Deployed Date: 06- March -14                                                                      *
   *@Case No: 2399518                                                                                  *
   *@Coded By: India Team                                                                              *
   *****************************************************************************************************/
  public static Set<String> getEmployeeRange(){
    Set<String> range = new Set<String>();
    range.addAll(LeadTriggerHelper.getPicklistValue());
    return range;
  }

  /*******************getEmployeeRange method Ends here************************************************/
  public static void generateCampaignMember(List<Lead> newLeads){
    List<CampaignMember> campaignMemberList = new List<CampaignMember>();
    Map<Id, Id> leadCampMap = new Map<Id, Id>();
    try{
      List<Id> leadIdsForDelete = new List<Id>();
      for (Lead newLeadObj : newLeads){
        if(newLeadObj.Lead_Brand_Name__c!=null && System.Label.BizMerge_Brand_Exclusion_List!=null && System.Label.BizMerge_Brand_Exclusion_List.contains(newLeadObj.Lead_Brand_Name__c)) {
          continue;
        }
        if ((newLeadObj.FirstName == 'something' && newLeadObj.LastName == 'new') || (newLeadObj.FirstName == 'rctu' && newLeadObj.LastName == '2calls4me')){
          leadIdsForDelete.add(newLeadObj.Id);
        } else{
          if (newLeadObj != null && newLeadObj.Primary_Campaign__c != null && newLeadObj.Primary_Campaign__c != ''){
            CampaignMember campMemberObj = new CampaignMember(CampaignId = newLeadObj.Primary_Campaign__c, LeadId = newLeadObj.Id, Old_Campaign__c = null, Primary_Marketing_Asset__c = newleadObj.Most_Recent_Asset__c);
            campMemberObj.Status = 'Responded';
            Boolean status = false;
            if (leadCampMap != null && leadCampMap.get(newLeadObj.Primary_Campaign__c) != null && leadCampMap.get(newLeadObj.Primary_Campaign__c) == newLeadObj.Id){
              status = true;
            }
            if (status == false){
              leadCampMap.put(newLeadObj.Primary_Campaign__c, newLeadObj.Id);
              campaignMemberList.add(campMemberObj);
            }
          }
        }
      }
      Database.delete(leadIdsForDelete);
      LeadTriggerHelperExt.insertCampaignMember(campaignMemberList, true);
    } catch (Exception ex){
      ExceptionHelper.createExceptionAndNotificacionHistory(ex, trigger.new, 'Lead Exception');
    }
  }

  public static void insertCampaignMember(List<CampaignMember> campaignMemberList, Boolean triggerOn){
    try{
      Feature_Toggle__c featureToogle = Feature_Toggle__c.getInstance();
      if (campaignMemberList.size() != 0){
        Decimal CampMemberAsyncRecordQantity = featureToogle.CampMemberAsyncRecordQantity__c != null ? featureToogle.CampMemberAsyncRecordQantity__c : 25;
        if (Trigger.new.size() > CampMemberAsyncRecordQantity){
          CampaignMemberPlatEvents.campaignMemberCreationAsyncFromLead(campaignMemberList, false);
        } else{
          if (!triggerOn){
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = true;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = true;
            insert campaignMemberList;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTCHECK = false;
            TriggerHandler.BY_PASS_CAMPAIGNMEMBER_TRIGGER_FIREPLATFORMEVENTLOG = false;
          } else{
            insert campaignMemberList;
          }

        }
      }
    } catch (Exception e){
      ExceptionHelper.createExceptionAndNotificacionHistory(e, campaignMemberList, 'Lead Exception');
    }
  }

  public static Map<Id, User> setLeadFields(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
    Map<Id, User> userDetailMap;
    Set<id> userids = new Set<id>();
    List<Lead> numberOfEmpLeadsUpdatedList = new List<Lead>();
    try{
      for (Lead leadObj : newLeads){
        userids.add(leadObj.OwnerId);
        userids.add(oldLeadMap.get(leadObj.id).ownerId);
        /********************************** Kenshoo workflow replacement ********************************/
        /*if((leadObj.status!=oldLeadMap.get(leadObj.id).status)||(leadObj.ConvertedDate!=oldLeadMap.get(leadObj.id).ConvertedDate)){
         leadObj.KS_Lead_Status_Change_Time_Stamp__c = DateTime.now();
         }*/
        /***********************************************************************************************/

        //NO. OF EMP CSV CODE ON LEAD UPDATE
        if (leadObj.NumberOfEmployees__c != null && leadObj.NumberOfEmployees__c != oldLeadMap.get(leadObj.id).NumberOfEmployees__c){
          numberOfEmpLeadsUpdatedList.add(leadObj);
        }

        //SETTING LEAD CURRENCY
        populateCurrencyBasedOnBrand(leadObj);

        //Avaya Lead country change starts
        Map<String, String> countryCurrencyMapForCommunity = CountryCurrencyCode.getCountryCurrencyMap();

        if (leadObj.Avaya_Partnership_Lead__c == true){
          String currencyForCntry = countryCurrencyMapForCommunity.get(String.valueof(leadObj.Country__c));
          if (leadObj.Lead_Brand_Name__c != 'Vodafone Business with RingCentral'){
            if (currencyForCntry != null && currencyForCntry != ''){
              leadObj.CurrencyIsoCode = currencyForCntry;
            } else{
              leadObj.CurrencyIsoCode = 'USD';
            }
          }
          //For Avaya Cloud Specialist Mapping
          Partner_LeadTrgHelper.leadBeforeMappings(leadObj, oldLeadMap);
        }
      }

      //Number of Employee Bucketing Logic on update.
      if (numberOfEmpLeadsUpdatedList != null && numberOfEmpLeadsUpdatedList.size() > 0){
        LeadTriggerHelperExt.getCheckForBadValue(numberOfEmpLeadsUpdatedList);
      }

      if(ConvertLead.IS_LEAD_CONVERT_PROCESSING && SettingsHelper.FEATURE_TOGGLE.EnableLeadConversionUsingCache__c){
        userDetailMap = UserHelper.retrieveUserMapWithCache(userids);
      }
      else {
        userDetailMap = retrieveUsersWithoutCache(userids);
      }


    } catch (exception ex){
      ExceptionHelper.createExceptionAndNotificacionHistory(ex, trigger.new, 'Lead Exception');
    }
    return userDetailMap;
  }

  /**
   * Retrieves user details without cache
   * @param userIds Set of user IDs to retrieve
   * @return Map of user ID to User record
   */
  private static Map<Id, User> retrieveUsersWithoutCache(Set<Id> userIds) {
    return new Map<Id, User>([
      SELECT Manager.Email, Name, Phone, Manager.Name, IsActive, Profile.Name, ManagerId, Mkto_Reply_Email__c
      FROM User
      WHERE Id IN :userIds
    ]);
  }


  /****************************************************************************************************
   *@Description: Check good value against the bad value                                               *
   *@Params:List<Lead>                                                                                 *
   *@Returns: Void                                                                                     *
   *****************************************************************************************************/
  public static void getCheckForBadValue(List<Lead> lstLead){
    try{
      List<Lead> filteredLeads = new List<Lead>();
      Set<String> range = new Set<String>();
      range.addAll(LeadTriggerHelper.getPicklistValue());
      for (Lead leadObj : lstLead){
        if (!isValidValue(range, leadObj)){
          filteredLeads.add(leadObj);
        }
      }
      if (filteredLeads.size() == 0) {
        return;
      }
      String csvFile;
      String fileName = 'No_Employee_Mapping';
      String[] fileLines = new String[]{  };
      Map<String, String> mapToGetGoodValueEmp = new Map<String, String>();
      Map<String, String> mapToGetGoodValueInd = new Map<String, String>();
      Map<String, String> mapToGetGoodValueJob = new Map<String, String>();
      Map<String, String> mapToGetGoodValuePur = new Map<String, String>();
      Map<String, Map<String, String>> masterMap = new Map<String, Map<String, String>>();
      List<Lead_Field_Map__c> fieldlst = Lead_Field_Map__c.getAll().Values();

      List<Document> compareDoc = getMyDocument(fileName);
      if (compareDoc.size() > 0 && compareDoc[0].body != null){
        csvFile = compareDoc[0].body.toString();
        fileLines = csvFile.split('#EOL#');
        for (String line : fileLines){
          if (!String.isBlank(line)){
            String[] inputvalues = line.split(',#,');
            if (inputvalues != null && inputvalues.size() == 3){
              If (inputvalues[0].trim().equalsIgnoreCase(NO_OF_EMPLOYEES)){
                mapToGetGoodValueEmp.put(inputvalues[1].trim().tolowercase(), inputvalues[2].trim());
              }
              if (inputvalues[0].trim().equalsIgnoreCase(INDUSTRY)){
                mapToGetGoodValueInd.put(inputvalues[1].trim().tolowercase(), inputvalues[2].trim());
              }
              if (inputvalues[0].trim().equalsIgnoreCase(JOB_FUNCTION)){
                mapToGetGoodValueJob.put(inputvalues[1].trim().tolowercase(), inputvalues[2].trim());
              }
              if (inputvalues[0].trim().equalsIgnoreCase(PURCHASE_TIMEFRAME)){
                mapToGetGoodValuePur.put(inputvalues[1].trim().tolowercase(), inputvalues[2].trim());
              }
            }
          }
        }
      }
      for (Lead_Field_Map__c lfp : fieldlst){
        if (lfp.api_name__c.trim() == NO_OF_EMPLOYEES){
          masterMap.put(String.valueOf(lfp.api_name__c).trim().tolowercase(), mapToGetGoodValueEmp);
        }
        if (lfp.api_name__c.trim() == PURCHASE_TIMEFRAME){
          masterMap.put(String.valueOf(lfp.api_name__c).trim().tolowercase(), mapToGetGoodValuePur);
        }
        if (lfp.api_name__c.trim() == JOB_FUNCTION){
          masterMap.put(String.valueOf(lfp.api_name__c).trim().tolowercase(), mapToGetGoodValueJob);
        }
        if (lfp.api_name__c.trim() == INDUSTRY){
          masterMap.put(String.valueOf(lfp.api_name__c).trim().tolowercase(), mapToGetGoodValueInd);
        }
      }

      for (Lead leadObj : filteredLeads){
        if (masterMap.containsKey(NO_OF_EMPLOYEES) && !String.isBlank(String.valueof(leadObj.NumberOfEmployees__c)) && mapToGetGoodValueEmp.containsKey(String.valueof(leadObj.NumberOfEmployees__c).tolowercase())){
          leadObj.Employee_Size_History__c = leadObj.NumberOfEmployees__c;
          leadObj.NumberOfEmployees__c = masterMap.get(NO_OF_EMPLOYEES).get(leadObj.NumberOfEmployees__c.toLowerCase().trim());
        }
        if (masterMap.containsKey(INDUSTRY) && !String.isBlank(String.valueof(leadObj.Industry)) && mapToGetGoodValueInd.containsKey(String.valueof(leadObj.Industry).toLowerCase())){
          leadObj.Industry = masterMap.get(INDUSTRY).get(leadObj.Industry.toLowerCase().trim());
        }
        if (masterMap.containsKey(JOB_FUNCTION) && !String.isBlank(String.valueof(leadObj.Job_Function__c)) && mapToGetGoodValueJob.containsKey(String.valueof(leadObj.Job_Function__c).toLowerCase())){
          leadObj.Job_Function__c = masterMap.get(JOB_FUNCTION).get(leadObj.Job_Function__c.toLowerCase().trim());
        }
        if (masterMap.containsKey(PURCHASE_TIMEFRAME) && !String.isBlank(leadObj.Purchase_Timeframe__c) && mapToGetGoodValuePur.containsKey(leadObj.Purchase_Timeframe__c.toLowerCase())){
          leadObj.Purchase_Timeframe__c = masterMap.get(PURCHASE_TIMEFRAME).get(leadObj.Purchase_Timeframe__c.toLowerCase().trim());
        }
      }
    } catch (exception e){
      ExceptionHelper.createExceptionAndNotificacionHistory(e, lstLead, 'Lead Exception');
    }
  }

  /****************************************************************************************************
   *   @Method         :   ClearLeadSpaceFields
   *   @Params         :   Lead
   *   @Description    :   Clear Lead Space Fields
   *   @returnType     :
   *   @created By     :   eugenebasianomutya
   ****************************************************************************************************/
  public static void ClearLeadSpaceFields(Lead leadObj){
    leadObj.LS_Company__c = NULL;
    leadObj.LS_Company_City__c = NULL;
    leadObj.LS_Company_Country__c = NULL;

    leadObj.LS_Company_Industry__c = NULL;
    leadObj.LS_Company_Original_Input__c = NULL;
    leadObj.LS_Company_Phone__c = NULL;
    leadObj.LS_Company_Products_and_Technologies__c = NULL;
    leadObj.LS_Company_Revenue__c = NULL;

    leadObj.LS_Company_Score__c = NULL;
    leadObj.LS_Company_Size__c = NULL;
    leadObj.LS_Company_Size_Range__c = NULL;
    leadObj.LS_Company_State__c = NULL;
    leadObj.LS_Company_Street__c = NULL;
    leadObj.LS_Company_Sub_Industry__c = NULL;
    leadObj.LS_Company_Website__c = NULL;
    leadObj.LS_Company_Zipcode__c = NULL;
    //leadObj.LS_DU_ID__c=NULL;
    leadObj.LS_Enrichment_Date__c = NULL;
    leadObj.LS_First_Name__c = NULL;
    leadObj.LS_Last_Name__c = NULL;
    leadObj.LS_Lead_Country__c = NULL;
    leadObj.LS_Lead_Department__c = NULL;

    leadObj.LS_Lead_Job_Functions__c = NULL;
    leadObj.LS_Lead_Level__c = NULL;
    leadObj.LS_Lead_Linkedin_Profile__c = NULL;
    leadObj.LS_Lead_Phone__c = NULL;
    leadObj.LS_Lead_Products_and_Technologies__c = NULL;
    leadObj.LS_Lead_Score__c = NULL;
    leadObj.LS_Lead_State__c = NULL;

    leadObj.LS_LTV_Predictive_Score__c = NULL;
    leadObj.LS_Name__c = NULL;
    leadObj.LS_Original_Email_Verification__c = NULL;
    leadObj.LS_Predictive_Score__c = NULL;
    leadObj.LS_Primary_NAIC__c = NULL;
    leadObj.LS_Primary_SIC__c = NULL;
    leadObj.LS_Response__c = NULL;
    leadObj.LS_Secondary_NAIC__c = NULL;
    leadObj.LS_Secondary_SIC__c = NULL;
    leadObj.LS_Site__c = NULL;
    leadObj.LS_Site_Phone__c = NULL;
    leadObj.LS_Site_Size__c = NULL;
    leadObj.LS_Site_Size_Range__c = NULL;
    leadObj.LS_Site_State__c = NULL;
    leadObj.LS_Site_Website__c = NULL;
    leadObj.LS_Site_Zipcode__c = NULL;
    leadObj.LS_Status__c = NULL;
    leadObj.LS_Sync_Trigger__c = False;
    leadObj.LS_Title__c = NULL;
    leadObj.LS_Total_Score__c = NULL;
    leadObj.LS_Verified__c = NULL;
    leadObj.SystemsProcessBypass__c = NULL;//Nullifying Systems Process Bypass when cloning for Gating process
  }

  public static void populateCurrencyBasedOnBrand(Lead leadObj){
    if (BRANDS_TO_SKIP_CURRENCY_POPULATION.contains(leadObj.Lead_Brand_Name__c)){
      return;
    }
    if (leadObj.Lead_Brand_Name__c == RingCentralHelper.BRAND_RINGCENTRAL_UK){
      leadObj.CurrencyIsoCode = RingCentralHelper.GBP;
    } else if (leadObj.Lead_Brand_Name__c == RingCentralHelper.BRAND_RINGCENTRAL_CANADA){
      leadObj.CurrencyIsoCode = RingCentralHelper.CAD;
    } else if (leadObj.Lead_Brand_Name__c == RingCentralHelper.BRAND_RINGCENTRAL_EU){
      leadObj.CurrencyIsoCode = RingCentralHelper.EUR;
    } else if (leadObj.Lead_Brand_Name__c == RingCentralHelper.BRAND_RINGCENTRAL_AU){
      leadObj.CurrencyIsoCode = RingCentralHelper.AUD;
    } else if (leadObj.Lead_Brand_Name__c == RingCentralHelper.BRAND_BT_BUSINESS){
        leadObj.CurrencyIsoCode = RingCentralHelper.GBP;
    } else {
      leadObj.CurrencyIsoCode = RingCentralHelper.USD;
    }
  }
}
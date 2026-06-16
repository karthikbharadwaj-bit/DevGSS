/*Change History
 *******************************************************************************************************************************************
 SCRUM/Jira ModifiedBy        Date        Description                 Tag
 *******************************************************************************************************************************************
 SCRUM      Praveen.U       12/27/2019   Excluding Market Users       T01
 SCRUM      Praveen.U       12/27/2019   Issue Fixing                 T02
 SCRUM      Praveen.U       01/17/2020   Adding Sales Notes           T03
 SCRUM      Praveen.U       01/20/2020   Populating SID field         T04
 *******************************************************************************************************************************************
 */
public class PartnerDealRegistrationUtil{
  public static final String OFFICE_STR = 'office';
  public static final String BRAND_STR = 'RingCentral';
  public static final String BRAND_BT = 'BT Business';
  public static final String BRAND_OTHER_STR = 'RingCentral US';
  public static final string ACCOUNT_TYPE_CUSTOMER = 'Customer';

  //Added for LTR-673 PS Deal Reg
    public static final String COMPLETE = 'Complete';
    public static final String PSPREMIERPARTNER = 'PS Premier Partner';
    public static final String ENROLLCDPSTATUS = 'Enroll in CDP for Partner Install';
    public static final String PARTNERINSTALLSTATUS = 'Partner Install, Certified Delivery Partner';

  public PartnerDealRegistrationUtil(){
  }

  public static List<Lead> AddDealAsLead(List<Deal_Registration__c> dealRegistrations){
    system.debug('AddDealAsLead');
    List<Lead> mitelLeads = new List<Lead>();
    Map<Id, Deal_Registration__c> mapDealReg = new Map<Id, Deal_Registration__c>();
    Set<String> partnerAccountIds = new Set<String>();
    for (Deal_Registration__c dealRegistration : dealRegistrations){
      partnerAccountIds.add(dealRegistration.Partner_Account__c);
      mapDealReg.put(dealRegistration.Id, dealRegistration);
    }

    Map<Id, Account> partnerAccountsMap = new Map<Id, Account>([SELECT Id, Name, CurrencyISOCode, Partner_ID__c, Inside_Sales_Rep__c, VAR_Territory__c, Partner_Account__c, Partner_Account__r.name, Partner_Account__r.Partner_ID__c, Parent_Partner_Account__c, Parent_Partner_Account__r.Name, Parent_Partner_Account__r.Partner_ID__c, SID__c, Partner_Account__r.Partner_Account__c, Partner_Account__r.Partner_Account__r.name, Partner_Account__r.Partner_Account__r.Partner_ID__c, Partner_Role__c, Partner_Type__c, BusinessIdentity__c FROM Account WHERE Id IN:partnerAccountIds]);

    List<Lead> partnerLeads = new List<Lead>();
    for (Deal_Registration__c dealRegistration : dealRegistrations){
      Lead partnerLead = new Lead();
      if (String.isNotBlank(dealRegistration.OwnerId)) {
          partnerLead.OwnerId = dealRegistration.OwnerId;
      }
      partnerLead.FirstName = dealRegistration.First_Name__c;
      partnerLead.LastName = dealRegistration.Last_Name__c;
      partnerLead.Title = dealRegistration.Business_Title__c;
      partnerLead.Company = dealRegistration.Company_Name__c;
      partnerLead.Email = dealRegistration.Email_Address__c;
      partnerLead.Phone = dealRegistration.Phone_Number__c;
      partnerLead.Street = dealRegistration.Street__c;
      partnerLead.City = dealRegistration.City__c;
      partnerLead.City__c = dealRegistration.City__c;
      partnerLead.State__c = dealRegistration.State__c;
      partnerLead.State = dealRegistration.State__c;
      partnerLead.PostalCode = dealRegistration.Postal_Code__c;
      partnerLead.Country__c = dealRegistration.Country__c;
      partnerLead.Country = dealRegistration.Country__c;
      partnerLead.Number_of_Users__c = dealRegistration.Forecasted_Users__c;
      partnerLead.Lead_Brand_Name__c = dealRegistration.Brand_Name__c;
      partnerLead.Lead_Tier_Name__c = dealRegistration.Tier_Name__c;
      partnerLead.Partner_Lead_Source__c = dealRegistration.Partner_Lead_Source__c;
      partnerLead.NumberOfEmployees__c = dealRegistration.Number_of_Employees__c;
      partnerLead.Number_of_Locations__c = dealRegistration.Number_of_Locations__c;
      partnerLead.Industry = dealRegistration.Industry__c;
      partnerLead.Estimated_Close_Date__c = dealRegistration.Estimated_Close_Date__c;
      partnerLead.How_did_you_acquire_this_Lead__c = dealRegistration.How_did_you_acquire_this_Lead__c;
      partnerLead.Description = dealRegistration.Description__c;
      partnerLead.website = dealRegistration.Website__c;
      partnerLead.Existing_Solution_Provider__c = dealRegistration.Existing_Solution_Provider__c;
      partnerLead.Prompting_Change__c = dealRegistration.Whats_prompting_change__c;
      partnerLead.Competitors__c = dealRegistration.Competitor_s__c;
      partnerLead.Decision_Maker__c = dealRegistration.Decision_Maker__c;
      partnerLead.Currently_in_a_contract__c = dealRegistration.Currently_in_a_contract__c;
      partnerLead.Project_budget__c = dealRegistration.Budget_available_for_project__c;
      partnerLead.Forecasted_RingCentral_Video_Users__c = dealRegistration.Forecasted_RingCentral_Video_Users__c;
      partnerLead.Deal_Registration__c = dealRegistration.Id;

      partnerLead.IsNamedAccount__c = dealRegistration.IsNamedAccount__c;
      partnerLead.Avaya_Cloud_Specialist__c = dealRegistration.Avaya_Cloud_Specialist__c;//Avaya Cloud Specialist Assignment
      partnerLead.Portal_Cloud_Specialist__c = dealRegistration.Portal_Cloud_Specialist__c;//Avaya Cloud Specialist Assignment
      partnerLead.RC_Overlay__c = dealRegistration.RC_Overlay__c;
      partnerLead.Portal_Lead__c = dealRegistration.Portal_Deal__c;//PRM lead.
      partnerLead.Forecasted_Contact_Center_Users__c = dealRegistration.Forecasted_Contact_Center_Users__c;

      partnerLead.LeadPartnerID__c = dealRegistration.Partner_ID__c;
      partnerLead.Partner_Contact__c = dealRegistration.Partner_Contact__c;
      partnerLead.Partner_Account__c = dealRegistration.Partner_Account__c;
      partnerLead.Partner_Type__c = dealRegistration.Partner_Type__c;
      partnerLead.BusinessIdentity__c = dealRegistration.BusinessIdentity__c;
      partnerLead.Settlement_type__c = dealRegistration.Settlement_type__c; //Added for JIRA 8871
      partnerLead.Partners_CRM_Opporunity_ID__c = dealRegistration.Partners_CRM_Opportunity_ID__c; //added for PRM-83.
      partnerLead.Preferred_Language__c = dealRegistration.Preferred_Language__c; //Added for switzerland
      partnerLead.Type_of_Customer_or_Prospect__c = dealRegistration.Type_of_Customer_or_Prospect__c; //Added for Mitel
      partnerLead.Mitel_Data_Sharing__c = dealRegistration.Mitel_Data_Sharing__c; //Added for Mitel
	  partnerLead.Partner_Program__c = dealRegistration.Partner_Program__c;//Added for QTC-943
      partnerLead.Installation_Service_Provider__c = dealRegistration.Installation_Service_Provider__c;  //Added for LTR-673 PS Deal Reg

      // Added for BZS-9384 start
      for (CountryBusinessIdentityMapping__c countryBI : CountryBusinessIdentityMapping__c.getAll().values()){
        if (countryBI.Brand_Name__c.equalsIgnoreCase(dealRegistration.Brand_Name__c) && countryBI.Country__c.equalsIgnoreCase(dealRegistration.Country__c)){
          partnerLead.BusinessIdentity__c = countryBI.Business_Identity__c;
        }
      }
      if (partnerLead.BusinessIdentity__c == null || partnerLead.BusinessIdentity__c == ''){
        partnerLead.BusinessIdentity__c = dealRegistration.BusinessIdentity__c;
      }
      // Added for BZS-9384 end

      if (partnerAccountsMap.get(dealRegistration.Partner_Account__c) != null){
        if (dealRegistration.Brand_Name__c.indexOf('Vodafone Business with RingCentral') > -1){
          partnerLead.CurrencyISOCode = partnerAccountsMap.get(dealRegistration.Partner_Account__c).CurrencyISOCode;
        }
        partnerLead.Partner_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name;
        partnerLead.Ultimate_Parent_Account_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != NULL ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c : partnerAccountsMap.get(dealRegistration.Partner_Account__c).Id;
      }
      try{
        if (dealRegistration.Brand_Name__c.indexOf('RingCentral') == -1){
          partnerLead.Ultimate_Parent_Account_Partner_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != NULL ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__r.Partner_ID__c : partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_ID__c;

          partnerLead.Ultimate_Parent_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != NULL ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__r.Name : partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name;
        }
        else{
          //if deal belongs to master agent then Ultimate partner account and id will be master agent's
          if (partnerAccountsMap != null && dealRegistration.Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c == partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c){

            partnerLead.Ultimate_Parent_Account_Partner_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_ID__c : '';
            partnerLead.Ultimate_Parent_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name : '';

          }
          else if (partnerAccountsMap != null && dealRegistration.Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c){
            //sub partner level
            partnerLead.Ultimate_Parent_Account_Partner_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__r.Partner_ID__c : '';
            partnerLead.Ultimate_Parent_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__r.Name : '';
          }
          else if (partnerAccountsMap != null && dealRegistration.Partner_Account__c != null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_Account__c == null && partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c == null){
            // top master level
            partnerLead.Ultimate_Parent_Account_Partner_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_ID__c != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_ID__c : '';
            partnerLead.Ultimate_Parent_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name != null ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name : '';
          }

        }

      }
      catch (Exception e){
        if (partnerAccountsMap.get(dealRegistration.Partner_Account__c) != null){
          partnerLead.Ultimate_Parent_Account_Partner_ID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != NULL ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__r.Partner_ID__c : partnerAccountsMap.get(dealRegistration.Partner_Account__c).Partner_ID__c;

          partnerLead.Ultimate_Parent_Account_Name__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__c != NULL ? partnerAccountsMap.get(dealRegistration.Partner_Account__c).Parent_Partner_Account__r.Name : partnerAccountsMap.get(dealRegistration.Partner_Account__c).Name;
        }
      }

      //<T04>
      if (partnerAccountsMap.ContainsKey(dealRegistration.Partner_Account__c)){
        if (partnerAccountsMap.get(dealRegistration.Partner_Account__c).SID__c != null){
          partnerLead.SID__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).SID__c;
        }
        if (partnerAccountsMap.get(dealRegistration.Partner_Account__c).Inside_Sales_Rep__c != null){
          partnerLead.Inside_Sales_Rep__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).Inside_Sales_Rep__c;
        }
        if (partnerAccountsMap.get(dealRegistration.Partner_Account__c).VAR_Territory__c != null){
          partnerLead.VAR_Territory__c = partnerAccountsMap.get(dealRegistration.Partner_Account__c).VAR_Territory__c;
        }
      }
      //</T04>
      partnerLead.Avaya_Partnership_Lead__c = true;
      partnerLead.Marketo_Sync_Disabled__c = true;
      partnerLead.RecordTypeId = LeadHelper.RT_ID_PARTNER_LEADS;//T02
      partnerLead.Sales_Notes__c = dealRegistration.Sales_Notes__c;//T03

      if (partnerAccountsMap != null && partnerAccountsMap.ContainsKey(dealRegistration.Partner_Account__c)){

        if ((dealRegistration.Brand_Name__c.indexOf('RingCentral') != -1 || dealRegistration.Brand_Name__c.indexOf('Unify Office') != -1) && dealRegistration.Inside_Sales_Rep__c != null){
          system.debug('Inside Sales_Rep__c');
          partnerLead.Inside_Sales_Rep__c = dealRegistration.Inside_Sales_Rep__c;
        }
      }

      partnerLeads.add(partnerLead);
      if (dealRegistration.How_did_you_acquire_this_Lead__c != null && dealRegistration.How_did_you_acquire_this_Lead__c.startsWithIgnoreCase('RC_Mitel')){
        mitelLeads.add(partnerLead);
      }
    }
    insert partnerLeads;
    if (!mitelLeads.isEmpty()){
      insertMitelCampaignMembers(mitelLeads, mapDealReg);
    }
    return partnerLeads;
  }

  static void insertMitelCampaignMembers(List<Lead> mitelLeads, Map<Id, Deal_Registration__c> dealRegs){
    Map<String, Id> mitelCampaigns = new Map<String, Id>();
    List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
    try{
      for (Campaign camp : (List<Campaign>)new CampaignSelector().selectCampaignsByNameLike(new List<Object>{ '%Mitel%' }).executeQuery()){
        mitelCampaigns.put(camp.Name.toLowerCase(), camp.Id);
      }
      for (Lead ld : mitelLeads){
        String campaignName = dealRegs.get(ld.Deal_Registration__c).How_did_you_acquire_this_Lead__c.toLowerCase();
        CampaignMember newCampMember = new CampaignMember(LeadId = ld.Id);
        newCampMember.CampaignId = mitelCampaigns.containsKey(campaignName) ? mitelCampaigns.get(campaignName) : mitelCampaigns.get('mitel_agency_unassigned');
        newCampMember.Status = dealRegs.get(ld.Deal_Registration__c).AgencyRep__c != null ? 'Meeting Requested' :
                                              'Responded';
        campaignMembersToInsert.add(newCampMember);
      }
      if (campaignMembersToInsert.size() < Feature_Toggle__c.getInstance().Mitel_Campaign_Member_sync__c){
        insert campaignMembersToInsert;
      }
      else{
        CampaignMemberPlatEvents.campaignMemberCreationAsyncFromLead(campaignMembersToInsert, true);
      }
    }
    catch (Exception ex){
      ExceptionHelper.createExceptionAndNotificacionHistory(ex, mitelLeads, 'Lead Exception');
    }
  }

  public class PartnerDetailWrapper{
    public String signUpLink;
    public String currentOwner;
    public String currentOwnerName;
    public String currentOwnerEmail;
    public String currencyCode;
    public PartnerDetailWrapper(String signUpLink, String currentOwner, String currentOwnerName, String currentOwnerEmail, String currencyCode){
      this.signUpLink = signUpLink;
      this.currentOwner = currentOwner;
      this.currentOwnerName = currentOwnerName;
      this.currentOwnerEmail = currentOwnerEmail;
      this.currencyCode = currencyCode;
    }

  }

  public static PartnerDetailWrapper fetchPartnerContact(Lead leadObj){
    List<Contact> contactList = [SELECT id, Account.Signup_Link__c, Account.Current_Owner__c, Account.Current_Owner_Name__c, Account.Current_Owner_Email__c, Account.CurrencyIsoCode FROM Contact WHERE Id = :leadObj.Partner_Contact__c];
    if (contactList != null && contactList.size() > 0){
      Contact conObj = contactList[0];
      PartnerDetailWrapper partnerDetailObj = new PartnerDetailWrapper(conObj.Account.Signup_Link__c, conObj.Account.Current_Owner__c, conObj.Account.Current_Owner_Name__c, conObj.Account.Current_Owner_Email__c, conObj.Account.CurrencyIsoCode);
      return partnerDetailObj;
    }
    else{
      return null;
    }
  }

  public static partnerDetailWrapper fetchPartnerOwner(Lead leadObj){
    List<User> userList = [SELECT id, Contact.Account.Signup_Link__c, Contact.Account.Inside_Sales_Rep__c, Contact.Account.Current_Owner__c, Contact.Account.Current_Owner_Name__c, Contact.Account.Current_Owner_Email__c, Contact.Account.CurrencyIsoCode FROM User WHERE Id = :leadObj.Partner_Lead_Owner__c];
    if (userList != null && userList.size() > 0){
      User userObj = userList[0];
      PartnerDetailWrapper partnerDetailObj = new PartnerDetailWrapper(userObj.Contact.Account.Signup_Link__c, userObj.Contact.Account.Current_Owner__c, userObj.Contact.Account.Current_Owner_Name__c, userObj.Contact.Account.Current_Owner_Email__c, userObj.Account.CurrencyIsoCode);
      return partnerDetailObj;
    }
    else{
      return null;
    }
  }

  public static PartnerLeadConvertResult convertPartnerLead(Lead leadObj, Boolean createNew){
    PartnerLeadConvertResult result = new PartnerLeadConvertResult();

    TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT();
    TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE();
    TriggerHandler.BY_PASS_CONTACT_ON_INSERT();
    TriggerHandler.BY_PASS_CONTACT_ON_UPDATE();
    TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT();
    TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE();
    DG_DFR_Class.byPassDFRContact = true; /*Added (11/Aug/21) for JIRA PRM-24*/

    Lead_Qualification__c leadQualificationObj;
    map<Id, Lead_Qualification__c> mapLeadQual = new map<Id, Lead_Qualification__c>();


    List<Note> leadNotes = [Select n.Id, n.Title, n.IsPrivate, n.Body From Note n where n.ParentId = :leadObj.Id];
    String strLeadTimeZone = leadObj.Timezone__c;
    LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted = true limit 1];

    Id partnerOwnerId = UserInfo.getUserId();
    PartnerDetailWrapper partnerDetailObj = fetchPartnerContact(leadObj);
    Database.LeadConvert lc = new database.LeadConvert();
    lc.setLeadId(leadObj.id);
    lc.setOwnerId(partnerOwnerId);
    lc.setConvertedStatus(convertStatus.MasterLabel);
    Account acc;
    Contact con;
    Opportunity opp;

    try{
      AccountTriggerHandler.isPartnerLeadConversion = true;
      Database.LeadConvertResult lcr = Database.convertLead(lc);
      updateExOpportunityContactRole(lcr);
      mapOpportunityContactRole(lcr, leadQualificationObj, leadObj);
      result.status = 'success';
      result.rwErrors = null;
      result.leadRecord = leadObj;
      result.accountId = lcr.getAccountId();
      result.contactId = lcr.getContactId();
      result.opportunityId = lcr.getOpportunityId();
      acc = new Account(Id = lcr.getAccountId(), Avaya_Partnership_Account__c = true);
      con = new Contact(Id = lcr.getContactId(), Avaya_Partnership_Contact__c = true, Marketo_Sync_Disabled__c = true);
      opp = new Opportunity(Id = lcr.getOpportunityId(), Avaya_Partnership_Opportunity__c = true);
    }
    catch (Exception e){
      return null;
    }
    // Set fields on Contact/Opp/Account to what we want them to be.
    con.Description = leadObj.Description;
    con.Email = leadObj.Email;
    con.FirstName = leadObj.FirstName;
    con.LastName = leadObj.LastName;
    con.LeadSource = leadObj.LeadSource;
    con.MailingCity = leadObj.City;
    con.MailingCountry = leadObj.Country;
    con.MailingPostalCode = leadObj.PostalCode;
    con.MailingState = leadObj.State;
    con.MailingStreet = leadObj.Street;
    con.Street_2__c = leadObj.Street_2__c;
    con.Phone = leadObj.Phone;
    con.Phone_Ext__c = leadObj.Phone_Ext__c;
    con.Title = leadObj.Title;
    con.indexedPhone__c = leadObj.Phone;
    con.indexedEmail__c = leadObj.email;

    opp.Brand_Name__c = leadObj.Lead_Brand_Name__c;
    opp.RecordTypeId = OpportunityHelper.RT_ID_VAR_OPPORTUNITY;
    opp.Website__c = leadObj.Website;
    opp.Installation_Service_Provider__c = leadObj.Installation_Service_Provider__c; //Added for LTR-673 PS Deal Reg

    opp = prepareOpportunity(opp, 'New Business', leadObj);
    // Account fields are being set to null because in the beigining we were not using them. This should be reviewed.
    acc.Phone = acc.Industry = acc.Description = acc.BillingStreet = null;
    acc.BillingCity = acc.BillingCountry = acc.BillingPostalCode = acc.BillingState = acc.ShippingCity = null;
    acc.ShippingCountry = acc.ShippingPostalCode = acc.ShippingState = acc.ShippingStreet = acc.Website = null;
    acc.NumberOfEmployees = null;
    acc.BillingStreet = leadObj.Street;
    acc.BillingCountry = (leadObj.Country != null ? leadObj.Country : leadObj.Country__c);
    acc.BillingState = (leadObj.State != null ? leadObj.State : leadObj.State__c);
    acc.BillingCity = (leadObj.City != null ? leadObj.City : leadObj.City__c);
    acc.BillingPostalCode = (leadObj.PostalCode != null ? leadObj.PostalCode : leadObj.Zip_Code__c);
    acc.RC_Brand__c = leadObj.Lead_Brand_Name__c;
    acc.CurrencyIsoCode = leadObj.CurrencyIsoCode; //added for mapping fields when converting from Avaya Portal
    acc.Partner_Type__c = leadObj.Partner_Type__c;
    acc.BusinessIdentity__c = leadObj.BusinessIdentity__c;
    acc.Settlement_Type__c = leadObj.Settlement_type__c; // Added for JIRA 8871
    acc.Preferred_Language__c = leadObj.Preferred_Language__c; //Added for switzerland
    if (createNew) {
      acc.RC_Sync_Status__c = 'Pending';
    }
    if (partnerDetailObj != null){
      if (String.isNotBlank(partnerDetailObj.currentOwner)){
        acc.Current_Owner__c = partnerDetailObj.currentOwner;
        acc.Current_Owner_Name__c = partnerDetailObj.currentOwnerName;
        acc.Current_Owner_Email__c = partnerDetailObj.currentOwnerEmail;
      }

      if (leadObj.Lead_Brand_Name__c.indexOf('Vodafone Business with RingCentral') > -1){
        acc.CurrencyIsoCode = partnerDetailObj.currencyCode;
      }
    }

    acc = mapLeadToAccountFields(acc, leadObj);

    if (leadObj.Website != NULL || leadObj.NumberOfEmployees != NULL || leadObj.Industry != NULL || leadObj.Effective_No_of_Employees_Range__c != NULL || leadObj.Number_of_Locations__c != NULL){
      acc.Customer_Profile_Last_modified_Date__c = System.now();
    }

    //added for mapping fields when converting from Avaya Portal
    opp.RecordTypeId = OpportunityHelper.RT_ID_VAR_OPPORTUNITY;
    opp.Type = OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS;

    opp.Partner_Owner__c = leadObj.Partner_Lead_Owner__c;
    opp.Partner_Account__c = leadObj.Partner_Account__c;
    opp.Partner_Contact__c = leadObj.Partner_Contact__c;
    acc.Partner_Contact__c = leadObj.Partner_Contact__c;
    acc.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('Customer Account');
    acc.Partner_Account__c = leadObj.Partner_Account__c;
    acc.partner_owner__c = con.partner_owner__c = opp.partner_owner__c = leadObj.Partner_Lead_Owner__c;

    con.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');
    con.Preferred_Language__c = leadObj.Preferred_Language__c; //Added for switzerland

    // Added for BZS-8715 - start
    opp.CurrencyIsoCode = leadObj.CurrencyIsoCode;
    String businessIdentityId = '';
    String businessIdentityCurrency = '';
    for (PackageBusinessIdentityMapping__c biMapping : PackageBusinessIdentityMapping__c.getAll().values()){
      if (biMapping.Active__c && biMapping.DefaultBrand__c.equalsIgnoreCase(leadObj.Lead_Brand_Name__c) && biMapping.BiName__c.equalsIgnoreCase(leadObj.BusinessIdentity__c) && biMapping.Currency__c.equalsIgnoreCase(leadObj.CurrencyIsoCode)){
        businessIdentityId = biMapping.BiId__c;
        businessIdentityCurrency = biMapping.Currency__c;
      }
    }
    if (businessIdentityId != '' && businessIdentityCurrency != ''){
      opp.BusinessIdentity__c = OpportunityHelper.businessIdentitySerialize(Integer.ValueOf(businessIdentityId), businessIdentityCurrency);// added for BZS-8715
    }
    // Added for BZS-8715 - end

    List<AccountTeamMember> atmList = ConvertLead.accountTeamMemberAssignment(opp.Id);
    if (!atmList.isEmpty()){
      insert atmList;
      ConvertLead.byPassStrategicPartner = true;
      opp.Strategic_Partner_RC_Owner__c = opp.OwnerId;
    }

    if (leadObj.Lead_Brand_Name__c.indexOf('Vodafone Business with RingCentral') > -1){
      opp.CurrencyIsoCode = partnerDetailObj.currencyCode;
    }

    update acc;
    update opp;
    update con;

    return result;
  }

  public static void updateExOpportunityContactRole(Database.LeadConvertResult leadConvertResult){
    try{
      if (leadConvertResult.getOpportunityId() != null && leadConvertResult.getContactId() != null){
        OpportunityContactRole oppContactRoleObj = [select id, IsPrimary from OpportunityContactRole where opportunityId = :leadConvertResult.getOpportunityId() and contactId = :leadConvertResult.getContactId() order by isPrimary DESC limit 1];
        if (oppContactRoleObj != null && oppContactRoleObj.id != null){
          if (!oppContactRoleObj.IsPrimary){
            oppContactRoleObj.isPrimary = true;
            update oppContactRoleObj;
          }
        }
        else{
          OpportunityContactRole oppConRoleObj = new OpportunityContactRole(ContactId = leadConvertResult.getContactId(), OpportunityId = leadConvertResult.getOpportunityId(), isPrimary = true);
          insert oppConRoleObj;
        }
      }
    }
    catch (Exception ex){
      // ...
    }
  }

  public static void mapOpportunityContactRole(Database.LeadConvertResult leadConvertResult, Lead_Qualification__c leadQualObj, Lead leadObj){
    try{
      if (leadQualObj != null && leadQualObj.Id != null){
        if (leadQualObj.Decision_Maker_Partner__c == 'Details Below'){
          Contact contactObj = new Contact();
          contactObj.AccountId = leadConvertResult.getAccountId();
          contactObj.FirstName = leadQualObj.Decision_Maker_First_Name__c;
          contactObj.LastName = leadQualObj.Decision_Maker_Last_Name__c;
          contactObj.Email = leadQualObj.Decision_Maker_Email__c;
          contactObj.Phone = leadQualObj.Decision_Maker_Phone__c;
          contactObj.Title = leadQualObj.Decision_Maker_Business_Title__c;
          contactObj.RecordTypeId = OpportunityHelper.getOppRecordTypeMap('VAR Visible');
          contactObj.Marketo_Sync_Disabled__c = true;
          contactObj.Avaya_Partnership_Contact__c = true;
          insert contactObj;
          if (contactObj != null && contactObj.id != null){
            OpportunityContactRole oppContactRoleObj = new OpportunityContactRole();
            oppContactRoleObj.OpportunityId = leadConvertResult.getOpportunityId();
            oppContactRoleObj.ContactId = contactObj.id;
            oppContactRoleObj.Role = 'Decision Maker';
            insert oppContactRoleObj;
          }
        }
        else if (leadQualObj.Decision_Maker_Partner__c == 'Same as Contact'){
          OpportunityContactRole oppContactRoleObj = [select id from OpportunityContactRole where opportunityId = :leadConvertResult.getOpportunityId() and contactId = :leadConvertResult.getContactId() limit 1];
          if (oppContactRoleObj != null && oppContactRoleObj.id != null){
            oppContactRoleObj.Role = 'Decision Maker';
            oppContactRoleObj.isPrimary = true;
            update oppContactRoleObj;
          }
        }
      }
    }
    catch (exception ex){
      // ...
    }
  }

  public static Account mapLeadToAccountFields(Account accountObj, Lead leadObj){
    try{
      if (!String.isBlank(leadObj.Website)){
        accountObj.Website = leadObj.Website;
      }
      if (leadObj.NumberOfEmployees != null){
        accountObj.NumberOfEmployees = leadObj.NumberOfEmployees;
      }
      if (!String.isBlank(leadObj.Industry)){
        accountObj.Industry = leadObj.Industry;
      }
      if (!String.isBlank(leadObj.Effective_No_of_Employees_Range__c)){
        accountObj.No_of_Employees__c = leadObj.Effective_No_of_Employees_Range__c;
      }
      if (!String.isBlank(leadObj.Number_of_Locations__c)){
        accountObj.Number_Of_Locations__c = leadObj.Number_of_Locations__c;
      }
    }
    catch (Exception ex){
      // ...
    }
    return accountObj;
  }

  public static Opportunity prepareOpportunity(Opportunity oppObj, string businessType, Lead leadObj){
    Opportunity opp = new Opportunity(Id = oppObj.Id);
    try{
      opp.closedate = (leadObj.Estimated_Close_Date__c == null) ? Date.today() : leadObj.Estimated_Close_Date__c;
      opp.Type = businessType;
      opp.Partner_ID__c = leadObj.LeadPartnerID__c;
      opp.Installation_Service_Provider__c = leadObj.Installation_Service_Provider__c; //Added for LTR-673 PS Deal Reg
      system.debug('description: ' + leadObj.Description);
      system.debug('notes: ' + leadObj.Notes__c);
      if (leadObj.Referrer_FName__c != null || leadObj.Referrer_LName__c != null || leadObj.Referrer_Email__c != null){
        opp.Description = ' Referrer FName: ' + (leadObj.Referrer_FName__c == null ? '' : leadObj.Referrer_FName__c) + '\n Referrer LName: ' + (leadObj.Referrer_LName__c == null ? '' : leadObj.Referrer_LName__c) + '\n Referrer Email: ' + (leadObj.Referrer_Email__c == null ? '' : leadObj.Referrer_Email__c) + '\n\n' + (leadObj.Description == null ? '' : leadObj.Description);
      }
      else{
        opp.Description = leadObj.Description;
      }
      opp.StageName = OpportunityHelper.defaultOpportunityStage;
      opp.Timezone__c = leadObj.Timezone__c;  //Populate oppirtunity timezone from Lead
      if (leadObj.Agent_Email_Address__c != null) {
        opp.Agent_Email_Address__c = leadObj.Agent_Email_Address__c;
      }
      //Added for passing Support Agent e-mail to Opp

      opp.Lead_Entry_Source__c = leadObj.Lead_Entry_Source__c;
      opp.Number_of_Employees__c = leadObj.NumberOfEmployees__c;
      setOpportunityCurrency(opp, leadObj);
    }
    catch (Exception ex){
    }
    System.debug(JSON.serializePretty(opp));
    return opp;
  }

  public static void setCampaignInfluence(Lead leadObj, Opportunity opp){
    Feature_Toggle__c featureCS = Feature_Toggle__c.getInstance();
    if (!Test.isRunningTest()){
      if (featureCS == null || !featureCS.New_Campaign_Influence__c) {
        return;
      }
    }
    List<Campaign> allCampaigns = [SELECT Id, BMID__c, Non_Attributable__c, (SELECT Id, CampaignId, CreatedDate FROM CampaignMembers WHERE LeadID = :leadObj.Id) FROM Campaign];
    List<Campaign> attCampaigns = new List<Campaign>();
    CampaignMember latestCampMember;
    String BMIDtoUpdate = '';

    for (Campaign c : allCampaigns){
      if (c.Non_Attributable__c == false && c.CampaignMembers.size() > 0){
        attCampaigns.add(c);
      }
    }

    if (attCampaigns.size() > 0){
      Datetime latest = DateTime.newInstance(0);
      for (Campaign c : attCampaigns){
        for (CampaignMember m : c.CampaignMembers){
          if (m.CreatedDate > latest){
            latestCampMember = m;
            BMIDtoUpdate = c.BMID__c;
            latest = m.CreatedDate;
          }
        }
      }
      opp.CampaignId = latestCampMember.CampaignId;
      opp.BMID__c = BMIDtoUpdate;
    }
  }

  @TestVisible
  private static Id populateOppRecordType(String leadRecordTypeDevName){
    Id oppRtId = null;
    if (leadRecordTypeDevName == 'Partner_Leads'){
      oppRtId = OpportunityHelper.getOppRecordTypeMap('VAR Opportunity');
    }
    else if (leadRecordTypeDevName == 'Sales_Leads'){
      oppRtId = OpportunityHelper.getOppRecordTypeMap('New Sales Opportunity');
    }
    return oppRtId;
  }

  @TestVisible
  private static Boolean userAccountIdIsNotNull(String objUserId){
    User objUserDetail = [Select id, Contact.AccountId, Contact.Account.Partner_id__c from User where Id = :objUserId];
    String strUserAccountId = objUserDetail.Contact.AccountId;
    return !String.isEmpty(strUserAccountId);
  }

  public static Opportunity setOpportunityCurrency(Opportunity oppptyToProcess, Lead sourceLead){
    if (sourceLead.Lead_Brand_Name__c == BRAND_BT){
      oppptyToProcess.CurrencyIsoCode = 'GBP';
    }
    return oppptyToProcess;
  }

  @future
  public static void performDuplicateCheck(Set<Id> dealIds){
    performDuplicateCheckMain(dealIds);
  }

  public static List<Deal_Registration__c> performDuplicateCheckMain(Set<Id> dealIds){
    //<T01>
    string nonAvayaUsers = System.Label.Non_Avaya_Users;
    string[] listUsers = nonAvayaUsers.split(';');
    List<Deal_Registration__c> dealsPendingApp = new List<Deal_Registration__c>();
    List<Deal_Registration__c> dealsPendingAppForOpp = new List<Deal_Registration__c>();
    //</T01>
    List<Deal_Registration__c> dealsPendingAppForAcc = new List<Deal_Registration__c>();
    List<Deal_Registration__c> dealsPendingAppForRejectedDeals = new List<Deal_Registration__c>();
    //PRM-179: Added Website__c and Duplicate_Match_Opportunity__c in SOQL
    List<Deal_Registration__c> deals = [SELECT id, Email_Address__c, Status__c, Website__c, Duplicate__c, Duplicate_Match_Lead__c, Duplicate_Match_Contact__c, Duplicate_Match_Opportunity__c, Duplicate_Match_Account__c, Duplicate_Deal_Registration__c, Company_Name__c, Partner_Account__c, Brand_Name__c FROM Deal_Registration__c WHERE id = :dealIds];

    List<String> emails = new List<String>();
    List<String> emailDomains = new List<String>();
    List<String> emailSearchDomains = new List<String>();
    List<Contact> lstContactsWithMatchingEmail = new List<Contact>();
    List<Contact> lstContactsWithMatchingEmailDomain = new List<Contact>();
    Map<String, Id> mapEmailDomainNContactId = new Map<String, Id>();
    String partnerRCTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByName().get('Partner Leads').getRecordTypeId();

    for (Deal_Registration__c deal : deals){
      if (deal.Email_Address__c != null){
        emails.add(deal.Email_Address__c);
        emailDomains.add((deal.Email_Address__c).substring(((deal.Email_Address__c).indexOf('@') + 1), (deal.Email_Address__c).length()));
        emailSearchDomains.add('%' + (deal.Email_Address__c).substring(((deal.Email_Address__c).indexOf('@') + 1), (deal.Email_Address__c).length()));
      }
    }

    Map<String, Id> emailLeadMap = new Map<String, Id>();
    List<Lead> dupLead = [SELECT Id, Email FROM Lead WHERE Email IN:emails AND CreatedDate = TODAY AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND Status != '0. Downgraded' AND (Duplicate_Lead__c = NULL OR Duplicate_Lead__c = false) AND IsConverted = false AND CreatedById NOT IN:listUsers AND Lead_Brand_Name__c != 'BT Business'//<T01>
     ORDER BY CreatedDate DESC];

    for (Lead obj : dupLead){
      if (emailLeadMap.get(obj.Email) == null) {
        emailLeadMap.put(obj.Email.toLowerCase(), obj.Id);
      }
    }

    // preveting the duplicate leads to be created
    for (Deal_Registration__c deal : deals){
      if (emailLeadMap.containsKey(deal.Email_Address__c.toLowerCase())){
        deal.Duplicate__c = true;
        deal.Duplicate_Match_Lead__c = emailLeadMap.get(deal.Email_Address__c.toLowerCase());
      }
    }

    // validatePerStatus
    dupLead = [SELECT Id, Email FROM Lead WHERE Email IN:emails AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND (Duplicate_Lead__c = null OR Duplicate_Lead__c = false) AND IsConverted = false AND Status IN ('1.5 Call Out', '2. Contacted') AND CreatedById NOT IN:listUsers AND Lead_Brand_Name__c != 'BT Business' //<T01>
     ORDER BY CreatedDate DESC];

    emailLeadMap = new Map<String, Id>();
    for (Lead obj : dupLead){
      if (emailLeadMap.get(obj.Email) == null) {
        emailLeadMap.put(obj.Email.toLowerCase(), obj.Id);
      }
    }

    // preveting the duplicate leads to be created
    for (Deal_Registration__c deal : deals){
      if (emailLeadMap.containsKey(deal.Email_Address__c.toLowerCase())){
        deal.Duplicate__c = true;
        deal.Duplicate_Match_Lead__c = emailLeadMap.get(deal.Email_Address__c.toLowerCase());
      }
    }

    // validatePerStages
    Map<String, String> accountsMap = new Map<String, String>();
    Map<String, String> accountContactMap = new Map<String, String>();
    Map<String, Id> emailContactMap = new Map<String, Id>();
    List<String> emailsNotConsider = new List<String>{ '%@ringcentral.com' };

    Contact[] contactList = [SELECT Id, Name, AccountId, Email, Contact.Account.Name FROM Contact WHERE (email IN:emails or email like:emailSearchDomains) AND Email != 'fake@email.com' AND Email != 'fake@fake.com' AND ( NOT Email like:emailsNotConsider) ORDER BY CreatedDate DESC];

    for (Contact c : contactList){
      if (c.Email != null){
        if (emails.contains(c.email)){
          lstContactsWithMatchingEmail.add(c);
        }
        else{
          lstContactsWithMatchingEmailDomain.add(c);
        }
      }
    }
    for (Contact c : lstContactsWithMatchingEmailDomain){
      mapEmailDomainNContactId.put(c.Email.substring(((c.Email).indexOf('@') + 1), (c.Email).length()), c.Id);
    }
    for (Deal_Registration__c deal : deals){
      if (mapEmailDomainNContactId.containsKey((deal.Email_Address__c).substring(((deal.Email_Address__c).indexOf('@') + 1), (deal.Email_Address__c).length()))){
        deal.Duplicate__c = true;
        deal.Duplicate_Match_Contact__c = mapEmailDomainNContactId.get((deal.Email_Address__c).substring(((deal.Email_Address__c).indexOf('@') + 1), (deal.Email_Address__c).length()));
      }
    }
    for (Contact c : lstContactsWithMatchingEmail){
      if (c.AccountId != null){
        accountsMap.put(c.AccountId, c.Email);
        accountContactMap.put(c.AccountId, c.Id);
      }
    }

    List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId in:accountsMap.keySet() AND StageName IN:OpportunityHelper.alteredStages ORDER BY CreatedDate DESC]);
    for (Opportunity oppObj : oppList){
      if (accountsMap.containsKey(oppObj.AccountId) != null){
        String email = accountsMap.get(oppObj.AccountId);
        if (emailContactMap.get(email) == null) {
          emailContactMap.put(email, accountContactMap.get(oppObj.AccountId));
        }
      }
    }

    for (Deal_Registration__c deal : deals){
      if (emailContactMap.containsKey(deal.Email_Address__c.toLowerCase())){
        deal.Duplicate__c = true;
        deal.Duplicate_Match_Contact__c = emailContactMap.get(deal.Email_Address__c.toLowerCase());
      }
    }

    dealsPendingApp = PartnerDealRegistrationUtil.checkDealBelongsToBlockedDomain(deals, emailDomains);
    //PRM-179: Added duplicate check logic for VAR and New Sales Opportunities
    dealsPendingAppForOpp = PartnerDealRegistrationUtil.checkDealForDuplicateOpp(dealsPendingApp);
    dealsPendingAppForAcc = PartnerDealRegistrationUtil.checkDealForDuplicateAccount(dealsPendingAppForOpp);
    dealsPendingAppForRejectedDeals = PartnerDealRegistrationUtil.checkDealForDuplicateDealReg(dealsPendingAppForAcc);
    for (Deal_Registration__c deal : dealsPendingAppForRejectedDeals){
      if (deal.Brand_Name__c == 'Vodafone Business with RingCentral'){
        deal.Status__c = 'Approved';
      }
      if (deal.Duplicate__c == false){
        deal.Status__c = 'Approved';
      }else{
        deal.Status__c = 'Pending Approval';
      }
    }

    update dealsPendingAppForRejectedDeals;
    return dealsPendingAppForRejectedDeals;
  }

  public static String getSelectedPartnerId(){
    String selectedPartnerAccount;
    try{
      Id sysAdminProfileId;
      List<Profile> sysAdminProfile = [SELECT id, Name FROM Profile Where Name = :Label.System_Administrator];

      if (!sysAdminProfile.isEmpty()){
        sysAdminProfileId = sysAdminProfile[0].Id;
      }


      if (UserInfo.getProfileId() == sysAdminProfileId){

        if (Test.isRunningTest()){
            selectedPartnerAccount = PartnerRecordsUtil.avayaMasterAccount.Id;
        }
      }
      else{
        User u = [SELECT Id, Name, ContactId, Contact.AccountId, Partner_Account_Id__c FROM User WHERE Id = :UserInfo.getUserId()];
        selectedPartnerAccount = u.Contact.AccountId;
      }

    }
    catch (Exception e){
      System.debug(e.getMessage());
    }
    return selectedPartnerAccount;
  }

  public static String getCurrentUserPartnerAccount(){
    User currentUser = new User();
    Id sysAdminProfileId;
    List<Profile> sysAdminProfile = [SELECT id, Name FROM Profile Where Name = :Label.System_Administrator];

    if (!sysAdminProfile.isEmpty()){
      sysAdminProfileId = sysAdminProfile[0].Id;
    }
    if (UserInfo.getProfileId() != sysAdminProfileId){
      List<User> users = [SELECT Id, Name, ContactId, Contact.AccountId, Contact.Account.Partner_Account__c FROM User WHERE Id = :UserInfo.getUserId()];
      if (null != users && users.size() > 0){
        currentuser = users.get(0);
      }
    }

    return currentUser.Contact.Account.Partner_Account__c;
  }

  //To get current user's contact Full Access to portal
  public static String getCurrentUserPartnerContactAccess(){
    User currentUser = new User();
    List<User> users = [SELECT Id, Name, ContactId, Contact.AccountId, Contact.Account.Partner_Account__c, Contact.Partner_Portal_View__c FROM User WHERE Id = :UserInfo.getUserId()];
    if (null != users && !users.isEmpty() && users.size() > 0){
      currentuser = users.get(0);
    }
    return currentUser.Contact.Partner_Portal_View__c;
  }

  public static List<Contact> getCurrentUserPartnerContact(){
    List<Contact> listOfCurrentContacts = new List<Contact>();
    List<User> users = [SELECT Id, Name, ContactId, Contact.AccountId, Contact.Account.Partner_Account__c, Contact.Partner_Portal_View__c, Contact.Partner_Geography__c FROM User WHERE Id = :UserInfo.getUserId()];
    system.debug('User Info - ' + UserInfo.getUserId());
    if (users != null && !users.isEmpty() && users.size() > 0){
      system.debug('yes, there is user');
      system.debug('user size - ' + users.size());
      listOfCurrentContacts.add(users.get(0).Contact);
    }
    Id sysAdminProfileId = [SELECT id, Name FROM Profile Where Name = 'System Administrator'].Id;
    if (userInfo.getProfileId() == sysAdminProfileId){
      if (Test.isRunningTest()){
        listOfCurrentContacts.clear();
        listOfCurrentContacts.add(partnerRecordsUtil.partnerContact);
      }
    }
    system.debug('users - ' + users);
    system.debug('listOfCurrentContacts - ' + listOfCurrentContacts);
    system.debug('listOfCurrentContacts size - ' + listOfCurrentContacts.size());
    return listOfCurrentContacts;
  }

  public static String getContactAccount(String contactId){
    Contact contact = new Contact();
    List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId];
    if (null != contacts && contacts.size() > 0){
      contact = contacts.get(0);
    }
    return contact.AccountId;
  }

  public static boolean isAvayaUser(){
    CommunityInfo comInf = new CommunityInfo();
    Community_Details__mdt comDetail = CommunityInfo.getCommunityDetails();

    boolean retVal = false;
    if (getSelectedPartnerId() == comDetail.Portal_Top_Master_Account_Id__c){
      retVal = true;
    }
    return retVal;
  }

  public class PartnerLeadConvertResult{
    public String status{ get; set; }

    public List<String> rwErrors{ get; set; }

    public Lead leadRecord{ get; set; }

    public String accountId{ get; set; }

    public String contactId{ get; set; }

    public String opportunityId{ get; set; }

  }

  public static List<Deal_Registration__c> checkDealBelongsToBlockedDomain(List<Deal_Registration__c> newDealLst, List<String> dealEmailDomains){
    String dealDomain = '';
    String emailAddr = '';
    List<String> blockedDomains = new List<String>();
    List<Deal_Registration__c> dealLst = new List<Deal_Registration__c>();
    blockedDomains = getBlockedDomains(dealEmailDomains);
    if (blockedDomains.size() > 0){
      for (Deal_Registration__c dealObj : newDealLst){
        emailAddr = dealObj.Email_Address__c;
        if (emailAddr != null){
          dealDomain = (emailAddr).substring((emailAddr.indexOf('@') + 1), emailAddr.length());
          //PRM-179: Removing generic domain criteria for all brands except Vodafone
          if (blockedDomains.contains(dealDomain) && dealObj.Brand_Name__c == System.Label.Vodafone_Business_API_Name){
            dealObj.Duplicate__c = true;
            dealObj.Is_Pending_Due_to_Domain__c = true;
          }
        }
        dealLst.add(dealObj);
      }
    }
    else{
      return newDealLst;
    }

    return dealLst;
  }

  public static List<String> getBlockedDomains(List<String> dealEmailDomains){
    List<String> blockedDomains = new List<String>();
    if (dealEmailDomains != null && !dealEmailDomains.isEmpty()){
      for (Avaya_Blocked_Domain__mdt abdObj : [Select Id, Domain_Name__c from Avaya_Blocked_Domain__mdt where Domain_Name__c in:dealEmailDomains]){
        blockedDomains.add(abdObj.Domain_Name__c);
      }
    }
    return blockedDomains;
  }

  //PRM-179: Added duplicate check logic for VAR and New Sales Opportunities
  public static List<Deal_Registration__c> checkDealForDuplicateOpp(List<Deal_Registration__c> newDealLst){
    List<String> oppNameLst = new List<String>();
    List<String> companyNameLst = new List<String>();
    List<Deal_Registration__c> dealLst = new List<Deal_Registration__c>();

    for (Deal_Registration__c dealOb : newDealLst){
      if (dealOb.Company_Name__c != null && dealOb.Brand_Name__c != System.Label.Vodafone_Business_API_Name){
        companyNameLst.add(dealOb.Company_Name__c);
      }
    }
    List<Opportunity> oppList = new List<Opportunity>();
    List<String> newSOppStageNames = new List<String>{ '1. Qualify', '2. Problem', '3. Solution', '4. Proof', '5. Agreement', '6. Order' };
    List<String> varOppStageNames = new List<String>{ '4. Proof', '5. Agreement', '6. Order' };
    if (companyNameLst.size() > 0){
      oppList = [select Id, Name from Opportunity where (name in:companyNameLst and RecordTypeName__c = 'VAR Opportunity' and StageName in:varOppStageNames) or (name in:companyNameLst and RecordTypeName__c = 'New Sales Opportunity' and StageName in:newSOppStageNames)];
    }
    Map<String, Id> oppMap = new Map<String, Id>();
    if (oppList.size() > 0){
      for (Opportunity objOpp : oppList){
        if (objOpp.Name != null){
          oppNameLst.add((objOpp.Name).toLowerCase());
          oppMap.put((objOpp.Name).toLowerCase(), objOpp.Id);
        }
      }
    }
    if (oppNameLst.size() > 0){
      for (Deal_Registration__c dealObj : newDealLst){
        //null check
        if (dealObj.Company_Name__c != null){
          if (oppNameLst.contains((dealObj.Company_Name__c).toLowerCase())){
            dealObj.Duplicate__c = true;
            if (oppMap.containsKey((dealObj.Company_Name__c).toLowerCase())) {
              dealObj.Duplicate_Match_Opportunity__c = oppMap.get((dealObj.Company_Name__c).toLowerCase());
            }
          }
        }
        dealLst.add(dealObj);
      }
    }
    else{
      return newDealLst;
    }
    return dealLst;
  }

  //PRM-179: Added Website rule in duplicate check logic for customer accounts
  public static List<Deal_Registration__c> checkDealForDuplicateAccount(List<Deal_Registration__c> newDealLst){

    List<String> accNameLst = new List<String>();
    List<String> accWebSiteLst = new List<String>();
    List<String> companyNameLst = new List<String>();
    List<String> webSiteNameLst = new List<String>();
    List<Deal_Registration__c> dealLst = new List<Deal_Registration__c>();

    for (Deal_Registration__c dealObjForLike : newDealLst){
      if (dealObjForLike.Company_Name__c != null) {
        companyNameLst.add(dealObjForLike.Company_Name__c);
      }
      if (dealObjForLike.Website__c != null) {
        webSiteNameLst.add(String.valueOf(dealObjForLike.Website__c));
      }
    }
    List<Account> accntList = new List<Account>();
    //PRM-179:Excluding following Account statuses from matching logic
    List<String> accStatusesToExclude = new List<String>{ '', 'Canceled', 'Disabled', 'DWH Sync pending', 'Test' };
    Id cusAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
    if (companyNameLst.size() > 0 || webSiteNameLst.size() > 0){
      accntList = [select Id, Name, Website from Account where RecordTypeId = :cusAccRecTypeId and (name in:companyNameLst or Website in:webSiteNameLst) and RC_Account_Status__c not in:accStatusesToExclude];
    }
    Map<String, Id> accMap = new Map<String, Id>();
    Map<String, Id> accWebSiteMap = new Map<String, Id>();
    if (accntList.size() > 0){
      for (Account objAcc : accntList){
        if (objAcc.Name != null){
          accNameLst.add((objAcc.Name).toLowerCase());
          accMap.put((objAcc.Name).toLowerCase(), objAcc.Id);
        }
        if (objAcc.Website != null){
          accWebSiteLst.add(String.ValueOf(objAcc.Website).toLowerCase());
          accWebSiteMap.put(String.ValueOf(objAcc.Website).toLowerCase(), objAcc.Id);
        }
      }
    }
    if (accNameLst.size() > 0 || accWebSiteLst.size() > 0){
      for (Deal_Registration__c dealObj : newDealLst){
        //null check
        if ((dealObj.Company_Name__c != null && accNameLst.contains((dealObj.Company_Name__c).toLowerCase())) || (dealObj.Website__c != null && accWebSiteLst.contains(String.ValueOf(dealObj.Website__c).toLowerCase()))){
          dealObj.Duplicate__c = true;
          if (accMap.containsKey((dealObj.Company_Name__c).toLowerCase())){
            dealObj.Duplicate_Match_Account__c = accMap.get((dealObj.Company_Name__c).toLowerCase());
          }
          else if (accWebSiteMap.containsKey(String.ValueOf(dealObj.Website__c).toLowerCase())){
            dealObj.Duplicate_Match_Account__c = accWebSiteMap.get(String.ValueOf(dealObj.Website__c).toLowerCase());
          }
        }
        dealLst.add(dealObj);
      }
    }
    else{
      return newDealLst;
    }
    return dealLst;
  }

  public static List<Deal_Registration__c> checkDealForDuplicateDealReg(List<Deal_Registration__c> newDealLst){

    Map<String, Id> emailDealRegMap = new Map<String, Id>();
    List<String> emails = new List<String>();

    for (Deal_Registration__c deal : newDealLst){
      if (deal.Email_Address__c != null){
        emails.add(deal.Email_Address__c);
      }
    }

    List<Deal_Registration__c> dupReg = [SELECT Id, Email_Address__c FROM Deal_Registration__c WHERE Email_Address__c IN:emails and Status__c = 'Rejected' and ( Not id in:newDealLst) ORDER BY CreatedDate DESC];

    for (Deal_Registration__c obj : dupReg){
      if (emailDealRegMap.get(obj.Email_Address__c) == null) {
        emailDealRegMap.put(obj.Email_Address__c.toLowerCase(), obj.Id);
      }
    }

    // preveting the duplicate leads to be created
    for (Deal_Registration__c deal : newDealLst){
      if (emailDealRegMap.containsKey(deal.Email_Address__c.toLowerCase())){
        deal.Duplicate__c = true;
        deal.Duplicate_Deal_Registration__c = emailDealRegMap.get(deal.Email_Address__c.toLowerCase());
      }
    }
    return newDealLst;
  }

}
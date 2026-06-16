/*
	Lead_Before on Lead trigger event BeforeInsert for
	Common Class to Search Lead and Contacts based On Email, Phone and Domain for BT Web service and Protection Rule Logic.
*/
public class RcDealHealper {

    /**************************************************STATIC VARIABLE DECLARATION*********************************************************/
    public static map<String,List<Lead>> emailLeadMap = new map<String,List<Lead>>();
    public static map<String,List<Contact>> emailContactMap = new map<String,List<Contact>>();
    public static map<String,List<Lead>> domainLeadMap = new map<String,List<Lead>>();
    public static map<String,List<Contact>> domainContactMap = new map<String,List<Contact>>();
    public static map<String,List<Lead>> phoneLeadMap = new map<String,List<Lead>>();
    public static map<String,List<Contact>> phoneContactMap = new map<String,List<Contact>>();

    private static final Set<String> DOMAINS_TO_SKIP_IN_LEAD_CONTACT_SEARCH = getDomainsToSkipInLeadContactSearch();

    /**************************************************************************************************************************************/

    /***************Method to search Lead and Contact on basis of Phone and Email For Single Lead************************/
    public searchResultClass LeadContactSearch(String emailId, String phoneNumber){
        String  domain;
        String formattedNumber = getFormattedPhone(phoneNumber);
        String conditionString = ' email =:emailId OR Phone =:phoneNumber OR Phone =:formattedNumber';
        String subConditionString = ' ORDER BY PartnerDeal_Registration_Expiration_Date__c DESC NULLS LAST LIMIT 1000';
        String leadQueryString = 'SELECT Id, PartnerDeal_Status__c, PartnerDeal_Registration_Expiration_Date__c, PartnerDeal_Registration_ID__c, RecordType.Name, Status FROM Lead WHERE IsConverted = false AND ';
        String contactExcludeRecordType = 'Internal Employee';
        String contactQueryString = 'SELECT Id, PartnerDeal_Status__c, PartnerDeal_Registration_Expiration_Date__c, PartnerDeal_Registration_ID__c, RecordType.Name, Account.RC_Account_Status__c FROM contact WHERE RecordType.Name != :contactExcludeRecordType AND ';
        List<Lead> leadList = new List<Lead>();
        List<Contact> contactList = new List<Contact>();
        searchResultClass resultClass;
        if(emailId != null){
            domain = getEmailDomain(emailId);
        }

        List<Segment_Data__c> DomainList = [SELECT Id, Attribute_1__c, Type__c from Segment_Data__c WHERE Attribute_1__c =:domain];
        resultClass = new searchResultClass();
        if(DomainList == null || DomainList.size() == 0){
            conditionString += ' OR email LIKE \'%@'+String.escapeSingleQuotes(domain.trim())+'\'';
        }
        conditionString = '('+conditionString+')';
        leadQueryString += conditionString + subConditionString;
        contactQueryString += conditionString + subConditionString;
        leadList = Database.query(leadQueryString);
        contactList = Database.query(contactQueryString);
        resultClass.leadResultList = leadList;
        resultClass.contactResultList = contactList;
        return resultClass;
    }
    /***************************************************************************************************************************/

    /*****************Method to get domain from email*********************************/
    public static String getEmailDomain(String emailId){
        String domain = emailId.substring(emailId.lastIndexOf('@')+1,emailId.length());
        return domain;
    }
    /*********************************************************************************/

    /****************Wrapper classes*****************/
    public class searchResultClass{
        public List<Lead> leadResultList{get;set;}
        public List<Contact> contactResultList{get;set;}
    }
    /***********************************************/

    /******************Method to fetch Contacts and Leads on basis of Phone and Email for bulk data*********************/
    public static map<string,searchResultClass> LeadContactSearch(List<Lead> newLeadList,map<String,String> prOwnerMap,
    																Map<String, Boolean> resultMap,Set<string> excludedPRUserIdSet){
    	Set<String> phoneSet = new Set<String>();
    	Set<String> emailSet = new Set<String>();
    	map<String,phoneFormatWrapper> phoneFormatWrapperMap = new map<String,phoneFormatWrapper>();
    	map<String,RcDealHealper.searchResultClass> leadContactSearchMap = new map<String,RcDealHealper.searchResultClass>();
    	map<string,boolean> validDomainMap = new map<string,boolean>();
    	for(Lead leadObj : newLeadList){
            if (leadObj.Bypass_PR__c) {
                continue;
            }
            if (leadObj.LeadSource == 'Other' || leadObj.RecordTypeName__c == 'Partner_Leads') {
                continue;
            }
            if (resultMap.get(leadObj.FirstName + '_' + leadObj.LastName) == true) {
                continue;
            }

            if(string.isNotBlank(leadObj.Email)){
                String domain = RcDealHealper.getEmailDomain(leadObj.Email.trim());
                emailSet.add(leadObj.Email);
                if (DOMAINS_TO_SKIP_IN_LEAD_CONTACT_SEARCH.contains(domain) == false) {
                    validDomainMap.put(domain, false);
                }
            }
            if(String.isNotBlank(leadObj.Phone)){
                phoneFormatWrapper phoneFormatWrapperObj = new phoneFormatWrapper();
                phoneFormatWrapperObj = RcDealHealper.formatPhoneNumber(leadObj.Phone);
                phoneFormatWrapperMap.put(leadObj.Phone,phoneFormatWrapperObj);

                phoneSet.add(leadObj.Phone);

                if(string.isNotBlank(phoneFormatWrapperObj.formattedNumber)){
                    phoneSet.add(phoneFormatWrapperObj.formattedNumber);
                }
                if(string.isNotBlank(phoneFormatWrapperObj.plusOnePhoneFormat)){
                    phoneSet.add(phoneFormatWrapperObj.plusOnePhoneFormat);
                }
            }
    	}

    	System.debug('=emailSet='+emailSet+'=phoneSet='+phoneSet+'=validDomainMap='+validDomainMap.keySet());

    	set<string> finalDomainSet = new set<string>();
        if(validDomainMap!=null && validDomainMap.size() > 0){
    		for(Segment_Data__c segmentObj : [SELECT ID,Attribute_1__c,Type__c FROM Segment_Data__c WHERE Attribute_1__c in : validDomainMap.keySet()]){
	 			validDomainMap.put(segmentObj.Attribute_1__c,true);
    		}
    		for(String domainStr : validDomainMap.keySet()){
    			if(validDomainMap.get(domainStr)==false){
    				finalDomainSet.add(domainStr);
    			}
    		}
    	}

     	Set<String> contactRecordType = new Set<String>{'VAR Visible','Internal'};
     	Set<String> accountRecordType = new Set<String> {'Customer Account'};

        List<Lead> leadList = new List<Lead>();
        List<Contact> contactList = new List<Contact>();


        if(emailSet!=null && emailSet.size() > 0){


        	String leadQueryString = 'SELECT Id,Phone,Email,Is_Protected__c,ownerId,owner.IsActive,LeadPartnerID__c,Inside_Sales_Rep__c,Partner_Contact__c,Partner_Lead_Owner__r.isActive,Partner_Lead_Owner__c,Partner_Lead_Source__c,RecordTypeId,Partner_Account_Name__c,Partner_Account__c,Ultimate_Parent_Account_Partner_ID__c,Ultimate_Parent_Account_Name__c,Current_Owner_Name__c,VAR_Territory__c,Street,City,State,Country,PostalCode From Lead where IsConverted = false AND (Email IN : emailSet OR Phone IN : phoneSet OR Domain__c IN : finalDomainSet) AND (Is_Protected__c = true AND Owner.IsActive = true) AND (OwnerId NOT IN : excludedPRUserIdSet) ';
            String contactQueryString = 'SELECT Id,AccountId,Account.RC_User_ID__c,Account.RecordType.Name,Account.Partner_Contact__c,Account.Partner_Owner__c,Account.Partner_Owner__r.isActive,Account.Name,Account.Partner_Account_Name__c,Account.Current_Owner__c,Account.Current_Owner__r.IsActive,Phone,Email,Account.Partner_ID__c,Account.Inside_Sales_Rep__c,Account.Ultimate_Parent_Partner_ID__c,Account.Ultimate_Parent_Account_Name__c,Account.VAR_Territory__c,Account.Current_Owner__r.Name,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode From contact where (Email IN : emailSet OR Phone IN : phoneSet OR Domain__c IN : finalDomainSet) AND (RecordType.Name In : contactRecordType) ';

        	String subConditionString = ' ORDER BY CreatedDate DESC ';

        	leadQueryString+=subConditionString;
			contactQueryString+=subConditionString;

			system.debug('leadQueryString='+leadQueryString);
        	system.debug('contactQueryString='+contactQueryString);

        	leadList = Database.query(leadQueryString);
        	contactList = Database.query(contactQueryString);

        	if( ( leadList!=null && leadList.size() > 0 ) || ( contactList!=null && contactList.size() > 0 ) ){
	        	createPhoneEmailMaps(leadList,contactList,emailSet,phoneSet,finalDomainSet,leadContactSearchMap);
	        	createLeadContactSearchMap(newLeadList,phoneFormatWrapperMap,leadContactSearchMap);
        	}

        }

        system.debug('=emailLeadMap='+emailLeadMap);
        system.debug('=emailContactMap='+emailContactMap);
        system.debug('=phoneLeadMap='+phoneLeadMap);
        system.debug('=phoneContactMap='+phoneContactMap);
        system.debug('=leadContactSearchMap='+leadContactSearchMap);

        return leadContactSearchMap;
    }
    /*******************************************************************************************************************************/

    /******************Method to create Map on the basis of Email and Phone on searched result***********************************/
    public static void createPhoneEmailMaps(List<Lead>leadList, List<Contact> contactList, Set<String> emailSet,Set<String> phoneSet,
    										Set<String> finalDomainSet,map<String,RcDealHealper.searchResultClass> leadContactSearchMap){
    	for(Lead leadObj : leadList){
        	if(!string.isBlank(leadObj.Email) && (emailSet.contains(leadObj.Email))){
        		if(emailLeadMap!=null && emailLeadMap.get(leadObj.Email) == null){
        			emailLeadMap.put(leadObj.Email,new List<Lead>{leadObj});
        		}
        	}
        	if(!string.isBlank(leadObj.Email) && finalDomainSet.contains(RcDealHealper.getEmailDomain(leadObj.Email.trim()))){
        		if(domainLeadMap!=null && domainLeadMap.get(RcDealHealper.getEmailDomain(leadObj.Email.trim())) == null){
        			domainLeadMap.put(RcDealHealper.getEmailDomain(leadObj.Email.trim()),new List<Lead>{leadObj});
        		}
        	}

        	if(!string.isBlank(leadObj.Phone) && phoneSet.contains(leadObj.Phone) ){
        		if(phoneLeadMap!=null && phoneLeadMap.get(leadObj.Phone) == null){
        			phoneLeadMap.put(leadObj.Phone,new List<Lead>{leadObj});
        		}
        	}
        }

        for(Contact conObj : contactList){
	        	if(!string.isBlank(conObj.Email) && (emailSet.contains(conObj.Email))){
	        		if(emailContactMap!=null && emailContactMap.get(conObj.Email)==null){
	        			emailContactMap.put(conObj.Email,new List<Contact>{conObj});
	        		}
	        	}
	        	if(!string.isBlank(conObj.Email) && finalDomainSet.contains(RcDealHealper.getEmailDomain(conObj.Email.trim()))){
	        		if(domainContactMap!=null && domainContactMap.get(RcDealHealper.getEmailDomain(conObj.Email.trim()))==null){
	        			domainContactMap.put(RcDealHealper.getEmailDomain(conObj.Email.trim()),new List<Contact>{conObj});
	        		}
	        	}

	        	if(!string.isBlank(conObj.Phone) && phoneSet.contains(conObj.Phone) ){
	        		if(phoneContactMap!=null && phoneContactMap.get(conObj.Phone)==null){
	        			phoneContactMap.put(conObj.Phone,new List<Contact>{conObj});
	        		}
	        	}
        	//}
        }
    }
    /*****************************************************************************************************************************************/

    /*********************Create Unique "Email+Phone" as a key for Map to get searched List of Lead and Contacts*******************************/
    public static void createLeadContactSearchMap(List<Lead> newLeadList,map<String,phoneFormatWrapper> phoneFormatWrapperMap,
    												map<String,RcDealHealper.searchResultClass> leadContactSearchMap){
    	for(Lead leadObj : newLeadList){
        	String uniqueKey = ( !string.isBlank(leadObj.Email) ? leadObj.Email : '') + ( !string.isBlank(leadObj.Phone) ? leadObj.Phone : '');
        	searchResultClass resultClass = new searchResultClass();
        	resultClass.leadResultList = new List<Lead>();
        	resultClass.contactResultList = new List<Contact>();
        	if(!string.isBlank(leadObj.Email)){
        		if(emailLeadMap!=null && emailLeadMap.get(leadObj.Email)!=null){
        			resultClass.leadResultList.addAll(emailLeadMap.get(leadObj.Email));
        			leadContactSearchMap.put(uniqueKey,resultClass);
        		}
        		if(emailContactMap!=null && emailContactMap.get(leadObj.Email)!=null){
        			resultClass.contactResultList.addAll(emailContactMap.get(leadObj.Email));
        			leadContactSearchMap.put(uniqueKey,resultClass);
        		}
        		if(domainLeadMap!=null && domainLeadMap.get(RcDealHealper.getEmailDomain(leadObj.Email.trim()))!=null){
        			resultClass.leadResultList.addAll(domainLeadMap.get(RcDealHealper.getEmailDomain(leadObj.Email.trim())));
        			leadContactSearchMap.put(uniqueKey,resultClass);
        		}
        		if(domainContactMap!=null && domainContactMap.get(RcDealHealper.getEmailDomain(leadObj.Email.trim()))!=null){
        			resultClass.contactResultList.addAll(domainContactMap.get(RcDealHealper.getEmailDomain(leadObj.Email.trim())));
        			leadContactSearchMap.put(uniqueKey,resultClass);
        		}

        	}
        	if(!string.isBlank(leadObj.Phone)){
        		String formattedNumber = ( phoneFormatWrapperMap!=null &&
        								   phoneFormatWrapperMap.get(leadObj.Phone)!=null &&
        								   !string.isBlank(phoneFormatWrapperMap.get(leadObj.Phone).formattedNumber)
        									? phoneFormatWrapperMap.get(leadObj.Phone).formattedNumber : '');
        		String plusOnePhoneFormat = ( phoneFormatWrapperMap!=null &&
        								   phoneFormatWrapperMap.get(leadObj.Phone)!=null &&
        								   !string.isBlank(phoneFormatWrapperMap.get(leadObj.Phone).plusOnePhoneFormat)
        									? phoneFormatWrapperMap.get(leadObj.Phone).plusOnePhoneFormat : '');

        		if(leadContactSearchMap!=null && leadContactSearchMap.get(uniqueKey)!=null){
        			resultClass = leadContactSearchMap.get(uniqueKey);
        		}

        		if(phoneLeadMap!=null && phoneLeadMap.get(leadObj.Phone)!=null){
        			resultClass.leadResultList.addAll(phoneLeadMap.get(leadObj.Phone));
        		}

        		if(phoneLeadMap!=null && phoneLeadMap.get(formattedNumber)!=null){
        			resultClass.leadResultList.addAll(phoneLeadMap.get(formattedNumber));
        		}

        		if(phoneLeadMap!=null && phoneLeadMap.get(plusOnePhoneFormat)!=null){
        			resultClass.leadResultList.addAll(phoneLeadMap.get(plusOnePhoneFormat));
        		}

        		if(phoneContactMap!=null && phoneContactMap.get(leadObj.Phone)!=null){
        			resultClass.contactResultList.addAll(phoneContactMap.get(leadObj.Phone));
        		}

        		if(phoneContactMap!=null && phoneContactMap.get(leadObj.Phone)==null && phoneContactMap.get(formattedNumber)!=null){
        			resultClass.contactResultList.addAll(phoneContactMap.get(formattedNumber));
        		}

        		if(phoneContactMap!=null && phoneContactMap.get(plusOnePhoneFormat)!=null){
        			resultClass.contactResultList.addAll(phoneContactMap.get(plusOnePhoneFormat));
        		}

        		leadContactSearchMap.put(uniqueKey,resultClass);
        	}
        }
    }
    /********************************************************************************************************************************/

    /***************Format the Phone Number and return its wrapper Object******************************/
    public static phoneFormatWrapper formatPhoneNumber(string phoneNumber){
        String strPhoneValue = phoneNumber.trim();
        phoneFormatWrapper wrapperObj = new phoneFormatWrapper();
        if(strPhoneValue!=''){
            if(strPhoneValue.startsWith('+44') || strPhoneValue.startsWith('44') || strPhoneValue.startsWith('0')){
                wrapperObj.formattedNumber = ValidationUtility.validatePhoneNumber(strPhoneValue,'UK');
            }else{
                wrapperObj.formattedNumber = ValidationUtility.commonUSandCAPhoneFormat(strPhoneValue);
            }
            if(!strPhoneValue.startsWith('+44') && !strPhoneValue.startsWith('44') && !strPhoneValue.startsWith('0')){
                wrapperObj.plusOnePhoneFormat = '1' + strPhoneValue;
            }
        }
        return wrapperObj;
    }
    /************************************************************************************************/

    /*****************************Return Formated Phone Number******************************************/
	public String getFormattedPhone(String phoneNumber){
        String formattedNumber = '';
        if(phoneNumber!=''){
            if(phoneNumber.startsWith('+44') || phoneNumber.startsWith('44') || phoneNumber.startsWith('0')){
                formattedNumber = ValidationUtility.validatePhoneNumber(phoneNumber,'UK');
            }else{
                formattedNumber = ValidationUtility.commonUSandCAPhoneFormat(phoneNumber);
            }
        }
        return formattedNumber;
    }
    /*************************************************************************************************/

    /*******************************Returns the Brand Name******************************************/
    public static String getBTBrand(){
    	String strBTBrand;
    	if(!Test.isRunningTest()){
	        String brandId = Brand_List__c.getAll().get('BT_Brand').Brand_Id__c;
	        String brandName = Brand_List__c.getAll().get('BT_Brand').Brand_Name__c;
	        String brandExtName = Brand_List__c.getAll().get('BT_Brand').Brand_Name_External__c;
	        if(String.isNotBlank(brandId)){
	        	strBTBrand = brandId;
	        }else if(String.isNotBlank(brandName)){
	        	strBTBrand = brandName;
	        }else if(String.isNotBlank(brandExtName)){
	        	strBTBrand = brandExtName;
	        }else{
	        	strBTBrand = 'BT Business';
	        }
	    }else{
	    	strBTBrand = 'BT Business';
	    }
    	return strBTBrand;
    }
    /***************************************************************************************************/

    private static Set<String> getDomainsToSkipInLeadContactSearch() {
        String domainsFromSettings = RingCentralVariousSettings__c.getInstance().DomainsToSkip__c;
        if (String.isBlank(domainsFromSettings)) {
            return new Set<String>();
        }
        return new Set<String>(domainsFromSettings.split(','));
    }


    /*********Wrapper for Phone Number Format******/
    public class phoneFormatWrapper{
    	public string formattedNumber;
    	public string plusOnePhoneFormat;
    }
    /*********************************************/
}
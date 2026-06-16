public class GenericE2CSetupHandler {
    
    private static List<Generic_E2C_setting__mdt> GenericE2CSettingList;
    private static Map<String,List<Generic_E2C_setting__mdt>> GenericE2CSettingMap;
    private static String templateBody;
    private static List<List<String>> keyFields;
    private static Boolean isTemplateFound;
    private static String resourceName;
    private static Boolean isKeyFieldsSequenceMismatch;
    private static List<List<String>> listSplit = new List<List<String>>();
    private static String brandIdentifier;
    private static Generic_E2C_setting__mdt gSetting;
    private static boolean isCaseComment = false;
    
    public static String toEmailAddresses;
    public static String fromAddresses; 

    
    //constructor - gets all the metadata records 
    public GenericE2CSetupHandler(Messaging.inboundEmail email)
    {
        try{
        	GenericE2CSettingList = Generic_E2C_setting__mdt.getAll().values();
        	GenericE2CSettingMap = new Map<String,List<Generic_E2C_setting__mdt>>();
    
    		//constructing map based on from address
    		for(Generic_E2C_setting__mdt generic: GenericE2CSettingList)
    		{
        		if(generic != null && generic.FromAddress__c != null && !GenericE2CSettingMap.containsKey(generic.FromAddress__c))
        		{
                	List<Generic_E2C_setting__mdt> genericList = new List<Generic_E2C_setting__mdt>();
                	genericList.add(generic);
            		GenericE2CSettingMap.put(generic.FromAddress__c, genericList);
        		}
            	else if(generic.FromAddress__c != null && GenericE2CSettingMap.containsKey(generic.FromAddress__c))
            	{
                	List<Generic_E2C_setting__mdt> genericList = GenericE2CSettingMap.get(generic.FromAddress__c);
                	genericList.add(generic);
                	GenericE2CSettingMap.put(generic.FromAddress__c, genericList);
            	}
    		}
        }catch(Exception e)
        {
          	String message = e.getStackTraceString()+' '+e.getCause()+' '+e.getMessage();
            GenericE2CExceptionHandler.genericException(email,message);
            GenericE2CSetup.isGenericException = true;
        }
    }
    
    //check if the email is received from a valid email address defined in the custom metadata type records
    public static boolean checkIsValidEmailAddress(String fromAddress, Messaging.inboundEmail email)
    {
        try{
        if(GenericE2CSettingMap != null && GenericE2CSettingMap.containsKey(fromAddress) && GenericE2CSettingMap.get(fromAddress) != null)
        {
            return true;
        }
        }catch(Exception e)
        {
            String message = e.getStackTraceString()+' '+e.getCause()+' '+e.getMessage();
            GenericE2CExceptionHandler.genericException(email,message);
            GenericE2CSetup.isGenericException = true;
        }
        return false;
    }
    
    //check if the template is available or not in static resource as a csv document. Checking the content type to be csv and template body is not null or blank
    public static boolean checkTemplateFound(String fromAddress, String emailSubject, Messaging.inboundEmail email)
    {
        try{
        	Set<String> templateNames = new Set<String>();
            Boolean isSubjectInvalid = false;
            if(!email.subject.containsIgnoreCase('Versatel')){
                if(email.subject.containsIgnoreCase('[') && email.subject.containsIgnoreCase(']') && email.subject.startsWithIgnoreCase('[') && email.subject.containsIgnoreCase('#')){
                    String emailSubjectValidation = email.subject.subStringBetween('[',']');
                    Pattern p = Pattern.compile('([A-Za-z])*(\\#)([A-Za-z0-9])*');
                    Matcher m = p.matcher(emailSubjectValidation);
                    if(!m.matches()){
                        isSubjectInvalid = true;
                    } 
                }
                else{
                    isSubjectInvalid = true;
                }
                String emailSubjectSubstring = email.subject.substringBefore('#').trim();
                
                if(GenericE2CSettingMap != null && GenericE2CSettingMap.containsKey(fromAddress)&& GenericE2CSettingMap.get(fromAddress) != null)
                {
                List<Generic_E2C_setting__mdt> gList = GenericE2CSettingMap.get(fromAddress);
                if(gList.size() > 0)
                {
                    for(Generic_E2C_setting__mdt g: gList)
                    { 
                        if(g.subject__c != null && emailSubjectSubstring.containsIgnoreCase(g.subject__c)) //CMR - 326460 subject line changes
                        {
                                isTemplateFound = true;
                                resourceName = g.Template_Name__c;
                                brandIdentifier = g.subject__c;
                                GenericE2CSetupHandler.toEmailAddresses = g.ToAddress__c;
                                GenericE2CSetupHandler.fromAddresses = g.Org_Wide_Email_Address__c;
                                break;
                            }
                        else{
                                isTemplateFound = false;
                            }
                        }
                    }
            
                    if(isTemplateFound == true && resourceName != null)
                    {
                    for(Generic_E2C_setting__mdt g: gList)
                    {
                        if(g.template_Name__c == resourceName)
                        {
                        gSetting = g;
                        toEmailAddresses = g.ToAddress__c;
                        fromAddresses = g.Org_Wide_Email_Address__c; 
                        break;
                        }
                    }
                }
                }
                if(isTemplateFound == false){
                    String message = 'Not able to create/update case in RC. Mismatch in subject format';
                    GenericE2CExceptionHandler.invalidPartnerName(email, message);
                }
                if(isSubjectInvalid == true){
                    GenericE2CSetup.isGenericException = true;
                    GenericE2CExceptionHandler.caseNotCreatedException(email);
                    return false;
                }
                return true;
            }
            //Code changes for versatel
            else{
                if(!email.subject.containsIgnoreCase('&') || !email.subject.containsIgnoreCase(':') || !email.subject.containsIgnoreCase('/') || !email.subject.startsWithIgnoreCase('1&1 Versatel')){
                   isSubjectInvalid = true; 
                }
                String emailSubjectSubstring = email.subject.substringBefore(':');
                if(emailSubjectSubstring.containsIgnoreCase('Versatel')){
                    emailSubjectSubstring = 'Versatel';
                }
                else{
                    isSubjectInvalid = true; 
                }
                if(GenericE2CSettingMap != null && GenericE2CSettingMap.containsKey(fromAddress)&& GenericE2CSettingMap.get(fromAddress) != null)
                {
                List<Generic_E2C_setting__mdt> gList = GenericE2CSettingMap.get(fromAddress);
                if(gList.size() > 0)
                {
                    for(Generic_E2C_setting__mdt g: gList)
                    { 
                        if(g.subject__c != null && emailSubjectSubstring.containsIgnoreCase(g.subject__c)) //CMR - 326460 subject line changes
                        {
                                isTemplateFound = true;
                                resourceName = g.Template_Name__c;
                                brandIdentifier = g.subject__c;
                                GenericE2CSetupHandler.toEmailAddresses = g.ToAddress__c;
                                GenericE2CSetupHandler.fromAddresses = g.Org_Wide_Email_Address__c;
                                break;
                            }
                        else{
                                isTemplateFound = false;
                            }
                        }
                    }
            
                    if(isTemplateFound == true && resourceName != null)
                    {
                    for(Generic_E2C_setting__mdt g: gList)
                    {
                        if(g.template_Name__c == resourceName)
                        {
                        gSetting = g;
                        toEmailAddresses = g.ToAddress__c;
                        fromAddresses = g.Org_Wide_Email_Address__c; 
                        break;
                        }
                    }
                }
                }
                if(isTemplateFound == false){
                    String message = 'Not able to create/update case in RC. Mismatch in subject format';
                    GenericE2CExceptionHandler.invalidPartnerName(email, message);
                }
                if(isSubjectInvalid == true){
                    GenericE2CSetup.isGenericException = true;
                    GenericE2CExceptionHandler.caseNotCreatedException(email);
                    return false;
                }
                return true;
            }

        }
        catch(Exception e)
        {
            String message = e.getStackTraceString()+' '+e.getCause()+' '+e.getMessage();
            GenericE2CExceptionHandler.genericException(email,message);
            GenericE2CSetup.isGenericException = true;
        }
       return false;
    }

    public static boolean checkCaseCreated(String fromAddress, String emailBody, String emailSubject, Messaging.inboundEmail email)
    {
        List<String> splitBody = new List<String>();
        try{
            
            if(fromAddress != null && emailBody != null && emailSubject != null)
            {
                List<StaticResource> sList = new List<StaticResource>();
                if(resourceName != null)
                {
                    sList = [SELECT Id,Body,ContentType,Name FROM StaticResource WHERE Name = :resourceName];
                }
                
                Boolean isHeaderAvailable = false;
                
                if(sList.size() > 0 && sList[0] != null)
                {
                    templateBody = sList[0].Body.toString();
                    if(templateBody != null)
                    {
                    	splitBody = templateBody.split('\n');
                    	if(splitBody != null && splitBody[0] != null)
                    	{
                        String headers = splitBody[0];
                        if(headers != null)
                        {
                            String[] splitHeader = headers.split(',');
                            if(splitHeader[0].trim().equalsIgnoreCase('order') && splitHeader[1].trim().equalsIgnoreCase('template key')
                               && splitHeader[2].trim().equalsIgnoreCase('field label') && splitHeader[3].trim().equalsIgnoreCase('default value')
                               && splitHeader[4].trim().equalsIgnoreCase('associated object') && splitHeader[5].trim().equalsIgnoreCase('retrieval field')
                               && splitHeader[6].trim().equalsIgnoreCase('condition field'))
                            {
                                isHeaderAvailable = true;
                            }
                            else
                            {
                                isHeaderAvailable = false;
                            }
                        }
                    }
                	}
                    if(isHeaderAvailable != null && isHeaderAvailable && splitBody != null)
                	{
                    	
                    	for(Integer i = 1; i < splitBody.size();i++)
                    	{
                        	String[] secondSplit = splitBody[i].split(',');
                        	if(listSplit != null && secondSplit != null)
                        	{
                            	listSplit.add(secondSplit);
                        	}
                    	}
                            
                            system.debug('List split: '+listSplit);
                            if(listSplit.size()>0)
                            {
                                for(Integer i = 0; i<listSplit.size(); i++)
                                {
                                    System.debug(listSplit[i].get(1).trim());
                                    if(emailBody.containsIgnoreCase(listSplit[i].get(1).trim()))
                                    {
                    					keyFields = listSplit;  
                                    }
                                    else
                                    {
                                        return false;
                                    }
                				}
                            }
                    }
                }
                
                //key fields incorrect sequence mismatch
                List<String> emailBodySplit = emailBody.split('\\*');
                List<String> emailSplit = new List<String>();
                for(String s: emailBodySplit){
                    if(String.isNotBlank(s) && !s.containsIgnoreCase('[External]')){
                        emailSplit.add(s);
                    }
                }
                isKeyFieldsSequenceMismatch = false;
                if(keyFields.size() > 0 && emailSplit.size() > 0){
                    for(Integer i = 0; i < emailSplit.size(); i++){
                        String emailAttr = '*'+emailSplit[i];
                        if(!emailAttr.containsIgnoreCase(keyFields[i].get(1))){
                            isKeyFieldsSequenceMismatch = true;
                            break;
                        }
                    }
                }
                
                if(isKeyFieldsSequenceMismatch == true){
                    GenericE2CExceptionHandler.caseNotCreatedException(email);
                    GenericE2CSetup.isGenericException = true;
                    return false;
                }
            
        		// Record type association
        		if(gSetting != null && keyFields.size() > 0 && isKeyFieldsSequenceMismatch == false)
        		{
        			String recordTypeName = gSetting.Record_Type_Name__c;
        			Id recordTypeId;
                    String partnerTicketNumber;
        			if(recordTypeName != null)
        			{
          				recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();  
        			}
                    //Code changed after versatel changes
                    if(email.subject != null && !email.subject.containsIgnoreCase('Versatel'))
                    {
                        partnerTicketNumber = email.subject.subStringBetween('#',']'); //CMR - 326460
                    }
                    else{
                        partnerTicketNumber = email.subject.subStringBetween(':','/').trim();
                    }
        
        			//Owner assignment
        			List<Group> ownerGrp;
        			String ownerType = gSetting.Owner_Type__c;
        			String ownerName = gSetting.Owner_Name__c; 
        			if(ownerType != null && ownerName != null)
        			{
            			ownerGrp = [SELECT Id FROM Group WHERE Type = :ownerType AND Name = :ownerName]; 
        			}

                        Schema.SObjectType objectType = ((SObject)Type.forName('Case').newInstance()).getSObjectType();
                		SObject newCase = objectType.newSObject();
                		for(integer i = 0; i < keyFields.size() ; i++)
                		{
                            String fieldLabel = keyFields[i].get(2).trim();
                    		String fieldValue;
                    		if(emailBody.containsIgnoreCase(keyFields[i].get(1))){
                    		if(i == keyFields.size() - 1)
                    		{
                        		if(emailBody.substringAfter(keyFields[i].get(1)+':') != null)
                        		{
                            		fieldValue = emailBody.substringAfter(keyFields[i].get(1)+':').trim();
                        		}
                    		}
                    		else if(keyFields[i].get(3) != null && String.isNotBlank(keyFields[i].get(3)))
                    		{
                        		fieldValue = keyFields[i].get(3).trim();
                    		}
                    		else if(keyFields[i].get(4) != null && keyFields[i].get(5) != null && keyFields[i].get(6) != null
                           		&& String.isNotBlank(keyFields[i].get(4)) && String.isNotBlank(keyFields[i].get(5)) && String.isNotBlank(keyFields[i].get(6)))
                    		{
                        		String objectName = keyFields[i].get(4).trim();
								String retrievalField = keyFields[i].get(5).trim();
								String conditionField = keyFields[i].get(6).trim();
                        		String whereConditionValue = emailBody.substringBetween(keyFields[i].get(1)+':', keyFields[i+1].get(1));
                        		whereConditionValue = whereConditionValue.normalizeSpace(); 
                        		String conditionValue = '\''+whereConditionValue+'\'';
                        		
                                if(fieldLabel.containsIgnoreCase('AccountId'))
                                {
                                    List<Account> accList = [SELECT Id FROM Account WHERE Rc_User_Id__c =: whereConditionValue];
                                    if(accList.size() > 0){
                                        newCase.put(fieldLabel,accList[0].Id);
                                    }
                                    else if(accList.size() == 0 || accList[0] != null){
                                        String message = 'No Account found with the specified UID';
                                        GenericE2CExceptionHandler.accountUIDMismatchException(email, message);
                                        GenericE2CSetup.isGenericException = true;
                                        return false;
                                    }
                                }
                        		else if(retrievalField != null && String.isNotBlank(retrievalField) && objectName != null && String.isNotBlank(objectName)
                           			&& conditionField != null && String.isNotBlank(conditionField) && conditionValue != null && String.isNotBlank(conditionValue))
                        		{
									String query = 'SELECT ' + retrievalField + ' FROM '+objectName+' WHERE '+ conditionField + '='+ conditionValue +' LIMIT 1';
                                    try
                                    {
                                        sObject[] sobjectValue = Database.query(query);
                                    	if(sobjectValue.size() > 0 && sobjectValue[0] != null)
                                    	{
											newCase.put(fieldLabel, sobjectValue[0].get(retrievalField));    
                                    	}                             
                                    }catch(Exception e)
                                    {
                                            GenericE2CExceptionHandler.genericException(email, e.getMessage());
                                        	GenericE2Csetup.isGenericException = true;
                                            return false;
                                    }
                        		}
                    		}
                    		else
                    		{
                        		if(keyFields[i].get(1) != null && String.isNotBlank(keyFields[i].get(1)) && keyFields[i+1].get(1) != null && String.isNotBlank(keyFields[i+1].get(1)) && emailBody.containsIgnoreCase(keyFields[i].get(1)) && emailBody.containsIgnoreCase(keyFields[i+1].get(1)))
                        		{
                            		if(emailBody.substringBetween(keyFields[i].get(1)+':', keyFields[i+1].get(1)) != null && String.isNotBlank(emailBody.substringBetween(keyFields[i].get(1)+':', keyFields[i+1].get(1))))
                            		{
                                		fieldValue = emailBody.substringBetween(keyFields[i].get(1)+':', keyFields[i+1].get(1)).trim();
                            		}
                        		}  
                   	 	}
                    	if(recordTypeId != null)
                    	{
                        	newCase.put('RecordTypeId',recordTypeId);
                    	}
                        if(partnerTicketNumber != null) 
                        {
                            newCase.put('Partner_Case_Number__c',partnerTicketNumber);        
                        }
                    	if(ownerGrp != null && ownerGrp[0] != null)
                    	{
                        	newCase.put('OwnerId',ownerGrp[0].Id);
                    	}	
                    	if(emailSubject != null)
                    	{
                        	newCase.put('Subject', emailSubject);
                    	}
                    	if(emailBody != null)
                    	{
                        	newCase.put('Description', emailBody);
                    	}
                        if(brandIdentifier != null)
                        {
                            newCase.put('Brand_Identifier__c',brandIdentifier);
                        }
                        if(email.subject != null)
                        {
                            newCase.put('Most_Recent_Subject__c',email.subject);
                         }
                    	if(fieldLabel != null && fieldValue != null && String.isNotBlank(fieldLabel) && String.isNotBlank(fieldValue))
                    	{
                        	newCase.put(fieldLabel, fieldValue);
                    	}
                        if(fromAddress != null)
                        {
                            newCase.put('SuppliedEmail',fromAddress);
                        }
                    }
                }
                    if(GenericE2CSetup.isGenericException == true){
                        return false;
                    }
                	if(newCase != null)
                	{
                   		List<Case> casesToInsert = new List<Case>();
                    	casesToInsert.add((Case)newCase);
                   		Database.SaveResult[] saveResults = Database.insert(casesToInsert);
                    	if(saveResults[0].isSuccess()){
                        	CaseComment newComment = new CaseComment();
                        	newComment.parentId = casesToInsert[0].Id;
                        	newComment.CommentBody = casesToInsert[0].Last_Case_Comment__c + '\n This comment was added by: '+casesToInsert[0].Brand_Identifier__c;
                        	if(newComment != null)
                        	{
                            	insert newComment;
                        	}
                    	}
                   	return true;
                	}

        		}
         }
            
        }catch(Exception e){
            	String message = e.getStackTraceString()+' '+e.getCause()+' '+e.getMessage();
            	GenericE2CExceptionHandler.genericException(email,message);
            	GenericE2CSetup.isGenericException = true;
        	}
        	return false;
    	}
    
    //generic method for creating case comments received from partner
    //CMR-350292: E2EStaging - Versatel Case Comments logic
    public static void partnerCaseCommentCreation(Messaging.InboundEmail email, String PartnerName)
    {
        try{
            String partner = PartnerName;
        	String CUSTOM_EXCEPTION_MESSAGE = '';

			if(GenericE2CSettingMap.size()>0 && GenericE2CSettingMap.containsKey(email.fromAddress) && GenericE2CSettingMap.get(email.fromAddress) != null)
        	{
                if(email.subject.containsIgnoreCase('ID-Extern:')|| (email.subject.containsIgnoreCase('RC Ticket:') && email.subject.containsIgnoreCase('Comment'))){
                   
                    List<Generic_E2C_setting__mdt> gList = GenericE2CSettingMap.get(email.fromAddress);

                    if(gList.size() > 0)
                    {
                        for(Generic_E2C_setting__mdt g: gList){
                            if(partner.equalsIgnoreCase(g.subject__c)){
                                isCaseComment = true;
                                gSetting = g;
                                break;
                            }
                        }
                    } 
                }
            	
    		}
        	if(isCaseComment == true && (email.subject.subStringAfter('RC Ticket:').length() >= 8||email.subject.containsIgnoreCase('ID-Extern:'))){
                
                String rcCaseId = '';
                
                if(email.subject.containsIgnoreCase('ID-Extern:')){
                    rcCaseId = email.subject.subStringAfter('ID-Extern: ').trim().substring(0,8);
                }
                else{
                    rcCaseId = email.subject.subStringAfter('RC Ticket:').trim().substring(0,8);
                }
                

            	Pattern p = Pattern.compile('[0-9]{8}');
            	Matcher pm = p.matcher(rcCaseId);
            	if(pm.matches() && rcCaseId.length() == 8)
                {
                    List<Case> partnerCase = [SELECT Id,Most_Recent_Subject__c FROM Case WHERE CaseNumber =: rcCaseId AND Brand_Identifier__c =: partner];
                    if(partnerCase.size() > 0){
                        CaseComment newComment = new CaseComment();
                        newComment.ParentId = partnerCase[0].Id;
                        if(email.plainTextBody != null) {
                            newComment.CommentBody = email.plainTextBody;
                        } else if(email.htmlBody != null) {
                            newComment.CommentBody = email.htmlBody.stripHtmlTags();
                        }
                        
                        newComment.CommentBody = newComment.CommentBody + '\nThis Comment was added by '+partner+'.';
                        
                        if(newComment != null){
                            insert newComment;
                        }
                        if(email.subject != null && !partnerCase[0].Most_Recent_Subject__c.equalsIgnoreCase(email.subject)){
                            partnerCase[0].Most_Recent_Subject__c = email.subject;
                            update partnerCase;
                        }
                    }
                    else
                    {
                        toEmailAddresses = gSetting.ToAddress__c;
                        fromAddresses = gSetting.Org_Wide_Email_Address__c;
                        CUSTOM_EXCEPTION_MESSAGE = 'No 	case has been identified with the given case number';
                        GenericE2CExceptionHandler.caseCommentNotCreateException(email,CUSTOM_EXCEPTION_MESSAGE);
                    }
                }
                else
                {
                    toEmailAddresses = gSetting.ToAddress__c;
                    fromAddresses = gSetting.Org_Wide_Email_Address__c;
                    CUSTOM_EXCEPTION_MESSAGE = 'RC Case Number format mismatch';
                    GenericE2CExceptionHandler.caseCommentNotCreateException(email,CUSTOM_EXCEPTION_MESSAGE);
                    
                }
        	}
            if(isCaseComment == false)
            {
             	String message = 'Not able to create/update case in RingCentral. Mismatch in subject format';
                GenericE2CExceptionHandler.invalidPartnerName(email, message);
            }
        }Catch(Exception e){
            GenericE2CExceptionHandler.genericException(email, e.getMessage()+' '+e.getStackTraceString());
        }
       }
    //FindPanrtnerName after Versatel Subject Change
    public static String findPartner(Messaging.InboundEmail email){
        if(!email.subject.containsIgnoreCase('Versatel')){
            return email.subject.subStringBetween('[','#');
        }
        else{
            String emailSubjectSubstring = email.subject.subStringBetween('&','/');
            if(emailSubjectSubstring.containsIgnoreCase('Versatel')){
                return 'Versatel';
            }
            else{
                return null;
            }
        }
    }
    //generic method for sending email notifications to partners 
    public static void sendEmailNotificationToPartner(List<CaseComment> caseComments)
    {
        try{
        	if(caseComments.size() > 0 && !caseComments[0].commentBody.containsIgnoreCase('This Comment was added by'))
        	{
           	List<Case> caseList = [SELECT Id,Brand_Identifier__c,Most_Recent_Subject__c FROM Case WHERE Id = :caseComments[0].parentId];
            if(caseList.size() > 0)
        	{
            	List<Generic_E2C_setting__mdt> gSetting = [SELECT ToAddress__c,Org_Wide_Email_Address__c FROM Generic_E2C_setting__mdt WHERE subject__c =: caseList[0].Brand_Identifier__c];
            	if(gSetting.size()>0 && gSetting[0].ToAddress__c != null && gSetting[0].Org_Wide_Email_Address__c != null){
                	String[] toAddresses = gSetting[0].ToAddress__c.split(';');
                
                	Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            		emailMessage.setSubject(caseList[0].Most_Recent_Subject__c);
              		emailMessage.setHtmlBody('New Comment: '+'<br/>'+caseComments[0].CommentBody);
              		emailMessage.toaddresses = toAddresses;
              		emailMessage.setOrgWideEmailAddressId(gSetting[0].Org_Wide_Email_Address__c);
                
                	Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {emailMessage};
             		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        			if (results[0].success) {
            			System.debug('The email was sent successfully.');
        			}else {
            			System.debug('The email failed to send: '+ results[0].errors[0].message);
                	}
            	}
        	}
            
        }
        }catch(Exception e){
            GenericE2CExceptionHandler.genericException(e.getMessage()+' '+e.getStackTraceString());
        }
    }
}
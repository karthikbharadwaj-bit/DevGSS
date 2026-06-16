global class CreateCaseFromCustomerFeedback implements Messaging.InboundEmailHandler{

    static final String IOS_TO_COMPARE = 'Ringcentral iOS';
    static final String ANDROID_TO_COMPARE = 'Ringcentral Android';

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        List<string> fieldsList=new List<string>();    
        List<Group> queueGroup = (Group[]) new GroupSelector()
            .selectQueueByName('General Support Queue')
            .executeQuery();

        try {
            if (email.subject.containsIgnoreCase(IOS_TO_COMPARE) || email.subject.containsIgnoreCase(ANDROID_TO_COMPARE)) {
                Case c = new Case();
                String emailbody=email.plainTextBody;
                if (emailbody!=null) {
                    if (emailbody.containsIgnoreCase('•')) {
                        emailbody=emailbody.substringAfter('•');
                    } else if (emailbody.containsIgnoreCase('*')) {
                        emailbody=emailbody.substringAfter('*');                
                    }
                }
                List<string> fieldList=new List<string>();
                String[] str1=emailbody.split(':');
                for (String fields:str1) {
                    String field;
                    if (fields.containsIgnoreCase('•')) {
                        field=fields.substringBeforeLast('•');
                    } else if (fields.containsIgnoreCase('*')) {
                        field=fields.substringBeforeLast('*');
                    } else {
                        field=fields;
                    }
                    field.normalizeSpace();
                    field.trim();
                    fieldList.add(field);
                }
            
                for (String fields:fieldList) {
                    string field= fields.trim();
                    if (field.contains('<mailto')) {
                        field=field.remove('<mailto');
                    }
                    fieldsList.add(field);                
                }

                c.Support_Jira__c= fieldsList[1];            
                c.recordtypeid = CaseHelper.RT_ID_CUSTOMER_FEEDBACK;
                c.priority= 'New';
                c.Origin = 'Email';
                c.OwnerId = queueGroup.isEmpty() ? null : queueGroup[0].id;
                c.Subject = email.subject;
                c.Name__c=fieldsList[2];
            
                if (fieldsList[3].containsIgnoreCase('.com')) {
                    c.Customer_contact_email__c=fieldsList[3];
                }

                if (emailbody.containsIgnoreCase('<mailto:')) {
                    c.Phone_Number__c=fieldsList[5];
                    c.App_Version__c=fieldsList[6];
                    c.Device_Model__c=fieldsList[7];
                    if (emailbody.containsIgnoreCase('UID')) {
                        if (String.isNotBlank(fieldsList[8])) {
                            c.Accountid= getAccountNumber(fieldsList[8]);
                            c.Description = fieldsList[9];
                        } else {
                            c.Description = fieldsList[9];
                        }
                    } else {
                        c.Description = fieldsList[8];
                    }                    
                } else {
                    c.Phone_Number__c=fieldsList[4];
                    c.App_Version__c=fieldsList[5];
                    c.Device_Model__c=fieldsList[6];
                    if (emailbody.containsIgnoreCase('UID')) {
                        if (String.isNotBlank(fieldsList[7])) {
                            c.Accountid= getAccountNumber(fieldsList[7]);
                            c.Description = fieldsList[8];
                        } else {
                            c.Description = fieldsList[8];
                        }
                    } else {
                        c.Description = fieldsList[7];
                    }
                }
                insert c;
          
              list<attachment> attachList=new list<attachment>();
              //Save text Attachment
                if (email.textAttachments!=null) {
                    for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                        Attachment attachment = new Attachment();
                        attachment.Name = tAttachment.fileName;
                        attachment.ParentId = c.Id;
                        attachment.Body = Blob.valueOf(tAttachment.body);
                        attachList.add(attachment);
                    }
                }

              //Save any Binary Attachment
                if (email.binaryAttachments!=null) {
                    for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                        Attachment attachment = new Attachment();
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body;
                        attachment.ParentId = c.Id;
                        attachList.add(attachment);
                    }
                }
              insert attachList;
              result.success = true;
            }
        } catch(Exception e) {
            result.success = false;
        }
      return result;
    }
  
    public static string getAccountNumber(String uId) {
        return new AccountSelector()
        .selectAccountsByUserIds(new Object[]{new String[]{uid}})
        .executeQuery()[0].Id;
    }

}
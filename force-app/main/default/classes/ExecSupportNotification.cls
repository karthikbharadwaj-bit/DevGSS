public class ExecSupportNotification {
    @InvocableMethod(label='Send Exec Request' description='Send email notification to e-staff' category='Opportunity')
    public static List<String> sendSupportNotification(List<ID> ids) {
        List<String> returnVal = new List<String>();
        EmailTemplate emailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where name = 'Exec Support Notification' limit 1];
        Opportunity opp = [SELECT Id, Owner.Id, Owner.Email, Owner.FirstName, Owner.LastName, Owner.Manager.Email, RC_Executive_Alignment__r.Email FROM Opportunity WHERE Id =: ids.get(0)]; 
        
        List<String> toAddresses = new List<String>();
        toAddresses.add(opp.Owner.Email);
        toAddresses.add(opp.Owner.Manager.Email);
        toAddresses.add(opp.RC_Executive_Alignment__r.Email);  
        
        for(User u: [SELECT Id, Email FROM User where Id in: (System.Label.Exec_Support_Other_Recipients.split(';'))]){
           toAddresses.add(u.email);
        }
           
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(emailTemplate.id, null, opp.id);
       
        //message.setTargetObjectId(temp.id); 
        message.ccAddresses = new String[] {System.Label.Exec_Support_Email};
        system.debug(System.Label.Exec_Support_Other_Recipients.split(';'));
        
        system.debug(toAddresses);
        
        message.toAddresses = toAddresses;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) {
            returnVal.add('The email was sent successfully');
        } else {
            returnVal.add('The email failed to send: ' + results[0].errors[0].message);
        }
        return returnVal;
  
  }
}
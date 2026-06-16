public class GroupMemberEmailInvoker {

    @InvocableMethod(label='Send Group Member Email')
    public static void sendEmail(List<Id> groupMemberIds) {

        sendEmailFuture(groupMemberIds);
    }

    @future
    public static void sendEmailFuture(List<Id> groupMemberIds) {

        List<GroupMember> members = [
            SELECT Id,
                   Group.Name,
                   UserOrGroupId
            FROM GroupMember
            WHERE Id IN :groupMemberIds
        ];

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for(GroupMember gm : members) {

            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

            mail.setToAddresses(
                new List<String>{'shubham.prabhakar@ringcentral.com'}
            );

            mail.setSubject('Group Member Created');

            mail.setPlainTextBody(
                'New member added to group: ' + gm.Group.Name
            );

            emails.add(mail);
        }

        if(!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
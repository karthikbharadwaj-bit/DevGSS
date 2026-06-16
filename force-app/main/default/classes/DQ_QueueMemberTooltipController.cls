public class DQ_QueueMemberTooltipController {
  
    @AuraEnabled
    public static List<User> getQueueMemberByQueueName(String groupId){
        if (Id.valueOf(groupId).getSobjectType() == Group.getSObjectType()) {
           return [SELECT Id, Name, Email, isActive, Profile.Name, UserRole.Name, UserType
            FROM User 
            WHERE Id IN  (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId)];
        }
        return null;
    }
}
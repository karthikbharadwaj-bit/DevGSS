@isTest
public class DQ_QueueMemberTooltipController_Test {
	@testSetup static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='testcasemanager@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testcasemanager@test.com');
        insert u;
        //Create Parent Group
        Group grp = new Group();
        grp.name = 'Test Group1';
        grp.Type = 'Regular'; 
        Insert grp; 
 
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = u.Id;
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
    }
    
    @isTest
    private static void getQueueMemberByQueueName() {
    	Group objGroup = [SELECT Id, Name FROM Group WHERE Type = 'Regular' limit 1];
        List<user> userList = DQ_QueueMemberTooltipController.getQueueMemberByQueueName(objGroup.Id);
        System.assertEquals(0,userList.size());
    }
     @isTest
    private static void getQueueMemberByQueueNameNegative() {
    	Group objGroup = [SELECT Id, Name FROM Group WHERE Type = 'Regular' limit 1];
        List<user> userList = DQ_QueueMemberTooltipController.getQueueMemberByQueueName(UserInfo.getUserId());
        System.assertEquals(null,userList);
    }
    
}
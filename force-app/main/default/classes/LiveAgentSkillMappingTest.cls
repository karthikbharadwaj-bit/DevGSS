//**********************************************************
//Class Name = LiveAgentSkillMapping ***********************
//**********************************************************

@isTest
public class LiveAgentSkillMappingTest 
{
    @isTest
    static void testMethod1() 
    {
        Test.StartTest(); 
            LiveAgentSkillMapping  testLASkillMap = new LiveAgentSkillMapping ();
            List<SkillUser> skillusers = testLASkillMap.getskillusers();
            List<SkillUser> USSalesSkillusers = testLASkillMap.getUSSalesSkillusers();  
            List<SkillUser> UKSalesSkillusers = testLASkillMap.getUKSalesSkillusers();  
            List<SkillUser> GCCSkillusers = testLASkillMap.getGCCSkillusers(); 
        Test.StopTest();

        System.assertNotEquals(skillusers, null);
        System.assertEquals(
            skillusers.size(), [
                SELECT count() 
                FROM SkillUser 
                WHERE User.IsActive = true 
                AND User.UserPermissionsLiveAgentUser = true
        ]);

        System.assertNotEquals(USSalesSkillusers, null);
        System.assertEquals(
            USSalesSkillusers.size(), [
                SELECT count() 
                FROM SkillUser 
                WHERE User.IsActive = true 
                AND User.UserPermissionsLiveAgentUser = true 
                AND (NOT Skill.MasterLabel LIKE '%Support%') 
                AND (NOT Skill.MasterLabel LIKE '%UK Team%') 
                AND (NOT Skill.MasterLabel LIKE '%TEST%')
        ]);

        System.assertNotEquals(UKSalesSkillusers, null);
        System.assertEquals(
            UKSalesSkillusers.size(), [
                SELECT count() 
                FROM SkillUser 
                WHERE User.IsActive = true 
                AND User.UserPermissionsLiveAgentUser = true 
                AND Skill.MasterLabel LIKE '%UK Team%'
        ]);

        System.assertNotEquals(GCCSkillusers, null);
        System.assertEquals(
            GCCSkillusers.size(), [
                SELECT count() 
                FROM SkillUser 
                WHERE User.IsActive = true 
                AND User.UserPermissionsLiveAgentUser = true 
                AND Skill.MasterLabel LIKE '%Support%'
        ]);
    }
}
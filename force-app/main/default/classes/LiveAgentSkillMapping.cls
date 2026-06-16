public class LiveAgentSkillMapping {
    transient List<SkillUser> skillusers;
    transient List<SkillUser> USSalesSkillusers;
    transient List<SkillUser> UKSalesSkillusers;
    transient List<SkillUser> GCCSkillusers;

    public List<SkillUser> getskillusers() {
        skillusers = [SELECT Skill.MasterLabel, User.Name, UserId, LastModifiedDate FROM SkillUser WHERE User.IsActive = true AND User.UserPermissionsLiveAgentUser = true  AND LastModifiedDate <=LAST_90_DAYS ];
        return skillusers;
    }


    public List<SkillUser> getUSSalesSkillusers() {
        USSalesSkillusers = [SELECT Skill.MasterLabel, User.Name, UserId FROM SkillUser WHERE User.IsActive = true AND User.UserPermissionsLiveAgentUser = true AND (NOT Skill.MasterLabel LIKE '%Support%') AND (NOT Skill.MasterLabel LIKE '%UK Team%') AND (NOT Skill.MasterLabel LIKE '%TEST%')AND (LastModifiedDate <=LAST_90_DAYS)];
        return USSalesSkillusers;
    }    



    public List<SkillUser> getUKSalesSkillusers() {
        UKSalesSkillusers = [SELECT Skill.MasterLabel, User.Name, UserId FROM SkillUser WHERE User.IsActive = true AND User.UserPermissionsLiveAgentUser = true AND Skill.MasterLabel LIKE '%UK Team%'AND LastModifiedDate <=LAST_90_DAYS];
        return UKSalesSkillusers;
    }
    

    public List<SkillUser> getGCCSkillusers() {
        GCCSkillusers = [SELECT Skill.MasterLabel, User.Name, UserId FROM SkillUser WHERE User.IsActive = true AND User.UserPermissionsLiveAgentUser = true AND Skill.MasterLabel LIKE '%Support%'AND LastModifiedDate <=LAST_90_DAYS];
        return GCCSkillusers;
    }   
    
}
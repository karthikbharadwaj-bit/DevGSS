public inherited sharing class UserSelectorDialogflow {
    private static UserSelectorDialogflow instance;
    
    public static UserSelectorDialogflow getInstance() {
        if (instance == null) {
            instance = new UserSelectorDialogflow();
        }
        return instance;
    }
    
    // Get user by Id
    public User getUserById(Id userId) {
        if (userId == null) {
            throw new UserSelectorException('User ID cannot be null');
        }
        
        List<User> users = [
            SELECT Id, Name, Email, IsActive
            FROM User 
            WHERE Id = :userId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return !users.isEmpty() ? users[0] : null;
    }
    
    // Check if user has read access to record
    public Boolean hasReadAccess(Id userId, Id recordId) {
        if (userId == null || recordId == null) {
            return false;
        }
        
        List<UserRecordAccess> access = [
            SELECT HasReadAccess,RecordId
            FROM UserRecordAccess 
            WHERE UserId = :userId 
            AND RecordId = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return !access.isEmpty() && access[0].HasReadAccess;
    }
    
    // Check if user has edit access to record
    public Boolean hasEditAccess(Id userId, Id recordId) {
        if (userId == null || recordId == null) {
            return false;
        }
        
        List<UserRecordAccess> access = [
            SELECT HasEditAccess, RecordId
            FROM UserRecordAccess 
            WHERE UserId = :userId 
            AND RecordId = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return !access.isEmpty() && access[0].HasEditAccess;
    }
    
    public class UserSelectorException extends Exception {}
}
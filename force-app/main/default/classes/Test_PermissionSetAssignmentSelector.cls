@isTest
private class Test_PermissionSetAssignmentSelector {
    //User fields defined
    private static final String USER_FIRST_NAME = 'TestFN';
    private static final String USER_LAST_NAME = 'TestLN';
    private static final String USER_USERNAME = 'testUser1@username.com';
    private static final String USER_EMAIL = 'user@email.com';

	//Permission set fields defined
    private static final String PERMISSION_SET_LABEL = 'TestApiName';
    private static final String PERMISSION_SET_NAME = 'TestApiName';

    //Assert messages defined
    private static final String ASSERT_MESSAGE = 'Permission set assignments should be selected';
    private static final String ASSERT_EQUALS_MESSAGE = 'Wrong permission set assignment selected';

    @testSetup
    private static void testData(){
        User testUser = (User) new SObjectBuilder(User.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    User.FirstName => USER_FIRST_NAME,
                    User.LastName => USER_LAST_NAME,
                    User.ProfileId => System.UserInfo.getProfileId(),
                    User.UserName => USER_USERNAME,
                    User.Email => USER_EMAIL,
                    User.isActive => TRUE
                }
            )
            .create()
            .getRecord();
        
        PermissionSet testPs = (PermissionSet) new SobjectBuilder(PermissionSet.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSet.Label => PERMISSION_SET_LABEL,
                    PermissionSet.Name => PERMISSION_SET_NAME
                	}
            )
            .create()
            .getRecord();

        PermissionSetAssignment testPSA = (PermissionSetAssignment) new SobjectBuilder(PermissionSetAssignment.SObjectType)
            .setFields(
                new Map<SObjectField, Object>{
                    PermissionSetAssignment.AssigneeId => testUser.Id,
                    PermissionSetAssignment.PermissionSetId => testPs.Id
                	}
            )
            .create()
            .getRecord();
    }
    
    @isTest
    private static void testSelectPermissionSetAssignmentByLabel(){
        List<PermissionSetAssignment> permissionSetAssignmentByLabel = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector(true, true)
            .selectPermissionSetAssignmentByLabel(new List<Object>{new Set<String>{PERMISSION_SET_LABEL}})
            .executeQuery();

        System.assert(permissionSetAssignmentByLabel.size() > 0, ASSERT_MESSAGE);
    }
    
    @isTest
    private static void testSelectPSABasedOnAssigneeAndLabel(){
        List<PermissionSetAssignment> permissionSetAssignmentByLabel = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPermissionSetAssignmentByLabel(new List<Object>{new Set<String>{PERMISSION_SET_LABEL}})
            .executeQuery();

        List<PermissionSetAssignment> pSABasedOnAssigneeAndLabel = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssigneeAndLabel(new List<Object>{new Set<Id>{permissionSetAssignmentByLabel[0].AssigneeId},
                											   new Set<String>{PERMISSION_SET_LABEL}})
            .executeQuery();
        
        System.assert(pSABasedOnAssigneeAndLabel.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(permissionSetAssignmentByLabel[0].Id, pSABasedOnAssigneeAndLabel[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    
    @isTest
    private static void testSelectPSABasedOnAssigneeAndPermissionSet(){
        List<PermissionSetAssignment> permissionSetAssignmentByLabel = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPermissionSetAssignmentByLabel(new List<Object>{new Set<String>{PERMISSION_SET_LABEL}})
            .executeQuery();

        List<PermissionSetAssignment> pSABasedOnAssigneeAndPermissionSet = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssigneeAndPermissionSet(new List<Object>{new Set<Id>{permissionSetAssignmentByLabel[0].AssigneeId},
                											   		   new Set<Id>{permissionSetAssignmentByLabel[0].PermissionSetId}})
            .executeQuery();
        
        System.assert(pSABasedOnAssigneeAndPermissionSet.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(permissionSetAssignmentByLabel[0].Id, pSABasedOnAssigneeAndPermissionSet[0].Id, ASSERT_EQUALS_MESSAGE);
    }
    
    @isTest
    private static void testSelectPSABasedOnAssignee(){
        List<PermissionSetAssignment> permissionSetAssignmentByLabel = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPermissionSetAssignmentByLabel(new List<Object>{new Set<String>{PERMISSION_SET_LABEL}})
            .executeQuery();

        List<PermissionSetAssignment> pSABasedOnAssignee = (List<PermissionSetAssignment>) new PermissionSetAssignmentSelector()
            .selectPSABasedOnAssignee(new List<Object>{new Set<Id>{permissionSetAssignmentByLabel[0].AssigneeId}})
            .executeQuery();
        
        System.assert(pSABasedOnAssignee.size() > 0, ASSERT_MESSAGE);
        System.assertEquals(permissionSetAssignmentByLabel[0].AssigneeId, pSABasedOnAssignee[0].AssigneeId, ASSERT_EQUALS_MESSAGE);
    }
    
}
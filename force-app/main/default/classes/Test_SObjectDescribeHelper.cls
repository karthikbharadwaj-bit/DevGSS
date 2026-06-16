@isTest
private class Test_SObjectDescribeHelper {
    
    @isTest
    static void testGetChildRelationship () {

        String childName = 'ACE__r';
        String parentName = 'Case';
        String resultChildName;

        Test.startTest();
        SObject parentSObject = ((SObject)Type.forName(parentName).newInstance()).getSObjectType().newSobject();
        SObjectDescribeHelper describeHelper = SObjectDescribeHelper.getDescribe(parentSObject);
        
        resultChildName = SObjectDescribeHelper.getChildRelationship(describeHelper.getSObjectType(), childName).getRelationshipName();
        Test.stopTest();
        
        System.assertEquals(childName, resultChildName, 'Names of child relationships must be equal');
    }
}
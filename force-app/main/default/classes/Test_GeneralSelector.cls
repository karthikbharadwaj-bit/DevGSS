@isTest
public class Test_GeneralSelector {
    
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void testGetFieldLists(){
        GeneralSelector gSelector = new GeneralSelector(Account.SObjectType);
        GeneralSelector gSelectorWithParams = new GeneralSelector(Account.SObjectType, true, true);
        
        List<Schema.SObjectField> defaultFieldList = gSelector.getDefaultFieldList();
        
        Schema.SObjectType sObjectType = gSelector.getSObjectType();
    }
}
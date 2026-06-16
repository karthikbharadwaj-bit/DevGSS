@isTest
public class Test_ImplementationStatus2LWCController {
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    public static void findImplementationdefinition(){
        List<Implementation_status_definition__mdt> ImpDef = ImplementationStatus2LWCController.getImplementationStatus();
    }
}
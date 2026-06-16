@isTest
public class Test_CustomMetadataSelector {

    @isTest
    private static void testSelectEUPrivacyMDT(){
        List<EU_Privacy_Setup__mdt> EUPrivacyList = (List<EU_Privacy_Setup__mdt>) new CustomMetadataSelector()
            .selectEUPrivacyMDT()
            .setQueryCaching(true)
            .executeQuery();
        System.assert(EUPrivacyList.size() > 0);
    }
        

}
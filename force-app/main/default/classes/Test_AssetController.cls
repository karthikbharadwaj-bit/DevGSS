@isTest
public class Test_AssetController {
	@isTest
    static void AssetControllerTest1(){
        Asset__c asst = new Asset__c();
        asst.Asset_Type__c = 'Hardware';
        asst.Sub_Asset_Type__c = 'Computer';
        asst.Manufacturer__c = 'Other';
        asst.Manufacturer_Other__c ='IBM';
        asst.Model__c ='Other';
        asst.Model_Other__c = 'IBM420';
        asst.Location__c ='Home Office';
        asst.Status__c = 'Deployed';
        insert asst;

        PageReference pageRef = Page.AssetClientPage;    
        Test.setCurrentPageReference(pageRef);  
        ApexPages.StandardController controller = new  ApexPages.StandardController ( asst );
        ApexPages.currentPage().getParameters().put('retURL', controller.getid());
        AssetController ac = new AssetController(controller);
        PageReference pg = ac.callDispatcher();
        PageReference testPage = new PageReference('/' + String.valueOf(asst.Id).left(15) + '/e');
        testPage.getParameters().put('retURL', controller.getId());
        testPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j0TM'), 'null');
        testPage.getParameters().put('nooverride','1');
        testPage.setRedirect(true);

        System.assertEquals(String.valueOf(pg), String.valueOf(testPage));
    }
}
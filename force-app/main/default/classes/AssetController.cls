public class AssetController {
   
    private String assetID;
    
    public AssetController(ApexPages.StandardController controller){
   		assetID  = 	controller.getId(); 
    }
    
    public PageReference callDispatcher() {
    	String keyPrefix = '/' + assetID + '/e'; 
	    PageReference assetPage = new PageReference(keyPrefix);
	    assetPage.getParameters().put('retURL',ApexPages.currentPage().getParameters().get('retURL'));
	    assetPage.getParameters().put(HardcodedIdsMapper.getMatchedObjectId('00N80000004j0TM'),'null');
        assetPage.getParameters().put('nooverride','1');
        assetPage.setRedirect(true);
        return assetPage;  
    }
}
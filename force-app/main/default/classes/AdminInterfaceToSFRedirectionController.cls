/*
Created By : Vidya Sampath
Purpose : Controller class for AdminInterfaceToSFRedirection VF Page
*/

public class AdminInterfaceToSFRedirectionController {

    public String baseURL { get; set; }
    public String enterpriseAccountID { get; set; }
    public String sfAccountID { get; set; }
    public String redirectionType { get; set; }
    public static final String DETAIL_TYPE = 'DETAIL';
    public static final String ENTERPRISE_ACCOUNT_ID_PARAM = 'EnterpriseAccountID';

    public AdminInterfaceToSFRedirectionController () {        

        /*Retrieve org base URL*/
        baseURL = Url.getOrgDomainUrl().toExternalForm();
        System.debug('baseURL : ' + baseURL);       
                
        enterpriseAccountID = '';
        /*Retrieve SF Account ID based on RC user ID*/
        if(Apexpages.currentPage().getParameters().get('EnterpriseAccountID')!=null){
            enterpriseAccountID = Apexpages.currentPage().getParameters().get('EnterpriseAccountID');            
            sfAccountID = getSFAccountID(enterpriseAccountID);
        }  
    }
    
    private String getSFAccountID(String RCUserID){
        
        List<Account> accts = [Select Id from Account where RC_User_ID__c = :RCUserID limit 1];        
        if(!accts.isEmpty()){
           return accts.get(0).Id;
        }        
        return '';
    }
}
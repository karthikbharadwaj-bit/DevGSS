public class LeadClonePageController {
    public static String leadId{get;set;}
    public static Boolean showSpinner{get;set;}
    public static String UITheme = UserInfo.getUIThemeDisplayed();
    public LeadClonePageController(ApexPages.StandardController controller)
    {
		leadId=controller.getId();     
        showSpinner = true;
    }
    public static PageReference cloneLead(){
        List<String> lstFieldAPINames = new List<String>();
        String returnURL;
        for(Lead_Fields_to_Clone__mdt lfc : [Select Field_API_Name__c from Lead_Fields_to_Clone__mdt])
        {
            lstFieldAPINames.add(lfc.Field_API_Name__c);
        }
        String query = 'SELECT '+String.join(lstFieldAPINames, ',')+' from Lead where Id = :leadId';
        Lead l = Database.query(query);
        
        Lead cloneLead = new Lead();
	   cloneLead.Lead_System_Source__c = 'Lead Clone Button';
        for(String s : lstFieldAPINames)
        {
            cloneLead.put(s,l.get(s));
        }
        insert cloneLead;
        if(UITheme == 'Theme4d')
        {
            returnURL = '/lightning/r/Lead/'+cloneLead.Id+'/edit?navigationLocation=DETAIL&backgroundContext=%2Flightning%2Fr%2FLead%2F'+cloneLead.Id+'%2Fview';
        }
        else
        {
            returnURL = '/'+cloneLead.Id+'/e?retURL=%2F'+cloneLead.Id;
        }
        return new PageReference(returnURL);
    }
}
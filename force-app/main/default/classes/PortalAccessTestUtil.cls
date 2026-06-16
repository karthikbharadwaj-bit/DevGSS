public class PortalAccessTestUtil {
    public static Account partnerAccount{get;set;}
    public static List<Contact> partnerContactLst{get;set;}
    
    public PortalAccessTestUtil(Account acctInput,List<Contact> contactLstInput){
        partnerAccount = acctInput;
        partnerContactLst = contactLstInput;
        this.createPortalAccessList();
    }
    public void createPortalAccessList(){
        List<Portal_Access__c> portalAccessLst = new List<Portal_Access__c>();
        for(Contact con : partnerContactLst){
        	Portal_Access__c pa1 = new Portal_Access__c();
            pa1.Account__c = partnerAccount.Id;
            pa1.Contact__c = con.Id;
            portalAccessLst.add(pa1);
        }
        List<Group> grpLst = [Select Id,DeveloperName from Group where DeveloperName = 'Avaya_CAM_Canada'];
        Group grp1 = new Group();
        if(grpLst != null && !grpLst.isEmpty()){
            grp1 = grpLst.get(0);
        }else{
            Group grp = new Group(
                DeveloperName='Avaya_CAM_Canada',
                Name = 'Avaya CAM Canada'
            );
            insert grp;
            grp1 = grp;
        }
        
        Portal_Access__c pa2 = new Portal_Access__c();
        pa2.Brand_Name__c = 'Avaya Cloud Office';
        pa2.Country__c = 'United States';
        pa2.Group_Developer_Name__c = 'Avaya_CAM_Canada';
        portalAccessLst.add(pa2);
        insert portalAccessLst;             
    }
    
    /*public void updPortalAccessList(){
        List<Portal_Access__c> portalAccessLstToUpd = [Select Id,Account__c, Contact__c from Portal_Access__c Limit 1];
        portalAccessLstToUpd.get(0).Contact__c = partnerContactLst.get(0).Id;
        update portalAccessLstToUpd;      
    }
    public void delPortalAccessList(){
        List<Portal_Access__c> portalAccessLstToDel = [Select Id,Account__c, Contact__c from Portal_Access__c Limit 1];
        delete portalAccessLstToDel;
    }*/
}
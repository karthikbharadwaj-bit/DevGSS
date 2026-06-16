public class BatchAccountPartnerManagerRole implements Database.Batchable<AggregateResult>{
    public Iterable<AggregateResult> start(Database.BatchableContext bc){
        String query;
        if(Test.isRunningTest()){
        	query = 'Select count(Id) cnt, PortalAccountId from UserRole where PortalType=\'Partner\' group by PortalAccountId having count(Id) = 1 limit 200' ;
        }
        else
        {
           query = 'Select count(Id) cnt, PortalAccountId from UserRole where PortalType=\'Partner\' group by PortalAccountId having count(Id) = 1' ; 
        }
        return new AggregateResultIterable(query);
    }
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        System.debug('Stato1:'+scope);
		List<UserRole> managerRolesList = new List<UserRole>();
        Map<Id,Integer> accountRoleCountMap = new  Map<Id,Integer>();
        AggregateResult[] accUserRoleCountResult;
        accUserRoleCountResult = scope;
        List<Id> accountRoleCountList = new List<Id>();
        for(AggregateResult ar : accUserRoleCountResult){
			accountRoleCountMap.put((Id)ar.get('PortalAccountId'),(Integer)ar.get('cnt'));
		}
        for(Id portalAcctId : accountRoleCountMap.keySet())
		{
           if(accountRoleCountMap.get(portalAcctId) < 2) {   
            UserRole role = new UserRole();
            role.portalType = 'Partner'; // use 'CustomerPortal' for customer portal roles
   			role.PortalAccountId = portalAcctId;
   			role.CaseAccessForAccountOwner = 'Edit'; //Modify as needed
    		role.OpportunityAccessForAccountOwner = 'Read'; //Modify as needed
    		role.ContactAccessForAccountOwner = 'None'; //Modify as needed
    		managerRolesList.add(role);
           }
		}
        System.debug('Stato1:'+managerRolesList);
        System.debug(managerRolesList.size());
        if(managerRolesList.size()>0){
            Database.insert(managerRolesList,true);
        }
    }
     public void finish(Database.BatchableContext BC){
    }
}
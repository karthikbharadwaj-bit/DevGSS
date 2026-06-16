public with sharing class AccountHierarchyValidation {

	public Static void validateAccountHierarchy(List<Account> lstAccount){
    
    	Set<ID> customerParent=new Set<ID>();
    	Set<String> customerAccountIdSet15Digit =new Set<String>();
    	Map<Id,List<Integer>> mapDepth=new Map<Id,List<Integer>>();
     	Map<Id,Account> mapParentAccount=new Map<Id,Account>();
    	String strQueryCondition=''; 
     	for(Account objAccount:lstAccount){
        	if(objAccount.ParentId!=null){
            	customerParent.add(objAccount.ParentId);
        	}
        	customerAccountIdSet15Digit.add('%' + string.valueOf(objAccount.Id).substring(0, 15) + '%');        
     	}
  
   		if(customerParent.size()>0){
     		mapParentAccount=new Map<ID,Account>([Select  id,Parent_Detail__c,Account_Depth__c from Account where ID IN: customerParent]);
   		}

    	for(Account objAccount:[SELECT id,Parent_Detail__c,Account_Depth__c FROM Account WHERE (Parent_Detail__c!=null AND ParentId!=NULL) 
                                AND Parent_Detail__c LIKE : customerAccountIdSet15Digit]){  
            if(objAccount.Parent_Detail__c!=null && objAccount.Parent_Detail__c!=''){
            	String strParentDetail=objAccount.Parent_Detail__c;
                List<String> lst=strParentDetail.split(','); 
            	for(String objString:lst){
                	if(objString!=null && objString!=''){
                    	List<String> lst2=objString.split('-');
                        if(lst2.size()==2){
                        	if(mapDepth.get(lst2.get(1))!=null){
                            	mapDepth.get(lst2.get(1)).add(Integer.valueOf(lst2.get(0)));
                        	}else{
                                mapDepth.put(lst2.get(1),new List<Integer>{Integer.valueOf(lst2.get(0))});
                          	}
                       	}
                    }
               	}
        	}
    	}
    
		for(Account objAccount:lstAccount){
     		if(objAccount.ParentId!=null){ 
          		Account objParentAccount=mapParentAccount.get(objAccount.ParentId);   
          		if(objParentAccount!=null  && ((objParentAccount.Account_Depth__c+1)>4)){
                	objAccount.addError('This account cannot be added to hierarchy('+(objParentAccount.Account_Depth__c+1)+'), as it exceeds to hierarchy limit(4).');// cant create parent
             	}else if(objParentAccount!=null){
                	if(mapDepth.get(objAccount.id)!=null){
                    	List<Integer> lstDepth=mapDepth.get(objAccount.id);
                      	lstDepth.sort();
                      	Integer maxChild=lstDepth.size()>0?lstDepth.get(lstDepth.size()-1):0;
                   		if((maxChild+objParentAccount.Account_Depth__c+1)>4){
                        	objAccount.addError('This account cannot be added to hierarchy('+(maxChild+objParentAccount.Account_Depth__c+1)+'), as it exceeds to hierarchy limit(4)');// cant create child
                    	}
                 	}
             	}
         	}  
     	}
	}
 }
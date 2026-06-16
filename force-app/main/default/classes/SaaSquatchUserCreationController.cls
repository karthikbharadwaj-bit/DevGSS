public class SaaSquatchUserCreationController {
    
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String email {get;set;}
    
    public SaaSquatchUserCreationController(ApexPages.StandardController controller){}
    
    public PageReference save(){
        
        if(firstName == null || firstName == ''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter First name'));
            return ApexPages.currentPage();
        }
        else if(lastName == null || lastName == ''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter Last name'));
            return ApexPages.currentPage();
        }
        else if(Email == null || Email == ''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter Email'));
            return ApexPages.currentPage();
        }
        else if(! Pattern.matches('^([0-9a-zA-Z+_.-]*[0-9a-zA-Z]+[@][0-9a-zA-Z+_.-]+\\.[0-9a-zA-Z+_.-]*)$', email)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter Email in a valid format'));
            return ApexPages.currentPage();
        }
        else
        {

        saasquatch.ReferralSaaSquatchUpsertUserByIdReq insertUser = new saasquatch.ReferralSaaSquatchUpsertUserByIdReq();
        List<saasquatch.ReferralSaaSquatchUpsertUserByIdReq> users = new List<saasquatch.ReferralSaaSquatchUpsertUserByIdReq>();
        
        insertUser.userId = email;
        insertUser.accountId = email;
        insertUser.firstName = firstName;
        insertUser.lastName = lastName;
        insertUser.Email = email;
        insertUser.immediatelyUpsertObjects=true;
            
        users.add(insertUser);
        if(!Test.isRunningTest()){
             saasquatch.ReferralSaaSquatchUpsertUserById.upsertUsers(users);   
        	}
            return new PageReference('javascript:window.close()');
        }

    }
            
    public PageReference cancel(){
        	return new PageReference('javascript:window.close()');
        }

}
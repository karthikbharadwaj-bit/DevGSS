@istest
public class test_doNotContactBannerController {

    @istest
    public static void getAccount(){
        Account acc = new Account(Name = 'test 01');
        insert acc;
        
        Account accDonot = new Account(Name = 'test 02', Partner_Account__c=acc.Id, PartnerAccountDoNotContact__c=true);
        insert accDonot;
        
        DoNotContactBannerController.getAccount(accDonot.Id);
        system.assertequals(True,accDonot.PartnerAccountDoNotContact__c);
    }
}
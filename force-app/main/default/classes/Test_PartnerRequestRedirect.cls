@isTest
public class Test_PartnerRequestRedirect {
    
    @isTest
    static void myUnitTestPartnerRequestRedirect() {    
        
        Lead objLead = new Lead();
        objLead.FirstName ='First Name';
        objLead.LastName ='Last Name';
        objLead.Title ='Title';
        objLead.Company ='Company Name';
        objLead.Email ='test@email.com';
        objLead.Website ='Website';
        objLead.Phone='tyityiyi';
        insert objLead;
        
        Test.startTest();  
        try {  
            ApexPages.currentPage().getParameters().put('leadId', objLead.Id);
            PartnerRequestRedirect prr = new PartnerRequestRedirect(); 
            prr.redirectToPartnerRequest();
            
        } catch(Exception e) {}
        Test.stopTest();
        
        Lead l = [Select Company FROM Lead Where Id =:objLead.Id];
        System.assertEquals(l.Company,'Company Name');
    }  
    @isTest
    static void myUnitTestPartnerRequestRedirectCon() {    
        
        
        Account acctest1 = new Account();
        acctest1.Name='TestAccount';
        insert acctest1;
        
        Contact objcon = new Contact(FirstName='test',LastName ='testl',AccountId = acctest1.id);
        insert objcon;
        
        Test.startTest();  
        try {  
            ApexPages.currentPage().getParameters().put('contactId', objcon.Id);
            PartnerRequestRedirect prr = new PartnerRequestRedirect(); 
            prr.redirectToPartnerRequest();
            
        } catch(Exception e) {}
        Test.stopTest();
        
        Contact c = [Select FirstName FROM Contact Where Id =:objcon.Id];
        System.assertEquals(c.FirstName,'test');
    }  
}
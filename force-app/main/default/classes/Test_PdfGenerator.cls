@isTest
private class Test_PdfGenerator {

    private static RC_Quote_Template__c createTemplate(String name, String objectName) {
        RC_Quote_Template__c template = new RC_Quote_Template__c(
            Name = name,
            Template_Engine__c = TemplateEngine.PDF_ENGINE_2_0,
            ObjectName__c = objectName,
            Active__c = true
        );

        insert template;
        return template;
    }

    private static User createUser(String name) {
        String[] splitedName = name.split(' ');
        User user = new User(
            Username = splitedName[0]+'@neverland.com',
            LastName = splitedName[1],
            Email = splitedName[0]+'@neverland.com',
            Alias = splitedName[0],
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name = name
        );

        insert acc;
        return acc;
    }

    private static Contact createContact(String name, Account acc) {
        Contact cont = new Contact(
            AccountId = acc.Id,
            FirstName = name.split(' ')[0],
            LastName = name.split(' ')[1],
            Email = name.split(' ')[0]+name.split(' ')[1]+'@neverland.com'
        );

        insert cont;
        return cont;
    }

    private static Opportunity createOpportunity(String name, Account acc, Contact cont) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = acc.Id,
            Primary_Opportunity_Contact__c = cont.Id,
            StageName = '1. Qualify',
            Type = 'Existing Business',
            CloseDate = System.today()
        );

        insert opp;
        return opp;
    }

    private static BigWins_Form__c createBigWinsForm(User user, Opportunity opp) {
        BigWins_Form__c bigwinsform = new BigWins_Form__c(
            Opportunity__c = opp.Id,
            Your_Name__c = user.Id,
            Payment_Terms__c = 'Annual',
            Contract__c = '1',
            Office_Edition__c = 'Standard',
            No_of_Users__c = 1,
            HUD__c = 'Irrelevant',
            Softphone__c = 'Irrelevant',
            Website__c = '123',
            Number_of_Phones__c = 1,
            Sales_Cycle_Days__c = 1,
            Is_this_customer_moving_to_a_New_Office__c = 'Not Sure',
            Is_cx_buying_PBX_1st_time_replacement__c = 'First PBX Purchase',
            Did_the_Mobile_App_play_a_role__c = 'No',
            Previous_Service__c = 'Test',
            Competitors__c = 'Test',
            What_Why_How_Please_provide_details__c = 'Test',
            Prioritized_requirements__c = 'Test',
            Core_objections__c = 'Test',
            Key_Features_Needed__c = 'Test',
            Account_Exective__c=UserInfo.getName(),
            Did_Glip_help_influence_this_deal__c = 'No'
        );

        insert bigwinsform;
        return bigwinsform;
    }



	@isTest static void test_get_templates() {

        Test.startTest();

        User user = createUser('Test User');
        Account acc = createAccount('Test Account');
        Contact cont = createContact('Test Contact', acc);
        Opportunity opp = createOpportunity('Test Opportunity', acc, cont);
        BigWins_Form__c bw = createBigWinsForm(user, opp);
        RC_Quote_Template__c template = createTemplate('Test Template', 'BigWins_Form');

        RC_Quote_Template__c[] templateList = PdfGenerator.getTemplates(bw.Id);

        Test.stopTest();

        System.assertEquals(1, templateList.size() );
        System.assertEquals('Test Template', templateList[0].Name );
    }

    @isTest static void test_attachPdf() {

        Test.startTest();

        User user = createUser('Test User');
        Account acc = createAccount('Test Account');
        Contact cont = createContact('Test Contact', acc);
        Opportunity opp = createOpportunity('Test Opportunity', acc, cont);
        BigWins_Form__c bw = createBigWinsForm(user, opp);
        RC_Quote_Template__c template = createTemplate('Test Template', 'BigWins_Form');

        // just for coverage =)
        ApexPages.currentPage().getParameters().put('objectid', bw.Id);
        ApexPages.currentPage().getParameters().put('templateId', template.Id);
        PdfGenerator ctrl = new PdfGenerator();

        Map<string,string> result = PdfGenerator.attachPdf(template.Id, bw.Id);
        Map<string,string> result2 = PdfGenerator.attachPdf(null, null);
        Test.stopTest();

        Attachment[] attachmentList = [SELECT Id, Name FROM Attachment WHERE parentId =: bw.Id ORDER BY LastModifiedDate ASC NULLS LAST LIMIT 1];
        BigWins_Form__c updatedBW = [SELECT LastAttachedPDFId__c, Name, Account_Name__r.Name FROM BigWins_Form__c WHERE Id =: bw.Id LIMIT 1];

        /*Set<String> pdfNamesList = new Set<String> {
                updatedBW.Account_Name__r.Name +' - '+UserInfo.getName()+ '.pdf',
                updatedBW.Name +' - '+UserInfo.getName()+ '.pdf'
        };*/
        System.assertEquals(1, attachmentList.size());
        System.assertEquals('OK', result.get('Status'));
        //System.assert(pdfNamesList.contains(attachmentList[0].Name));
        System.assertEquals(updatedBW.LastAttachedPDFId__c, attachmentList[0].Id);

        System.assertEquals('ERROR', result2.get('Status'));
    }
}
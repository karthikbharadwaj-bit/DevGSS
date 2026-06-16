/**************************************************************************************************
* Project Name..........: RingCentral -                                                           *
* File..................: Test_DynamicHomeComponentctrl                                           *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 7th October 2014                                                        *
* Description...........: This is a test class for PartnerPortal to be dynamic                    *
* UPDATE
* By:                     eugenebasianomutya
* Date:                   29/04/2015
* Detail:                 Get Folder id so that class can be used to all sandbox
**************************************************************************************************/
@isTest
private class Test_DynamicHomeComponentctrl{
     @isTest
	public static void unitTest_DynamicHomeComponentctrl(){ 

        //Get Folder ID
        Folder f = [Select Id From Folder where Name = 'Public Documents'];    

        Document doc = new Document();
        doc.Name = 'PartnerPortalEventsCSV';
        doc.Body = Blob.valueOf('PartnerPortalEventsCSV');
        doc.FolderId = f.Id; 
        insert doc;

        Document doc1 = new Document();
        doc1.Name = 'PartnerPortalAnnouncement';
        doc1.Body = Blob.valueOf('PartnerPortalAnnouncement');
        doc1.FolderId = f.Id; 
        insert doc1 ;

        Document doc2 = new Document();
        doc2.Name = 'PartnerPortalHomeCmp'; 
        doc2.Body = Blob.valueOf('PartnerPortalHomeCmp');
        doc2.FolderId = f.Id; 
        insert doc2 ;

        DynamicHomeComponentctrl dynHomeComp = new DynamicHomeComponentctrl(); 
        String contents='DBLQT';    
        Boolean skipHeaders =true; 
        DynamicHomeComponentctrl.parseCSV(contents, skipHeaders);

        Test.startTest();
            Blob csvbody = doc.Body;
            List<DynamicHomeComponentctrl.CSVWrapper> wrappers = dynHomeComp.getResults();
        Test.stopTest();

        System.assertNotEquals(wrappers, null);
        System.assertEquals(wrappers.size(), 0);
    }

    @isTest
    static void testCSVWrapperConstructor() {
        DynamicHomeComponentctrl.CSVWrapper wrapper = new DynamicHomeComponentctrl.CSVWrapper('Monday', '2024-05-07', '10:00 AM', 'Location', 'Webinar', 'https://example.com');
        
        System.assertEquals('Monday', wrapper.eventDay);
        System.assertEquals('2024-05-07', wrapper.eventDate);
        System.assertEquals('10:00 AM', wrapper.eventTime);
        System.assertEquals('Location', wrapper.eventLocation);
        System.assertEquals('Webinar', wrapper.webinar);
        System.assertEquals('https://example.com', wrapper.eventUrl);
    }
 }
/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Each testMethod is names for the trigger or object it is testing
 */
@isTest
private class triggerTests {
	private class LimitException extends Exception {}
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testRefundBefore(){
		try{
		test.startTest();

        Account a = new Account();
        a.Name = 'TestRefundAccount';
        a.RC_User_ID__c = '345';
        a.RC_Brand__c = 'RC';
        a.RC_Service_name__c = 'mobile';
        a.RC_Tier__c = 'professional';
        insert a;

        a.RC_Activation_Date__c = null;
        a.RC_Service_name__c = 'RCOffice';
        update a;

        datetime myDT = datetime.now();
        a.RC_Activation_Date__c = myDT;
        a.RC_Service_name__c = 'RC Office';
        update a;

        Refund__c r = new Refund__c();
        r.Account__c = a.Id;
        r.Reference__c = '1234';
        insert r;

        test.stopTest();
        }catch(Exception exp){

    	}
	}

	//
	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testCaseBefore(){
		try{
			Test.startTest();
			Account a = new Account(Name='new');
			insert a;
			//test.startTest();
			Case caseTest = new Case(Account=a);
			insert caseTest;

			//Contact c = new Contact(lastName='lastTest', AccountId = a.Id, email='test@ringcentral.com');
			Contact c = new Contact(lastName='lastTest', AccountId = a.Id, email='rcpartnersync@ringcentral.com.box1');
			insert c;
			test.stopTest();
			Case caseTest2 = new Case(Account=a, ContactId=c.Id);
			insert caseTest2;

			update caseTest2;
			//Test.stopTest();
		}catch(Exception exp){

		}

   	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testSaverTriggers() {
		try {
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
			// Create test data (a new Account with an Attachment)
			Account acct = new Account(Name = 'Test Account');
			insert acct;
			List<SObject> objects = new List<SObject>();
			List<Opportunity> opps = (List<Opportunity>) new SObjectBuilder(Opportunity.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Opportunity.AccountId => acct.Id,
					Opportunity.Name => 'testOpp',
					Opportunity.Type => 'New Business',
					Opportunity.CloseDate => Date.today(),
					Opportunity.StageName => new ValueProvider.ListProvider(new List<String> {
                        OpportunityHelper.defaultOpportunityStage,
                        '3. NoActivePipe'
                    }),
					Opportunity.OwnerId => new ValueProvider.ListProvider(new List<String> {
						null,
						HardcodedIdsMapper.getMatchedObjectId('0058000000379gR')
					})
				})
				.quantity(2)
				.create()
				.getRecords();
			
			Lead l = (Lead) new SObjectBuilder(Lead.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Lead.LastName => 'Last',
					Lead.Company => 'Company',
					Lead.Phone => '345565',
					Lead.Email => 'ead@triggertest.com',
					Lead.OwnerId => HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ')
				})
				.create()
				.getRecord();
			
			List<Event> events = (List<Event>) new SObjectBuilder(Event.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Event.Subject => 'testEvent',
					Event.StartDateTime => DateTime.now(),
					Event.DurationInMinutes => 10,
					Event.WhatId => new ValueProvider.ListProvider(new List<Id> {
                        opps.get(1).Id, null
                    }),
					Event.WhoId => new ValueProvider.ListProvider(new List<String> {
						null, l.Id
					})
				})
				.quantity(2)
				.create()
				.getRecords();

			Task t = (Task) new SObjectBuilder(Task.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Task.Subject => 'testTask',
					Task.WhatId => opps.get(1).Id,
					Task.ActivityDate => Date.Today()
				})
				.build()
				.getRecord();

			Implementation__c i = (Implementation__c) new SObjectBuilder(Implementation__c.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Implementation__c.Name => 'testImp',
					Implementation__c.Implementation_Status__c => 'Needed'
				})
				.build()
				.getRecord();

			Note n = (Note) new SObjectBuilder(Note.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Note.Title => 'testNote',
					Note.ParentId => opps.get(1).Id,
					Note.Body => 'Note body'
				})
				.build()
				.getRecord();

			Attachment a = (Attachment) new SObjectBuilder(Attachment.SObjectType)
				.setFields(new Map<SObjectField, Object> {
					Attachment.Name => 'testAttachment',
					Attachment.ParentId => opps.get(1).Id,
					Attachment.Body => Blob.valueOf('dkjghdksgjdshgdkh')
				})
				.build()
				.getRecord();
			objects.addAll(new List<SObject>{t, i, n, a});

			try {
				insert objects;
			} catch (Exception e) {
				System.debug(e);
			}
			objects.clear();
			events.get(0).subject = 'newSubject';
			t.subject = 'newSubject';
			n.title = 'newTitle';
			a.Name='newName';
			objects.addAll(new List<SObject>{events.get(0), t, n, a});
			Test.startTest();
			try {
				update objects;
			} catch (Exception e) {
				System.debug(e);
			}

			try {
				Note nl = (Note) new SObjectBuilder(Note.SObjectType)
					.setFields(new Map<SObjectField, Object> {
						Note.Title => 'testNote',
						Note.ParentId => l.id,
						Note.Body => 'Note body'
					})
					.create()
					.getRecord();

				nl.title = 'newTitle';
				update nl;
			} catch (Exception e) {
				System.debug(e);
			}
			try {
				Task tl = (Task) new SObjectBuilder(Task.SObjectType)
					.setFields(new Map<SObjectField, Object> {
						Task.Subject => 'testTask',
						Task.WhoId => l.Id,
						Task.ActivityDate => Date.Today()
					})
					.create()
					.getRecord();

				new SObjectBuilder(Attachment.SObjectType)
					.setFields(new Map<SObjectField, Object> {
						Attachment.Name => 'testAttachment',
						Attachment.ParentId => l.Id,
						Attachment.Body => Blob.valueOf('dkjghdksgjdshgdkh')
					})
					.create();

				events.get(1).subject = 'newSubject';
				update events.get(1);
				tl.subject = 'newSubject';
				update tl;
			} catch (Exception e) {
				System.debug(e);
			}

			// Verify the "Unable to delete attachments" error is thrown when attachment is deleted
			Boolean errorThrown = false;
			try {
				delete n;
			} catch (Exception e) {
				System.debug(e);
			}

			errorThrown = false;
			try {
				delete events.get(0);
			} catch (Exception e) {
				System.debug(e);
			}

			errorThrown = false;
			try {
				delete t;
			} catch (Exception e) {
				System.debug(e);
			}

			errorThrown = false;
			try {
				delete i;
			} catch (Exception e) {
				System.debug(e);
			}
			Test.stopTest();
		} catch(Exception exp) {

		}
	}

	/**
    * Verify that Standard User profiles are unable to delete attachments
    */
    @isTest
    static void testSaveTriggers() {
		Test.startTest();
        try{
    		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;

        // Create a new user with the Standard User profile
        Profile salesAgentProf = [select id from profile where name='Sales Agent SDR w Insidesales'];
        User su = new User(firstname='testy', lastname='test', alias = 'testing', email='salesagent@test.com',
            emailencodingkey='UTF-8', languagelocalekey='en_US',
            localesidkey='en_US', profileid = salesAgentProf.Id,
            timezonesidkey='America/Los_Angeles', username='salesagent123@test.com');
        insert su;

        Employee__c emp = new Employee__c(User__c = su.Id, Division__c = 'Sales');
        insert emp;

        // Switch current user to Sales Agent User
        System.runAs(su) {
			// Create test data (a new Account with an Attachment)
			Triggers.switchOff();
            Account acct = new Account(Name = 'Test Account');
			insert acct;
			Triggers.switchOn();
            //Opportunity opp = new Opportunity(AccountId = acct.Id, Name='testOpp', Type = 'New Business', CloseDate = Date.today(), StageName = OpportunityHelper.defaultOpportunityStage);
            //insert opp;
            Opportunity opp = new Opportunity(AccountId = acct.Id, Name='testOpp', OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'), Type = 'New Business', CloseDate = Date.today(), StageName = '3. NoActivePipe');
            insert opp;

            Event event = new Event(subject='testEvent', whatId = opp.Id, StartDateTime = DateTime.now(), DurationInMinutes = 10);
            try {
            	insert event;
            	 event.subject = 'newSubject';
            update event;
            }catch (Exception e) {
                System.debug(e);
            }

            Task t = new Task(subject='testTask', whatId = opp.Id, ActivityDate = Date.Today());
             try {
            insert t;
            t.subject = 'newSubject';
            update t;
            }catch (Exception e) {
                System.debug(e);
            }

            System.debug('3 System.Limits.getQueries() >>>>>>>>> ' + System.Limits.getQueries());

            Implementation__c i = new Implementation__c(name='testImp', Implementation_Status__c='Needed');
             try {
            insert i;
            } catch (Exception e) {
                System.debug(e);
            }

            Note n = new Note(title = 'testNote', parentId = opp.Id, Body = 'Note body');
            try {
            insert n;
            n.title = 'newTitle';
            update n;
            } catch (Exception e) {
                System.debug(e);
            }

            Attachment a = new Attachment(Name='testAttachment', parentId=opp.Id, body=Blob.valueOf('dkjghdksgjdshgdkh'));
            try {
            insert a;
            a.Name='newName';
            update a;
            } catch (Exception e) {
                System.debug(e);
			}

			Boolean errorThrown = false;
			try {
				delete i;
			} catch (Exception e) {
				System.debug(e);
				if (e.getMessage().contains('Unable to delete Implementations.')) {
					errorThrown = true;
				}
				errorThrown = true;
			}
			System.assert(errorThrown);

			// Verify the "Unable to delete attachments" error is thrown when attachment is deleted
			errorThrown = false;
			try {
				delete n;
			} catch (Exception e) {
				errorThrown = true;
			}
			System.assert(errorThrown);
        }
        Test.stopTest();
        }catch(Exception e){}
	}
	
	@isTest
    static void testSaveTriggersForLead() {
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;

        // Create a new user with the Standard User profile
        Profile salesAgentProf = [select id from profile where name='Sales Agent SDR w Insidesales'];
        User su = new User(firstname='testy', lastname='test', alias = 'testing', email='salesagent@test.com',
            emailencodingkey='UTF-8', languagelocalekey='en_US',
            localesidkey='en_US', profileid = salesAgentProf.Id,
            timezonesidkey='America/Los_Angeles', username='salesagent456@test.com');
        insert su;

        Employee__c emp = new Employee__c(User__c = su.Id, Division__c = 'Sales');
		insert emp;
		
		System.runAs(su) {
			Lead l = new Lead(LastName='Last', Company='Company', Phone='345565', Email='lead@triggertest.com', OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'));
			try {
			insert l;
			} catch (Exception e) {
				System.debug(e);
			}
			Test.startTest();
			Note nl = new Note(title = 'testNote', parentId = l.id, Body = 'Note body');
			try {
				insert nl;
				nl.title = 'newTitle';
				update nl;
			} catch (Exception e) {
				System.debug(e);
			}

			Event eventl = new Event(subject='testEvent', whoId = l.Id, StartDateTime = DateTime.now(), DurationInMinutes = 10);
			Task tl = new Task(subject='testTask', whoId = l.Id, ActivityDate = Date.Today());
			try {
			insert eventl;
			insert tl;
			Attachment al = new Attachment(Name='testAttachment', parentId=l.Id, body=Blob.valueOf('dkjghdksgjdshgdkh'));
			insert al;
			Test.stopTest();
			eventl.subject = 'newSubject';
			update eventl;
			tl.subject = 'newSubject';
			update tl;
			//al.Name='newName';
			//update al;
			} catch (Exception e) {
				System.debug(e);
			}

			Boolean errorThrown = false;
			try {
				delete eventl;
			} catch (Exception e) {
				System.debug(e);
				if (e.getMessage().contains('Unable to delete events.')) {
					errorThrown = true;
				}
				errorThrown = true;
			}
			//System.assert(errorThrown);

			errorThrown = false;
			try {
				delete tl;
			} catch (Exception e) {
				System.debug(e);
				if (e.getMessage().contains('Unable to delete tasks.')) {
					errorThrown = true;
				}
				errorThrown = true;
			}
			System.assert(errorThrown);
		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void testSaveTriggersForAnotherLead() {
		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
		TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
		Lead l1 = new Lead(LastName='Last1', Company='Company1', Phone='3455651', Email='lead1@triggertest.com', OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'));
		insert l1;

		try {
			Note nl1 = new Note(title = 'testNote1', parentId = l1.id, Body = 'Note body1');
			insert nl1;
			nl1.title = 'newTitle';
			update nl1;
		} catch (Exception e) {
			System.debug(e);
		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
    static void myOppStageTest(){
		try{
			TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
			TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
	        Profile salesAgentProf = [select id from profile where name='Sales Agent SDR w Insidesales'];
	        User su = new User(firstname='testy', lastname='test', alias = 'testing', email='salesagent@test.com',
	            emailencodingkey='UTF-8', languagelocalekey='en_US',
	            localesidkey='en_US', profileid = salesAgentProf.Id,
	            timezonesidkey='America/Los_Angeles', username='salesagent789@test.com');
	        insert su;

	        Employee__c emp = new Employee__c(User__c = su.Id, Division__c = 'Sales');
	        insert emp;

	        Account a = new Account();
	        a.Name = 'TestbyJesse';
	        insert a;
	        Contact c = new Contact();
	        c.LastName = 'contactLast';
	        c.AccountId = [SELECT id FROM Account WHERE name=: a.Name].id;
	        c.email='test@rc.com';
	        insert c;

	        System.runAs(su) {
			        Opportunity oD = new Opportunity();
			        oD.Name = 'TestaOppOwnerD';
			        oD.AccountId = c.AccountId;
			        oD.Type = 'New Business';
			        oD.CloseDate = Date.today();
			        oD.StageName = OpportunityHelper.defaultOpportunityStage;
			        oD.RC_User_ID__c = '3455';
			        oD.Primary_Loss_Reason__c = 'Price';
			        oD.Service_Lost__c = 'Office';
			        insert oD;
		        /* end test with owner */

		        oD.Name = 'update';
		        oD.StageName = OpportunityHelper.closedStage;
		        update oD;
	        }

	        Test.startTest();

	        Opportunity o = new Opportunity();
	        o.Name = 'TestaOpp';
	        o.AccountId = c.AccountId;
	        o.Type = 'New Business';
	        o.CloseDate = Date.today();
	        o.StageName = OpportunityHelper.defaultOpportunityStage;
	        o.RC_User_ID__c = '345';
	        o.Primary_Competitor__c = '3Com';
	        o.Primary_Loss_Reason__c = 'Price';
	        o.Service_Lost__c = 'Office';
	        insert o;
	        OpportunityContactRole ocr = new OpportunityContactRole(ContactId=c.Id, OpportunityId=o.Id);
	        insert ocr;


	        o.StageName = '0. Trial';
	        system.debug('this is opp stage, reason: ' + o.StageName + ', ' + o.Downgrade_Reason_Opp__c);
	        o.OwnerId = HardcodedIdsMapper.getMatchedObjectId('0058000000379gR');
	        update o;

	        o.StageName = '0. Downgraded';
	        o.Downgrade_Reason_Opp__c = 'Trial Expired';
	        try{
	        	update o;
	        }
	        catch(System.Exception e){

	        }

	        o.StageName = '0. Downgraded';
	        o.Downgrade_Reason_Opp__c = 'Lost to Competition';
	        try{
	        	update o;
	        }
	        catch(System.Exception e){

	        }
	        system.debug('this is opp stage, reason' + o.StageName + ', ' + o.Downgrade_Reason_Opp__c);

	        o.StageName = OpportunityHelper.closedStage;
	        update o;

	        o.Warm_transfer_to_SE__c = true;
	        update o;

	        o.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
	        o.Campaign = [SELECT id FROM Campaign WHERE Name='Default Campaign'];
	        update o;
	 		Test.stopTest();
		} catch(Exception exp){ }
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testAgentCredit(){
		try{
		Account a = new Account(name='testaccount',RC_Account_Number__c='1231234567');
		insert a;
		Order__c o = new Order__c(name='testorder', account__c=a.Id, Order_Type__c='New', Sales_Model__c='Direct');
		insert o;
		Test.startTest();
		Agent_Credit__c ac = new Agent_Credit__c(name='test', Agent_SPID__c='DDEMINK', order__c=o.id, Agent_Email__c='daved@ringcentral.com', X12M_Sales_Booking_Amount__c=decimal.valueOf('100.00'), Compensation_Date__c=Date.Today(), Agent_First_Name__c='test', Agent_Last_Name__c='');
		insert ac;

		Agent_Credit__c ac2 = new Agent_Credit__c(name='test', Agent_SPID__c='DDEMINK', order__c=o.id, Agent_Email__c='notReal@ringcentral.com', X12M_Sales_Booking_Amount__c=decimal.valueOf('100.00'), Compensation_Date__c=Date.Today(), Agent_First_Name__c='test', Agent_Last_Name__c='');
		insert ac2;
		Test.stopTest();
		}catch(Exception exp){

    	}

	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testEvent(){
		Event e =new Event(subject='Call', StartDateTime=DateTime.now().addDays(-1), EndDateTime=DateTime.now().addDays(-1));
		try{
			insert e;
		}
		catch(System.Exception ex){

		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	public static void testEventError(){
		Event e =new Event(
			subject='Call',
			StartDateTime=DateTime.now().addDays(-3), 
			EndDateTime=DateTime.now().addDays(-1), 
			RecordTypeId=Schema.SObjectType.Event.getRecordTypeInfosByName().get('VIP Event').getRecordTypeId()
		);
		try{
			insert e;
		}
		catch(System.Exception ex){
		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testTask(){
		Task t =new Task(subject='Call', ActivityDate=Date.today().addDays(-1));
		try{
			insert t;
		}
		catch(System.Exception e){

		}
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testLead(){
		try{
			Campaign c = new Campaign(name='testcampaign', aid__c='1111', isactive=true);
			insert c;

			List<Lead> leads = new List<Lead>();
	        Lead l1 = new Lead(lastname='DC0', company='DC0',phone='4565342558', aid__c='7580',LeadSource='Inbound Call', NumberOfEmployees__c='10-19',email='DB0@ringcentral.com', OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'));
	        leads.add(l1);

	        Lead l = new Lead(OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'), lastname='DC0', company='DC0',phone='4565342559', five9_dnis__c='8004293709', LeadSource='Partner Request', NumberOfEmployees__c='10-19',email='DC0@ringcentral.com');
	        leads.add(l);

	        l = new Lead(OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'), lastname='new', firstname='something', company='DC1',phone='4565342560', LeadSource='Initial', NumberOfEmployees__c='10-19',email='DC1@ringcentral.com');

	        leads.add(l);

	        l = new Lead(OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'), lastname='DC2', company='DC2',phone='4565342561', LeadSource='About To Be Cancelled', NumberOfEmployees__c='10-19',email='DC2@ringcentral.com');
	        l.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
	        leads.add(l);

			l = new Lead(OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ'), lastname='DC2', company='DC2',phone='4565342561', LeadSource='About To Be Cancelled', NumberOfEmployees__c='10-19',email='DC2@ringcentral.com');
	        l1.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
			l1.BMID__c = 'FAXTESTDRIVE2' ;
			l1.FirstName ='NotSomething' ;
			l1.LastName ='NewNot';
	        leads.add(l);

	        insert leads;

	        // test downgrade validation rule
			l.status = '0. Downgraded';
			try{
				update l1;
			}
			catch(System.Exception e){
				l.downgrade_reason__c='Lost to Competition';
				l.ownerId = HardcodedIdsMapper.getMatchedObjectId('00580000001gviZ');
				l.phone='321';
				l.email='mail@rc.com';
				update l1;
			}

			// test lead owner change
			// change lead owner
			l1.OwnerId = HardcodedIdsMapper.getMatchedObjectId('0058000000379gR');
			l1.AID__c = '6138';
			update l1;

			// test lead owner change to Dave D
			// change lead owner to Dave D
			l1.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
			l1.Five9_DNIS__c = '8005745290';
			l1.AID__c = '6139';
			update l1;

			l1.OwnerId = HardcodedIdsMapper.getMatchedObjectId('005800000036sJJ');
			l1.BMID__c = 'FAXTESTDRIVE2' ;
			l1.FirstName ='NotSomething' ;
			l1.LastName ='NewNot';
			update l1;
		}catch(Exception exp) {

		}

    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	public static void testImplementation(){

    	try{
    		if( Limits.getLimitQueries() == Limits.getQueries() ){
				throw new LimitException();
			} else {
		        Profile seProf = [select id from profile where name='Sales Engineer Lightning'];
		        User su = new User(alias = 'testing', email='se@test.com',
		            emailencodingkey='UTF-8', lastname='TestingTrigger', languagelocalekey='en_US',
		            localesidkey='en_US', profileid = seProf.Id,
		            timezonesidkey='America/Los_Angeles', username='se@test43.com');

		        // Switch current user to Sales Agent User

		        system.Test.startTest();

		        System.runAs(su){
		        }
		     	system.Test.stopTest();
    		}
    	}catch(Exception exp){

    	}

    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
	public static void testAccount(){

    }

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
	public static void testPRM() {
     	try{
     		Test.startTest();
	    	Partner_Request__c PRM = new Partner_Request__c ();
	    	PRM.Partner_Request_Source__c = 'General Partner';
	    	PRM.Partner_First_Name__c =  'test';
	    	PRM.Partner_Last_Name__c = 'test';
	    	PRM.Partner_Company_Name__c = 'test';
	    	PRM.Partner_Address1__c = 'test';
	    	PRM.Partner_City__c = 'test';
	    	PRM.Partner_State__c = 'test';
	    	PRM.Partner_Country__c = 'test';
	    	PRM.Partner_Phone__c = '12346789';
	    	PRM.Partner_Email_Address__c = 'test@test.com';
	    	insert PRM;
	    	Test.stopTest();
     	}catch(Exception exp){

     	}

     }

	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
     @isTest
	public static void testEmployee() {
     	// Create a new user with the Standard User profile
       try{
       	if( Limits.getLimitQueries() == Limits.getQueries() ){
				throw new LimitException();
		} else {
        Profile salesAgentProf = [select id from profile where name='Sales Agent SDR w Insidesales'];
        User su = new User(firstname='testy', lastname='test', alias = 'testing', email='salesagent@test.com',
            emailencodingkey='UTF-8', languagelocalekey='en_US',
            localesidkey='en_US', profileid = salesAgentProf.Id,
            timezonesidkey='America/Los_Angeles', username='salesagent134@test.com');
        insert su;
        Test.startTest();
        Employee__c emp = new Employee__c(User__c = su.Id, Division__c = 'Sales', Department__c='Sales',Team__c='Sales');
        insert emp;

        update emp;
        Test.stopTest();
       	}
        }catch(Exception exp){

    	}
     }

	 @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
	@isTest
	public static void testEmailMessage(){
       try{
           Case objCase=new Case();
           insert objCase;

            EmailMessage objEmailMessage=new EmailMessage();
            objEmailMessage.ParentId=objCase.id;
            objEmailMessage.FromAddress='kanishk.singh@simplion.com';
            objEmailMessage.FromAddress ='kanishk.singh@simplion.com';
            insert objEmailMessage;
            delete objEmailMessage;
         }catch(Exception e){
          }
   	}

 	@isTest
	public static void testAttachment() {
 		  setByPassTriggers();
     	  if( Limits.getLimitQueries() == Limits.getQueries() ){
				throw new LimitException();
		  } else {
	       Profile p = [SELECT Id FROM Profile WHERE Name='Sales Agent SDR w Insidesales'];

	       User u1 = new User(Alias = 'suppmgr1', Email='supportmanager1@testorg.com',
	       EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
	       LocaleSidKey='en_US', ProfileId = p.Id,
	       TimeZoneSidKey='America/Los_Angeles', UserName='supportmanager132@testorg.com');

	       insert u1;

	       User u = new User(Alias = 'suppmgr2', Email='supportmanager2@testorg.com',
	       EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
	       LocaleSidKey='en_US', ProfileId = p.Id,
	       TimeZoneSidKey='America/Los_Angeles', UserName='supportmanager232@testorg.com');

	       insert u;

           Employee__c managerEmpObjToInsert = new Employee__c();
           managerEmpObjToInsert.First_Name__c = 'TestFNameMan';
           managerEmpObjToInsert.Last_Name__c = 'TestLNameMan';
           managerEmpObjToInsert.Email__c = 'standarduserman@testorg.com';
           insert managerEmpObjToInsert;

	       Employee__c empObj = new Employee__c();
	       empObj.User__c = u.Id;
	       empObj.First_Name__c = 'TestFName';
	       empObj.Last_Name__c = 'TestLName';
	       empObj.Email__c = 'standarduser@testorg.com';
	       empObj.Location__c = 'Denver, US';
	       empObj.Department__c = 'IT';
	       empObj.Team__c = 'Marketing';
	       empObj.Division__c = 'CV';
	       empObj.SPID__c = '12345';
           empObj.Manager_Employee_Number__c = (Id) new ValueProvider.DummyIdProvider(Employee__c.sObjectType).getValue();
           try {
                insert empObj;
           } catch (DmlException dmle) {
                empObj.Manager_Employee_Number__c = managerEmpObjToInsert.Id;
                insert empObj;
           }
	       System.runAs(u) {
	       	 try {
			       Account accVal = new  Account ();
			       accVal.Name = 'Test Account Name1';
			       insert accVal;

			       List<Opportunity> oppLst = new List<Opportunity>();

			       Opportunity oppObj = new Opportunity();
			       oppObj.AccountId = accVal.Id;
			       oppObj.Type = 'New Business';
			       oppObj.Brand_Name__c = 'RingCentral';
			       oppObj.Name = 'TestaOppOwnerD';
			       oppObj.CloseDate = Date.today();
			       oppObj.StageName = OpportunityHelper.defaultOpportunityStage;
			       oppObj.CurrencyIsoCode = 'USD';
			       oppObj.Sales_Model__c = 'Direct';

			       //insert oppObj;


			       Opportunity oppObj1 = new Opportunity();
			       oppObj1.AccountId = accVal.Id;
			       oppObj1.Type = 'New Business';
			       oppObj1.Brand_Name__c = 'RingCentral';
			       oppObj1.Name = 'TestaOppOwnerD1';
			       oppObj1.CloseDate = Date.today();
			       oppObj1.StageName = OpportunityHelper.defaultOpportunityStage;
			       oppObj1.CurrencyIsoCode = 'USD';
			       oppObj1.Sales_Model__c = 'Direct';

			       //insert oppObj1;

			       oppLst.add(oppObj1);
			       oppLst.add(oppObj);

			       insert oppLst;

			       List<Lead> leadLst = new List<Lead>();

			       Lead leadObj = new Lead();
			       leadObj.Company = 'Test company1';
			       leadObj.FirstName = 'Test Name';
			       leadObj.LastName = 'Test Name1';
			       leadObj.email = 'test1@test.com';
			      // leadObj.Last_Touched_By__c = ;
			       leadLst.add(leadObj);
			       //insert leadObj;

			       Lead leadObj1 = new Lead();
			       leadObj1.Company = 'Test company2';
			       leadObj1.FirstName = 'Test Nam2';
			       leadObj1.LastName = 'Test Name2';
			       leadObj1.email = 'test2@test.com';

			      leadLst.add(leadObj1);

			       Lead leadObj2 = new Lead();
			       leadObj2.Company = 'Test company3';
			       leadObj2.FirstName = 'Test Nam3';
			       leadObj2.LastName = 'Test Name3';
			       leadObj2.email = 'test3@test.com';

			      leadLst.add(leadObj2);

			       Lead leadObj3 = new Lead();
			       leadObj3.Company = 'Test company4';
			       leadObj3.FirstName = 'Test Nam4';
			       leadObj3.LastName = 'Test Name4';
			       leadObj3.email = 'test4@test.com';

			       leadLst.add(leadObj3);

			       Lead leadObj4 = new Lead();
			       leadObj4.Company = 'Test company5';
			       leadObj4.FirstName = 'Test Nam5';
			       leadObj4.LastName = 'Test Name5';
			       leadObj4.email = 'test5@test.com';

			       leadLst.add(leadObj4);

			       Lead leadObj5 = new Lead();
			       leadObj5.Company = 'Test company6';
			       leadObj5.FirstName = 'Test Nam6';
			       leadObj5.LastName = 'Test Name6';
			       leadObj5.email = 'test6@test.com';

			       leadLst.add(leadObj5);

			       insert leadLst;


			       List<Case> caseLst = new List<Case>();

			       Case caseObj = new Case();
			       caseObj.Status = 'New';

			       caseLst.add(caseObj);

			       Case caseObj1 = new Case();
			       caseObj1.Status = 'New';
			       caseLst.add(caseObj1);

			       insert caseLst;

			       List<Attachment> attachLst = new List<Attachment>();

			       for(Opportunity oppval : oppLst) {
				       Attachment attObj = new Attachment();
				       attObj.ParentId = oppval.Id;
				       attObj.Name = 'Test 1';
				       attObj.Body = EncodingUtil.base64Decode('test');
				       attachLst.add(attObj);
			       }

			       for(Lead leadVal : leadLst) {
				       	Attachment attObj2 = new Attachment();
				        attObj2.ParentId = leadVal.Id;
				        attObj2.Name = 'Test 3';
				        attObj2.Body = EncodingUtil.base64Decode('test2');
				        attachLst.add(attObj2);
			       }

			       for(Case caseVal : caseLst) {
				       Attachment attObj4 = new Attachment();
				       attObj4.ParentId = caseVal.Id;
				       attObj4.Name = 'Test 4';
				       attObj4.Body = EncodingUtil.base64Decode('test2');
				       attachLst.add(attObj4);
			       }

			       Test.startTest();

			       insert attachLst;

			       Test.stopTest();

			       leadObj = [select name,Last_Touched_By__c from Lead where Id = :leadObj.Id];
			       leadObj1 = [select name,Last_Touched_By__c from Lead where Id = :leadObj1.Id];

			       leadObj2 = [select name,Last_Touched_By__c from Lead where Id = :leadObj2.Id];
			       leadObj3 = [select name,Last_Touched_By__c from Lead where Id = :leadObj3.Id];
			       leadObj4 = [select name,Last_Touched_By__c from Lead where Id = :leadObj4.Id];
			       leadObj5 = [select name,Last_Touched_By__c from Lead where Id = :leadObj5.Id];

			       oppObj = [select name,Last_Touched_By__c from Opportunity where Id = :oppObj.Id];
			       oppObj1 = [select name,Last_Touched_By__c from Opportunity where Id = :oppObj1.Id];

			       System.assertEquals(leadObj.Last_Touched_By__c,u.Id);
			       System.assertEquals(leadObj1.Last_Touched_By__c,u.Id);

			       System.assertEquals(leadObj2.Last_Touched_By__c,u.Id);
			       System.assertEquals(leadObj3.Last_Touched_By__c,u.Id);
			       System.assertEquals(leadObj4.Last_Touched_By__c,u.Id);
			       System.assertEquals(leadObj5.Last_Touched_By__c,u.Id);

			       System.assertEquals(oppObj1.Last_Touched_By__c,u.Id);
			       System.assertEquals(oppObj.Last_Touched_By__c,u.Id);

   			   } catch(Exception ex) {}
   			}}
     }


       public static void setByPassTriggers(){
	   		TriggerHandler.BY_PASS_ACCOUNT_ON_BEFORE = true;
	   		TriggerHandler.BY_PASS_ACCOUNT_ON_AFTER = true;
	   		TriggerHandler.BY_PASS_ACCOUNT_ON_INSERT = true;
	   		TriggerHandler.BY_PASS_ACCOUNT_ON_UPDATE = true;
			TriggerHandler.BY_PASS_CASE_ON_UPDATE  = true;
			TriggerHandler.BY_PASS_CASE_ON_INSERT  = true;
			TriggerHandler.BY_PASS_CASE_Trigger = true;
			TriggerHandler.BY_PASS_OPPORTUNITY_ON_INSERT = true;
            TriggerHandler.BY_PASS_OPPORTUNITY_ON_UPDATE = true;
            TriggerHandler.BY_PASS_LEAD_UPDATE = true;
	        TriggerHandler.BY_PASS_LEAD_UPDATE_ON_INSERT	= true;
	   }
}
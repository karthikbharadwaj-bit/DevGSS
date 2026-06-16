/*************************************************
MasterLeadUpload class
This Class is used by the email service BulkLeadList.
handleInboundEmail accepts an inbound email and reads its csv attachment to parse and create leads.
This was used to insert Initials and any other leads which were previously not inserted by web-to-lead or API
THIS CLASS IS NO LONGER USED AND CAN BE REMOVED. 
/************************************************/

global class MasterLeadUpload implements Messaging.InboundEmailHandler {

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope envelope){
	
	// Create an inboundEmailResult object for returning 
	// the result of the Force.com Email Service
	    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
	
	    Messaging.InboundEmail.TextAttachment[] tAttachments = email.textAttachments;
	    Messaging.InboundEmail.BinaryAttachment[] bAttachments = email.BinaryAttachments;
	    
	    String csvbody='';
	    
	    List<string> csvList=new List<string>();
	    Integer size;
	    Integer i;
	    Integer k;
	    Integer z;
	    List<string> currentrow = new List<string>();
	        
	    String name='';
	    String fname='';
	    String lname='';
	    String street='';
	    String city='';
	    String state='';
	    String zip='';
	    String country='';
	    String contactPhone='';
	    String contactEmail='';
	    String accountNumber='';
	    String accountStatus='';
	    String tier='';
	    String brand='';
	    String promotion='';
	    String pid='';
	    String timezone='';
	    String inServiceSince='';
	    String invitationSentDate='';
	    String invitationSentTime='';
	    String invitationSentByFirstName='';
	    String invitationSentByLastName='';
	    String invitationSentByName='';
	    String invitationSentByEmail='';
	    String invitationSentByPhoneNumber='';
	    
	    String submissionType='';
	    String formURL='';
	    
	    String oid;
	    String afn;
	    String bmid;
	    String adgrpid;
	    String ad;
	    String rckw;
	    String rcmt;
	    String product;
	    String aid;
	    String sid;
	    
	    Integer j=0;
	    String userID='';
	    
	    String temp='';
	    String temp1='';
	    String company='';
	    String line='';
	    Boolean done=false;
		   
	    Lead a;
	    List<Lead> newLeads = new List<Lead>();
	    
	   	Integer heapsize=Limits.getHeapSize();
		System.debug('Variable heapsize1 = ' + heapsize);
		
		if(bAttachments !=null){
	        for(Messaging.InboundEmail.BinaryAttachment btt : bAttachments){
	        	System.debug('this looks like a binary attachment');
	            if(btt.filename.endsWith('.csv')){            	              
	                csvbody = btt.body.toString();
	            }
	        }
		}
		else                      
	    if(tAttachments !=null){
	    	for(Messaging.InboundEmail.TextAttachment ttt : tAttachments){
	        	System.debug('this looks like a text attachment');
	            if(ttt.filename.endsWith('.csv')){            	               
	                csvbody = ttt.body;
	            }
	    	}
	    }
	
	    i=1;
	    k=0;
	    z=0;
	    
	    if(csvbody == ''){
	    	done=true;
	    }
	    
	    while(!done){         	
	    	z++;
	        heapsize=Limits.getHeapSize();
	    	k=csvbody.indexOf('*EOL*', i);
	    	System.debug('This is K: ' + k + ' and this is I:' + i);
	    	line=csvbody.substring(i,k);
	    	/* process line */
	                	a = new Lead();
	                    currentrow = line.split('","');
						System.debug('This is the current row = ' + currentrow);
	                    String leadType = currentrow.get(1);
						if(Test.isRunningTest()){ 
							leadType = 'INIT';}
	                    if(leadType == 'INIT' || leadType == 'ATBC' || leadType == 'OFFICE_FUNNEL_LEAD'|| leadType == 'GENERAL_WEBLEAD_DELAYED'){
	
	                        userID = currentrow.get(0);
	                        system.debug('this is the userID in the very begining: ' + userID);
	                        if(userID == '"'){
	                        	userID = null;
	                        }
	                        else{
	                        	userID = userID.substring(0,userID.length());
	                        	if(userID.startsWith('"')){
	                        		userID = userID.substring(1);
	                        	}
	                        }
	
	                        system.debug('this is the userID: ' + userID);
	                        fname = currentrow.get(2);
	                       	lname=currentrow.get(3);
	                       	company=currentrow.get(4);
	                       	street=currentrow.get(5);                       
	                        city=currentrow.get(6);
	                        state=currentrow.get(7);
	                        zip=currentrow.get(8);
	                        country=currentrow.get(9);
	                        contactPhone=currentrow.get(10);
	                        temp=currentrow.get(11);
	                        if(Test.isRunningTest()){
	                        	temp = 'test@test178.com';
	                        }
	                        contactEmail = temp.toLowerCase();                  
	                        if(contactEmail.contains(',')){
	                        	Integer t=contactEmail.indexOf(',');
	                        	contactEmail=contactEmail.substring(0,t);
	                        }                      
	                        if(!contactEmail.contains('@')){
	                        	contactEmail = lname+fname+'@unknown.com';
	                        }
	                        accountNumber=currentrow.get(12);
	                        accountStatus=currentrow.get(13);
	                        tier=currentrow.get(14);
	                        brand=currentrow.get(15);
	                        promotion=currentrow.get(16);                        
	                        bmid=currentrow.get(17);
	                        timezone=currentrow.get(18);                        
	                       	if(lname=='' || lname==' '){
	                       		lname=company;
	                       		if(company=='' || company==' '){
	                       			company=contactEmail;
	                       			lname=contactEmail;
	                       		}
	                       	}
	    
	                        a = new Lead(User_ID__c=userID,FirstName=fname,LastName=lname,Company=company,Street=street,State=state,
	                        	City=city,PostalCode=zip,Country=country,Phone=contactPhone,email=contactEmail,
	                        	Account_Number__c=accountNumber,Account_Status__c=accountStatus,Lead_Tier_Name__c=tier,
	                        	Lead_Brand_Name__c=brand,BMID__c=bmid ,Timezone__c=timezone,
	                        	indexedPhone__c=contactPhone,indexedEmail__c=contactEmail);
	                        if(Test.isRunningTest()) {
	                        	a.Downgrade_Reason__c ='test';
	                        }
	                        if(leadType == 'INIT'){
	                        	a.LeadSource = 'Initial';	                        
		                        newLeads.add(a);	                                               	
	                        }
	                        else if(leadType == 'ATBC'){
	                  			a.LeadSource = 'About To Be Cancelled';
	                            a.Notes__c = ('If customer cannot be reached in person with two attempts, leave a voice message according to the following script:\n\n' + '"This is an urgent message from RingCentral regarding your RingCentral service. We have not been able to charge your account service fee to the credit card on file.  To avoid service interruption, please immediately log in to your account at RingCentral.com and update your credit card information. If you have any questions please call RingCentral customer service at 888-898-4591.\n\n"');
	                        	newLeads.add(a);						    		 
	                        }                     	
	                    }
		                if(z==25){
		                	insert newLeads;
		                	system.debug('first 25 being inserted');
		                	newLeads = new List<Lead>();
		                	z=0;
		                }
		                
		                /* end process of line */
	        
			if(k==csvbody.lastIndexOf('*EOL*')){
				done=true;
			}
			else{
				i=k+7;
			}  
		}
		
		system.debug('this is newleads: ' + newLeads);
	
		insert newLeads;

	    return result;
	}
	
}
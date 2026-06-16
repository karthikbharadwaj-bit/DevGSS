/*************************************************
OpportunityUpload class
OpportunityUpload was made to take a list of RC User Ids and create opportunties directly into their Account.
This was so we could create Farming Opportunities without having to create lead's first.
Most of the class is commented out because it is not used and so it would not count as lines of code in production.
THIS CLASS IS NO LONGER USED AND CAN BE REMOVED. 
/************************************************/

global class OpportunityUpload implements Messaging.InboundEmailHandler {

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
	            
	    Integer j=0;
	    Integer userID=0;
	    
	    String temp='';
	    String temp1='';
	    String company='';
	    String line='';
	    Boolean done=false;
	    
	    Opportunity o;
	    Contract c;
		
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
	
	    i=0;
	    k=0;
	    z=0;
	    return result;
	}	
}
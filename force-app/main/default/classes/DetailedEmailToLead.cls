/*
NO LONGER USED. CAN BE REMOVED
*/

global class DetailedEmailToLead implements Messaging.InboundEmailHandler {

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope envelope){
	
	// Create an inboundEmailResult object for returning 
	// the result of the Force.com Email Service
	    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
	
	
	    return result;
	}
	
}
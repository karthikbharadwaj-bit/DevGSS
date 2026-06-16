/*       
        * Created By    : Madhumita Majumdar
        * Created Date  : 30-03-2020
        * Description   : Update owner based on "Assign to Avaya" & "Assign to Deals Desk" button avaialble in Deal Support
        * Test Class    :       
        
Change History
********************************************************************************************************************
    SCRUM/Jira          ModifiedBy      Date     Description                             Tag

********************************************************************************************************************

*/
global class Partner_UpdateDSOwner {
    
    webservice static String changeownerpartnerqueue(Id DS_id,String brandName) { 
        String response;
        String QueueName;
        Id queueId;
        List<String> brandList;
        try{  
            Deal_Support__c dsObj = [select Id, Opportunity__c, Opportunity__r.OwnerId, OwnerId, Partner_Account__c,Partner_Account__r.Permitted_Brands__c from Deal_Support__c where  Id =: DS_id];
            if(dsObj.Partner_Account__c!=null && dsObj.Partner_Account__r.Permitted_Brands__c !=null) {
            	brandList=dsObj.Partner_Account__r.Permitted_Brands__c.split(';');
            }
            if(brandName == null || brandName == '')
            {
                if(dsObj.Partner_Account__c!=null && dsObj.Partner_Account__r.Permitted_Brands__c !=null) {
                	brandName = dsObj.Partner_Account__r.Permitted_Brands__c;
                }
                if(brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')) {
                    brandName='RingCentral';
                }   
                system.debug('Brand Name - '+brandName);
            }
            if(brandName.contains('RingCentral') && dsObj.Opportunity__c!=null && dsObj.Partner_Account__c!=null 
               && dsObj.Partner_Account__r.Permitted_Brands__c!=null && (brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')) )
            {
                queueId = dsObj.Opportunity__r.OwnerId;
            }
            else
            {                
                Map<String,Community_Details__mdt> commdetails = CommunityInfo.getAllCommunityDetails();
                Community_Details__mdt commdetail = commdetails.get(brandName);
                QueueName = commdetail.Portal_Queue__c;
                queueId =  Quote_PartnerQuoteUtil.getQueueId(QueueName);  
            }
            system.debug('queueId '+queueId);
            if(dsObj.OwnerId != queueId){
                dsObj.OwnerId = queueId;
                update dsObj;
                response = 'The record owner has been successfully updated';
            }
            else
            {
                if(brandName.contains('RingCentral') && dsObj.Opportunity__c!=null && dsObj.Partner_Account__c!=null 
               && dsObj.Partner_Account__r.Permitted_Brands__c!=null && (brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')))
                {
                    response = 'Owner is already assigned to this record.';
                }
                else
                {                    
                    response = QueueName+' is already assigned to this record.';
                }
            }
            
        }
        catch(Exception e)
        {
            response = 'The request could not be processed due to some error.';
        }
        return response;
        
    }
    
    webservice static String changeownerdealdesk(Id DS_id,String brandName) { 
        String response;
        String QueueName;
        Id queueId;
        List<String> brandList;
        try{   
            Deal_Support__c dsObj = [select Id, Opportunity__c, Opportunity__r.OwnerId, OwnerId, Partner_Account__c,Partner_Account__r.Permitted_Brands__c from Deal_Support__c where  Id =: DS_id];
            brandList=dsObj.Partner_Account__r.Permitted_Brands__c.split(';');               
            if(brandName == null || brandName == '')
            {
                brandName = dsObj.Partner_Account__r.Permitted_Brands__c;
                if(brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')) {
                    brandName='RingCentral';
                }
            }
            if(brandName.contains('RingCentral') && dsObj.Opportunity__c!=null && dsObj.Partner_Account__c!=null 
               && dsObj.Partner_Account__r.Permitted_Brands__c!=null && (brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')))
            {
                queueId = dsObj.Opportunity__r.OwnerId;
            }
            else
            {
                Map<String,Community_Details__mdt> commdetails = CommunityInfo.getAllCommunityDetails();
                Community_Details__mdt commdetail = commdetails.get(brandName);
                QueueName = commdetail.Deal_Desk_Queue__c;
                queueId =  Quote_PartnerQuoteUtil.getQueueId(QueueName);  
            }
            if(dsObj.OwnerId != queueId){
                dsObj.OwnerId = queueId;
                update dsObj;
                response = 'The record owner has been successfully updated';
            }
            else
            {
                if(brandName.contains('RingCentral') && dsObj.Opportunity__c!=null && dsObj.Partner_Account__c!=null 
               && dsObj.Partner_Account__r.Permitted_Brands__c!=null && (brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')))
                {
                    response = 'Owner is already assigned to this record.';
                }
                else
                {                    
                    response = QueueName+' is already assigned to this record.';
                }
            }
            
        }
        catch(Exception e)
        {
            response = 'The request could not be processed due to some error.';
        }
        return response;
        
    }
}
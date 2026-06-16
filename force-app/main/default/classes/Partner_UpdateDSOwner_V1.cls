global class Partner_UpdateDSOwner_V1 {
    @AuraEnabled
    webservice static String changeownerpartnerqueue(Id DS_id,String brandName,Boolean isClicked) { 
        String response;
        String QueueName;
        Id queueId;
        List<String> brandList;
        try{  
            if(isClicked== true){
                Deal_Support__c dsObj = [select Id, /*BZS-3941*/Brand_Name__c/*BZS-3941*/, Opportunity__c, Opportunity__r.OwnerId, OwnerId, Partner_Account__c,Partner_Account__r.Permitted_Brands__c from Deal_Support__c where  Id =: DS_id];
                
                /*BZS-3941*/
                brandName = dsObj.Brand_Name__c;
                /*BZS-3941*/
                if(dsObj.Partner_Account__c != null && dsObj.Partner_Account__r.Permitted_Brands__c!=null) {
                    brandList=dsObj.Partner_Account__r.Permitted_Brands__c.split(';');
                }
                if(brandName == null || brandName == '')
                {   
                    if(dsObj.Partner_Account__c !=null && dsObj.Partner_Account__r.Permitted_Brands__c!=null) {
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
            else
            {
                response = 'QueueName remains Unchanged.';
            }    
        }
        catch(Exception e)
        {
            response = 'The request could not be processed due to some error.';
        }
        return response;
        
    }
    
    @AuraEnabled
    webservice static String changeownerdealdesk(Id DS_id,Boolean isClicked) { 
        String response;
        String QueueName;
        String brandName;
        Id queueId;
        List<String> brandList;
        try{   
            if(isClicked== true){
                Deal_Support__c dsObj = [select Id, Brand_Name__c, Opportunity__c, Opportunity__r.OwnerId, OwnerId, Partner_Account__c,Partner_Account__r.Permitted_Brands__c from Deal_Support__c where  Id =: DS_id];
                brandName = dsObj.Brand_Name__c;
                brandList=dsObj.Partner_Account__r.Permitted_Brands__c.split(';');
                if(brandName == null || brandName == '')
                {
                    brandName = dsObj.Partner_Account__r.Permitted_Brands__c;
                    if(brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')) {
                        brandName='RingCentral';
                    }
                }
                system.debug('brandName '+brandName);
                
                if(brandName.contains('RingCentral') && dsObj.Opportunity__c!=null && dsObj.Partner_Account__c!=null 
                   && dsObj.Partner_Account__r.Permitted_Brands__c!=null && (brandList.contains('RingCentral')||brandList.contains('RingCentral Canada')||brandList.contains('RingCentral UK')||brandList.contains('RingCentral EU')||brandList.contains('RingCentral AU')))
                {
                    queueId = dsObj.Opportunity__r.OwnerId;
                }
                else
                {
                    Map<String,Community_Details__mdt> commdetails = CommunityInfo.getAllCommunityDetails();
                    Community_Details__mdt commdetail = commdetails.get(brandName);
                    system.debug('commdetail '+commdetail);
                    QueueName = commdetail.Deal_Desk_Queue__c;
                    system.debug('QueueName '+QueueName);
                    if(QueueName == 'Deals Desk Queue'||QueueName == null){
                        QueueName = 'ACO Deal Desk users';                      
                    }
                    queueId =  Quote_PartnerQuoteUtil.getQueueId(QueueName);  
                    system.debug('queueId '+queueId);
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
                
            }else
            {
                response = 'QueueName remains Unchanged.';
            }    
        }
        catch(Exception e)
        {
            response = 'The request could not be processed due to some error.';
        }
        return response;
        
    }
}
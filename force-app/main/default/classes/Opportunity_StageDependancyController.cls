public class Opportunity_StageDependancyController{
    
       public String validFor;
   
    
    @AuraEnabled
    public static Opportunity getOppDetails(String OppId){
       Opportunity opp = [Select id,IsClosed,StageName,RecordTypeId,Downgrade_Reason_Opp__c,Incentive__c,Sub_Stage__c,Primary_Competitor__c,
                                 Primary_Loss_Reason__c,Service_Lost__c,Sub_Downgrade_Reason__c,RC_Product_Gaps_Features__c,
                                 Customer_Limitations__c From Opportunity where Id = :OppId];
       return opp;
    
    }
    @AuraEnabled
    public Static List<String> getOptions(Id RectypeId,Boolean isClosed){
        List<Opportunity_Stage_Record_Type_Mapping__mdt> stages = [select RecordType_Name__c,
                                                             Stage_Names__c
                                                             From Opportunity_Stage_Record_Type_Mapping__mdt];
        List<String> stagelist = new List<String>();
        for(Opportunity_Stage_Record_Type_Mapping__mdt stage: stages){
            system.debug('test' + Stage.RecordType_Name__c + ((SObject)Type.forName('Opportunity').newInstance()).getSObjectType().getDescribe().getRecordTypeInfosById().get(RectypeId).getName());
            if(Stage.RecordType_Name__c.equals(((SObject)Type.forName('Opportunity').newInstance()).getSObjectType().getDescribe().getRecordTypeInfosById().get(RectypeId).getName())){
                system.debug('Inside if' + Stage.Stage_Names__c.split(','));
                
                stagelist.addAll(Stage.Stage_Names__c.split(','));
                return stagelist;
            }
        }
        return null;
        
    }
    
     
   /*get dependent picklist start*/
    public static Map<Object,List<String>> getDependentPicklistValues( Schema.sObjectField dependToken ) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if ( controlToken == null ) {
            return null;
        }
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
        (   control.getType() == Schema.DisplayType.Boolean
        ?   null
        :   control.getPicklistValues()
        );
    
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if ( entry.isActive() ) {
                List<String> base64chars =
                    String.valueOf
                    (   ((Map<String,Object>) JSON.deserializeUntyped( JSON.serialize( entry ) )).get( 'validFor' )
                    ).split( '' );
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ ) {
                    Object controlValue =
                    (   controlEntries == null
                    ?   (Object) (index == 1)
                    :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                    );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size()-1) { 
                        break; 
                    }
                    Integer bitShift = 5 - Math.mod( index, 6 );            
                    if  (   controlValue == null
                        ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0) {
                        continue;
                    }
                    if ( !dependentPicklistValues.containsKey( controlValue )) {
                        dependentPicklistValues.put( controlValue, new List<String>() );
                    }
                    dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
                }
            }
        }
        return dependentPicklistValues;
    }
   /* get dependent picklist End*/
    /*get dependent picklist overloaded method start*/
    @AuraEnabled
    public static Map<Object,List<String>> getDependentPicklistValuesWithOptions( String sObjectName, String fieldName )
	{
        Map<Schema.sObjectField,List<String>> result = new  Map<Schema.sObjectField,List<String>>();
    	System.debug('Doing'+sObjectName);
    	System.debug('Doing'+fieldName);
        system.debug('fieldName'+fieldName);
        
        return getDependentPicklistValues
    	(   ((SObject)Type.forName(sObjectName).newInstance()).getSObjectType().getDescribe().fields.getMap().get(fieldName)
    	);
            
      
	}
    /*get dependent picklist overloaded method end*/
    /*update button code start*/
    @AuraEnabled
    public static String updateOpp
        (String recId,
         String Stage,
         String SubStage,
         String Dwngradereasons,
		 String LosttoCompetition,
		 String ReasonforLoss,
		 String CustomerLimitations,
		 String RCProductGaps,
		 String ServiceLost,
		 String SubDowngradeReason,
		 String Incentive)
    {
        string responsemessage;
        try{
        Opportunity opp = [Select isClosed,StageName,RecordTypeId,Downgrade_Reason_Opp__c,Incentive__c,Sub_Stage__c,Primary_Competitor__c,
                                 Primary_Loss_Reason__c,Service_Lost__c,Sub_Downgrade_Reason__c,RC_Product_Gaps_Features__c,
                                 Customer_Limitations__c From Opportunity where Id = :recId];
        system.debug('SubStage'+SubStage);
        opp.StageName = Stage;
        opp.Sub_Stage__c = SubStage;
        opp.Downgrade_Reason_Opp__c = Dwngradereasons;
        opp.Primary_Competitor__c = LosttoCompetition;
        opp.Primary_Loss_Reason__c = ReasonforLoss;
        opp.Customer_Limitations__c = CustomerLimitations;
        opp.RC_Product_Gaps_Features__c = RCProductGaps;
        opp.Service_Lost__c= ServiceLost;
        opp.Sub_Downgrade_Reason__c = SubDowngradeReason;
        opp.Incentive__c = Incentive;
            
        update opp;
        system.debug('opp'+opp);
        responsemessage ='Success';
    }
     catch(Exception e)
     {
         responsemessage = e.getMessage();
     }
        return responsemessage;
    }

  
}
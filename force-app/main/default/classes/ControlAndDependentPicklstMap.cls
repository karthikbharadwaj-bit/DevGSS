public class ControlAndDependentPicklstMap {
    public static String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        
        Schema.DescribeFieldResult dependentField = dependToken.getDescribe();
        Schema.sObjectField controlField = dependentField.getController();
        
        if (controlField == null) {
            return new Map<String, List<String>>();
        }
        
        Schema.DescribeFieldResult controlFieldDesc = controlField.getDescribe();
        List<Schema.PicklistEntry> controlFieldValues = new List<Schema.PicklistEntry>();
        controlFieldValues = controlFieldDesc.getPicklistValues();
        
        Map<String,List<String>> dependentControlFieldMap = new Map<String,List<String>>();
        
        for (Schema.PicklistEntry depentFieldObj : dependentField.getPicklistValues()) {
            
            if (depentFieldObj.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(depentFieldObj))).get('validFor')))) {
                dependentControlFieldMap = getControlFieldValue(dependentControlFieldMap,controlFieldValues,depentFieldObj);
            }else{
                //System.debug('Not Valid '+depentFieldObj);
            }
        }
        return dependentControlFieldMap;
    }
    public static Map<String,List<String>> getControlFieldValue(Map<String,List<String>> dependentControlFieldMap,
                                                                List<Schema.PicklistEntry> controlFieldValues,
                                                               Schema.PicklistEntry depentFieldObj){
		String base64ForControlField = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(depentFieldObj))).get('validFor'));
        List<String> base64charLst = base64ForControlField .split('');
           
        for (Integer index = 0; index < (controlFieldValues != null ? controlFieldValues.size() : 2); index++) {
            
            Object currControlFieldValue =(controlFieldValues == null ?   (Object) (index == 1) :   (Object) (controlFieldValues[index].isActive() ? controlFieldValues[index].getValue() : null));
            
            Integer bitIndex = index / 6;
            if(currControlFieldValue != null){
                if (!dependentControlFieldMap.containsKey((String) currControlFieldValue)) {
                    dependentControlFieldMap.put((String) currControlFieldValue, new List<String>());
                }
            }
            if (bitIndex > base64charLst.size() - 1) {	
                break;
            }
            Integer bittoBeShift = 5 - Math.mod(index, 6);
            if  (currControlFieldValue == null || (base64map.indexOf( base64charLst[ bitIndex ] ) & (1 << bittoBeShift)) == 0){
                continue;
            }
            
            dependentControlFieldMap.get((String) currControlFieldValue).add(depentFieldObj.getValue().toUpperCase());
        }
        return dependentControlFieldMap;
    }
    // Added for JIRA - 6994 start
     public static Map<String, List<String>> getDependentPicklistValues2(Schema.sObjectField dependToken) {
         
         Schema.DescribeFieldResult dependentField = dependToken.getDescribe();
         Schema.sObjectField controlField = dependentField.getController();
         
         if (controlField == null) {
             return new Map<String, List<String>>();
         }
         
         Schema.DescribeFieldResult controlFieldDesc = controlField.getDescribe();
         List<Schema.PicklistEntry> controlFieldValues = new List<Schema.PicklistEntry>();
         controlFieldValues = controlFieldDesc.getPicklistValues();
         
         Map<String,List<String>> dependentControlFieldMap = new Map<String,List<String>>();
         
         for (Schema.PicklistEntry depentFieldObj : dependentField.getPicklistValues()) {
             
             if (depentFieldObj.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(depentFieldObj))).get('validFor')))) {
                 dependentControlFieldMap = getControlFieldValue2(dependentControlFieldMap,controlFieldValues,depentFieldObj);
             }else{
                //  System.debug('Not Valid '+depentFieldObj);
             }
         }
         return dependentControlFieldMap;
         
     }
     public static Map<String,List<String>> getControlFieldValue2(Map<String,List<String>> dependentControlFieldMap,
                                                                 List<Schema.PicklistEntry> controlFieldValues,
                                                                Schema.PicklistEntry depentFieldObj){
         String base64ForControlField = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(depentFieldObj))).get('validFor'));
         List<String> base64charLst = base64ForControlField .split('');
            
         for (Integer index = 0; index < (controlFieldValues != null ? controlFieldValues.size() : 2); index++) {
             
             Object currControlFieldValue =(controlFieldValues == null ?   (Object) (index == 1) :   (Object) (controlFieldValues[index].isActive() ? controlFieldValues[index].getValue() : null));
             
             Integer bitIndex = index / 6;
             if(currControlFieldValue != null){
                 if (!dependentControlFieldMap.containsKey((String) currControlFieldValue)) {
                     dependentControlFieldMap.put((String) currControlFieldValue, new List<String>());
                 }
             }
             if (bitIndex > base64charLst.size() - 1) {	
                 break;
             }
             Integer bittoBeShift = 5 - Math.mod(index, 6);
             if  (currControlFieldValue == null || (base64map.indexOf( base64charLst[ bitIndex ] ) & (1 << bittoBeShift)) == 0){
                 continue;
             }
             
             dependentControlFieldMap.get((String) currControlFieldValue).add(depentFieldObj.getValue());
               
         }
         return dependentControlFieldMap;
     }
       // Added for JIRA - 6994 end
}
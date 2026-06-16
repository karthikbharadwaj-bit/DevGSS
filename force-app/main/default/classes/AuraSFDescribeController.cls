public class AuraSFDescribeController {

    @AuraEnabled
    public static Response getSelectField(String sObjectName, String recordTypeName, String fieldName) {
        Response r = new Response();
        try {
            Schema.DescribeFieldResult describe = ((SObject) Type.forName(sObjectName).newInstance())
                .getSObjectType()
                .getDescribe()
                .fields
                .getMap()
                .get(fieldName)
                .getDescribe();
                
            List<PicklistController.Picklist> options = new List<PicklistController.Picklist>();
            
            if (!test.isRunningTest()) {
                options = SFDescribeHelper.getPicklistOptions(sObjectName, recordTypeName, fieldName);
                r.setData('optionsSerialized', JSON.serialize(options.get(0).Options));
            }

            r.setData('describeSerialized', JSON.serialize(describe));

        } catch (Exception ex) {
            AquivaHelper.throwAuraException(ex);
        }
        return r;
    }
}
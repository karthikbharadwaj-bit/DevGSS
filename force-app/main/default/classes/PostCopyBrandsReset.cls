/*
* Name         : PostCopyBrandsReset.cls
* Created By   : Fedor Golovanov (fgolovanov@aquivalabs.com)
* Created Date : 20/April/2017
* Description  : Resets the brands from the 'Brands' static resource. Part of the Sandbox Post Copy framework.
* Dependencies : PostCopyWorker.cls
*/

public with sharing class PostCopyBrandsReset extends PostCopyWorker {

    public override String getClassName() {
        return PostCopyBrandsReset.class.getName();
    }

    public override void run() {

        //Get brands field describe.
        Map<String, Schema.DescribeFieldResult> brandDescribe =
            generateMapDescribe(Schema.SObjectType.schedulerConfiguration__c.fields.getMap());

        //Genere what brands needed.
        Map<Decimal, schedulerConfiguration__c> brandsToInsert = createNewBrands(brandDescribe);

        //Insert new brands and update existing pricebooks
        Database.SaveResult[] srListBrands =  Database.insert(brandsToInsert.values(), false);
        PostCopyUtil.handleSaveResults(srListBrands);

        List<Pricebook2> pricebooksToUpdate = updatePriceBooks(brandsToInsert);
        Database.SaveResult[] srListPriceBooks =  Database.update(pricebooksToUpdate, false);
        PostCopyUtil.handleSaveResults(srListPriceBooks);
    }

    public static List<Pricebook2> updatePriceBooks(Map<Decimal, schedulerConfiguration__c> brands) {
        List<Pricebook2> pricebooksToUpdate = new List<Pricebook2>();
        Map<Decimal, List<Pricebook2>> pricebooks = new Map<Decimal, List<Pricebook2>>();

        for(Pricebook2 pb : [SELECT Id, BrandId__c, Brand__c FROM Pricebook2 WHERE BrandId__c IN : brands.keySet()]){
            if(pb.BrandId__c != null){
                if(!pricebooks.containsKey(pb.BrandId__c)) {
                    pricebooks.put(pb.BrandId__c, new List<Pricebook2>());
                }
                pricebooks.get(pb.BrandId__c).add(pb);
            }
        }

        for(Decimal brandId : pricebooks.keySet()){
            for(Pricebook2 pb : pricebooks.get(brandId)){
                pb.Brand__c = brands.get(brandId).Id;
                pricebooksToUpdate.add(pb);
            }
        }

        return pricebooksToUpdate;
    }

    public static Map<Decimal, schedulerConfiguration__c> createNewBrands(
        Map<String, Schema.DescribeFieldResult> brandDescribe
    ) {
        //Select pre-loaded brand configuration file.
        StaticResource defaultResource = [Select s.Body From StaticResource s where s.Name LIKE 'Brands'];

        //Get file body and escape double quotes in the row values.
        Blob tempBrands = defaultResource.Body;
        String contentFile = tempBrands.toString().remove('"');

        //Parse the body, the first line is the field names, others are data.
        String[] filelines = contentFile.split('\n');
        String[] fieldNames = filelines[0].toLowerCase().split(',');

        Map<Decimal, schedulerConfiguration__c> defaults = new Map<Decimal, schedulerConfiguration__c>();

        //Populate new brand fields, make sure that fields are Accessible and Updateable
        for (Integer i = 1; i < filelines.size(); i++)
        {
            schedulerConfiguration__c newBrand =  new schedulerConfiguration__c();
            String[] fieldValues = filelines[i].split(',');
            system.debug('fieldValues:' + filelines[i].split(','));
            for(Integer j = 0; j < fieldValues.size(); j++){
                schema.DescribeFieldResult dr = brandDescribe.get(fieldNames[j]);
                if(dr != null && dr.isUpdateable() && dr.isAccessible()){
                    String fieldType = dr.getType().name().toLowerCase();
                    if(fieldType == 'currency' || fieldType == 'double' || fieldType == 'percent' || fieldType == 'decimal' )
                    {
                        newBrand.put(fieldNames[j], Decimal.valueOf(fieldValues[j]));
                    }
                    else if(fieldType == 'boolean')
                    {
                        newBrand.put(fieldNames[j], Boolean.valueOf(fieldValues[j]));
                    }
                    else if(fieldType == 'date')
                    {
                        newBrand.put(fieldNames[j], Date.valueOf(fieldValues[j]));
                    }
                    else if(fieldType == 'datetime')
                    {
                        newBrand.put(fieldNames[j], Datetime.valueOf(fieldValues[j]));
                    }
                    else
                    {
                        newBrand.put(fieldNames[j], fieldValues[j]);
                    }
                }
            }
            if(newBrand.Brand_Id__c != null) {
                defaults.put(Decimal.ValueOf(newBrand.Brand_Id__c), newBrand);
            }
            system.debug('newBrand: ' + newBrand);
        }

        system.debug('defaults: ' + defaults);

        return defaults;
    }


    public static Map<String, Schema.DescribeFieldResult> generateMapDescribe(Map<String, Schema.SObjectField> mapField) {
        Map<String, Schema.DescribeFieldResult> ret = new Map<String, Schema.DescribeFieldResult>();
        for(String fKey : mapField.keySet())
        {
            Schema.DescribeFieldResult dr = mapField.get(fKey).getDescribe();
            ret.put(dr.getName().ToLowerCase(), dr);
        }
        return ret;
    }
}
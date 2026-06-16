@isTest
private class Test_SaveResultWrapper {
    @isTest static void saveResultWrapperIsCreatedCorrectly() {
        Boolean isSuccess = true;
        String recordId = '123456789';
        Test.startTest();
        SaveResultWrapper srWrap = new SaveResultWrapper(isSuccess, recordId, new Database.Error[]{});
        Test.stopTest();
        System.assertEquals(isSuccess, srWrap.isSuccess, 'Whether operation was a success should have been logged');
        System.assertEquals(recordId, srWrap.recordId, 'Record Id should have been correctly assigned');
    }
    
    @isTest static void errorWrapperIsCreatedCorrectly() {
        List<String> fields = new List<String>{'Field__c', 'SecondField__c'};
        String message = 'Cross Reference';
        System.StatusCode status = System.StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY;        
        SaveResultWrapper.ErrorWrapper errorWrap;
        Test.startTest();
        errorWrap = new SaveResultWrapper.ErrorWrapper(fields, message, status);
        Test.stopTest();
        System.assertEquals(fields, errorWrap.fields, 'Fields should have been correctly assigned');
        System.assertEquals(message, errorWrap.message, 'Message should have been correctly assigned');
        System.assertEquals(status, errorWrap.statusCode, 'statusCode should have been correctly assigned');
            
    }
}
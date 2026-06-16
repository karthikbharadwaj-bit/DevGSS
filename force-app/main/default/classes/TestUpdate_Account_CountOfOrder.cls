@isTest
private class TestUpdate_Account_CountOfOrder {

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    static void myUnitTest() {

        //Create Account

            Account acctObj = new Account();
            acctObj.Name = 'Test1';
            acctObj.SignupType__c = 'TRIAL_30NOCC';
            acctObj.RC_Account_Status__c = null;
            acctObj.SignupPlatform__c = 'iphone';
            acctObj.RC_Service_name__c = 'office123';
            insert acctObj;

        //Create Orders

            list<Order__c>  lOrder = new list<Order__c>();
            Order__c  o1 = new Order__c();
            o1.Name = 'Test Order';
            o1.Service_Plan_Change_Amount__c = 2;
            o1.Account__c = acctObj.Id;
            Order__c  o2 = new Order__c();
            o2.Account__c = acctObj.Id;
            o2.Name = 'Test Order';
            o2.Service_Plan_Change_Amount__c = -2;

            lOrder.add(o1);
            lOrder.add(o2);
            insert(lOrder);

        //Update Account
            acctObj.Name = 'Test2';
            update acctObj;

            map<Id,Account> mAcc = new map<Id,Account>();
            mAcc.put(acctObj.Id, acctObj);
            AccountTriggerHelperExt.Update_Account_CountOfOrder(mAcc);


    }
}

/**************************************************************************************************
* @Case...................:  04018783                                                             * 
* @Discription............:  Update Account Trigger to Pull Count of Order                        * 
* @Param..................:  Account                                                              *
* @Return.................:  NA                                                                   *
* @Code to test...........:  Account_Before.AccountTriggerHelperExt.Update_Account_CountOfOrder   *
* @Last Modified by.......:  eugenebasianomutya                                                   *
* @Last Modified Date.....:  10/14/2015                                                           *  
**************************************************************************************************/
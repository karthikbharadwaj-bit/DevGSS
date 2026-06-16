/***************************************************************************************************
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Target Class/Trigger: RollUpOnLead Trigger
* Created by: eugenebasianomutya
* Date Updated: 12/30/2015
* Case: 04130409 - Enable Touch Tracking
****************************************************************************************************/

@isTest
private class RollUpOnLeadTest {

  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
  @isTest
    static void myUnitTest1() {

    //Create a Lead
    List<Lead> leadList = new List<Lead>();
    leadList.add(new Lead(firstName='Singh', Title='VP', Lead_Entry_Source__c='ROI Form', LeadSource='Initial', lastname = 'Virendra', company='Simplion', email='virendra.singh@simplion.com', phone='9910106804'));
    insert leadList;

    //Create a Task
    List<Task> tasks = new List<Task>();
    tasks.add(new Task( ActivityDate = Date.today().addDays(7), Subject='Call', WhoId = leadList[0].Id, OwnerId = UserInfo.getUserId(), Status='In Progress'));
    insert tasks;

    //Update a Task
    tasks[0].Subject = 'Calls';
    update tasks[0];

    tasks[0].Subject = 'Call';
    update tasks[0];

    //Delete a Task
    delete tasks[0];

    //Undelete a Task
    undelete tasks[0];

  }

}
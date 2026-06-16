/**************************************************************************************************
* Project Name..........: Medallia                                                                *
* File..................: ScheduleMedalliaActiveAccountBatch120.class                             *
* Version...............: 1.0                                                                     *
* Created by............: eugenebasianomutya                                                      *
* Created Date..........: 01/05/2017 02:44 AM                                                     *
* Last Modified by......:                                                                         *
* Last Modified Date....:                                                                         *
* Description...........: This is a class to schedule Medallia Active Account 120 batch class.    *
**************************************************************************************************/

global class ScheduleMedalliaActiveAccountBatch120 implements Schedulable {
    
    /******************************************************************************
    * @Description : Execute method to schedule the batch.                        *
    * @Params      : SchedulableContext                                           *
    * @Return      : void                                                         * 
    ******************************************************************************/
    global void execute(SchedulableContext SC) {
      MedalliaActiveAccountsBatch120 maabObj = new MedalliaActiveAccountsBatch120();
      database.executebatch(maabObj,50); 
   }

}
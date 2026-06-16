/**************************************************************************************************
* Project Name..........: RingCentral - Self Serve Scheduling                                     *
* File..................: Implementation.trigger                                                  *
* Version...............: 1.0                                                                     *
* Created by............: Simplion Technologies                                                   *
* Created Date..........: 24 June 2013                                                            *
* Last Modified by......: Simplion Technologies                                                   *
* Last Modified Date....:                                                                         *
* Description...........: Trigger on Implementation object.                                       *
*                         Before Update: Enforce business rules Create and send survey.           *
**************************************************************************************************/

trigger Implementation on Implementation__c (before insert, before update) {

    ByPassTrigger__c bypassTrigger = ByPassTrigger__c.getInstance();
        if (bypassTrigger != null && bypassTrigger.Bypass_Implementation_Trigger__c == true) {
             System.debug('$$$ ByPassTrigger__c Active For Implementation Credit $$$');
            return;
        }

    new Triggers()
            .bind(Triggers.Evt.beforeinsert, new ImplementationTriggerHelper.LegacyCodeProcessing())
            .bind(Triggers.Evt.beforeinsert, new ImplementationTriggerHelper.ProfessionalServicesCheckBoxPopulation())
            .bind(Triggers.Evt.beforeinsert, new ImplementationTriggerHelper.PopulateImplemantationFieldsWithPackageFields())
            .bind(Triggers.Evt.beforeupdate, new ImplementationTriggerHelper.PopulateImplemantationFieldsWithPackageFields())
            .bind(Triggers.Evt.beforeupdate, new ImplementationTriggerHelper.LegacyCodeProcessing())

            .bind(Triggers.Evt.beforeinsert, new ImplementationTriggerHelper.BrandPartnerPopulationHandler())
            .bind(Triggers.Evt.beforeupdate, new ImplementationTriggerHelper.BrandPartnerPopulationHandler())

            .manage();
}
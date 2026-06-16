trigger MavenlinkIntegrator on Mavenlink_Integrator__c (before insert, before update, after insert) {
    new Triggers()
        .bind(Triggers.Evt.beforeinsert, new MavenlinkIntegratorTriggerHandler.MavenlinkIntegratorBefore())
        .bind(Triggers.Evt.beforeupdate, new MavenlinkIntegratorTriggerHandler.MavenlinkIntegratorBefore())

        .bind(Triggers.Evt.afterinsert, new MavenlinkIntegratorTriggerHandler.MavenlinkIntegratorAfter())
    .manage();
}
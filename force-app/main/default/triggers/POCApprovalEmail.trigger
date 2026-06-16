trigger POCApprovalEmail on POCApprovalEmail__e (after insert) {
    PlatformEventsManager.processEvents('PlatformEvents.POCApprovalEmailInterface', Trigger.new);
}
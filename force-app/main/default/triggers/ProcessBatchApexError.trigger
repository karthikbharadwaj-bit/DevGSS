trigger ProcessBatchApexError on BatchApexErrorEvent (after insert) {
	BatchApexErrorEventHandler.HandleBatchApexErrorEvent(Trigger.new);
}
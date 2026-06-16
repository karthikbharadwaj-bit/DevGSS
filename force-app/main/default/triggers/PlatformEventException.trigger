trigger PlatformEventException on Exception__e (after insert) {
	PlatformEventsManager.processEvents('PlatformEvents.PlatformEventException', Trigger.new);
}
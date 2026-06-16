public class SWNSyncToICBOrInContactRunner extends SWNActionRunner {

    @TestVisible
    private SWNSyncToICBOrInContactRunner() {}

    public SWNSyncToICBOrInContactRunner(Id quoteId, String action) {
        super(quoteId, action);
    }

    @TestVisible
    protected override void run() {
        isSkipFinalize = true;
    }
}
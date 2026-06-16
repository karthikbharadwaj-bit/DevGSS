public with sharing class SWNScenarioHelper {
    public static final String SCENARIO = 'scenario';
    public static final String SCENARIO_KEY = 'scenarioKey';
    public static final String STEPNAMES = 'stepNames';
    @TestVisible
    private static final Map<String, Scenario> SCENARIOS = new Map<String, Scenario> {
        // only discount/contract sync
        'NON_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC}
        ),
        'CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC}
        ),
        // upsell
        'NON_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC, SWNStep.UP_SELL}
        ),
        // downsell
        'NON_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL}
        ),
        'CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.REPRICE_SYNC}
        ),
        // upsell + downsell
        'NON_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.REPRICE_SYNC, SWNStep.UP_SELL}
        ),


        // upgrade
        'NON_CONTRACTED_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'CONTRACTED_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'NON_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_NON_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        // upgrade + upsell
        'NON_CONTRACTED_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'NON_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_NON_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        // upgrade + downsell
        'NON_CONTRACTED_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'CONTRACTED_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'NON_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_NON_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        // upgrade + upsell + downsell
        'NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),

        // non paid + upgrade
        'NON_CONTRACTED_NON_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID}
        ),
        'CONTRACTED_NON_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),

        // non paid + upgrade + target change
        'NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        // non paid + upgrade + upsell
        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE, SWNStep.UP_SELL}
        ),

        // non paid + upgrade + upsell + target change
        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),

        // non paid + upgrade + downsell
        'NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),

        // non paid + upgrade + downsell + target change
        'NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC,  SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        // non paid + upgrade + upsell + downsell
        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID, SWNStep.UP_SELL}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        // non paid + upgrade + upsell + downsell + target change
        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),

        'NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        'WHOLESALE_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),


        /* License limits update */
        'NON_CONTRACTED_S8' => new Scenario(
            new List<String> {SWNStep.UPDATE_LICENSE_LIMITS}
        ),
        /* Non Contract Plan Change / Package Change with optional New Discounts */
        'NON_CONTRACTED_S9' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        /* Adding new Discounts for current Package */
        'NON_CONTRACTED_S10' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC}
        ),
        /* Upsell with optional Discounts */
        'NON_CONTRACTED_S11' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UP_SELL}
        ),
        /* Downsell with optional Discounts */
        'NON_CONTRACTED_S12' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL}
        ),
        /* Upgrade + Upsell with optional Discounts */
        'NON_CONTRACTED_S13' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),
        /* Upgrade + Downsell with optional Discounts */
        'NON_CONTRACTED_S14' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        /* Upsell + Downsell with optional Discounts */
        'NON_CONTRACTED_S15' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UP_SELL}
        ),
        /* Downsell + Upgrade + Upsell with optional Discounts */
        'NON_CONTRACTED_S16' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.UP_SELL}
        ),

        /* Engage scenarios */
        // upgrade
        'CONTRACTED_PAID_UPGRADE_CCB' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_TO_CCB_UPGRADE}
        ),
        // down-sell
        'CONTRACTED_PAID_SYNC_CCB_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_TO_CCB_DOWNSELL, SWNStep.REPRICE_SYNC}
        ),
        // up-sell
        'CONTRACTED_PAID_SYNC_CCB_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC, SWNStep.SYNC_TO_CCB_UPSELL}
        ),
        // down-sell + upsell
        'CONTRACTED_PAID_SYNC_CCB_DOWNSELL_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_TO_CCB_DOWNSELL, SWNStep.REPRICE_SYNC, SWNStep.SYNC_TO_CCB_UPSELL}
        ),

        // LBO scenarios
        // only discount/contract sync
        'LBO_NON_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC}
        ),
        'LBO_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC}
        ),
        // upsell
        'LBO_NON_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC, SWNStep.ORDER}
        ),
        // downsell
        'LBO_NON_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL}
        ),
        'LBO_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.REPRICE_SYNC}
        ),
        // upsell + downsell
        'LBO_NON_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.REPRICE_SYNC, SWNStep.ORDER}
        ),


        // upgrade
        'LBO_NON_CONTRACTED_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'LBO_NON_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        // upgrade + upsell
        'LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        // upgrade + upsell free to office
        'LBO_NON_CONTRACTED_PHOENIX_FREE_TO_OFFICE_UPGRADE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_NON_CONTRACTED_PHOENIX_FREE_TO_OFFICE_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PHOENIX_FREE_TO_OFFICE_UPGRADE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PHOENIX_FREE_TO_OFFICE_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        // upgrade + downsell
        'LBO_NON_CONTRACTED_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'LBO_NON_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        // upgrade + upsell + downsell
        'LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        // non paid + upgrade
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),

        // non paid + upgrade + target change
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        // non paid + upgrade + upsell
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE, SWNStep.ORDER}
        ),

        // non paid + upgrade + upsell + target change
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        // non paid + upgrade + downsell
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),

        // non paid + upgrade + downsell + target change
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE}
        ),

        // non paid + upgrade + upsell + downsell
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.CONVERT_TO_PAID, SWNStep.ORDER}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.CONVERT_TO_PAID_WHOLESALE}
        ),

        // non paid + upgrade + upsell + downsell + target change
        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        'LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        'WHOLESALE_LBO_NON_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_NON_PAID_UPGRADE_UPSELL_DOWNSELL_TARGET_CHANGE_INVOICE' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UPGRADE, SWNStep.ORDER}
        ),

        /* License limits update */
        'LBO_NON_CONTRACTED_S8' => new Scenario(new List<String> {SWNStep.UPDATE_LICENSE_LIMITS}),
        /* Non Contract Plan Change / Package Change with optional New Discounts */
        'LBO_NON_CONTRACTED_S9' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE}),
        /* Adding new Discounts for current Package */
        'LBO_NON_CONTRACTED_S10' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC}),
        /* Upsell with optional Discounts */
        'LBO_NON_CONTRACTED_S11' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.ORDER}),
        /* Downsell with optional Discounts */
        'LBO_NON_CONTRACTED_S12' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL}),
        /* Upgrade + Upsell with optional Discounts */
        'LBO_NON_CONTRACTED_S13' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}),
        /* Upgrade + Downsell with optional Discounts */
        'LBO_NON_CONTRACTED_S14' => new Scenario(new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.UPGRADE}),
        /* Upsell + Downsell with optional Discounts */
        'LBO_NON_CONTRACTED_S15' => new Scenario(new List<String> {SWNStep.DOWN_SELL, SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.ORDER}),
        /* Downsell + Upgrade + Upsell with optional Discounts */
        'LBO_NON_CONTRACTED_S16' => new Scenario(new List<String> {SWNStep.DOWN_SELL, SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.UPGRADE, SWNStep.ORDER}),

        // Wholesale
        // only discount/contract sync
        'WHOLESALE_NON_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE}
        ),
        'WHOLESALE_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC}
        ),
        // upsell
        'WHOLESALE_NON_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC, SWNStep.UP_SELL}
        ),
        // downsell
        'WHOLESALE_NON_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE}
        ),
        'WHOLESALE_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC}
        ),
        // upsell + downsell
        'WHOLESALE_NON_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC, SWNStep.UP_SELL}
        ),
        // only discount/contract sync
        'WHOLESALE_LBO_NON_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC}
        ),
        // upsell
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC, SWNStep.ORDER}
        ),
        // downsell
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC}
        ),
        // upsell + downsell
        'WHOLESALE_LBO_NON_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.ORDER}
        ),
        'WHOLESALE_LBO_CONTRACTED_PAID_UPSELL_DOWNSELL' => new Scenario(
            new List<String> {SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE, SWNStep.REPRICE_SYNC, SWNStep.ORDER}
        ),
        // Contract cancellation
        'WHOLESALE_NON_CONTRACTED_S10' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE}
        ),
        'WHOLESALE_NON_CONTRACTED_S11' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_INVOICE, SWNStep.UP_SELL}
        ),
        'WHOLESALE_NON_CONTRACTED_S12' => new Scenario(
            new List<String> {SWNStep.CONTRACT_CANCELLATION, SWNStep.DISCOUNT_SYNC, SWNStep.DOWN_SELL, SWNStep.SYNC_INVOICE}
        ),

        /* Account termination */
        'ENGAGE_ACCOUNT_TERMINATION' => new Scenario(new List<String> {SWNStep.ENGAGE_ACCOUNT_TERMINATION}),

        /* inContact scenarios */
        // upgrade
        'CONTRACTED_PAID_UPGRADE_ICB' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.SYNC_TO_NGBS_UPGRADE
            }
        ),
        // down-sell w/o Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_DOWNSELL' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.SYNC_TO_NGBS_DOWNSELL, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC
            }
        ),
        // up-sell w/o Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_UPSELL' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC, SWNStep.SYNC_TO_NGBS_UPSELL
            }
        ),
        // down-sell + upsell w/o Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_DOWNSELL_UPSELL' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.SYNC_TO_NGBS_DOWNSELL, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.REPRICE_SYNC, SWNStep.SYNC_TO_NGBS_UPSELL
            }
        ),
        // down-sell with Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_DOWNSELL_CHARGE_TERM_SYNC' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.SYNC_TO_NGBS_DOWNSELL, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CHARGE_TERM_SYNC
            }
        ),
        // up-sell with Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_UPSELL_CHARGE_TERM_SYNC' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CHARGE_TERM_SYNC, SWNStep.SYNC_TO_NGBS_UPSELL
            }
        ),
        // down-sell + upsell with Contract Plan Change
        'CONTRACTED_PAID_SYNC_ICB_DOWNSELL_UPSELL_CHARGE_TERM_SYNC' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.SYNC_TO_NGBS_DOWNSELL, SWNStep.CONTRACT_SYNC, SWNStep.DISCOUNT_SYNC, SWNStep.CHARGE_TERM_SYNC, SWNStep.SYNC_TO_NGBS_UPSELL
            }
        ),
        // contract plan change
        'CONTRACTED_PAID_CHARGE_TERM_SYNC' => new Scenario(
            new List<String> {
                SWNStep.SYNC_TO_ICB, SWNStep.SYNC_TO_INCONTACT, SWNStep.DISCOUNT_SYNC, SWNStep.CONTRACT_SYNC, SWNStep.CHARGE_TERM_SYNC
            }
        )
    };

    public class Scenario {
        @AuraEnabled public List<String> stepNames;
        @AuraEnabled public List<SWNStep> steps;
        public Map<String, SWNStep> stepsMap = new Map<String, SWNStep>();

        public Scenario(List<String> stepNames) {
            this.stepNames = stepNames;
            this.steps = new List<SWNStep>();
            for (String stepName : stepNames) {
                SWNStep st = SWNStep.STEPS.get(stepName);
                stepsMap.put(st.name, st);
                this.steps.add(st);
            }
        }

        public void addAffectedLicensesToStep(String stepName, List<String> affectedLicenses) {
            if (stepName == null || !stepsMap.containsKey(stepName)) {
                return;
            }
            stepsMap.get(stepName).addAffectedLicenses(affectedLicenses);
        }
    }

    public class Context {
        @TestVisible
        private IFlow flow;

        public void setFlow(IFlow flow) {
            this.flow = flow;
        }

        private String getKey() {
            return flow.getKey();
        }

        public Scenario getScenario() {
            String key = getKey();
            Scenario sc = SCENARIOS.get(key);

            if (sc != null) {
                Map<String, List<String>> affectedLicenses = flow.getAffectedLicenses();
                if (affectedLicenses != null) {
                    for (String stepName : affectedLicenses.keySet()) {
                        sc.addAffectedLicensesToStep(stepName, affectedLicenses.get(stepName));
                    }
                }
            }
            return sc;
        }
    }
    public class Transition {
        String source;
        TransitionTo[] to;
    }
    public class TransitionTo {
        String packageId;
    }

    private abstract class State {
        Quote qt;
        public List<QuoteLineItem> qlis;
        public Boolean isUpsell = false;
        public Boolean isDownsell = false;
        public Boolean isPhoenixToOffice = false;

        public Map<String, List<String>> affectedLicenses = new Map<String, List<String>> {
            SWNStep.UP_SELL => new List<String>(),
            SWNStep.DOWN_SELL => new List<String>()
        };

        private Transition getTransitions(String catalogId) {
            Transition result;

            try {
                String endpoint = NGBSAPI.NGBS_CATALOG_PATH + '/transitions/' + catalogId;
                HttpResponse res = new HttpResponse();

                if (!Test.isRunningTest()) {
                    res = NGBSAPI.requestNGBS(endpoint, HttpHelper.METHOD_GET);
                } else {
                    res = new HttpResponse();
                    res.setBody('{"from":"110","to":[{"transitionId":486001,"packageId":"21","permittedTo":null}]}');
                    res.setStatusCode(200);
                }

                String body = res.getBody();
                if (String.isNotBlank(body)) {
                    body = body.replaceAll('from', 'source');
                    result = (Transition) JSON.deserialize(body, Transition.class);
                }
            } catch(Exception ex) {
                AquivaHelper.throwAquivaException('Unexpected error occurred retrieving transitions from NGBS. Please contact administrator');
            }

            return result;
        }

        @TestVisible
        private Boolean isUpgrade {
            get {return QuoteHelper.isNGBSPlanChange(qt, qlis) || QuoteHelper.isNGBSPackageChange(qt, qlis);}
            set;
        }

        private Boolean isNGBSPackageChange {
            get {return QuoteHelper.isNGBSPackageChange(qt, qlis);}
            set;
        }

        private Boolean isNGBSPlanChange {
            get {return QuoteHelper.isNGBSPlanChange(qt, qlis);}
            set;
        }

        @TestVisible
        private Boolean hasInvoiceStep {
            get {
                NGBSAPI.PaymentMethod currentPaymentMethod =
                    NGBSAPI.getDefaultPaymentMethodFromBillingAccount(qt.Account.Billing_ID__c);
                if (QuoteHelper.isNGBSPartnerPackageChange(qt, qlis)) { // Would be only for the Wholesale flow for now
                    return true;
                } else if (QuoteHelper.isPhoenix(qt) || this.isPhoenixToOffice) {
                    Boolean needToUpdateInvoice = currentPaymentMethod == null || currentPaymentMethod.invoiceInfo == null;
                    return OpportunityHelper.hasInvoiceApproval(qt.OpportunityId) && needToUpdateInvoice;
                } else if (AccountHelper.isInvoiceOnBehalfAccount(qt.Account)) {
                    Boolean needToUpdateIoB = currentPaymentMethod == null || currentPaymentMethod.invoiceOnBehalfInfo == null;
                    return AccountHelper.isApprovedInvoiceOnBehalf(qt.Account) && needToUpdateIoB;
                }
                return false;
            }
            set;
        }

        private Boolean isUpgradeFromPaid {
            get {
                Boolean result = false;
                try {
                    QuoteLineItem qli = QuoteLineItemHelper.getAnyQuoteLineItemWithEntitlement(qlis);

                    if (qli == null) {
                        AquivaHelper.throwAquivaException('QLI not found');
                    }

                    Entitlement__c ent = qli.Entitlement__r;

                    if (ent == null) {
                        AquivaHelper.throwAquivaException('Entitlement not found');
                    }

                    BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);

                    if (pInfo == null || pInfo.packageInfo == null) {
                        AquivaHelper.throwAquivaException('Quote package info not found');
                    }

                    if (pInfo.packageInfo.catalogId == null) {
                        AquivaHelper.throwAquivaException('Can not get catalogId from package info');
                    }

                    String prevCatalogId = ent.PackageCatalogId__c;
                    String currentCatalogId = pInfo.packageInfo.catalogId;

                    Transition tr = getTransitions(prevCatalogId);

                    List<String> catalogIds = new List<String>();
                    for (TransitionTo to : tr.to) {
                        catalogIds.add(to.packageId);
                    }

                    result = !catalogIds.contains(currentCatalogId);
                } catch (Exception e) {
                    AquivaHelper.throwAquivaException('Can not get information for "isUpgradeFromPaid" ('+e.getMessage()+')');
                }

                return result;
            }
            set;
        }

        private Boolean isTargetChange {
            get {
                return !isPhoenixToOffice && isUpgradeFromPaid;
            }
            set;
        }

        private String type {
            get {
                String LBO = SWNHelper.isLBOOrOfficeProductSelected(qt) ? 'LBO_' : '';
                String wholesale = QuoteHelper.isNGBSPartnerPackageChange(qt, qlis) ? 'WHOLESALE_' : '';
                String contract = SWNHelper.isContractExistInSF(qt) ? 'CONTRACTED' : 'NON_CONTRACTED';
                return wholesale + LBO + contract;
            }
            set;
        }

        public State (Quote qt) {
            this.qt = qt;
            this.qlis = qt.QuoteLineItems;
            this.init(qt.QuoteLineItems);
        }

        public void init(List<QuoteLineItem> qlis) {
            for (QuoteLineItem qli : qlis) {
                if (!QuoteLineItemHelper.isQLIApplicableForSyncWithNGBS(qli)) {
                    continue;
                }
                Decimal entQty = qli.Entitlement__r != null ? qli.Entitlement__r.Quantity__c : 0;
                Decimal qliQty = qli.NewQuantity__c;

                if (entQty < qliQty) {
                    this.isUpsell = true;
                    this.affectedLicenses.get(SWNStep.UP_SELL).add(qli.Product2.Name);
                }

                if (entQty > qliQty) {
                    this.isDownsell = true;
                    this.affectedLicenses.get(SWNStep.DOWN_SELL).add(qli.Product2.Name);
                }
            }

            if (QuoteHelper.isCrossUpgrade(this.qt) ) {
                BillingWrappers.QuotePackageInfo pInfo = QuoteHelper.getPackageInfo(qt);
                if (pInfo != null && pInfo.existingPackageInfo != null && pInfo.existingPackageInfo.productName != null &&
                    pInfo.existingPackageInfo.productName.equalsIgnoreCase(Product2Helper.PRODUCT_MEETINGS)) {
                    this.isPhoenixToOffice = true;
                }
            }
        }
    }

    @TestVisible
    private class SalesQuoteState extends State{
        @TestVisible
        private Boolean isFree {
            get {return QuoteHelper.isEntitlementPackageOfferTypeFree(qt) || QuoteHelper.isExistingPackageOfferTypeFree(qt);}
            set;
        }
        @TestVisible
        private Boolean isTrial {
            get {return QuoteHelper.isEntitlementPackageOfferTypeTrial(qt);}
            set;
        }
        private Boolean isPOC {
            get {return QuoteHelper.isEntitlementPackageOfferTypePOC(qt);}
            set;
        }
        private Boolean isPaid {
            get {return !this.isFree && !this.isTrial && !this.isPOC;}
            set;
        }
        public SalesQuoteState(Quote qt) {
            super(qt);
        }
    }

    private class POCQuoteState extends State{
        public POCQuoteState(Quote qt) {
            super(qt);
        }
    }

    private class EngageQuoteState extends State {
        public EngageQuoteState(Quote qt) {
            super(qt);
        }
    }

    @TestVisible
    private interface IFlow{
        String getKey();
        Map<String, List<String>> getAffectedLicenses();
    }

    @TestVisible
    private class SalesQuoteFlow implements IFlow {
        @TestVisible
        SalesQuoteState s;

        public SalesQuoteFlow(Quote qt) {
            s = new SalesQuoteState(qt);
        }

        public String getKey() {
            String scNumber;
            if (s.isPaid) {
                if (s.isUpgrade) {
                    if (s.isUpsell && s.isDownsell) {
                        scNumber = 'PAID_UPGRADE_UPSELL_DOWNSELL';
                    } else if (s.isUpsell) {
                        scNumber = 'PAID_UPGRADE_UPSELL';
                    } else if (s.isDownsell) {
                        scNumber = 'PAID_UPGRADE_DOWNSELL';
                    } else {
                        scNumber = 'PAID_UPGRADE';
                    }
                    if (s.hasInvoiceStep) {
                        scNumber += '_INVOICE';
                    }
                } else {
                    if (s.isUpsell && s.isDownsell) {
                        scNumber = 'PAID_UPSELL_DOWNSELL';
                    } else if (s.isUpsell) {
                        scNumber = 'PAID_UPSELL';
                    } else if (s.isDownsell) {
                        scNumber = 'PAID_DOWNSELL';
                    } else {
                        scNumber = 'PAID';
                    }
                }
            } else {
                if (s.isUpgrade) {
                    if (s.isPhoenixToOffice) {
                        scNumber = 'PHOENIX_FREE_TO_OFFICE_UPGRADE';
                    } else if (s.isUpsell && s.isDownsell) {
                        scNumber = 'NON_PAID_UPGRADE_UPSELL_DOWNSELL';
                    } else if (s.isUpsell) {
                        scNumber = 'NON_PAID_UPGRADE_UPSELL';
                    } else if (s.isDownsell) {
                        scNumber = 'NON_PAID_UPGRADE_DOWNSELL';
                    } else {
                        scNumber = 'NON_PAID_UPGRADE';
                    }

                    // Specific case target change
                    if (s.isTargetChange ) {
                        scNumber += '_TARGET_CHANGE';
                    }
                    if (s.hasInvoiceStep) {
                        scNumber += '_INVOICE';
                    }
                }
            }

            String key = s.type + '_' + scNumber;
            return key;
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return s.affectedLicenses;
        }
    }

    @TestVisible
    private class SalesQuoteCancellationFlow implements IFlow {
        @TestVisible
        SalesQuoteState s;

        public SalesQuoteCancellationFlow(Quote qt) {
            s = new SalesQuoteState(qt);
        }

        public String getKey() {
            String scNumber;
            if (!s.isFree && !s.isTrial) {
                if (!s.isUpsell && !s.isDownsell && s.isUpgrade) {
                    scNumber = 'S9';
                }
                if (!s.isUpsell && !s.isDownsell && !s.isUpgrade) {
                    scNumber = 'S10';
                }
                if (s.isUpsell && !s.isUpgrade) {
                    scNumber = 'S11';
                }
                if (s.isDownsell && !s.isUpgrade) {
                    scNumber = 'S12';
                }
                if (s.isUpsell && s.isUpgrade) {
                    scNumber = 'S13';
                }
                if (s.isDownsell && s.isUpgrade) {
                    scNumber = 'S14';
                }
                if (s.isDownsell && s.isUpsell && !s.isUpgrade) {
                    scNumber = 'S15';
                }
                if (s.isDownsell && s.isUpsell && s.isUpgrade) {
                    scNumber = 'S16';
                }
            }

            String key = s.type + '_' + scNumber;
            return key;
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return s.affectedLicenses;
        }
    }

    @TestVisible
    private class POCQuoteFlow implements IFlow {
        @TestVisible
        POCQuoteState s;

        public POCQuoteFlow(Quote qt) {
            s = new POCQuoteState(qt);
        }

        public String getKey() {
            String scNumber;

            if (s.isUpsell && !s.isUpgrade) {
                scNumber = 'S8';
            }
            String key = s.type + '_' + scNumber;
            return key;
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return s.affectedLicenses;
        }
    }

    @TestVisible
    private class EngageQuoteFlow implements IFlow {
        @TestVisible
        EngageQuoteState s;

        public EngageQuoteFlow(Quote qt) {
            s = new EngageQuoteState(qt);
        }

        public String getKey() {
            String scNumber;

            if (s.isUpgrade) {
                scNumber = 'PAID_UPGRADE_CCB';
            } else {
                if (s.isUpsell && s.isDownsell) {
                    scNumber = 'PAID_SYNC_CCB_DOWNSELL_UPSELL';
                } else if (s.isUpsell) {
                    scNumber = 'PAID_SYNC_CCB_UPSELL';
                } else if (s.isDownsell) {
                    scNumber = 'PAID_SYNC_CCB_DOWNSELL';
                } else {
                    scNumber = 'PAID';
                }
            }

            String key = s.type + '_' + scNumber;
            return key;
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return s.affectedLicenses;
        }
    }

    private class AccountTerminationFlow implements IFlow {
        public String getKey() {
            return 'ENGAGE_ACCOUNT_TERMINATION';
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return null;
        }
    }

    private class SyncToIcbFlow implements IFlow {
        EngageQuoteState s;

        public SyncToIcbFlow(Quote qt) {
            s = new EngageQuoteState(qt);
        }

        public String getKey() {
            String scNumber;

            if (s.isNGBSPackageChange) {
                scNumber = 'PAID_UPGRADE_ICB';
            } else if (s.isNGBSPlanChange) {
                if (s.isUpsell && s.isDownsell) {
                    scNumber = 'PAID_SYNC_ICB_DOWNSELL_UPSELL_CHARGE_TERM_SYNC';
                } else if (s.isUpsell) {
                    scNumber = 'PAID_SYNC_ICB_UPSELL_CHARGE_TERM_SYNC';
                } else if (s.isDownsell) {
                    scNumber = 'PAID_SYNC_ICB_DOWNSELL_CHARGE_TERM_SYNC';
                } else {
                    scNumber = 'PAID_CHARGE_TERM_SYNC';
                }
            } else {
                if (s.isUpsell && s.isDownsell) {
                    scNumber = 'PAID_SYNC_ICB_DOWNSELL_UPSELL';
                } else if (s.isUpsell) {
                    scNumber = 'PAID_SYNC_ICB_UPSELL';
                } else if (s.isDownsell) {
                    scNumber = 'PAID_SYNC_ICB_DOWNSELL';
                } else {
                    scNumber = 'PAID';
                }
            }

            String key = s.type + '_' + scNumber;
            return key;
        }

        public Map<String, List<String>> getAffectedLicenses() {
            return s.affectedLicenses;
        }
    }

    // Please, do not remove this method even if there is no reference to it. This method can be used for debugging purposes
    public static Scenario getScenarioByKey(String key) {
        return SCENARIOS.get(key);
    }

    public static Response getContextScenario(Quote qt, List<BillingWrappers.BillingContract> billingContracts) {
        Response res = new Response();

        try {
            Context context = getContext(qt, billingContracts);

            Scenario sc = context.getScenario();

            if (sc == null) {
                res.error('Error', 'Scenario not found');
                return res;
            }
            if (SWNHelper.isLBOOrOfficeProductSelected(qt) && !QuoteHelper.isNewBusiness(qt)) {
                if (!qt.IsSendOrderToNGBS__c) {
                    for (Integer i = sc.stepNames.size() - 1; i >= 0 ; --i) {
                        if (sc.stepNames.get(i) != SWNStep.DISCOUNT_SYNC &&
                            sc.stepNames.get(i) != SWNStep.CONTRACT_SYNC &&
                            sc.stepNames.get(i) != SWNStep.REPRICE_SYNC) {
                            sc.stepNames.remove(i);
                        }
                    }
                    for (Integer i = sc.steps.size() - 1; i >=0 ; --i) {
                        if (sc.steps.get(i) != sc.stepsMap.get(SWNStep.DISCOUNT_SYNC) &&
                            sc.steps.get(i) != sc.stepsMap.get(SWNStep.CONTRACT_SYNC) &&
                            sc.steps.get(i) != sc.stepsMap.get(SWNStep.REPRICE_SYNC)) {
                            sc.stepsMap.remove(sc.steps.get(i).name);
                            sc.steps.remove(i);
                        }
                    }
                }
                if (qt.Opportunity.Type == OpportunityHelper.OPPORTUNITY_TYPE_NEW_BUSINESS &&
                    qt.Account.Offer_Type__c == AccountHelper.OFFER_TYPE_POC && sc.stepsMap.containsKey(SWNStep.ORDER)) {
                    for (Integer i = sc.stepNames.size() - 1; i >= 0 ; --i) {
                        if (sc.stepNames.get(i) == SWNStep.ORDER) {
                            sc.stepNames.set(i, SWNStep.UP_SELL);
                        }
                    }
                    for (Integer i = sc.steps.size() - 1; i >=0 ; --i) {
                        if (sc.steps.get(i) == sc.stepsMap.get(SWNStep.ORDER)) {
                            sc.stepsMap.remove(sc.steps.get(i).name);
                            sc.stepsMap.put(SWNStep.UP_SELL, SWNStep.STEPS.get(SWNStep.UP_SELL));
                            sc.steps.set(i, SWNStep.STEPS.get(SWNStep.UP_SELL));
                        }
                    }
                }
                if (sc.stepsMap.containsKey(SWNStep.ORDER)) {
                    Boolean hasOneTimeItems = false;
                    Boolean hasCreditLimitApprovals = false;
                    if (!qt.Approvals__r.isEmpty()) {
                        hasCreditLimitApprovals = true;
                    }
                    for (QuoteLineItem qli : qt.QuoteLineItems) {
                        if (!qli.Zero_Quantity__c && qli.Quantity > 0 && QuoteLineItemHelper.isOneTime(qli) && !Product2Helper.isTaxes(qli.Product2)) {
                            hasOneTimeItems = true;
                            break;
                        }
                    }
                    if (hasCreditLimitApprovals && hasOneTimeItems) {
                        sc.stepNames.add(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE);
                        sc.steps.add(SWNStep.STEPS.get(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE));
                        sc.stepsMap.put(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE, SWNStep.STEPS.get(SWNStep.SYNC_SPENDING_LIMIT_RETRIEVE));
                    }
                }
            }

            if (qt != null && sc.stepsMap.containsKey(SWNStep.REPRICE_SYNC)) {
                SWNHelper.filterRepriceStep(sc, qt, billingContracts);
            }

            if (qt != null && SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c) {
                SWNHelper.updateSimplifiedDownsellStep(sc, qt);
            }

            res.setData(SCENARIO, sc);
            res.setData(SCENARIO_KEY, context.getKey());
        } catch (Exception e) {
            res.error('Error', e.getMessage() + ': ' + e.getStackTraceString());
        }
        return res;
    }

    public static String getRCCCSyncStatus(Opportunity opp, Quote qt) {
        Context context = new Context();
        context.setFlow(new SyncToIcbFlow(qt));

        // In order to define MPUB or MPL flow isMultiproductTechnicalOpportunity__c field is used
        // instead of AccountHelper.isMPUB method because this method relies on MPUB enabled Feature Toggle
        // However Integration User has this FT disabled and method cannot define MPUB structure correctly
        // TODO: Remove this workaround after FT is enabled for Integration User
        Boolean isMPUB = !opp.isMultiproductTechnicalOpportunity__c;
        NGBSSyncables.ISyncable syncable = NGBSSyncables.getSyncable(isMPUB, qt.Id, opp);

        Map<String, Boolean> resultMap = new Map<String, Boolean> {
            SWNStep.DISCOUNT_SYNC => syncable.isDiscountsSynced(),
            SWNStep.CONTRACT_SYNC => syncable.isContractsSynced(),
            SWNStep.SYNC_TO_NGBS_UPSELL => syncable.isUpsellStepCompleted(),
            SWNStep.SYNC_TO_NGBS_DOWNSELL => syncable.isDownsellStepCompleted(),
            SWNStep.SYNC_TO_NGBS_UPGRADE => syncable.isUpgradeStepCompleted(),
            SWNStep.SYNC_INVOICE => syncable.isInvoiceStepCompleted(),
            SWNStep.CHARGE_TERM_SYNC => syncable.isChargeTermSynced()
        };

        for (SWNStep s : context.getScenario().steps) {
            if (!resultMap.containsKey(s.name)) {
                continue;
            }
            Boolean isStepSynced = resultMap.get(s.name);
            if (!isStepSynced) {
                return 'IN_PROGRESS';
            }
        }
        return 'COMPLETED';
    }

    private static Context getContext(Quote qt, List<BillingWrappers.BillingContract> billingContracts) {
        Context context = new Context();

        if (QuoteHelper.isEngage(qt)) {
            if (QuoteHelper.isEngageTerminationQuote(qt)) {
                context.setFlow(new AccountTerminationFlow());
            } else {
                context.setFlow(new EngageQuoteFlow(qt));
            }
            return context;
        }

        if (QuoteHelper.isNewBillingQuote(qt)) {
            context.setFlow(new SalesQuoteFlow(qt));
        }

        if (QuoteHelper.isNewBillingQuote(qt)
            && SettingsHelper.FEATURE_TOGGLE.Enable_Contract_Cancellation__c
            && SWNHelper.isContractWasDeselected(qt, billingContracts)
        ) {
            context.setFlow(new SalesQuoteCancellationFlow(qt));
        }

        if (QuoteHelper.isPOCQuote(qt)) {
            context.setFlow(new POCQuoteFlow(qt));
        }

        if (QuoteHelper.isRCCC(qt)) {
            context.setFlow(new SyncToIcbFlow(qt));
        }

        return context;
    }

    public static Response getSyncScenario(SWNDataCollector sdc) {
        Response res = new Response();
        try {
            String syncInfoField = sdc.syncable.getSyncInfoField();

            res = String.isBlank(syncInfoField)
                ? buildScenario(sdc)
                : getSyncScenarioFromJSON(sdc, syncInfoField);

            res.setData('qt', sdc.qt);
        } catch (Exception ex) {
            res.error('Error', ex.getMessage() + ': ' + ex.getStackTraceString());
        }

        return res;
    }

    public static Response getSyncScenarioFromJSON(SWNDataCollector sdc, String syncInfoField) {
        SWNSyncInfo syncInfo = (SWNSyncInfo) JSON.deserialize(syncInfoField, SWNSyncInfo.class);
        if (hasSimplifiedDownSell(sdc, syncInfo.stepNames)) {
            return buildScenario(sdc);
        }

        Response res = new Response();
        res.setData(SCENARIO, new Scenario(syncInfo.stepNames));
        res.setData(SCENARIO_KEY, syncInfo.scenarioName);
        return res;
    }

    private static Response buildScenario(SWNDataCollector sdc) {
        NGBSAPI.initNgbsEndpoints(sdc.opp.isFedRamp__c);
        return getContextScenario(sdc.qt, sdc.billingContracts);
    }

    private static Boolean hasSimplifiedDownSell(SWNDataCollector sdc, List<String> stepNames) {
        return SettingsHelper.FEATURE_TOGGLE.EnableSimplifiedLBODownsell__c
            && stepNames.contains(SWNStep.DOWN_SELL);
    }
}
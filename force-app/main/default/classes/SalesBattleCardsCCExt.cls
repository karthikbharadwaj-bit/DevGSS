public with sharing class SalesBattleCardsCCExt {
    public String ccFeatureDoc { get;set; }
    public String workOptimizationDoc { get;set; }
    public String customerSuccessDoc { get;set; }
    public String funcMatrixDoc { get;set; }
    public String ccBasicDoc { get;set; }
    public String ccAdvanceDoc { get;set; }
    public String ccUltimateDoc { get;set; }
    public String ordersDoc { get;set; }
    public String omniDoc { get;set; }
    public String smsDoc { get;set; }
    public String socialDoc { get;set; }


    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public SalesBattleCardsCCExt(ApexPages.StandardController stdController) {
        ccFeatureDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026wpe');
        workOptimizationDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026u4H');
        customerSuccessDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026u4M');
        funcMatrixDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026tf7');
        ccBasicDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uYv');
        ccAdvanceDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uZ0');
        ccUltimateDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uZ5');
        ordersDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uYH');
        omniDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uY7');
        smsDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uY2');
        socialDoc = HardcodedIdsMapper.getMatchedObjectId('015340000026uYC');
    }
}
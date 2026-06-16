@isTest
private class Test_SalesViewController {
    @isTest private static void controllerCanRedirectToLightningPage() {
        SalesViewController controller = new SalesViewController();
        System.assertNotEquals(controller.redirect(), null, 'Controller should return a valid link.');
        System.assert(controller.redirect().getUrl().contains('/lightning/n/Sales_View'), 'Controller should return a valid link.');
    }
}
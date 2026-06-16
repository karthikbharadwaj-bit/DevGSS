/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
@IsTest public with sharing class CommunitiesLandingControllerTest {
    @IsTest
    public static void testCommunitiesLandingController() {
        // Instantiate a new controller with all parameters in the page
        CommunitiesLandingController controller = new CommunitiesLandingController();
        PageReference pg = controller.forwardToStartPage();
        PageReference testPage = Network.communitiesLanding();

        System.assertEquals(String.valueOf(pg), String.valueOf(testPage));
    }
}
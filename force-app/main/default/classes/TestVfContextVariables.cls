@isTest
public class TestVfContextVariables {

    public static final String fakeUrl = 'https://rc--fake--c.visual.force.com';
    public static final String fakeSid = '00D55000000D7uD!ARkAQHx7kux39yALycipBR2iFOIocTm26r9FmCzAtVAKC9V0tGNFbM5sXzDlYYO' + 
            'FOfAxkye3Ym.FW1Y9JdVQvLA0kutsdI8d'; 

    @isTest
    private static void testGetVfContextVariables() {
        VfContextVariables vfContext = VfContextVariables.getVfContextVariables();
        System.assertEquals(fakeSid, vfContext.sid, 'Wrong session Id');
        System.assertEquals(fakeUrl, vfContext.url, 'Wrong visualforce url.');
    }
}
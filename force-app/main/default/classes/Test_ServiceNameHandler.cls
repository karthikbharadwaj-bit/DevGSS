@isTest
public class Test_ServiceNameHandler {
    @isTest
    static void test_getServiceName() {
        // this list was obtained based on all accounts on prod
        Assert.areEqual('AT&T Office@Hand', ServiceNameHandler.getServiceName('Office', 'AT&T Office@Hand'));
        Assert.areEqual('Avaya Cloud Office', ServiceNameHandler.getServiceName('Office', 'Avaya Cloud Office'));
        Assert.areEqual('Engage Digital Legacy', ServiceNameHandler.getServiceName('Engage Digital Legacy', null));
        Assert.areEqual('Engage Digital Standalone', ServiceNameHandler.getServiceName('Engage Digital Standalone', null));
        Assert.areEqual('Engage Voice Standalone', ServiceNameHandler.getServiceName('Engage Voice Standalone', null));
        Assert.areEqual('Meetings', ServiceNameHandler.getServiceName('Meetings', 'Unify Office'));
        Assert.areEqual('Rainbow Office', ServiceNameHandler.getServiceName('Office', 'Rainbow Office'));
        Assert.areEqual('RC Office AU', ServiceNameHandler.getServiceName('Office', 'RingCentral AU'));
        Assert.areEqual('RC Office Canada', ServiceNameHandler.getServiceName('Office', 'RingCentral Canada'));
        Assert.areEqual('RC Office EU', ServiceNameHandler.getServiceName('Office', 'RingCentral EU'));
        Assert.areEqual('RC Office', ServiceNameHandler.getServiceName('Office', 'RingCentral'));
        Assert.areEqual('RCMeetings', ServiceNameHandler.getServiceName('RCMeetings', null));
        Assert.areEqual('RingCentral Contact Center', ServiceNameHandler.getServiceName('RingCentral Contact Center', null));
        Assert.areEqual('RingCentral Fax Canada', ServiceNameHandler.getServiceName('Fax', 'RingCentral Canada'));
        Assert.areEqual('RingCentral Fax', ServiceNameHandler.getServiceName('Fax', 'RingCentral'));
        Assert.areEqual('RingCentral for Symphony', ServiceNameHandler.getServiceName('Office', 'RingCentral for Symphony'));
        Assert.areEqual('RingCentral mit ecotel', ServiceNameHandler.getServiceName('Office', 'RingCentral mit ecotel'));
        Assert.areEqual('RingCentral Office UK', ServiceNameHandler.getServiceName('Office', 'RingCentral UK'));
        Assert.areEqual('RingCentral Professional Canada', ServiceNameHandler.getServiceName('Professional', 'RingCentral Canada'));
        Assert.areEqual('RingCentral Professional UK', ServiceNameHandler.getServiceName('Professional', 'RingCentral UK'));
        Assert.areEqual('RingCentral Professional', ServiceNameHandler.getServiceName('Professional', 'RingCentral'));
        Assert.areEqual('RingCentral with Verizon', ServiceNameHandler.getServiceName(null, 'RingCentral with Verizon'));
        Assert.areEqual('TELUS Office', ServiceNameHandler.getServiceName('Office', 'TELUS Business Connect'));
        Assert.areEqual('Unify Office RCMeetings', ServiceNameHandler.getServiceName('RCMeetings', 'Unify Office'));
        Assert.areEqual('Unify Office', ServiceNameHandler.getServiceName('Office', 'Unify Office'));
        Assert.areEqual('Vodafone', ServiceNameHandler.getServiceName('Office', 'Vodafone Business with RingCentral'));

        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Frontier with RingCentral'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'RingCentral mit 1&1 Connected Calls'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'RingCentral mit Telekom'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Rise America'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Rise International'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Spectrum Business Connect with RingCentral'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Spectrum Enterprise Unified Communications with RingCentral'));
        Assert.areEqual('Office', ServiceNameHandler.getServiceName('Office', 'Unify Office by RingCentral'));

        // Legacy conditions
        Assert.areEqual('BT Office', ServiceNameHandler.getServiceName('Office', 'BT Business'));
        Assert.areEqual('eXtreme Fax', ServiceNameHandler.getServiceName('Fax', 'eXtreme Fax'));
        Assert.areEqual('TELUS Mobile', ServiceNameHandler.getServiceName('Mobile', 'TELUS Business Connect'));

        // Test unknown service
        Assert.areEqual('', ServiceNameHandler.getServiceName('Unknown', 'Unknown'));
    }
}
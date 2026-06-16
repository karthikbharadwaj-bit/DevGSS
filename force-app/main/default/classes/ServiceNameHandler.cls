public class ServiceNameHandler {
    private static final Map<String, String> serviceMap = new Map<String, String>{
        'RCMeetings' => 'RCMeetings',
        'RCMeetings:Unify Office' => 'Unify Office RCMeetings',
        'Meetings:Unify Office' => 'Meetings',
        'Office:RingCentral' => 'RC Office',
        'Office:AT&T Office@Hand' => 'AT&T Office@Hand',
        'Office:TELUS Business Connect' => 'TELUS Office',
        'Office:RingCentral Canada' => 'RC Office Canada',
        'Office:RingCentral UK' => 'RingCentral Office UK',
        'Office:RingCentral AU' => 'RC Office AU',
        'Office:Avaya Cloud Office' => 'Avaya Cloud Office',
        'Office:Vodafone Business with RingCentral' => 'Vodafone',
        'Office:RingCentral EU' => 'RC Office EU',
        'Office:Unify Office' => 'Unify Office',
        'Office:RingCentral for Symphony' => 'RingCentral for Symphony',
        'Office:Rainbow Office' => 'Rainbow Office',
        'Office:RingCentral mit ecotel' => 'RingCentral mit ecotel',
        'Fax:RingCentral' => 'RingCentral Fax',
        'Fax:RingCentral Canada' => 'RingCentral Fax Canada',
        'Professional:RingCentral' => 'RingCentral Professional',
        'Professional:RingCentral Canada' => 'RingCentral Professional Canada',
        'Professional:RingCentral UK' => 'RingCentral Professional UK',
        'Engage Digital Legacy' => 'Engage Digital Legacy',
        'Engage Voice Standalone' => 'Engage Voice Standalone',
        'Engage Digital Standalone' => 'Engage Digital Standalone',
        'RingCentral Contact Center' => 'RingCentral Contact Center',
        ':RingCentral with Verizon' => 'RingCentral with Verizon',

        // Other Office
        'Office:Spectrum Business Connect with RingCentral' => 'Office',
        'Office:Spectrum Enterprise Unified Communications with RingCentral' => 'Office',
        'Office:Rise International' => 'Office',
        'Office:Frontier with RingCentral' => 'Office',
        'Office:Unify Office by RingCentral' => 'Office',
        'Office:Rise America' => 'Office',
        'Office:RingCentral mit Telekom' => 'Office',
        'Office:RingCentral mit 1&1 Connected Calls' => 'Office',

        // Legacy conditions
        'Office:BT Business' => 'BT Office',
        'Fax:eXtreme Fax' => 'eXtreme Fax',
        'Mobile:TELUS Business Connect' => 'TELUS Mobile'
    };

    public static String getServiceName(String serviceType, String brand) {
        String key = (serviceType != null ? serviceType : '') + (brand != null ? ':' + brand : '');
        return serviceMap.containsKey(key) ? serviceMap.get(key) : '';
    }
}
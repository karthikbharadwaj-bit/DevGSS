public with sharing class RingCentralHelper{
  // Brand
  public static final String BRAND_RINGCENTRAL = 'RingCentral';
  public static final String BRAND_RINGCENTRAL_CANADA = 'RingCentral Canada';
  public static final String BRAND_RINGCENTRAL_UK = 'RingCentral UK';
  public static final String BRAND_RINGCENTRAL_EU = 'RingCentral EU';
  public static final String BRAND_RINGCENTRAL_AU = 'RingCentral AU';
  public static final String BRAND_TELUS = 'TELUS';
  public static final String BRAND_TELUS_BUSINESS_CONNECT = 'TELUS Business Connect';
  public static final String BRAND_ATT = 'AT&T';
  public static final String BRAND_BT_BUSINESS = 'BT Business';
  public static final String BRAND_BT = 'BT';
  public static final String BRAND_AVAYA = 'Avaya Cloud Office';
  public static final String BRAND_ATOS = 'Unify Office';
  public static final String BRAND_RAINBOW = 'Rainbow Office';
  public static final String BRAND_VODAFONE = 'Vodafone Business with RingCentral';
  public static final String BRAND_VODAFONE_EU = 'Vodafone EU';
  public static final String BRAND_VODAFONE_UK = 'Vodafone UK';
  public static final Set<String> BRANDS_VODAFONE_LEGACY = new Set<String>{ BRAND_VODAFONE_EU, BRAND_VODAFONE_UK };
  public static final string BRAND_VERIZON = 'RingCentral with Verizon';
  public static final string BRAND_ATTOFFICE = 'AT&T Office@Hand';
  public static final string BRAND_BIZDUMMY = 'Biz Dummy';

  // CurrencyIsoCode
  public static final String USD = 'USD';
  public static final String CAD = 'CAD';
  public static final String GBP = 'GBP';
  public static final String EUR = 'EUR';
  public static final String AUD = 'AUD';
  public static final String SGD = 'SGD';
  public static final String INR = 'INR';
  public static final String CHF = 'CHF';
  public static final String TWD = 'TWD';

  // Business Identity Id
  public static final String BUSINESS_IDENTITY_SINGAPORE = '45';
  public static final String BUSINESS_IDENTITY_RC_EU_FR = '1';
  public static final String BUSINESS_IDENTITY_RC_EU_DE = '33';
  public static final String BUSINESS_IDENTITY_VERIZON = '47';
  public static final String BUSINESS_IDENTITY_RC_EU_CH = '58';
  public static final String BUSINESS_IDENTITY_UO_CH = '59';
  public static final String BUSINESS_IDENTITY_ACO_CH = '60';

  public static String brandToCurrencyIsoCode(String brand){
    String result = USD;
    if (brand == BRAND_RINGCENTRAL_UK || brand == BRAND_BT || brand == BRAND_BT_BUSINESS || brand == BRAND_VODAFONE || brand == BRAND_VODAFONE_UK){
      result = GBP;
    } else if (brand == BRAND_RINGCENTRAL_CANADA || brand == BRAND_TELUS_BUSINESS_CONNECT){
      result = CAD;
    } else if (brand == BRAND_RINGCENTRAL_EU || brand == BRAND_VODAFONE_EU){
      result = EUR;
    } else if (brand == BRAND_RINGCENTRAL_AU){
      result = AUD;
    }
    return result;
  }

  public static List<String> getOrgCurrencyCodes() {
    List<String> currencyCodes = new list<string>();
    for(currencyType curr: [SELECT IsoCode FROM CurrencyType]){
        currencyCodes.add(curr.isocode);
    }
    return currencyCodes;
  }

}
public with sharing class AddressValidationApi implements HttpCalloutMock {

	public class CustomException extends Exception {}

	public static String mockJsonResponce = '';

	public static final String NO_ADDRESSES_TO_VALIDATE = 'There are no addresses to validate';
	public static final String LACK_OF_LOCATION_DATA = 'Please populate all required location fields';
	public static final String REQUEST_FAILED_ERROR_MESSAGE = 'Failed to connect to validation service. Response status: ';
	public static final String ENDPOINT_NOT_FOUND_ERROR_MESSAGE = 'Not found Address_Validation_API_Endpoint__c url. Check RingCentralVariousSettings__c custom setting';


	public class SFDCRequestDTO {
		@auraEnabled public AddressRequest addressStandardizationRequest;

		public SFDCRequestDTO(AddressRequest addressStandardizationRequest) {
			this.addressStandardizationRequest = addressStandardizationRequest;
		}
	}

	public class AddressRequest {
		@auraEnabled public List<AddressRequestItem> address;

		public AddressRequest(List<AddressRequestItem> address) {
			this.address = address;
		}
	}

	public class AddressRequestItem {
		@auraEnabled public String seqId;
		@auraEnabled public String addressLine1;
		@auraEnabled public String addressLine2;
		@auraEnabled public String city;
		@auraEnabled public String state;
		@auraEnabled public String zip;
		@auraEnabled public String country;

		public AddressRequestItem(String seqId, String addressLine1, String addressLine2, String city, String state, String zip, String country) {
			this.seqId = seqId;
			this.addressLine1 = addressLine1;
			this.addressLine2 = addressLine2;
			this.city = city;
			this.state = state;
			this.zip = zip;
			this.country = country;
		}
	}

	public class SFDCResponseDTO {
		@auraEnabled public AddressResponse response;

		public SFDCResponseDTO(AddressResponse response) {
			this.response = response;
		}
	}

	public class AddressResponse {
		@auraEnabled public List<AddressResponseItem>  addressStandardizationResponse;

		public AddressResponse(List<AddressResponseItem> addressStandardizationResponse) {
			this.addressStandardizationResponse = addressStandardizationResponse;
		}
	}

	public class AddressResponseItem{
		@auraEnabled public String seqId;
		@auraEnabled public String address;
		@auraEnabled public String adressLine;
		@auraEnabled public String addressQualityFlags;
		@auraEnabled public String carrierRoute;
		@auraEnabled public String city;
		@auraEnabled public String cityStateZip;
		@auraEnabled public String countyCode;
		@auraEnabled public String deliveryPointValidation;
		@auraEnabled public String enhancedLineOfTravel;
		@auraEnabled public String reliability;
		@auraEnabled public String state;
		@auraEnabled public String pcode;
		@auraEnabled public String zip;
		@auraEnabled public String zip4;
		@auraEnabled public String addressFault;

		public AddressResponseItem(String seqId, String address, String adressLine, String addressQualityFlags, String carrierRoute, String city, String cityStateZip, String countyCode, String deliveryPointValidation, String enhancedLineOfTravel, String reliability, String state, String pcode, String zip, String zip4, String addressFault) {
			this.seqId = seqId;
			this.address = address;
			this.adressLine = adressLine;
			this.addressQualityFlags = addressQualityFlags;
			this.carrierRoute = carrierRoute;
			this.city = city;
			this.cityStateZip = cityStateZip;
			this.countyCode = countyCode;
			this.deliveryPointValidation = deliveryPointValidation;
			this.enhancedLineOfTravel = enhancedLineOfTravel;
			this.reliability = reliability;
			this.state = state;
			this.pcode = pcode;
			this.zip = zip;
			this.zip4 = zip4;
			this.addressFault = addressFault;
		}
	}

	public static Map<String, AddressResponseItem> validateAddresses(List<AddressRequestItem> addressItemList) {

		if(addressItemList.isEmpty()){
			throw new CustomException(NO_ADDRESSES_TO_VALIDATE);
		}

		AddressRequest addressRequest = new AddressRequest(addressItemList);
		SFDCRequestDTO requestDTO = new SFDCRequestDTO(addressRequest);
		return sendRequest(requestDTO);
	}

	public static Map<String, AddressResponseItem> validateAddresses(List<Hardware_Line_Item__c> hliList) {

		if(hliList.isEmpty()){
			throw new CustomException(NO_ADDRESSES_TO_VALIDATE);
		}

		List<AddressRequestItem> addressItemList = new List<AddressRequestItem>();
		for(Hardware_Line_Item__c hli : hliList) {

			if(hli.Id == null || (new Set<String>{hli.Address_Line__c, hli.City__c, hli.State__c}).contains(null)){
				throw new CustomException(LACK_OF_LOCATION_DATA);
			}

			AddressRequestItem addressItem = new AddressRequestItem(
				hli.Id,
				hli.Address_Line__c,
				'',
				hli.City__c,
				hli.State__c,
				hli.Postal_Code__c,
				hli.Country__c
			);
			addressItemList.add(addressItem);
		}

		AddressRequest addressRequest = new AddressRequest(addressItemList);
		SFDCRequestDTO requestDTO = new SFDCRequestDTO(addressRequest);
		return sendRequest(requestDTO);
	}

	public static Map<String, AddressResponseItem> sendRequest(SFDCRequestDTO requestDTO) {

		String apiUrl = RingCentralVariousSettings__c.getInstance().Address_Validation_API_Endpoint__c;

        if(String.isBlank(apiUrl) || apiUrl == null) {
            throw new CustomException(ENDPOINT_NOT_FOUND_ERROR_MESSAGE);
        }

		String jsonRequestDTO = JSON.serialize(requestDTO);
        System.debug('///// Validate address JSON request(pretty) ' + JSON.serializePretty(requestDTO));

        HttpResponse response = makeRequest(apiUrl, 'POST', jsonRequestDTO);

        if (response.getStatus() != 'OK') {
            throw new CustomException(REQUEST_FAILED_ERROR_MESSAGE + response.getStatusCode() + ' ' +  response.getStatus());
        }

        String jsonResponse = response.getBody();
        SFDCResponseDTO result = (SFDCResponseDTO) JSON.deserialize(jsonResponse, SFDCResponseDTO.class);

        Map <String, AddressResponseItem> pliIdToResponseData = new Map<String, AddressResponseItem>();
        for (AddressResponseItem addressItem : result.response.addressStandardizationResponse) {
        	pliIdToResponseData.put(addressItem.seqId, addressItem);
        }
        return pliIdToResponseData;
	}

	@TestVisible
    private static HttpResponse makeRequest(String url, String method, String jsonRequestDTO) {

        if(String.isBlank(url) || String.isBlank(method) || String.isBlank(jsonRequestDTO)) {
            return null;
        }

        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(url);
        request.setTimeout(120000);
        request.setMethod(method);
        request.setBody(jsonRequestDTO);

        HttpResponse response = new Http().send(request);

        return response;
    }

    public HTTPResponse respond(HTTPRequest req) {

        System.assertEquals('POST', req.getMethod());

        // Create fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(mockJsonResponce);
        res.setStatus('OK');
        res.setStatusCode(200);
        return res;
    }

    public static Boolean isResponseValid(AddressResponseItem addrResponse){
        System.debug('addrResponse: '+ addrResponse);
        System.debug('isValid: '+ (addrResponse != null && String.isBlank(addrResponse.addressFault)));
        return addrResponse != null && String.isBlank(addrResponse.addressFault);
    }
}
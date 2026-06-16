@RestResource(urlMapping='/AssignmentLineItemService/*')
global with sharing class AssignmentLineItemService {

    private static final String ERROR_ACTION = 'Cannot find action';

    @HttpPost
    global static void handleRequest() {
        String body = RestContext.request.requestBody.toString();
        Response resp = new Response();

        if (RestContext.response == null) {
            RestContext.response = new RestResponse();
        }

        try {
            RequestParams params = (RequestParams) JSON.deserialize(body, RequestParams.class);

            switch on params.action {
                when 'createAssignmentLineItem' {
                    resp.setData(
                        createAssignmentLineItem(
                            params.parentId,
                            params.childId,
                            params.areaCodeId,
                            params.quantity
                        )
                    );
                }
                when 'syncAssignmentLineItems' {
                    resp.setData(
                        syncAssignmentLineItems(
                            params.quoteId,
                            params.alis
                        )
                    );
                }
                when 'getAssignmentLineItems' {
                    resp.setData(
                        getAssignmentLineItems(
                            params.parentId,
                            params.childId,
                            params.areaCodeId
                        )
                    );
                }
                when 'updateAssignmentLineItem' {
                    resp.setData(
                        updateAssignmentLineItem(
                            params.parentId,
                            params.childId,
                            params.areaCodeId,
                            params.quantity
                        )
                    );
                }
                when 'deleteAssignmentLineItem' {
                    resp.setData(
                        deleteAssignmentLineItem(
                            params.parentId,
                            params.childId,
                            params.areaCodeId
                        )
                    );
                }
                when 'getAssignmentLineItemsForQuote' {
                    resp.setData(
                        getAssignmentLineItemsForQuote(
                            params.quoteId
                        )
                    );
                }
                when else {
                    resp.setData('error', ERROR_ACTION);
                }
            }
        } catch (Exception ex) {
            RestContext.response.responseBody = Blob.valueOf(
                JSON.serialize(getErrorResponse(ex))
            );
        }
        RestContext.response.responseBody = Blob.valueOf(
            JSON.serialize(resp)
        );
    }

    private static Response createAssignmentLineItem(
        String parentId,
        String childId,
        String areaCodeId,
        String quantity
    ) {
        Response resp = new Response();

        if (String.isBlank(parentId) || String.isBlank(childId)) {
            resp.setData('assignmentLineItemId', null);
            return resp;
        }

        AssignmentLineItem__c assignment = (AssignmentLineItem__c) new SObjectBuilder(
            AssignmentLineItem__c.SObjectType
        )
            .setFields(new Map<SObjectField, Object> {
                AssignmentLineItem__c.Parent__c   => parentId,
                AssignmentLineItem__c.Child__c    => childId,
                AssignmentLineItem__c.AreaCode__c => areaCodeId,
                AssignmentLineItem__c.Quantity__c => Decimal.valueOf(
                    (String) NumberHelper.getNumberNullSafe(quantity)
                )
            })
            .create()
            .getRecord();

        resp.setData('assignmentLineItemId', assignment.Id);

        return resp;
    }

    private static Response syncAssignmentLineItems(
        String quoteId,
        List<BillingWrappers.AssignmentLineItem> alis
    ) {
        Response resp = new Response();
        List<AssignmentLineItem__c> alisToUpsert = new List<AssignmentLineItem__c>();
        List<AssignmentLineItem__c> alisToReturn = new List<AssignmentLineItem__c>();
        List<AssignmentLineItem__c> alisToDelete = new List<AssignmentLineItem__c>();
        Set<String> usedAlis = new Set<String>();

        List<AssignmentLineItem__c> assignments = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQuote(new List<Object> { quoteId })
            .executeQuery();

        Map<String, QuoteLineItem> elementIdToQliMap = QuoteLineItemHelper.buildElementIdToQliMap(
            (List<QuoteLineItem>) new QuoteLineItemSelector().selectQuoteLineItemsByQuoteIds(quoteId).executeQuery()
        );

        Map<String, Area_Codes__c> mergedAreaCodesMap = AreaCodeService.syncAreaCodesForAssignmentLineItem(alis, quoteId);

        for (BillingWrappers.AssignmentLineItem ali : alis) {

            String areaId = AreaCodeService.getAreaId(ali.areaCodeInfo);

            if (!mergedAreaCodesMap.containsKey(areaId)) {
                AquivaHelper.throwAquivaException('Error occurred during synchronization of assignment line items.');
            }

            Area_Codes__c sfAreaCode = mergedAreaCodesMap.get(areaId);

            AssignmentLineItem__c aliBootstrap = new AssignmentLineItem__c(
                AreaCode__c = sfAreaCode.Id,
                AreaCode__r = sfAreaCode,
                Child__c = elementIdToQliMap.get(ali.childId).Id,
                Child__r = elementIdToQliMap.get(ali.childId),
                Parent__c = elementIdToQliMap.get(ali.parentId).Id,
                Parent__r = elementIdToQliMap.get(ali.parentId),
                Quantity__c = ali.quantity
            );
            alisToReturn.add(aliBootstrap);

            // Find Existing Assignment Line Item
            AssignmentLineItem__c matchedALI;

            for (AssignmentLineItem__c existingAli : assignments) {
                if (
                    aliBootstrap.AreaCode__c == existingAli.AreaCode__c
                    && aliBootstrap.Child__c == existingAli.Child__c
                    && aliBootstrap.Parent__c == existingAli.Parent__c
                ) {
                    matchedALI = existingAli;
                    break;
                }
            }

            // Upsert Existing Assignment Line Item if changed
            if (matchedALI != null) {
                usedAlis.add(matchedALI.Id);
                aliBootstrap.Id = matchedALI.Id;
                if (aliBootstrap.Quantity__c != matchedALI.Quantity__c) {
                    alisToUpsert.add(aliBootstrap);
                }

            } else {
                // Insert new Assignment Line Item
                alisToUpsert.add(aliBootstrap);
            }
        }

        // Delete Assignment Line Item that are no longer used in assignment
        for (AssignmentLineItem__c existingAli : assignments) {
            if (!usedAlis.contains(existingAli.Id)) {
                alisToDelete.add(existingAli);
            }
        }

        upsert alisToUpsert;
        delete alisToDelete;

        // For spinnerless the custom address assignments will be removed in the corresponding method in "Single Save" process
        // otherwise shipping items won't be saved correctly
        if (!Feature_Toggle__c.getInstance().EnableSpinnerless__c) {
	        deleteCustomAdressesAssignments(alisToUpsert, alisToDelete);
        }

        resp.setData('upsertedAssignmentLineItems', alisToUpsert.size());
        resp.setData('assignmentLineItems', alisToReturn);
        resp.setData('deletedAssignmentLineItems', alisToDelete.size());

        return resp;
    }

    private static Response getAssignmentLineItems(
        String parentId,
        String childId,
        String areaCodeId
    ) {
        List<AssignmentLineItem__c> assignments = queryAssignmentLineItems(parentId, childId, areaCodeId);
        Response resp = new Response();

        resp.setData('assignmentLineItems', assignments);

        return resp;
    }

    private static Response updateAssignmentLineItem(
        String parentId,
        String childId,
        String areaCodeId,
        String quantity
    ) {
        List<AssignmentLineItem__c> assignments = queryAssignmentLineItems(parentId, childId, areaCodeId);
        Response resp = new Response();

        for (AssignmentLineItem__c asg : assignments) {
            asg.Quantity__c = (Decimal) NumberHelper.getNumberNullSafe(quantity);
        }

        resp.setData('updatedAssignmentLineItemsSize', assignments.size());

        return resp;
    }

    private static Response deleteAssignmentLineItem(
        String parentId,
        String childId,
        String areaCodeId
    ) {
        List<AssignmentLineItem__c> assignments = queryAssignmentLineItems(parentId, childId, areaCodeId);
        Response resp = new Response();

        delete assignments;

        resp.setData('deletedAssignmentLineItemsSize', assignments.size());

        return resp;
    }

    private static Response getAssignmentLineItemsForQuote(String quoteId) {
        List<AssignmentLineItem__c> assignments = (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQuote(new List<Object> { quoteId })
            .executeQuery();
        Response resp = new Response();

        resp.setData('assignmentLineItems', assignments);

        return resp;
    }

    @testVisible
    private static List<AssignmentLineItem__c> queryAssignmentLineItems(
        String parentId,
        String childId,
        String areaCodeId
    ) {
        List<AssignmentLineItem__c> assignments = new List<AssignmentLineItem__c>();

        if (
            String.isNotBlank(parentId) &&
            String.isNotBlank(childId) &&
            String.isNotBlank(areaCodeId)
        ) {
            assignments = getAssignmentLineItemsByAllRelated(parentId, childId, areaCodeId);
        } else if (
            String.isNotBlank(parentId) &&
            String.isNotBlank(childId)
        ) {
            assignments = getAssignmentLineItemsByQLIsId(parentId, childId);
        } else if (
            String.isNotBlank(parentId) ||
            String.isNotBlank(childId)
        ){
            String qliId = String.isNotBlank(parentId) ? parentId : childId;
            assignments = getAssignmentLineItemsByQLIId(qliId);
        }

        return assignments;
    }

    private static List<AssignmentLineItem__c> getAssignmentLineItemsByQLIId(String qliId) {
        return (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQLI(new List<Object> { qliId })
            .executeQuery();
    }

    private static List<AssignmentLineItem__c> getAssignmentLineItemsByQLIsId(
        String parentId,
        String childId
    ) {
        return (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForQLIsRelated(new List<Object> { parentId, childId })
            .executeQuery();
    }

    private static List<AssignmentLineItem__c> getAssignmentLineItemsByAllRelated(
        String parentId,
        String childId,
        String areaCodeId
    ) {
        return (List<AssignmentLineItem__c>) new AssignmentLineItemSelector()
            .selectALIForAllRelated(new List<Object> { parentId, childId, areaCodeId })
            .executeQuery();
    }

    @testVisible
    private static Map<String, String> getErrorResponse(Exception ex) {
        return new Map<String, String> {
            'error'      => ex.getMessage(),
            'stackTrace' => ex.getStackTraceString()
        };
    }

    public class RequestParams {
        public String action;
        public String quoteId;
        public String parentId;
        public String childId;
        public String areaCodeId;
        public String quantity;
        public List<BillingWrappers.AssignmentLineItem> alis;
    }

    public static void deleteCustomAdressesAssignments(List<AssignmentLineItem__c> alisToUpsert, List<AssignmentLineItem__c> alisToDelete) {
        List<Id> qliIdsFromChangedAssignmentLineItems = new List<Id>();
        for(AssignmentLineItem__c ali: alisToUpsert) {
            qliIdsFromChangedAssignmentLineItems.add(ali.Child__c);
        }
        for(AssignmentLineItem__c ali: alisToDelete) {
            qliIdsFromChangedAssignmentLineItems.add(ali.Child__c);
        }
        List<CustomAddressAssignments__c> customAddressesAssignmentsToDelete = new List<CustomAddressAssignments__c>();
        if (!qliIdsFromChangedAssignmentLineItems.isEmpty()) {
            customAddressesAssignmentsToDelete = new CustomAddressAssignmentsSelector()
                .selectCustomAddressAssignmentsByQliIds(qliIdsFromChangedAssignmentLineItems)
                .executeQuery();
        }
        if (!customAddressesAssignmentsToDelete.isEmpty()) {
            Triggers.switchOff();
            delete customAddressesAssignmentsToDelete;
            Triggers.switchOn();
        }
    }
}
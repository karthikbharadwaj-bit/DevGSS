public with sharing class POSignUpBodyHelper {

    public interface ISignUpBodyBuilder {
        POWrappers.SignUpRequestBody buildBody(POWrappers.SignUpParams data);
    }

    public class SignUpBodyBuilder implements ISignUpBodyBuilder {
        public POWrappers.SignUpRequestBody buildBody(POWrappers.SignUpParams data) {
            return buildSignUpBody(data);
        }

        private POWrappers.SignUpRequestBody buildSignUpBody(POWrappers.SignUpParams data) {
            SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
            manager.build(new SignUpRequestBuilderManager.OfferTypeBuilder())
                .build(new SignUpRequestBuilderManager.DefaultPackageLimitsBuilder())
                .build(new SignUpRequestBuilderManager.TaxSettingsBuilder())
                .build(new SignUpRequestBuilderManager.SubscriptionInfoBuilder())
                .build(new SignUpRequestBuilderManager.LBoxOverridesBuilder())
                .build(new SignUpRequestBuilderManager.IsTerminationOpportunityBuilder())
                .build(new SignUpRequestBuilderManager.UserBuilder())
                .build(new SignUpRequestBuilderManager.UBrandIdBuilder())
                .build(new SignUpRequestBuilderManager.PIDBuilder())
                .build(new SignUpRequestBuilderManager.SAFIDBuilder())
                .build(new SignUpRequestBuilderManager.EnterpriseAccountIdBuilder())
                .build(new SignUpRequestBuilderManager.BillingIdBuilder())
                .build(new SignUpRequestBuilderManager.RCAccountIDBuilder())
                .build(new SignUpRequestBuilderManager.OpportunityBuilder())
                .build(new SignUpRequestBuilderManager.ContractDescriptionBuilder())
                .build(new SignUpRequestBuilderManager.ContractTermBuilder())
                .build(new SignUpRequestBuilderManager.ContractAutoRenewalBuilder())
                .build(new SignUpRequestBuilderManager.ContractRenewalTermBuilder())
                .build(new SignUpRequestBuilderManager.EnablePhoneLeasingBuilder())
                .build(new SignUpRequestBuilderManager.OrderIdBuilder())
                .build(new SignUpRequestBuilderManager.FSCAmountBuilder())
                .build(new SignUpRequestBuilderManager.PlanDurationBuilder())
                .build(new SignUpRequestBuilderManager.BusinessIdentityIdBuilder())
                .build(new SignUpRequestBuilderManager.PromotionsBuilder())
                .build(new SignUpRequestBuilderManager.PackageBuilder())
                .build(new SignUpRequestBuilderManager.PreferredLanguageIdBuilder())
                .build(new SignUpRequestBuilderManager.BillingTimeZoneIdLanguageIdBuilder())
                .build(new SignUpRequestBuilderManager.TrialDurationBuilder())
                .build(new SignUpRequestBuilderManager.ELATypeBuilder())
                .build(new SignUpRequestBuilderManager.DiscountIDBuilder())
                .build(new SignUpRequestBuilderManager.ExemptFromStateAndLocalTaxesBuilder())
                .build(new SignUpRequestBuilderManager.RCBSBuilder())
                .build(new SignUpRequestBuilderManager.EnabledLBOBuilder())
                .build(new SignUpRequestBuilderManager.NGBSPartnerIdBuilder())
                .build(new SignUpRequestBuilderManager.PartnerPackageIdBuilder())
                .build(new SignUpRequestBuilderManager.PartnerPackageVersionBuilder())
                .build(new SignUpRequestBuilderManager.InContactBuilder())
                .build(new SignUpRequestBuilderManager.EnterpriseCustomerIdBuilder())
                .build(new SignUpRequestBuilderManager.BillingAlignmentEnabledBuilder())
                .build(new SignUpRequestBuilderManager.InvoiceConsolidationEnabledBuilder());

                if(QuoteHelper.isPOCQuote(data.targetQuote) && QuoteHelper.isEngageVService(data.targetQuote)) {
                    manager.build(new SignUpRequestBuilderManager.TargetPackageBuilder());
                } else {
                    manager.build(new SignUpRequestBuilderManager.ApprovedPackageLimitsBuilder())
                    .build(new SignUpRequestBuilderManager.PaymentMethodTypeBuilder());
                }

            manager.validateSignUpRequestBody();
            return manager.getSignUpRequestBody();
        }
    }

    public class ProServSignUpBodyBuilder implements ISignUpBodyBuilder {
        public POWrappers.SignUpRequestBody buildBody(POWrappers.SignUpParams data) {
            return buildSignUpProServBody(data);
        }

        private POWrappers.SignUpRequestBody buildSignUpProServBody(POWrappers.SignUpParams data) {
            SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
            manager.build(new SignUpRequestBuilderManager.BillingAccountIdBuilder())
                .build(new SignUpRequestBuilderManager.SalesOrderIdBuilder())
                .build(new SignUpRequestBuilderManager.ServiceInfoBuilder())
                .build(new SignUpRequestBuilderManager.ServiceOrderIdBuilder())
                .build(new SignUpRequestBuilderManager.SalesAgentIdBuilder());

            return manager.getSignUpRequestBody();
        }
    }

    public class EventsSignUpBodyBuilder implements ISignUpBodyBuilder {
        public POWrappers.SignUpRequestBody buildBody(POWrappers.SignUpParams data) {   
                if(data.targetQuote?.IsMultiProductTechnicalQuote__c){
                    return buildEventsMultiProdSignUpBody(data);
                }else{
                    return buildEventsStandaloneSignUpBody(data);
                }
        }

        public POWrappers.SignUpRequestBody buildEventsMultiProdSignUpBody(POWrappers.SignUpParams data) {
            SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
            manager.build(new SignUpRequestBuilderManager.BillingAccountIdBuilder())
            .build(new SignUpRequestBuilderManager.SalesOrderIdBuilder())
            .build(new SignUpRequestBuilderManager.ServiceOrderIdBuilder())
            .build(new SignUpRequestBuilderManager.SalesAgentIdBuilder())
            .build(new SignUpRequestBuilderManager.ServiceInfoBuilder());
            
            return manager.getSignUpRequestBody();
        }
    
        public POWrappers.SignUpRequestBody buildEventsStandaloneSignUpBody(POWrappers.SignUpParams data) {
            SignUpRequestBuilderManager manager = new SignUpRequestBuilderManager(data);
            manager.build(new SignUpRequestBuilderManager.BillingAccountIdBuilder())
            .build(new SignUpRequestBuilderManager.SalesOrderIdBuilder())
            .build(new SignUpRequestBuilderManager.ServiceOrderIdBuilder())
            .build(new SignUpRequestBuilderManager.SalesAgentIdBuilder())
            .build(new SignUpRequestBuilderManager.AccountInfoBuilder())
            .build(new SignUpRequestBuilderManager.ServiceInfoBuilder());
            return manager.getSignUpRequestBody();
        }
    }
}
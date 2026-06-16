import { LightningElement, track, api } from 'lwc';
import { getOppContactRoleInfo, handleError, showToast} from "c/clService";
import ClOpportunityInfo from 'c/clOpportunityInfo';
import alreadyContactRoleLabel from '@salesforce/label/c.ClContactRoleSelectorAlreadyContactRole';
import AdditionalBuyerinSalesCycle from '@salesforce/label/c.clContactRoleSelectorAdditionalBuyerinSalesCycle';
import SelectedAdditionalBuyer from '@salesforce/label/c.clContactRoleSelectorSelectedAdditionalBuyer';
import None from '@salesforce/label/c.clContactRoleSelectorNone';
import NoOpportunitynorContactwereselected from '@salesforce/label/c.clContactRoleNoOpportunitynorContactwereselected';
import PleaseselectanOpportunityandContactfromtheirrespectivelists from '@salesforce/label/c.clContactRolePleaseselectanOpportunityandContactfromtheirrespectivelists';
import NoContactwasselected from '@salesforce/label/c.clContactRoleNoContactwasselected';
import PleaseselectaContactfromthelist from '@salesforce/label/c.clContactRolePleaseselectaContactfromthelist';
import NoOpportunitywasselected from '@salesforce/label/c.clContactRoleNoOpportunitywasselected';
import PleaseselectanOpportunityfromthelist from '@salesforce/label/c.clContactRolePleaseselectanOpportunityfromthelist';
import NoAdditionalBuyerwasselected from '@salesforce/label/c.clContactRoleNoAdditionalBuyerwasselected';
import PleaseselectaAdditionalBuyerfromtheDrop from '@salesforce/label/c.clContactRolePleaseselectaAdditionalBuyerfromtheDrop';
import SelectAdditionalBuyer from '@salesforce/label/c.clContactRoleSelectorSelectAdditionalBuyer';
import NonePlaceHolder from '@salesforce/label/c.ClContactRoleSelectorNonePlaceHolder';
export default class ClContactRoleSelector extends LightningElement {
    @track selectedRole;
    @track contactRoleSectionShouldShow = false;
    @track isExpanded = true;
    @track showExistingContactRoleSelector = true;
    @track dropDownShouldShow = true;
    @track alreadyIsContactRole = false;
    @track selectedMatchedContactRole = false;
    @track isNewOppBeingCreated = false;
    @track selectedCon = [];
    @track selectedOpp = [];
    @track isPrimary = true;
    @track showApplyEditButton = false;
    @track alreadyContactRoleTitle = alreadyContactRoleLabel;
    @track label = {
        NonePlaceHolder,
        SelectAdditionalBuyer,
        SelectedAdditionalBuyer,
        AdditionalBuyerinSalesCycle,
        SelectedAdditionalBuyer,
        None,
        NoOpportunitynorContactwereselected,
        PleaseselectanOpportunityandContactfromtheirrespectivelists,
        NoContactwasselected,
        PleaseselectaContactfromthelist,
        NoOpportunitywasselected,
        PleaseselectanOpportunityfromthelist,
        NoAdditionalBuyerwasselected,
        PleaseselectaAdditionalBuyerfromtheDrop
        };

    connectedCallback() {
        window.addEventListener('onSelectExistingAccountForContactRole', this.loadContactRoleComponent.bind(this));
        window.addEventListener('onEditIsOkay', this.hideContactRoleSection.bind(this));
        window.addEventListener('onContactOpportunityEdited', this.hideContactRoleSection.bind(this));
        window.addEventListener('onContactOpportunityApplied', this.showContactRoleSection.bind(this));
        window.addEventListener('onRadioGroupChangeToNoOppCreated',
                                 eventData => {this.contactRoleSectionShouldShow = eventData.detail});
        window.addEventListener('onResetOpportunityFinished', this.hideContactRoleSection.bind(this));
        window.addEventListener('onCreateNewAcc', this.clearContactRoleVariables.bind(this));
    }

    clearContactRoleVariables() {
        this.selectedRole = null;
        this.isPrimary = null;
        CL.app.setMatchedContactRole(this.selectedRole, this.isPrimary);
    }

    showContactRoleSection() {
        this.contactRoleSectionShouldShow = true;
        this.showDropDownLogic();
    }

    hideContactRoleSection() {
        this.contactRoleSectionShouldShow = false;
        this.showDropDownLogic();
    }

    loadContactRoleComponent() {
        this.contactRoleSectionShouldShow = true;
        this.onClAppReady();
    }

    onClAppReady() {
        CL.app.rx.selectedOpportunity.subscribe(selectedOpportunity => {
            if (selectedOpportunity != this.selectedOpp) {
                this.selectedOpp = selectedOpportunity;
                if (this.selectedOpp && this.selectedCon) {
                    this.oppHasExistingPrimary();
                }
            }
        });
        CL.app.rx.selectedContact.subscribe(selectedContact => {
            if (selectedContact != this.selectedCon) {
                this.selectedCon = selectedContact;
                if (this.selectedOpp && this.selectedCon) {
                    this.oppHasExistingPrimary();
                }
            }
        });
        CL.app.rx.isCreateNewOpportunity.subscribe(isCreateNewOpportunity => {
            if (isCreateNewOpportunity) {
                this.alreadyIsContactRole = false;
                this.dropDownShouldShow = true;
            }
        });
    }

    oppHasExistingPrimary() {
        this.alreadyIsContactRole = false;
        getOppContactRoleInfo(this.selectedOpp.id, this.selectedCon.id)
            .then(r => {
                this.alreadyIsContactRole = r.data.alreadyAContactRole;
                this.isPrimary = !r.data.alreadyHasPrimary;
                if (this.alreadyIsContactRole) {
                    this.selectedRole = r.data.role;
                    CL.app.setMatchedContactRole(this.selectedRole, this.isPrimary);
                } else {
                    this.selectedRole = null;
                    CL.app.setMatchedContactRole(this.selectedRole, this.isPrimary);
                }
                this.showDropDownLogic();
            })
            .catch(handleError)
    }

    showDropDownLogic() {
        if (this.selectedOpp && this.selectedCon && this.alreadyIsContactRole) {
            this.dropDownShouldShow = false;
            this.selectedMatchedContactRole = false;
            this.showApplyEditButton = false;
            this.toggleContactRoleHasApplied(true);
        } else {
            this.alreadyIsContactRole = false;
            this.dropDownShouldShow = true;
            this.showApplyEditButton = true;
            this.selectedRole = null;
            this.selectedMatchedContactRole = false;
            this.isExpanded = true;
            
            if (CL.app.isCreateNewAccount != true) {
            this.toggleContactRoleHasApplied(false);
            } 
            if (CL.app.opportunityCreationOption == 'doNotCreateOpp'){
            this.toggleContactRoleHasApplied(true);
            }
        }
    }

    toggleIsExpanded() {
        let errorTitle = null;
        let errorMessage = null;
        this.toggleContactRoleHasApplied(false);
        !CL.app.selectedContact && !CL.app.selectedOpportunity
        && CL.app.opportunityCreationOption == 'selectExistingOpp' && CL.app.matchedOpportunities.length ?
                                                             (errorTitle =
                                                                this.label.NoOpportunitynorContactwereselected,
                                                             errorMessage =
                                                                this.label.PleaseselectanOpportunityandContactfromtheirrespectivelists
                                                                  )
                                : !CL.app.selectedContact ? (errorTitle = this.label.NoContactwasselected,
                                                             errorMessage = this.label.PleaseselectaContactfromthelist)
                                : !CL.app.selectedOpportunity
                                 && CL.app.opportunityCreationOption == 'selectExistingOpp' && CL.app.matchedOpportunities.length ?
                                                            (errorTitle = this.label.NoOpportunitywasselected,
                                                             errorMessage = this.label.PleaseselectanOpportunityfromthelist)
                                : null;
        !this.isExpanded && errorTitle ? showToast({title: errorTitle,
                                                    message: errorMessage,
                                                    type: 'error',
                                                    duration: 5000})
                                      : this.isExpanded = !this.isExpanded;

    }

    apply() {
        !this.selectedMatchedContactRole && this.dropDownShouldShow ? showToast({title: this.label.NoAdditionalBuyerwasselected,
                                                      message: this.label.PleaseselectaAdditionalBuyerfromtheDrop,
                                                      type: 'error',
                                                      duration: 5000})
                                         : this.isExpanded = !this.isExpanded,
                                           CL.app.setMatchedContactRole(this.selectedRole, this.isPrimary);
                                           this.toggleContactRoleHasApplied(!this.isExpanded);
    }

    toggleContactRoleHasApplied(hasApplied) {
        CL.app.opportunityContactRoleHasApplied = hasApplied;
    }

    get isCollapsedView() {
        return (!this.isExpanded || !this.showExistingAccountSelector);
    }

    get isExpandedView() {
        return this.isExpanded;
    }

    get isCollapsedView() {
        return !this.isExpanded;
    }

    get contactRoles() {
        return [
            { label: 'Influencer', value: 'Influencer' },
            { label: 'Decision Maker', value: 'Decision Maker' },
        ];
    }

    handleChange(event) {
        this.selectedRole = event.detail.value;
        this.selectedMatchedContactRole = true;
    }

    onModalOk() {
        window.addEventListener('onCreateNewAcc', function(){
            this.contactRoleSectionShouldShow = false;
        });
    }
}
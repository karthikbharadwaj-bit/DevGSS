import { LightningElement, track, api } from 'lwc';
import LookupService from './lookupService';

export default class InputLookup extends LightningElement {
    @api icon;
    @api method;
    @api label;
    @api placeholder;
    @api params;
    @api disabled;
    @api required = false;
    @api forcedAttributes; // temporary solution until rLookupServiceesearch on separated modal for dropdown
    @api isDisableLink = false;

    _class;
    @api
    set customClass(value) {
        this._class = 'slds-form-element ' + value;
    }

    get customClass() {
        return this._class;
    }

    isConnected = false;
    _value;
    @api
    set value(value) {
        this._value = value;
        this.isConnected && this.syncValue();
    }

    get value() {
        return this._value;
    }

    get lookupLink() {
        return this.valueObj && `/${this.valueObj.id}`;
    }

    @api
    get lookupId() {
        return this.valueObj && this.valueObj.id;
    }

    get dropdownIcon() {
        return this.isLoading ? 'utility:clock' : this.icon;
    }

    _isValidValue = true;
    @api
    get isValidValue() {
        return this._isValidValue;
    }
    _errorMessageUnderField;
    get errorMessageUnderField() {
        return this._errorMessageUnderField;
    }

    @api
    setFieldValidity(isValid, errorMessage) {
        this._isValidValue = isValid;
        this._errorMessageUnderField = errorMessage;
    }

    @api
    scrollToField() {
        let field = this.template.querySelector(".slds-has-error");
        field.scrollIntoView({behavior: 'smooth'});
        setTimeout(() => {field.focus()}, 300);
    }

    @track searchResults = [];
    @track isOpen = false;
    @track isLoading = false;
    @track selectedIndex = 0;
    @track valueObj = null;


    get isShowRemoveButton() {
        return this.isValueSelected && !this.disabled;
    }

    get isInputDisabled() {
        return this.disabled;
    }

    lookupService = null;

    connectedCallback() {
        this.isConnected = true;
        this.lookupService = new LookupService(this.method);
        this.syncValue();

        window.addEventListener('resize', () => this.setDropdownPosition());
        window.addEventListener('scroll', () => this.setDropdownPosition());
    }

    get isValueSelected() {
        return this.valueObj;
    }

    get isOneLetter() {
        return !this.isLoading && this.userText && this.userText.length === 1;
    }

    get comboboxCss() {
        return [
            'slds-combobox',
            this.isOpen && 'slds-is-open',
        ].filter(Boolean).join(' ');
    }

    get containerCss() {
        return [
            'slds-combobox_container',
            this.isValueSelected && 'slds-has-selection',
        ].filter(Boolean).join(' ');
    }

    get inputCss() {
        return [
            'slds-input slds-combobox__input',
            this.isValueSelected && 'slds-combobox__input-value slds-grid',
            !this._isValidValue && 'slds-has-error',
            this.isOpen && 'slds-has-focus',
        ].filter(Boolean).join(' ');
    }

    get formElementCss() {
        return [
            'slds-combobox__form-element slds-input-has-icon',
            this.isValueSelected ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right'
        ].filter(Boolean).join(' ');
    }

    @track _dropdownStyle = {};
    get dropdownStyle() {
        let styles = '';
        if (this._dropdownStyle) {
            for (let key in this._dropdownStyle) {
                styles += `${key}: ${this._dropdownStyle[key]};`;
            }
        }
        return styles;
    }

    get isNoResultsToDisplay(){
        return this.searchResults.length === 0 && !this.isLoading && !this.isOneLetter;
    }

    onFocus() {
        if (!this.isValueSelected && !this.disabled) {
            this.openDropdown();
            this.searchForText();
        }
    }

    onBlur() {
        this.hideDropdown();
    }

    onUserInput(event) {
        this.userText = event.target.value;
        this.searchForText();
    }

    openDropdown() {
        this.isOpen = true;
        setTimeout(() => this.setDropdownPosition());
    }

    hideDropdown() {
        delete this._dropdownStyle.opacity;
        delete this._dropdownStyle.transform;
        setTimeout(() => {
            this.isOpen = false;
            this._dropdownStyle = null;
        }, 300);
    }

    searchForText() {
        if (this.isOneLetter) {
            return;
        }
        this.isLoading = true;
        this.lookupService.search({
            searchText: this.userText,
            params: this.params,
            method: this.method
        })
            .then(results => {
                this.searchResults = results || [];
                this.selectedIndex = 0;
                this.isLoading = false;
                this.setDropdownPosition();
            });
    }

    searchForValue(recordId) {
        this.isLoading = true;
        this.lookupService.search({
            params: this.params,
            recordId: recordId,
            method: this.method
        })
            .then(results => {
                this.valueObj = results[0];
                this.isLoading = false;
            });
    }

    onSelect(event) {
        this.setValue(this.searchResults.find(r => r.id === event.currentTarget.dataset.id))
    }

    setValue(valueObj) {
        this.valueObj = valueObj;
        this.userText = '';
        this._isValidValue = true;
        this.fireChangeEvent();
        this.hideDropdown();
    }

    onRemoveClicked() {
        this.removeValue();
    }

    removeValue() {
        this.valueObj = null;
        this.setFieldValidity(!this.required, 'Complete this field.');
        this.fireChangeEvent();
    }

    fireChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                value: this.valueObj && this.valueObj.id,
                valueObj: this.valueObj
            }
        }));
    }

    syncValue() {
        if (this.value) {
            this.searchForValue(this.value);
        } else {
            this.valueObj = null;
        }
    }

    setDropdownPosition() {
        const dropdown = this.template.querySelector('.slds-dropdown');
        const input = this.template.querySelector('.slds-combobox__input');
        if (!dropdown || !input) {
            return;
        }

        const pos = this.getPopoverInfo({
            target: input,
            popover: dropdown,
            preferredPositions: ['bottom-middle', 'top-middle'],
            useTargetWidth: true,
            nubbin: 3
        });

        this._dropdownStyle = {
            ...pos.styles,
            'opacity': '1',
            'transform': 'none',
        };
    }


    getPopoverInfo(userProperties) {
        const defaultProperties = {
            target: null,
            popover: null,
            container: {
                getBoundingClientRect: () => {
                    return {
                        top: 0,
                        right: window.innerWidth,
                        bottom: window.innerHeight,
                        left: 0
                    };
                }
            },
            useTargetWidth: false,
            nubbin: 0,
            nubbinMargin: 0,
            preferredPositions: [],
            minHeight: null
        };
        const properties = Object.assign(defaultProperties, userProperties);
        const popoverRect = properties.popover.getBoundingClientRect();
        const targetRect = properties.target.getBoundingClientRect();
        const containerRect = properties.container.getBoundingClientRect();
        if (properties.useTargetWidth) {
            popoverRect.width = targetRect.width;
        }
        let top;
        let left;
        const nubbin = defaultProperties.nubbin; // Nubbin width [px]
        const nubbinMargin = defaultProperties.nubbinMargin; // Space from the edge to the nubbin [px]
        const popoverWidth = popoverRect.width + nubbin;
        const popoverHeight = popoverRect.height + nubbin;

        const isNumeric = n => !isNaN(parseFloat(n)) && isFinite(n);
        /**
         *  1) Check Space around target if popover will fit
         */
            // Enough space on the right
        const isRightOk = () => (containerRect.right - targetRect.right) > popoverWidth;

        // Enough space on the left
        const isLeftOk = () => (targetRect.left - containerRect.left) > popoverWidth;

        // Enough space on the top
        const isTopOk = () => (targetRect.top - containerRect.top) > popoverHeight;

        // Enough space on the bottom
        const isBottomOk = () => (containerRect.bottom - targetRect.bottom) > popoverHeight;

        // Enough space if popover is on the middle of the top/bottom side of the target
        const ishMiddleOk = () => ((targetRect.left - containerRect.left) > (popoverRect.width - targetRect.width) / 2) &&
            ((containerRect.right - targetRect.right) > (popoverRect.width - targetRect.width) / 2);

        // Enough space if popover is shifted to the Right
        const ishRightOk = () => (containerRect.right - targetRect.right) > (popoverRect.width - targetRect.width);

        // Enough space if popover is on the middle of the side of the target
        const isvMiddleOk = () => ((targetRect.top - containerRect.top) > (popoverRect.height - targetRect.height) / 2) &&
            ((containerRect.bottom - targetRect.bottom) > (popoverRect.height - targetRect.height) / 2);

        // Enough space if popover is shifted to the Top
        const isvTopOk = () => (targetRect.top - containerRect.top) > (popoverRect.height - targetRect.height);

        /**
         *  2) Decide where to put popover and calculate its position
         */
        let nubbinPosition;

        // Center popover vertically related to target
        const vMiddle = () => targetRect.bottom - containerRect.top - (targetRect.height / 2) - (popoverRect.height / 2);
        const vTop = () => targetRect.bottom - containerRect.top - (targetRect.height / 2) - popoverRect.height + nubbinMargin;
        const vBottom = () => targetRect.bottom - containerRect.top - (targetRect.height / 2) - nubbinMargin;

        // Center popover horizontally related to target
        const hMiddle = () => targetRect.right - containerRect.left - (targetRect.width / 2) - (popoverRect.width / 2);
        const hRight = () => targetRect.right - containerRect.left - (targetRect.width / 2) - nubbinMargin;
        const hLeft = () => targetRect.right - containerRect.left - (targetRect.width / 2) - popoverRect.width + nubbinMargin;

        const getSide = prefPosition => prefPosition && prefPosition.split('-')[0];
        const getShift = prefPosition => prefPosition && prefPosition.split('-')[1];
        const isSuitablePos = (val, position) => val === position || !val;

        const position = prefPosition => {
            if (isRightOk() && isSuitablePos(getSide(prefPosition), 'right')) {
                // Place popover on the right from target
                left = targetRect.right - containerRect.left + nubbin;
                nubbinPosition = 'left';
                if (isvMiddleOk() && isSuitablePos(getShift(prefPosition), 'middle')) {
                    // Popover in the middle
                    top = vMiddle();
                } else if (isvTopOk() && isSuitablePos(getShift(prefPosition), 'top')) {
                    // Shift Popover to the top
                    top = vTop();
                    nubbinPosition += '-bottom';
                } else if (isSuitablePos(getShift(prefPosition), 'bottom')) {
                    // Shift Popover to the bottom
                    top = vBottom();
                    nubbinPosition += '-top';
                }

            } else if (isLeftOk() && isSuitablePos(getSide(prefPosition), 'left')) {
                // Place popover on the left from target
                left = targetRect.left - popoverRect.width - nubbin;
                nubbinPosition = 'right';
                if (isvMiddleOk() && isSuitablePos(getShift(prefPosition), 'middle')) {
                    // Popover in the middle
                    top = vMiddle();
                } else if (isvTopOk() && isSuitablePos(getShift(prefPosition), 'top')) {
                    // Shift Popover to the top
                    top = vTop();
                    nubbinPosition += '-bottom';
                } else if (isSuitablePos(getShift(prefPosition), 'bottom')) {
                    // Shift Popover to the bottom
                    top = vBottom();
                    nubbinPosition += '-top';
                }

            } else if (isTopOk() && isSuitablePos(getSide(prefPosition), 'top')) {
                // Place popover on the top from target.
                top = targetRect.top - containerRect.top - popoverRect.height - nubbin;
                nubbinPosition = 'bottom';
                if (ishMiddleOk() && isSuitablePos(getShift(prefPosition), 'middle')) {
                    // Popover in the middle
                    left = hMiddle();
                } else if (ishRightOk() && isSuitablePos(getShift(prefPosition), 'right')) {
                    // Shift Popover to the right
                    left = hRight();
                    nubbinPosition += '-left';
                } else if (isSuitablePos(getShift(prefPosition), 'left')) {
                    // Shift Popover to the left
                    left = hLeft();
                    nubbinPosition += '-right';
                }

            } else if (isBottomOk() && isSuitablePos(getSide(prefPosition), 'bottom')) {
                // Place popover on the bottom from target.
                top = targetRect.bottom - containerRect.top + nubbin;
                nubbinPosition = 'top';
                if (ishMiddleOk() && isSuitablePos(getShift(prefPosition), 'middle')) {
                    // Popover in the middle
                    left = hMiddle();
                } else if (ishRightOk() && isSuitablePos(getShift(prefPosition), 'right')) {
                    // Shift Popover to the right
                    left = hRight();
                    nubbinPosition += '-left';
                } else if (isSuitablePos(getShift(prefPosition), 'left')) {
                    // Shift Popover to the left
                    left = hLeft();
                    nubbinPosition += '-right';
                }

            }
        };

        properties.preferredPositions.forEach(pos => {
            if (isNumeric(top) && isNumeric(left)) {
                return;
            }
            position(pos);
        });
        // If it is not possible to place popover on preferred position, place it automatically
        if (!isNumeric(top) && !isNumeric(left)) {
            position(null);
        }

        // 3) Convert position to css styles
        const isFit = isNumeric(top) && isNumeric(left);
        top = isNumeric(top) ? top : 0;
        left = Boolean(this.forcedAttributes?.left) ? this.forcedAttributes.left : isNumeric(left) ? left : 0;
        top = parseInt(top);
        left = parseInt(left);
        const maxHeight = containerRect.bottom - top;
        const styles = {
            'left': `${left}px`,
            'top': `${top}px`,
        };
        if (properties.useTargetWidth) {
            styles['width'] = popoverRect.width + 'px';
        }
        return {
            styles,
            offsets: {
                popover: {
                    top: popoverRect.top,
                    right: popoverRect.right,
                    bottom: popoverRect.bottom,
                    left: popoverRect.left,
                    maxHeight: maxHeight
                }
            },
            nubbinPosition,
            isFit
        };
    }
}
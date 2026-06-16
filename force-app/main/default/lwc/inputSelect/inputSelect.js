import {LightningElement, api, track} from 'lwc';
import getSelectField from '@salesforce/apex/AuraSFDescribeController.getSelectField';

export default class InputSelect extends LightningElement {
    @api label;
    @api sObjectName;
    @api recordTypeName;
    @api fieldName;
    @api value;
    @api options;
    @api disabled;
    @api isLoading;

    @track sfOptions;
    @track defaultValue;

    get selectOptions() {
        if (this.options) {
            return this.createOpts(this.options, this.value)
        } else if (this.sfOptions) {
            return this.createOpts(this.convertSfOpts(this.sfOptions), this.value)
        } else {
            return []
        }
    };

    connectedCallback() {
        if (this.canRetrieveOptionsFromSF()) {
            this.retrieveOptionsFromSF();
        }
    }

    canRetrieveOptionsFromSF() {
        return this.sObjectName && this.recordTypeName && this.fieldName;
    }

    retrieveOptionsFromSF() {
        getSelectField({
            sObjectName: this.sObjectName,
            recordTypeName: this.recordTypeName,
            fieldName: this.fieldName,
        })
            .then(r => {
                const options = JSON.parse(r.data.optionsSerialized);
                const describe = JSON.parse(r.data.describeSerialized);

                this.setPicklist(options, describe);
                this.dispatchEvent(new CustomEvent('ready', {detail: this.selectOptions}));
            });
    }

    setPicklist(options, describe) {
        if (!this.label) {
            this.label = describe.label;
        }
        const defaultValue = describe.defaultValue || options.length > 0 && options[0].Value;
        this.sfOptions = options;
        this.defaultValue = defaultValue;
    }

    convertSfOpts(options) {
        return options.map(o => {
            return {
                value: o.Value,
                label: o.Label
            }
        })
    }

    onchange(event) {
        this.dispatchEvent(new CustomEvent('change', {detail: event}));
    }

    /**
     * Creates array of maps for use in Select input options
     * Example helper.createOpts(['','one', {value: '2', label="two"}])
     * return [
     *        {value: '', label="--None--"},
     *        {value: 'one', label="one"},
     *        {value: '2', label="two"}
     *    ]
     */
    createOpts(opts, selectedValue) {
        selectedValue = selectedValue || '';
        const result = [];
        if (Array.isArray(opts)) {
            opts.forEach(opt => {
                let value;
                let label;
                if (typeof opt === 'string' || !opt) {
                    value = opt || '';
                    label = opt || '--None--';
                } else {
                    value = opt.value;
                    label = opt.label;
                }
                result.push({
                    value,
                    label,
                    selected: value === selectedValue
                });
            });
        }
        if (!result.find(v => v.selected)) {
            result.unshift(selectedValue);
            return this.createOpts(result, selectedValue);
        }
        result.map((o, index) => o.key = index);
        return result;
    }
}
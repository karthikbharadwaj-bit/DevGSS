({
    init: function (component, event, helper) {
        component.set('v.columns', [
            {
                label: 'Line Items',
                fieldName: 'lineItems',
                type: 'text'},
            {
                label: 'Current',
                fieldName: 'current',
                type: 'text'},
            {
                label: 'Proposed',
                fieldName: 'proposed',
                type: 'text'},
            {
                label: 'Delta',
                fieldName: 'delta',
                type: 'text'}
        ]);
        const tableType = component.get('v.tableType');
        const contactCenter = [
            'Plan', '# Seats Contracted', '# Seats Configured',
            'Price per Seat', 'Seat MRR', 'Minute Bundle Desc.',
            'Minute Bundle MRR', 'Minutes Charges', 'Bundle Total'
        ];
        const tollFree = [
            'Bundle Description', 'Minute Bundle Cost',
            'Bundle Overage Cost', 'Bundle Total'
        ];
        const largeMeetings = [
            'Option 1: Upgrade Editions', 'Option 1: Total Plan MRR',
            'Option 2: Purchase Meetings License', 'Option 2: Total Meetings MRR'
        ];
        const contactCenterTable = 'Contact center table';
        const tollFreeTable = 'Toll free table';
        const meetingsTable = 'Meetings table';
        let content = [];
        if (tableType == contactCenterTable) {
            Array.prototype.push.apply(content, contactCenter);
        } else if (tableType == tollFreeTable) {
            Array.prototype.push.apply(content, tollFree);
        } else if (tableType == meetingsTable) {
            Array.prototype.push.apply(content, largeMeetings);
        }
        let data = [];
        let action = component.get('c.getFieldValues');
        action.setParams({
            upsellId: component.get('v.recordId')
        });
        action.setCallback(this, resp => {
            const state = resp.getState();
            if(state == 'SUCCESS') {
                if (resp.getReturnValue() != null) {
                    if (tableType == contactCenterTable) {
                        for (let i = 0; i < content.length; i++) {
                            data.push({
                                id: i,
                                lineItems: content[i],
                                current: resp.getReturnValue()[i],
                                proposed: resp.getReturnValue()[i + content.length],
                                delta: resp.getReturnValue()[i + 2 * content.length]
                            });
                        }
                        const firstTitle = resp.getReturnValue()[Object.keys(resp.getReturnValue()).length - 3];
                        component.set('v.title', ((firstTitle.length === 0)? '0' : firstTitle));
                    } else if (tableType == tollFreeTable) {
                        const fixedLength = 27;
                        for (let i = fixedLength; i < content.length + fixedLength; i++) {
                            data.push({
                                id: i,
                                lineItems: content[i - fixedLength],
                                current: resp.getReturnValue()[i],
                                proposed: resp.getReturnValue()[i + content.length],
                                delta: resp.getReturnValue()[i + 2 * content.length]
                            });
                        }
                        const secondTitle = resp.getReturnValue()[Object.keys(resp.getReturnValue()).length - 2];
                        component.set('v.title', ((secondTitle.length === 0)? '0' : secondTitle));
                    } else if (tableType == meetingsTable) {
                        const fixedLength = 39;
                        for (let i = fixedLength; i < content.length + fixedLength; i++) {
                            data.push({
                                id: i,
                                lineItems: content[i - fixedLength],
                                current: resp.getReturnValue()[i],
                                proposed: resp.getReturnValue()[i + content.length],
                                delta: resp.getReturnValue()[i + 2 * content.length]
                            });
                        }
                        const thirdTitle = resp.getReturnValue()[Object.keys(resp.getReturnValue()).length - 1];
                        component.set('v.title', ((thirdTitle.length === 0)? '0' : thirdTitle));
                    }
                } else {
                    for (let i = 0; i < content.length; i++) {
                        data.push({
                            id: i,
                            lineItems: content[i],
                            current: '',
                            proposed: '',
                            delta: ''
                        });
                    }
                    component.set('v.title', '$0');
                }
                component.set('v.data', data);
            } else {
                alert('Can not get Upsell Dashboard content.');
            }
        });
        $A.enqueueAction(action);
    }
})